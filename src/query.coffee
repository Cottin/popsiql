{__, add, all, append, apply, assoc, assocPath, empty, equals, gt, gte, intersection, isEmpty, join, keys, length, lt, lte, map, max, merge, path, reduce, remove, set, sort, split, toPairs} = R = require 'ramda' # auto_require:ramda
{cc} = require 'ramda-extras'

# NOTE:
# Different adapters might not support all predicates or operations. For example,
# you could have a valid popsiql query that will throw an error if passed to the
# firebase adapter.
# Predicates and operations defined here are thus a sort of "maximum" capability
# of what you could implement in an adapter.

# supported predicates
predicates = ['eq', 'neq', 'in', 'notIn', 'lt', 'lte', 'gt', 'gte', 'like']

# supported parameters
parameters = ['start', 'max']

# supported operations
operations = ['$get', '$set', '$merge', '$push', '$remove', '$do', '$apply']

# o -> o
# Takes a flattened popsiql query and returns a nested version.
# e.g. toNestedQuery {a__b__c: {$set: 1}, a__d: {$set: 2}}
#						returns {a: {b: {c: {$set: 1}}, d: {$set: 2}}}
toNestedQuery = (o) ->
	ensurePath = (acc, [k, v]) -> assocPath split('__', k), v, acc
	return reduce ensurePath, {}, toPairs(o)

# o -> o
# Takes a nested popsiql query and returns an unnested version.
# e.g. toFlatQuery {a: {b: {c: {$set: 1}}, d: {$set: 2}}}
#						returns {a__b__c: {$set: 1}, a__d: {$set: 2}}
toFlatQuery = (o, path = []) ->
	flattenKV = (acc, [k, v]) ->
		# we've reached a valid operation in the nested query,
		# so add the path and the operation
		if !isEmpty intersection(keys(v), operations)
			return assoc join('__', append(k, path)), v, acc

		# we've drilled down far enough to reach a non-object or an empty object,
		# which means the query is missing a valid operation in one of it's branches
		if !R.is(Object, v) || cc(equals(0), length, keys, v)
			throw new Error "Popsiql query missing valid operation
			(#{join(',', operations)}) for path #{path}"

		return toFlatQuery v, append(k, path) # continue drilling down

	return reduce flattenKV, {}, toPairs(o)

# o -> b   # Returns true for valid popsiql queires, false otherwise
isValidQuery = (o) ->
	try
		toFlatQuery o
		return true
	catch
		return false


toQueryList = (o) ->
	# toItem = ([k, v]) ->

	# 	{path: k, }
	# queryList = cc map(toItem), toPairs, o


module.exports = {predicates, parameters, toNestedQuery, isValidQuery,
toFlatQuery}
