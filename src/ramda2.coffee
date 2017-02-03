___ = module.exports
{__, allPass, append, complement, compose, contains, drop, equals, filter, findIndex, flatten, gt, gte, head, isEmpty, isNil, keys, lensPath, lt, lte, map, max, over, project, prop, propEq, propSatisfies, props, replace, set, sort, take, test, toPairs, type, values, where} = R = require 'ramda' #auto_require:ramda
{cc, getPath} = require 'ramda-extras'
co = compose
util = require 'util'

# s -> [s, a] -> f   Builds a predicate function
# eg. 'name' -> (['eq', 'elin']) -> propEq('name', 'elin')
toPred = (k0) -> ([k, v]) ->
	switch k
		when 'eq' then propEq(k0, v)
		when 'neq' then complement propEq(k0, v)
		when 'gt' then propSatisfies gt(__, v), k0
		when 'gte' then propSatisfies gte(__, v), k0
		when 'lt' then propSatisfies lt(__, v), k0
		when 'lte' then propSatisfies lte(__, v), k0
		when 'in' then propSatisfies contains(__, v), k0
		when 'nin' then propSatisfies complement(contains(__, v)), k0
		when 'like' then (o) ->
			re = new RegExp(replace(/%/g, '.*', v), 'i')
			test re, o[k0]

# [s, a] -> [f]   Builds an array of predicate functions for the property k
toPreds = ([k, v]) ->
	if R.is Object, v
		cc map(toPred(k)), toPairs, v
	else
		# if no predicate given, we assume an implicit equals
		propEq k, v

# o -> f   Builds a predicate function for the where part of the query object
_where = (query) ->
	props = toPairs query.where
	preds = cc flatten, map(toPreds), props
	return filter allPass(preds)

# a -> f   Builds a filter function for the id part of the query
_whereId = (ids) ->
	return filter (o) ->
		if o && o.id && contains o.id, ids then true
		else false

# o -> f   Builds the get function from the query object
_get = (query) -> (data) ->
	data_ = getPath query.get, data
	if isNil(data_) || isEmpty(data_) then return null

	{where, id} = query

	if id
		ids = if R.type(id) == 'Array' then id else [id]
		data_ = _whereId(ids)(data_)
	else if where
		data_ = _where(query)(data_)

	if isNil(data_) || isEmpty(data_) then return null

	{sort} = query
	if sort
		if type(sort) == 'Array'
			toComparator = (a) ->
				if type(a) == 'Object'
					k = cc head, keys, a
					v = a[k]
					if v == 'desc' then return R.descend(prop(k))
					else if v == 'asc' then return R.ascend(prop(k))
					else throw new Error 'sort direction must be asc or desc, given: ' + v
				else if type(a) == 'Array'
					throw new Error 'invalid sort array given, elements cannot be arrays'
				else
					return R.ascend(prop(a))

			comparators = map toComparator, sort
			data_ = R.sortWith comparators, values(data_)
		else
			data_ = R.sortWith [R.ascend(prop(sort))], values(data_)

	{start} = query
	if start
		if type(data_) == 'Object'
			data_ = values data_
		data_ = drop start, data_

	{max} = query
	if max
		if type(data_) == 'Object'
			data_ = values data_

		data_ = take max, data_

	{fields} = query
	if fields
		data_ = project fields, data_
	
	return data_

# o -> f   Returns a set function from the query object
_set = (query) -> (data) ->
	key = cc head, keys, query.set
	if query.where
		idx = findIndex _where(query), data[key]
		dataLens = lensPath [key, idx]
	else
		dataLens = lensPath [key]

	return set dataLens, query.set[key], data

# o -> f   Returns an append function from the query object
_push = (query) -> (data) ->
	key = cc head, keys, query.push
	dataLens = lensPath [key]

	return over dataLens, append(query.push[key]), data

# o -> f   Converts a popsiql query to a function using ramda functions
___.toRamda = toRamda = (query) ->
	if query.get then return _get query
	else if query.set then return _set query
	else if query.push then return _push query

	throw new Error 'no valid operation found in query ' + JSON.stringify(query)
