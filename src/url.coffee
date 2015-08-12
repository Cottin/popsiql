{contains, createMapEntry, eq, map, mapObj, match, reduce, split, toPairs, where} = require 'ramda' # auto_require:ramda
{cc} = require 'ramda-extras'

{predicates} = require './popsiql'

# :: s -> o
# parses a string to an object where predicate is key
# eg. 'eq(abc)' -> {eq: 'abc'}
_parse = (x) ->
	matches = match /([a-z]+)\((.+)\)/i, x
	if !matches then return null

	[_, pred, value] = matches
	if ! contains pred, predicates then return null

	if pred == 'in' || pred == 'notIn'
		return createMapEntry pred, split(',', value)
	else return createMapEntry pred, value

# :: o -> o
# takes a urlQuery and parses it to popsiql
# eg. {a: 'eq(abc)'} -> {where: {a: {eq: 'abc'}}}
fromUrl = (urlQuery) ->
	where = mapObj _parse, urlQuery
	return {where}

# note: maybe this is unneccessary? I might just use it with query in yun
toUrl = (popsiql) ->
	buildString = (mem, [k, v]) ->
		start = if mem == '' then '' else mem + '&'
		pairToString = ([k, v]) -> "#{k}(#{v})"
		valueAsString = cc map(pairToString), toPairs, v
		return "#{start}#{k}=#{valueAsString}"
	str = cc reduce(buildString, ''), toPairs, popsiql.where
	return str


module.exports = {fromUrl, toUrl}


