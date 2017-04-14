{assoc, compose, contains, dissoc, find, fromPairs, gt, gte, has, lt, lte, map, pair, replace, toPairs, values, where} = require 'ramda' # auto_require:ramda
{predicates} = require './query'
{cc, mergeMany} = require 'ramda-extras'

# mappings between popsiql predicate/values to mongo query
_mongoMapping =
	eq: (v) -> ['$eq', v]
	neq: (v) -> ['$ne', v]
	in: (v) -> ['$in', v]
	notIn: (v) -> ['$nin', v]
	gt: (v) -> ['$gt', v]
	gte: (v) -> ['$gte', v]
	lt: (v) -> ['$lt', v]
	lte: (v) -> ['$lte', v]
	like: (v) -> ['$regex', new RegExp(replace(/%/g, '.*', v), 'i')]

# :: [k, v] -> [k2, v2]
# transforms a popsiql predicate-value-pair to a mongo query
_queryToMongoQuery = ([k, v]) ->
	if ! contains k, predicates then return null
	return _mongoMapping[k](v)

# :: o -> o
# takes a popsiql {predicate: v} and transforms to mongo query like {$xxx: v}
_transformPredicates = compose fromPairs, map(_queryToMongoQuery), toPairs

# :: o -> o
# takes a popsiql query and returns the parts of the corresponding mongo query
toMongo = (query) -> 
	where_ = query.where
	if where_ && has 'id', where_
		where_ = cc assoc('_id', where_['id']), dissoc('id'), where_
	find = map _transformPredicates, (where_ || {})
	skip = if query.start then {skip: parseInt(query.start)}
	limit = if query.max then {limit: parseInt(query.max)}
	return mergeMany {find}, (skip || {}), (limit || {})

# TODO: kanske denna får man göra själv?? Ej med i popsiql biblioteket??
# :: o -> o -> Thenable
# takes a popsiql query and returns a functions that expects a mongo native driver
# collection on which it applies the mongo query transformed from the popsiql query
toMongoAndExecute = (query) -> (collection) ->
	{find, skip, limit} = toMongo query
	x = collection
	if find then x = x.find(find)
	if skip then x = x.skip(skip)
	if limit then x = x.limit(limit)
	return x

module.exports = {toMongo, toMongoAndExecute}
