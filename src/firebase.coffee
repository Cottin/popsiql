{equals, __, complement, contains, createMapEntry, eq, functions, gt, gte, head, isNil, keys, last, length, lt, lte, max, omit, pickBy, toPairs, where} = require 'ramda' # auto_require:ramda
{predicates} = require './query'
{mergeMany, reduceObj, cc, dropLast, ymap, isa} = require 'ramda-extras'

# s, s, a -> o
# Given a key, value and predicate returns the parse result or throws an error
_parseUnit = (k, pred, v) ->
	switch pred
		when 'eq' then return {orderByChild: k, equalTo: v}
		when 'neq' then throw new Error 'not equal is not supported by firebase'
		when 'in'
			if k != 'id'
				throw new Error 'predicate in can only be used for property id'
			return {inArray: v}
		when 'notIn' then throw new Error 'not in is not supported by firebase'
		when 'gt' then throw new Error 'gt is not supported by firebase, BUT gte is!'
		when 'gte' then return {orderByChild: k, startAt: v}
		when 'lt' then throw new Error 'lt is not supported by firebase, BUT lte is!'
		when 'lte' then return {orderByChild: k, endAt: v}
		when 'like'
			# Note: only "startsWith" like-queries are supported by firebase
			if last(v) != '%'
				throw new Error 'like must end with % for Firebase queries (startsWith)'

			value = dropLast 1, v
			if contains '%', value
				throw new Error 'like must only contain one % and it must be the last character'

			# https://www.firebase.com/docs/web/guide/retrieving-data.html#section-queries
			return {orderByChild: k, startAt: value, endAt: value + '\uf8ff'}

# o -> o   Parses the where component of the popsiql query
_parseWhere = (where) ->
	if ! where || cc equals(0), length, keys, where then return {}

	# Firebase per 25 nov 2015 only supports ordering by one key
	# https://www.firebase.com/docs/web/api/query/orderbychild.html
	if cc gt(__, 1), length, keys, where
		throw new Error 'Firebase only supports one key in where clause'

	[k, predicates] = cc head, toPairs, where

	if cc gt(__, 1), length, keys, predicates
		throw new Error 'Firebase adapter only supports one predicate in where for the moment'

	[pred, value] = cc head, toPairs, predicates
	
	return _parseUnit k, pred, value

# o -> o
# Takes a popsiql query and returns the parts of the corresponding firebase subscription
toFirebase = (query) -> 
	property = omit ['start', 'end', 'max'], query
	if cc gt(__, 1), length, keys, property
		throw new Error 'Firebase only supports one property per query'

	[k, v] = cc head, toPairs, property

	{orderByChild, startAt, endAt, equalTo, inArray} = _parseWhere v

	if startAt && query.start
		throw new Error 'You cannot use a where predicate that causes a startAt and 
		at the same time use start in your query since the will override each other'
	if endAt && query.end
		throw new Error 'You cannot use a where predicate that causes a endAt and at 
		the same time use end in your query since the will override each other'

	if inArray then return createMapEntry k, inArray

	result = {
		orderByChild
		equalTo
		startAt: query.start || startAt
		endAt: query.end || endAt
		limitToFirst: query.max
	}

	return cc createMapEntry(k), pickBy(complement(isNil)), result

# o -> o -> o
# Takes a popsiql query and returns a functions that expects a firebase ref
# on which it applies the firebase parts derived from the parsing of the popsiql query
toFirebaseAndExecute = (query) -> (ref) ->
	[k, v] = cc head, toPairs, toFirebase, query
	if isa Array, v then return ymap v, (x) -> ref.child "#{k}/#{x}"

	{orderByChild, equalTo, startAt, endAt, limitToFirst} = v
	x = ref.child(k)
	if orderByChild then x = x.orderByChild orderByChild
	if equalTo then x = x.equalTo equalTo
	if startAt then x = x.startAt startAt
	if endAt then x = x.endAt endAt
	if limitToFirst then x = x.limitToFirst limitToFirst
	return x

module.exports = {toFirebase, toFirebaseAndExecute}
