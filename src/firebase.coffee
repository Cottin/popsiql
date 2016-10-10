{__, any, complement, contains, createMapEntry, eq, fromPairs, functions, gt, gte, has, head, intersection, isEmpty, isNil, join, keys, last, length, lt, lte, map, max, merge, omit, path, pickBy, split, toPairs, update, where} = require 'ramda' # auto_require:ramda
{predicates} = require './query'
{isNotNil, isEmptyObj, mergeMany, reduceObj, cc, dropLast, ymap, isa} = require 'ramda-extras'
q = require 'q'

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
		when 'gt' then throw new Error 'gt is not supported by firebase, but gte is!'
		when 'gte' then return {orderByChild: k, startAt: v}
		when 'lt' then throw new Error 'lt is not supported by firebase, but lte is!'
		when 'lte' then return {orderByChild: k, endAt: v}
		when 'like'
			# Note: only "startsWith" like-queries are supported by firebase
			if last(v) != '%'
				throw new Error 'like must end with % for Firebase queries (startsWith)'

			value = dropLast 1, v
			if contains '%', value
				throw new Error 'like must only contain one % and it must be the last
				character'

			# https://www.firebase.com/docs/web/guide/retrieving-data.html#section-queries
			return {orderByChild: k, startAt: value, endAt: value + '\uf8ff'}

# o -> o   Parses the $get component of the popsiql query
_parseGet = ($get) ->
	if !$get || isEmptyObj $get then return {}

	# Firebase per 25 nov 2015 only supports ordering by one key
	# https://www.firebase.com/docs/web/api/query/orderbychild.html
	if cc gt(__, 1), length, keys, $get
		throw new Error 'Firebase only supports one key in $get clause'

	[k, predicates] = cc head, toPairs, $get

	if cc gt(__, 1), length, keys, predicates
		throw new Error "Firebase adapter only supports one predicate in $get
		for the moment, your keys: #{keys(predicates)}"

	[pred, value] = cc head, toPairs, predicates
	
	return _parseUnit k, pred, value

# o -> o
# Takes a popsiql query and returns the parts (get, set, update, push)
# of the corresponding firebase subscription 
toFirebase = (query) -> 
	if cc gt(__, 1), length, keys, query
		throw new Error "Firebase only supports one collection per query,
		your query: #{JSON.stringify(query)}"

	[collection, operations] = cc head, toPairs, query	
	path = cc join('/'), split('__'), collection

	opKeys = keys operations
	if !cc isEmpty, intersection(['$set', '$merge', '$push']), opKeys
		if contains '$set', opKeys
			return {set: {path, value: operations.$set}}
		if contains '$merge', opKeys
			return {update: {path, value: operations.$merge}}
		if contains '$push', opKeys
			return {push: {path, value: operations.$push}}
		# {$set, $merge, $push} = operations
		# if $set then return {set: {path, value: $set}}
		# else if $merge then return {update: {path, value: $merge}}
		# else if $push then return {push: {path, value: $push}}
	else if contains '$get', opKeys
		{$get} = operations
		{orderByChild, startAt, endAt, equalTo, inArray} = _parseGet $get

		if startAt && operations.$start
			throw new Error 'You cannot use a where predicate that causes a startAt and 
			at the same time use start in your query since the will override each other'
		if endAt && operations.$end
			throw new Error 'You cannot use a where predicate that causes a endAt and at 
			the same time use end in your query since the will override each other'

		if inArray then return {get: {path, inArray}}

		result = {
			orderByChild
			equalTo
			startAt: operations.$start || startAt
			endAt: operations.$end || endAt
			limitToFirst: operations.$max
		}
		return {get: merge({path}, pickBy(isNotNil, result))}

	throw new Error "firebase query could not be parsed " + JSON.stringify(query)

# o -> o -> o
# Takes a popsiql query and returns a functions that expects a firebase ref
# on which it applies the firebase parts derived from the parsing of the
# popsiql query
toFirebaseAndExecute = (query) -> (ref) ->
	{get, set, update, push} = toFirebase query

	if set
		def = q.defer()
		ref.child(set.path).set set.value, (err) ->
			if err then def.reject(new Error err)
			else def.resolve null
		return def.promise
	if update
		def = q.defer()
		ref.child(update.path).update update.value, (err) ->
			if err then def.reject(new Error err)
			else def.resolve null
		return def.promise
	if push
		pushRef = ref.child(push.path).push()
		def = q.defer()
		key = pushRef.key()
		pushRef.set push.value, (err) -> 
			if err
				def.reject(new Error err)
			else
				def.resolve {key}
		promise = def.promise
		promise.key = key
		return promise
	if get
		{path, orderByChild, equalTo, startAt, endAt, limitToFirst, inArray} = get
		x = ref.child(path)

		if inArray
			refPair = (x) -> [x, ref.child "#{path}/#{x}"]
			return cc fromPairs, map(refPair), get.inArray

		if orderByChild then x = x.orderByChild orderByChild
		if equalTo then x = x.equalTo equalTo
		if startAt then x = x.startAt startAt
		if endAt then x = x.endAt endAt
		if limitToFirst then x = x.limitToFirst limitToFirst
		return x


module.exports = {toFirebase, toFirebaseAndExecute}











# deprecation line --------------

	# return null

	# if k == 'set'
	# 	collection = cc head, keys, v
	# 	if ! isa Array, v[collection]
	# 		throw new Error 'set query requires value to be pair for the moment'
	# 	[childPath, data] = v[collection]
	# 	childPath_ = if isa Array, childPath then join '/', childPath else childPath
	# 	return ref.child("#{collection}/#{childPath_}").set(data)

	# if k == 'update'
	# 	collection = cc head, keys, v
	# 	if ! isa Array, v[collection]
	# 		throw new Error 'update query requires value to be pair for the moment'
	# 	[childPath, data] = v[collection]
	# 	return ref.child("#{collection}/#{childPath}").update(data)

	# if k == 'create'
	# 	collection = cc head, keys, v
	# 	data = v[collection]
	# 	pushRef = ref.child(collection).push()
	# 	pushRef.set(data)
	# 	return pushRef.key()
	# 	# return ref.child(collection).push().set(data)


	# if isa Array, v
	# 	refPair = (x) -> [x, ref.child "#{k}/#{x}"]
	# 	return cc fromPairs, map(refPair), v

	# {orderByChild, equalTo, startAt, endAt, limitToFirst} = v
	# x = ref.child(k)
	# if orderByChild then x = x.orderByChild orderByChild
	# if equalTo then x = x.equalTo equalTo
	# if startAt then x = x.startAt startAt
	# if endAt then x = x.endAt endAt
	# if limitToFirst then x = x.limitToFirst limitToFirst
	# return x








	# # todo: move this validation of popsiql queries to a common file
	# if has 'set', query
	# 	if cc gt(__, 1), length, keys, query
	# 		throw new Error "Popsiql set queries does not allow any other keys than set"
	# 	{set} = query
	# 	if cc gt(__, 1), length, keys, set
	# 		throw new Error "Firebase only supports one collection in set query"
	# 	return {set}

	# if has 'update', query
	# 	if cc gt(__, 1), length, keys, query
	# 		throw new Error 'Popsiql update queries does not allow any other keys than update'
	# 	{update} = query
	# 	if cc gt(__, 1), length, keys, update
	# 		throw new Error 'Firebase only supports one collection in update query'
	# 	return {update}

	# if has 'create', query
	# 	if cc gt(__, 1), length, keys, query
	# 		throw new Error 'Popsiql create queries does not allow any other keys than create'
	# 	{create} = query
	# 	if cc gt(__, 1), length, keys, create
	# 		throw new Error 'Firebase only supports one collection in create query'
	# 	return {create}

	# property = omit ['start', 'end', 'max'], query
	# if cc gt(__, 1), length, keys, property
	# 	throw new Error "Firebase only supports one property per query, your query: #{JSON.stringify(property)}"


	# [k, v] = cc head, toPairs, property

	# {orderByChild, startAt, endAt, equalTo, inArray} = _parseGet v

	# if startAt && query.start
	# 	throw new Error 'You cannot use a where predicate that causes a startAt and 
	# 	at the same time use start in your query since the will override each other'
	# if endAt && query.end
	# 	throw new Error 'You cannot use a where predicate that causes a endAt and at 
	# 	the same time use end in your query since the will override each other'

	# if inArray then return createMapEntry k, inArray

	# result = {
	# 	orderByChild
	# 	equalTo
	# 	startAt: query.start || startAt
	# 	endAt: query.end || endAt
	# 	limitToFirst: query.max
	# }

	# return cc createMapEntry(k), pickBy(complement(isNil)), result
