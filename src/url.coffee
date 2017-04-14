{add, chain, compose, concat, contains, join, length, map, match, mergeAll, objOf, omit, pick, split, toPairs, values, where} = R = require 'ramda' # auto_require:ramda
{cc, mergeMany} = require 'ramda-extras'

{predicates, parameters} = require './query'

# :: s -> o
# parses a string to an object where predicate is key
# eg. 'eq(abc)' -> {eq: 'abc'}
_parse = (x) ->
	if R.is(Object, x) then return cc mergeAll, map(_parse), values, x
	else if !R.is(String, x) then return x
	matches = match /([a-z]+)\((.+)\)/i, x
	if length(matches) == 0 then return x

	[_, pred, value] = matches
	if ! contains pred, predicates then return null

	if pred == 'in' || pred == 'notIn'
		return objOf pred, split(',', value)
	else return objOf pred, value

# :: o -> o
# takes a urlQuery and parses it to popsiql query
# eg. {a: 'eq(abc)'} -> {where: {a: {eq: 'abc'}}}
fromUrl = (urlQuery) ->
	params = pick parameters, urlQuery
	where = map _parse, omit(parameters, urlQuery)
	return mergeMany {where}, params


# :: o -> s
# takes a popsiql query and transforms it to a url query string
toUrl = (query) ->
	predToString = ([k, v]) -> "#{k}(#{v})"
	predObjectToString = compose map(predToString), toPairs
	whereFieldToString = ([k, pred]) ->
		if R.is(Object, pred) then cc map(add("#{k}=")), predObjectToString(pred)
		else "#{k}=#{pred}"
	wheres = cc chain(whereFieldToString), toPairs, query.where

	# LIMITS
	limits = cc map(join('=')), toPairs, pick(parameters), query

	nonEmptyParts = concat(wheres, limits)
	return join '&', nonEmptyParts

module.exports = {fromUrl, toUrl}


