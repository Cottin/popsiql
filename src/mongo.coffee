{assoc, curry, dissoc, find, gt, gte, has, isNil, lt, lte, map, merge, none, replace, sort, type, values, where} = require 'ramda' # auto_require:ramda
{cc, change, yfoldObj} = require 'ramda-extras'

utils = require './utils'

# mappings between popsiql predicate/values to mongo query
_mongoMapping =
	eq: (v) -> {$eq: v}
	neq: (v) -> {$ne: v}
	in: (v) -> {$in: v}
	nin: (v) -> {$nin: v}
	gt: (v) -> {$gt: v}
	gte: (v) -> {$gte: v}
	lt: (v) -> {$lt: v}
	lte: (v) -> {$lte: v}
	like: (v) -> {$regex: new RegExp(replace(/%/g, '.*', v), 'i')}

# o -> o   # converts a map of popsiql preds to mongo preds
_predsToMongoPreds = (preds) ->
	return yfoldObj preds, {}, (acc, k, v) ->
		merge acc, _mongoMapping[k](v)

# o -> o
# converts a popsiql where to a mongo "find"
_whereToFind = (where) ->
	if isNil where then return {}

	{id} = where
	if isNil id then where_ = where
	else where_ = change {_id: id, id: undefined}, where

	return yfoldObj where_, {}, (acc, k, v) ->
		if type(v) != 'Object' then assoc k, {$eq: v}, acc # implicit eq
		else assoc k, _predsToMongoPreds(v), acc

# o -> o
# takes a popsiql query and returns the parts of the corresponding mongo query
toMongo = (query) -> 
	utils.validate query # we want to assume a valid query in this adapter

	op = utils.getOp query
	entity = utils.getEntity query
	find = _whereToFind query.where
	skip = if query.start then parseInt(query.start)
	limit = if query.max then parseInt(query.max)
	sort = if query.sort then 'not yet implementd'
	return {op, entity, find, skip, limit, sort}

# o -> o   # replaces _id with id on x
_idToid = (x) ->
	if ! has '_id', x then x
	else cc assoc('id', x._id), dissoc('_id'), x

# o -> o -> Thenable
# takes a popsiql query and returns a functions that expects a mongo native driver
# collection on which it applies the mongo query transformed from the popsiql query
execMongo = curry (query, colls) ->
	{op, entity, operation, find, skip, limit, sort} = query
	if ! has entity, colls
		throw new Error "no collection '#{entity}' in colls"
	x = colls[entity]
	switch op
		when 'one'
			return x.findOne(find)
		when 'many'
			x = x.find(find)
			if skip then x = x.skip(skip)
			if limit then x = x.limit(limit)
			ar = x.toArray()
			# if its sorted, we need the array...
			if !isNil sort then return ar.then (val) -> map _idToid, val
			# ...but by default we want to work with maps and not arrays
			return ar.then (val) ->
				val_ = {}
				for x in val
					if ! has '_id', x
						return val # if we have one id missing, just return the array
					val_[x._id] = _idToid x
				return val_
		else
			throw new "execMongo: op #{op} not yet implemented"


#auto_export:none_
module.exports = {toMongo, execMongo}