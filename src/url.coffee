{add, chain, compose, concat, contains, join, length, map, match, mergeAll, objOf, omit, pick, split, toPairs, values, where} = R = require 'ramda' # auto_require:ramda
{cc, mergeMany} = require 'ramda-extras'

{predicates, parameters} = require './query'
utils = require './utils'

# a -> a   # optimistically parses to Number or Boolean if needed
_autoConvert = (val) ->
	if !isNaN(val) then Number(val)
	else if val == 'true' then return true
	else if val == 'false' then return false
	else return val

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
		return objOf pred, map(_autoConvert, split(',', value))
	else return objOf pred, _autoConvert(value)

# :: o -> o
# takes a urlQuery and parses it to popsiql query
# eg. {a: 'eq(abc)'} -> {where: {a: {eq: 'abc'}}}
fromUrl = (urlQuery) ->
	params = pick parameters, urlQuery
	where = map _parse, omit(parameters, urlQuery)
	return mergeMany {where}, params


# :: o -> s
# takes a popsiql query and transforms it to a url query string
# toUrl = (query) ->
# 	predToString = ([k, v]) -> "#{k}(#{v})"
# 	predObjectToString = compose map(predToString), toPairs
# 	whereFieldToString = ([k, pred]) ->
# 		if R.is(Object, pred) then cc map(add("#{k}=")), predObjectToString(pred)
# 		else "#{k}=#{pred}"
# 	wheres = cc chain(whereFieldToString), toPairs, query.where

# 	# LIMITS
# 	limits = cc map(join('=')), toPairs, pick(parameters), query

# 	nonEmptyParts = concat(wheres, limits)
# 	return join '&', nonEmptyParts

_toQueryString = ({where}) ->
	cc toPairs, where

toUrl = (query) ->
	utils.validate query # we want to assume we're working with a valid query

	entity = utils.getEntity query
	queryString = _toQueryString query

module.exports = {fromUrl, toUrl}


