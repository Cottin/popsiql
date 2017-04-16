{assoc, curry, find, gt, gte, has, isNil, lt, lte, map, merge, none, replace, type, values, where} = require 'ramda' # auto_require:ramda
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

	entity = utils.getEntity query
	find = _whereToFind query.where
	skip = if query.start then parseInt(query.start)
	limit = if query.max then parseInt(query.max)
	return {entity, find, skip, limit}

# o -> o -> Thenable
# takes a popsiql query and returns a functions that expects a mongo native driver
# collection on which it applies the mongo query transformed from the popsiql query
execMongo = curry (query, colls) ->
	{entity, find, skip, limit} = query
	if ! has entity, colls
		throw new Error "no collection '#{entity}' in colls"
	x = colls[entity]
	if find then x = x.find(find)
	if skip then x = x.skip(skip)
	if limit then x = x.limit(limit)
	return x

#auto_export:none_
module.exports = {toMongo, execMongo}