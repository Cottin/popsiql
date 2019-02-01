{all, always, clone, concat, contains, has, head, identity, intersection, isEmpty, join, keys, length, mapObjIndexed, match, merge, pickBy, prepend, reject, replace, test, toLower, toUpper, type, union, where} = R = require 'ramda' # auto_require: ramda
{fchange, doto, $, fmap, fmapObjIndexed, $$, toPair} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːDateTime, ːInt, ːStr〳, ːInt〳, ːFloat, ːID_Int_Seq, ːDate〳, ːBool, ːBool〳, ːFloat〳, ːid, ːDate, ːDateTime〳, ːStr] = ['DateTime', 'Int', 'Str〳', 'Int〳', 'Float', 'ID_Int_Seq', 'Date〳', 'Bool', 'Bool〳', 'Float〳', 'id', 'Date', 'DateTime〳', 'Str'] #auto_sugar
util = require 'util'

sf = (o) -> JSON.stringify o, ((k, v) => if v == undefined then '__UNDEFINED__' else v), 0
sf2 = (o) -> JSON.stringify(o, ((k, v) => if v == undefined then '__UNDEFINED__' else v), 2)

class PopsiqlValidationError extends Error
	constructor: (query, msg) ->
		if type(query) == 'String' then super(query)
		else super(msg + ". Your query: #{sf query}")
		@name = 'PopsiqlValidationError'
		Error.captureStackTrace this, PopsiqlValidationError

PVE = PopsiqlValidationError

_ = (...xs) -> xs


_flattenBase = (base) ->
	[base, fieldsClause, rels] = base
	if type(base) == 'Array' then return concat _flattenBase(base), [[fieldsClause, rels]]

	entity = $ base, keys, head
	[fieldsClauseʹ, relsʹ] = base[entity]
	return [[fieldsClauseʹ, relsʹ, entity], [fieldsClause, rels]]

flattenComposed = (composedQuery) ->
	bases = _flattenBase composedQuery
	entity = null
	return fmap bases, ([fieldsClause, rels, entityʹ]) ->
		if entityʹ then entity = entityʹ
		{[entity]: if rels then [fieldsClause, rels] else [fieldsClause]}

expandQuery = (query, model, createMode) ->
	if !query then throw new PVE query, 'query cannot be nil'
	if !model then throw new PVE query, 'model cannot be nil'

	# console.log sf query

	ks = keys query
	if type(query) == 'Array'

		queries = flattenComposed query
		expanded = fmap queries, (q) ->
			[entity, body] = toPair q
			return expandNode([null, null], model, q)(body, entity)
		merged = _mergeQueries expanded
		return {query: merged}
		return
		[base, fieldsClause, rels] = query
		bases = flattenBase base
		return
		# console.log fieldsClause, rels
		# firstBase = head bases
		# console.log firstBase
		# entity = $ firstBase, keys, head
		# # restBases = $ bases, skip(1), map ()
		return null
	else if ks.length == 1 && ks[0][0] == toUpper(ks[0][0])
		[entity, body] = toPair query
		{query: expandNode([null, null], model, query)(body, entity)}
	else
		res = fmap query, (q) -> 
			[entity, body] = toPair q
			return expandNode([null, null], model, query)(body, entity)

		if type(query) == 'Array' then _merge res else res

_mergeQueries = (queries) ->
	entity = queries[0]?.entity
	merged = {entity, where: {}, fields: [], allFields: [], blockedFields: [], topLevel: true}
	for q in queries
		if entity != q.entity then throw new PVE 'cannot merge queries, with different top entity'

		mergeNode = (ref, n, isRel) ->
			if !isEmpty n.where
				ref.where = if isEmpty ref.where then n.where else {AND: [ref.where, n.where]}
			if !isEmpty n.fields
				if !isEmpty intersection ref.blockedFields, n.fields
					inter = intersection ref.blockedFields, n.fields
					throw new PVE "field(s) '#{join(', ', inter)}' is blocked in merged query, cannot select"
				ref.fields = union ref.fields, n.fields
			if !isEmpty n.allFields
				if !isEmpty intersection ref.blockedFields, n.allFields
					inter = intersection ref.blockedFields, n.fields
					throw new PVE "field(s) '#{join(', ', inter)}' is blocked in merged query, cannot select"
				ref.allFields = union ref.fields, n.fields
			if !isEmpty n.blockedFields
				ref.blockedFields = union ref.blockedFields, n.blockedFields
			if !isEmpty n.rels
				for k, v of n.rels
					ref.rels ?= {}
					if v == undefined then ref.rels[k] = undefined
					else
						if has(k, ref.rels) && ref.rels[k] == undefined
							throw new PVE "field '#{k}' is blocked in merged query, cannot select"
						ref.rels[k] ?= {entity: v.entity, where: {}, fields: [], allFields: [],
						blockedFields: [], parentOn: v.parentOn, parentMultiplicity: v.parentMultiplicity}
						mergeNode ref.rels[k], v

		mergeNode merged, q

	return merged




expandWrite = (query, model) ->
	if keys(query).length != 1
		throw new PVE query, 'multi write queries not (yet?) supported'

	op = doto query, keys, head
	if ! contains op, ['CREATE', 'UPDATE', 'DELETE']
		throw new PVE query, "unsupported write operation #{op}"

	queryʹ = query[op]

	expanded = expandQuery queryʹ, model
	ks = keys expanded
	if ks.length != 1 || ks[0] != 'query'
		throw new PVE query, 'multi or named alter queries not (yet?) supported'

	if expanded.query.rels
		throw new PVE query, 'multi level alter queries not (yet?) supported'

	# TODO: build validation separetly and use it here

	fchange expanded,
		query:
			where: undefined
			type: toLower op
			values: fmap expanded.query.where, (x) ->
				if type(x) != 'Object' || keys(x).length != 1 || keys(x)[0] != 'eq'
					throw new PVE query, 'no where clause allowed in alter queries'
				return x.eq

_merge = (qsʹ) ->
	return qsʹ


expandSub = ({parentEntity, model, query, key}) ->
	subType = type(model[parentEntity].$subs?[key])
	if subType == 'Object'
		k = $ model[parentEntity].$subs?[key], keys, head
		if model[parentEntity].$rels?[k]
			[entityK] = model[parentEntity].$rels[k].on
			return {deps: {fields: [entityK]}, rel: model[parentEntity].$subs?[key]}
			# TODO: some validation of the sub here maybe?
		else if model[parentEntity].$subs?[k]
			throw new PVE query, 'not yet implemented'
		else
			throw new PVE query, "invalid subquery #{parentEntity}/#{key}"
	else if subType == 'Function'
		throw new PVE query, "sub as function not yet supported"
	else
		throw new PVE query, "sub need to be object or function not #{subType} (#{parentEntity}/#{key})"

expandBody = ({model, entity, query, body}) ->
	if type(body) != 'Array'
		throw new PVE query, "the body of a query needs to be an Array, not an #{type(body)}"
	[fieldsClause, relsAndSubs] = body

	if !fieldsClause
		throw new PVE query, "fields clause is always required"

	if type(fieldsClause) != 'Object'
		throw new PVE query, "fields clause must be an Object not '#{type(fieldsClause)}'"

	rels = {}
	subs = {}
	for k,v of relsAndSubs
		if model[entity].$rels?[k] then rels[k] = v
		else if model[entity].$subs?[k] then subs[k] = v
		else throw new PVE query, "no relation or subquery '#{k}' on entity '#{entity}'"

	return {fieldsClause, rels, subs}

expandFieldsClause = ({fieldsClause, query}) ->
	fields = []
	blockedFields = []

	addToFields = (k) ->
		if test /〳$/, k then blockedFields = union blockedFields, [replace /〳$/, '', k]
		else fields = union fields, [k]

	resolveFieldsClause = (fieldsClause) ->
		return fmapObjIndexed fieldsClause, (v, k) ->
			# kʹ = replace /〳$/, '', k
			# isBlocked = test /〳$/, k
			# console.log k, kʹ
			if k == 'AND' || k == 'OR'
				if type(v) != 'Array' || length(v) != 2
					throw new PVE query, "AND / OR clause must have array of length two"
				[left, right] = v
				return [resolveFieldsClause(left), resolveFieldsClause(right)]
			else if type(v) == 'String' && k == 'ː'+v
				addToFields k.substr(1)
				return undefined
			else if type(v) == 'Object'
				addToFields k
				return v
			else 
				addToFields k, v
				return {eq: v}

	where = $ fieldsClause, resolveFieldsClause, pickBy (x) -> x != undefined

	return {fields, blockedFields, where}

expandNode = ([parentEntity, parentBody], model, query) -> (body, key) ->
	###### entity
	if !parentEntity
		if !model[key] then throw new PVE query, "no entity '#{key}' in model"
		entity = key
	else
		if model[parentEntity].$rels?[key]
			{entity} = model[parentEntity].$rels[key]
		else if model[parentEntity].$subs?[key]
			return expandSub {parentEntity, model, query, key}
		else
			throw new PVE query, "no relation or subquery '#{key}' on entity '#{parentEntity}'"

	###### fieldsClause, rels, subs
	if type(body) == 'Undefined' then return undefined
	{fieldsClause, rels, subs} = expandBody {model, entity, query, body}

	###### fields, blockedFields, where
	{fields, blockedFields, where} = expandFieldsClause {fieldsClause, query}

	###### isAggregation
	isAggregation = undefined
	AGG_REGEX = /〳(\w+)$/
	for f in fields
		if !model[entity][f] && f != 'ALL'
			if test AGG_REGEX, f
				[___, op] = match AGG_REGEX, f
				if !contains op, ['COUNT', 'SUM', 'MIN', 'MAX', 'AVG']
					throw new PVE query, "invalid aggregation '#{f}' on entity '#{entity}'"
				isAggregation = true
			else
				throw new PVE query, "invalid field '#{f}' on entity '#{entity}'"

	if isAggregation && !all test(AGG_REGEX), fields
		throw new PVE query, "mixing aggr. and normals not (yet?) supported ['#{join("', '", fields)}']"

	###### allFlag
	res = {entity, where, fields, blockedFields}
	if isAggregation then res.isAggregation = true
	if contains 'ALL', fields
		res.fields = $ model[entity], keys, reject test /^\$/
		res.allFlag = true

	###### allFields
	res.allFields = clone res.fields
	if rels
		for k of rels
			[entityK] = model[entity].$rels[k].on
			if ! contains entityK, res.allFields then res.allFields.push entityK

	if parentBody
		[___, parentrels] = parentBody
		for k of parentrels
			if k != key then continue
			[parentK, relK] = model[parentEntity].$rels[k].on
			if ! contains relK, res.allFields then res.allFields.push relK
			res.parentOn = model[parentEntity].$rels[k].on
			res.parentMultiplicity = model[parentEntity].$rels[k].multiplicity

	if ! contains ːid, res.allFields then res.allFields.push ːid # force ːid

	###### continuation: rels and subs
	if !isEmpty rels
		res.rels = mapObjIndexed expandNode([entity, body], model, query), rels
	if !isEmpty subs
		res.subs = mapObjIndexed expandNode([entity, body], model, query), subs
	if !parentEntity then res.topLevel = true

	return res

_camelToSnake = (s) -> doto s, replace(/^./, toLower s[0]), replace /[A-Z]/, (s) -> '_' + toLower s

createModel = (spec) ->
	model = {$config: {entityToTable: identity}} # default config

	# first pass for fields (and config)
	for entity, fields of spec
		if entity == '$config'
			for k, v of fields
				if k == 'entityToTable'
					if type(v) == 'Function' then entityToTable = v
					else if v == 'camelToSnake' then model.$config.entityToTable = _camelToSnake
					else throw new PVE "invalid config for entityToTable, '#{sf(v)}'"
			continue

		if entity[0] != toUpper(entity[0])
			throw new PVE "entity must begin with uppercase character, see entity '#{entity}'"
		o = model[entity] = {}

		for k, v of fields
			switch v
				when ːStr, ːInt, ːBool, ːFloat, ːDate, ːDateTime then o[k] = v
				when ːStr〳, ːInt〳, ːBool〳, ːFloat〳, ːDate〳, ːDateTime〳 then o[k] = v
				when ːID_Int_Seq then o[k] = v
				else
					if type(v) != 'Object'
						throw new PVE "unknown field type '#{v}' in model '#{entity}'"

					[k1, v1] = toPair v
					switch k1
						when 'oneToOne', 'oneToMany', 'manyToOne', 'oneToOne〳', 'oneToMany〳', 'manyToOne〳'
							if type(v1) != 'String' then throw new PVE "invalid relationship '#{v1}'"
							o._$rels ?= {}
							o._$rels[k] = {type: k1, link: v1}
						else
							o._$unknownFields ?= []
							o._$unknownFields.push [k, k1, v1]

	# second pass for rels
	for entity, fields of model
		if fields._$rels
			fields.$rels = {}
			for k, v of fields._$rels
				[___, e1, e1p, e2, e2p] = match /(.*?)\.(.*)\s=\s(.*?)\.(.*)/, v.link
				if ! contains e1, keys(model)
					throw new PVE "invalid link '#{v.link}' to non-existing entity '#{e1}'"
				if ! contains e2, keys(model)
					throw new PVE "invalid link '#{v.link}' to non-existing entity '#{e2}'"
				if e1 != entity
					throw new PVE "first entity '#{e1}' need to be '#{entity}' in link '#{v.link}'"
				if e1p == k
					throw new PVE """linking column '#{e1p}' cannot have same name as relationship \
					itself ('#{k}') for entity '#{entity}'"""

				fromForeignType = (dataType) ->
					if dataType == ːID_Int_Seq then ːInt
					else dataType

				if ! has e1p, fields then fields[e1p] = fromForeignType model[e2][e2p]
				else if ! has e2p, model[e2] then model[e2][e2p] = fromForeignType fields[e1p]


				fields.$rels[k] = {multiplicity: v.type, entity: e2, on: [e1p, e2p]}
				
			delete fields._$rels

	# third pass for unknownFields (subs)
	for entity, fields of model
		if fields._$unknownFields
			fields.$subs = {}
			subSubs = []
			subsForFaking = {}
			for [field, k, v] in fields._$unknownFields
				rel = fields.$rels?[k]
				if rel
					try
						relFakeQuery = {[rel.entity]: _ {[rel.on[1]]: 'fake-id'}}
						subFakeQuery = prepend relFakeQuery, v
						expandedFakeQuery = expandQuery subFakeQuery, model
						subsForFaking[field] = subFakeQuery
						# fields.$subs[field] = [expandedFakeQuery.query]
						fields.$subs[field] = {[k]: v}
					catch err
						err.message += " ...for subquery #{JSON.stringify {[k]: v}} on entity #{entity}"
						throw err
				else
					subSubs.push [field, k, v]

			while subSubs.length > 0
				toRemove = []
				for [field, k, v], i in subSubs
					if fields.$subs[k]
						try
							fakeQuery = prepend subsForFaking[k], v
							expandedFakeQuery = expandQuery fakeQuery, model
							subsForFaking[field] = subFakeQuery
							fields.$subs[field] = {[k]: v}
							toRemove.push i
						catch err
							err.message += " ...for subquery #{JSON.stringify {[k]: v}} on entity #{entity}"
							throw err

				for i in toRemove
					subSubs.splice(i, 1)

				if isEmpty toRemove 
					throw new PVE """invalid relationship or property or infinate loop in model '#{entity}'
					keys so far: #{keys(subsForFaking)}
					#{sf2 subSubs}"""

			delete fields._$unknownFields


	return model

module.exports =

	_isSimple: (query) ->
		ks = keys query
		return ks.length == 1 && ks[0][0] == toUpper(ks[0][0])

	_expandQuery: expandQuery
	_expandWrite: expandWrite

	_camelToSnake: _camelToSnake

	createModel: createModel




















