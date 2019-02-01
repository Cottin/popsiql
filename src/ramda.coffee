{allPass, compose, contains, curry, equals, flatten, gt, gte, isEmpty, join, keys, length, lt, lte, map, mapObjIndexed, pick, pickBy, replace, test, union, values, where} = R = require 'ramda' # auto_require: ramda
{change, $} = RE = require 'ramda-extras' # auto_require: ramda-extras
[] = [] #auto_sugar

{_expandQuery, _isSimple} = require './query'

$$ = (data, functions...) -> compose(functions...)(data)

preds = {}

whereToComp = (where) ->
	$$ where, allPass, flatten, values, mapObjIndexed (preds, field) ->
		$$ preds, values, mapObjIndexed (v, op) ->
			switch op 
				when 'eq' then (o) -> equals o[field], v
				when 'ne' then (o) -> !equals o[field], v
				when 'gt' then (o) -> o[field] > v
				when 'lt' then (o) -> o[field] < v
				when 'gte' then (o) -> o[field] >= v
				when 'lte' then (o) -> o[field] <= v
				when 'in' then (o) -> contains o[field], v
				when 'like' then (o) -> test new RegExp(replace(/%/g, '.*', v)), o[field]
				when 'ilike' then (o) -> test new RegExp(replace(/%/g, '.*', v), 'i'), o[field]
				when 'notlike' then (o) -> ! test new RegExp(replace(/%/g, '.*', v)), o[field]
				when 'notilike' then (o) -> ! test new RegExp(replace(/%/g, '.*', v), 'i'), o[field]

readNode = curry (cache, node, join = null) ->
	# NOTE: this one could probably be optimized quite a bit if needed
	{entity, where: ʹwhere, fields, allFields, rels} = node

	where = if join then change ʹwhere, join else ʹwhere

	vals = null
	if isEmpty where then vals = $ cache[entity], values

	else if where.id && $(where, keys, length, equals(1)) && $ where.id, keys, equals ['eq']
		vals = [cache[entity][where.id.eq]]

	else
		comp = whereToComp(where)
		vals = $ cache[entity], pickBy(whereToComp(where)), values, map(pick(allFields))

	relFields = []
	if rels
		for val in vals
			for k, rel of rels
				[parentOnK, relOnK] = rel.parentOn
				val[k] = readNode cache, rel, {[relOnK]: {eq: val[parentOnK]}}
				relFields.push k

	valsʹ = map pick(union fields, relFields), vals

	if test /One〳?$/, node.parentMultiplicity then valsʹ[0]
	else valsʹ

	# return $ cache[entity], pickBy ({id, age}) -> id > 2 && id < 8 && age < 35 && age > 30



###### MAIN ###################################################################
module.exports =
	write: (query, model, options = {}) ->
	update: (query, model, options = {}) ->
	remove: (query, model, options = {}) ->
	read: (query, cache, model) ->
		queries = _expandQuery query, model

		# console.log JSON.stringify queries, null, 2

		res = map readNode(cache), queries
		# console.log 'res:', JSON.stringify res, null, 2

		if _isSimple query then res.query else res

















