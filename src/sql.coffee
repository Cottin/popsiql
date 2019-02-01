{append, apply, concat, contains, curry, flatten, isEmpty, join, map, path, replace, test, toLower, toPairs, trim, type, union, unnest, values, where} = R = require 'ramda' # auto_require: ramda
{change, cc, doto, $, fmap, fmapObjIndexed, $$, toPair, mapO} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːID_Int_Seq, ːBool, ːStr, ːDate, ːDateTime, ːInt, ːFloat] = ['ID_Int_Seq', 'Bool', 'Str', 'Date', 'DateTime', 'Int', 'Float'] #auto_sugar

util = require 'util'
S = (o) -> util.inspect o, {depth: 9}
{_expandQuery, _expandWrite, _isSimple} = require './query'

class PopsiqlSQLError extends Error
	constructor: (msg) ->
		super msg
		@name = 'PopsiqlSQLError'
		Error.captureStackTrace this, PopsiqlSQLError

PSE = PopsiqlSQLError

###### HELPERS ################################################################
esc = (s) -> "\"#{s}\""
unEsc = (s) -> replace /\"/g, '', s
val = (x) -> if isNaN x then "'#{x}'" else x
ent = (e, model) -> esc model.$config.entityToTable e

addAlias = curry (aliases, node) ->
	if node.topLevel && !node.rels then return node
	alias = toLower node.entity[0]
	alias += node.entity[alias.length] while contains alias, aliases
	aliases.push alias

	if !node.rels then {...node, alias}
	else {...node, alias, rels: map addAlias(aliases), node.rels}

addAliases = (queries) ->
	fmap queries, (q) -> addAlias [], q


###### FROM ###################################################################
makeFrom = ({entity, rels}, model) ->
	"#{ent entity, model}#{rels && " as #{toLower entity[0]}" || ''}"


###### FIELDS #################################################################
makeFieldsForNode = ({allFields, allFlag, alias, rels}) ->
	# if allFlag then return []
	fs = fmap allFields, (s) -> alias && "#{alias}.#{esc(s)}" || esc(s)
	concat fs, doto rels || {}, map(makeFieldsForNode), values, flatten

# makeFields = (query) -> join(', ', makeFieldsForNode(query)) || '*'


###### WHERE ##################################################################
ops = {eq: '=', ne: '<>', gt: '>', gte: '>=', lt: '<', lte: '<=', in: 'IN',
like: 'LIKE', ilike: 'ILIKE', notlike: 'NOT LIKE', notilike: 'NOT ILIKE'}

toOpAndVal = (op, v) -> op == 'in' && "IN (#{map(val, v)})" || "#{ops[op]} #{val(v)}"

toPred = curry (alias, k, op, v) -> "#{alias && alias + '.' || ''}#{esc(k)} #{toOpAndVal(op, v)}"

toPreds = curry (alias, k, v) -> $ v, toPairs, map(apply(toPred(alias, k)))

makePreds = ({where, alias}) ->
	$ where, toPairs, map(apply(toPreds(alias))), flatten, join ' AND '


###### JOIN ###################################################################
makeJoinForNode = curry (model, query) ->
	{entity, alias, rels, where} = query
	if !rels then return []

	joins = fmapObjIndexed rels, (rel, k) ->
		[on1, on2] = model[entity].$rels[k].on
		"""left outer join #{ent rel.entity, model} as #{rel.alias} \
		on #{alias}.#{esc(on1)} = #{rel.alias}.#{esc(on2)}\
		#{if isEmpty rel.where then '' else ' AND ' + makePreds rel}"""

	concat values(joins), $(rels, map(makeJoinForNode(model)), values, flatten)

makeJoin = (query, model, newLine) -> join newLine, makeJoinForNode(model, query)


###### CREATE TABLE ###########################################################
coldef = (k, v) -> "#{esc k} #{v}"

makeColumns = (fields) ->
	res = doto fields, toPairs, map ([field, dataType]) ->
		if field == '$rels' || field == '$subs'
			return []

		if type(dataType) == 'Object'
			[k, v] = toPair dataType
			if k == 'oneToOne' then return [] # not yet implemented
			else if k == 'oneToMany' then return [] # not yet implemented
			else if k == 'manyToOne' then return [] # not yet implemented
			throw new PSE "Object type for key '#{k}' not yet implemented"

		notNull = if test /〳$/, dataType then '' else ' NOT NULL'
		dataTypeʹ = if test /〳$/, dataType then replace /〳$/, '', dataType else dataType
		switch dataTypeʹ
			when ːID_Int_Seq then coldef(field, 'serial') + ", PRIMARY KEY (\"#{field}\")"
			when ːStr then coldef field, 'text' + notNull
			when ːInt then coldef field, 'integer' + notNull
			when ːFloat then coldef field, 'float' + notNull
			when ːBool then coldef field, 'boolean' + notNull
			when ːDate then coldef field, 'date' + notNull
			when ːDateTime then coldef field, 'timestamp with time zone' + notNull
			else throw new PSE "unsupported data type '#{dataType}'"

	return flatten res

makeTables = (model) ->
	tables = []
	for entity, fields of model
		if entity == '$config' then continue

		tables.push """CREATE TABLE "public".#{ent entity, model} (
			#{join(',\n\t', makeColumns(fields))}
		);
		"""

	return tables


###### BUILD RESULT ###########################################################
buildColMap = ({entity, allFields, rels}) ->
	allFieldsʹ = fmap allFields, (f) -> [entity, f]
	if !rels then allFieldsʹ
	else concat allFieldsʹ, $ rels, values, map(buildColMap), unnest


###### SUB QUERIES ###########################################################
extractSubQueries = (query, model) ->
	res = flatten subsForNode model, [], query
	console.log '####################################################'
	console.log S res

subsForNode = curry (model, path, node) ->
	subs = []
	if node.subs
		test1 = $$ node.subs, values, mapO (v, key) -> {...v, key, path}
		console.log test1
		subs.push ...test1
		console.log subs

	if node.rels
		relSubs = $ node.rels, mapO((v, k) -> subsForNode(model, append(k, path), v)), values
		return subs.concat relSubs

	return subs

buildData = (query, rows, cache = {}) ->
	colMap = buildColMap query


	for row in rows
		obj = {}
		[lastEntity, _] = colMap[0]
		for col, i in row
			[entity, field] = colMap[i]
			if col == undefined then continue
			if entity != lastEntity
				cache = change {[lastEntity]: {[obj.id]: obj}}, cache
				obj = {}
			obj[field] = col
			lastEntity = entity
		cache = change {[lastEntity]: {[obj.id]: obj}}, cache

	return cache
	# fieldsʹ = map unEsc, fields
	# return fmap rows, (r) ->
	# 	console.log 0, fieldsʹ
	# 	console.log 0, r
	# 	zipObj fieldsʹ, r

handleQuery = (q, model, exec, cache, {newLine}) ->
	fields = makeFieldsForNode q

	sql = cc replace(/  /, ' '), trim, join(newLine), [
		"SELECT #{q.allFlag && '*' || join(', ', fields)}"
		"FROM #{makeFrom q, model}"
		makeJoin q, model, newLine
		if isEmpty q.where then '' else 'WHERE ' + makePreds q
	]
	sqlRows = exec sql
	data = buildData q, sqlRows, cache
	# dataʹ = await handleSubQueries q, model, data, exec
	return data


handleSubQueries = (query, model, data, exec) ->
	return _expandSubQuery query, model, data, (q, input) ->
		sql = 1
			# "SELECT #{makeFields q}"
			# "FROM #{makeFrom q, model}"
			# makeJoin q, model, newLine
			# if isEmpty q.where then '' else 'WHERE ' + makePreds q
		sqlRows = exec sql
		dataʹ = buildResult sqlRows, data
		return handleSubQueries q, model, dataʹ, exec




###### MAIN ###################################################################
module.exports =
	write: (query, model, options = {}) ->
		{query: queryʹ} = _expandWrite query, model

		"""INSERT INTO #{ent queryʹ.entity, model} \
		(#{doto(queryʹ.fields, map(esc), join(', '))}) VALUES \
		(#{doto(queryʹ.values, values, map(val), join(', '))}) RETURNING \
		#{doto(queryʹ.fields, union(['id']), map(esc), join(', '))};"""

	update: (query, model, options = {}) ->
	remove: (query, model, options = {}) ->
	read: (rawQuery, model, exec, options = {}) ->
		queries = _expandQuery rawQuery, model
		queriesʹ = addAliases queries
		newLine = if options.newLine then '\n' else ' '

		cache = {}
		for k,q of queriesʹ
			cache = await handleQuery q, model, exec, cache, {newLine}
		# res = $$ queriesʹ, map (q) ->
		# 	data = await handleQuery q, model, exec, {newLine}
		# 	return data

		# res = fmap queriesʹ, (q) ->
		# 	sql = cc replace(/  /, ' '), trim, join(newLine), [
		# 		"SELECT #{makeFields q}"
		# 		"FROM #{makeFrom q, model}"
		# 		makeJoin q, model, newLine
		# 		if isEmpty q.where then '' else 'WHERE ' + makePreds q
		# 	]
		# 	sqlRows = exec sql
		# 	console.log '--------------'
		# 	console.log util.inspect q, {depth: 8}
		# 	console.log '--------------'
		# 	console.log sqlRes
		# 	console.log '--------------'
		# 	subs = extractSubQueries q, model

		# 	data = buildData sqlRows
		# 	subData = await handleSubQueries q, model, data, exec

		# 	return sqlRes


		# console.log 3, res, _isSimple rawQuery
		# res2 = await PromiseProps res
		# console.log 6, res2
		# console.log 7, Promise.prop

		return cache
		# if _isSimple rawQuery then res2.query else res2

	buildResult: (query, rows, model) ->
		queries = _expandQuery query, model
		cache = {}
		for k, queryʹ of queries
			colMap = buildColMap queryʹ

			for row in rows
				obj = {}
				[lastEntity, _] = colMap[0]
				for col, i in row
					[entity, field] = colMap[i]
					if entity != lastEntity
						cache = change {[lastEntity]: {[obj.id]: obj}}, cache
						obj = {}
					obj[field] = col
					lastEntity = entity
				cache = change {[lastEntity]: {[obj.id]: obj}}, cache

		return cache







	createTables: (model, options = {}) ->
		tblsToCreate = makeTables model
		return join '\n', tblsToCreate

	# exportData: (model, options = {}) ->
	# importData: (model, data, options = {}) ->




















