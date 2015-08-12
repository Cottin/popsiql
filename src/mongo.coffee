{compose, contains, eq, find, fromPairs, functions, gt, gte, lt, lte, map, mapObj, replace, toPairs, values} = require 'ramda' # auto_require:ramda
{predicates} = require './popsiql'

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
	like: (v) -> ['$regex', replace(/%/g, '.*', v)]

# :: [k, v] -> [k2, v2]
# transforms a popsiql predicate-value-pair to a monto query
_queryToMongoQuery = ([k, v]) ->
	if ! contains k, predicates then return null
	return _mongoMapping[k](v)

# :: o -> o
# takes a popsiql {predicate: v} and transforms to mongo query like {$xxx: v}
_transformPredicates = compose fromPairs, map(_queryToMongoQuery), toPairs

# :: o -> o
# takes a popsiql query and returns the parts of the corresponding mongo query
toMongo = (query) -> 
	find = mapObj _transformPredicates, query.where
	return {find}

# TODO: kanske denna får man göra själv?? Ej med i popsiql biblioteket??
# :: o -> o -> Thenable
# takes a popsiql query and returns a functions that expects a mongo native driver
# collection on which it applies the mongo query transformed from the popsiql query
toMongoAndExecute = (query) -> (collection) ->
	{find} = toMongo query
	return collection.find(find)

module.exports = {toMongo, toMongoAndExecute}
