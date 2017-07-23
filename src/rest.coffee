{any, flatten, gte, indexOf, isEmpty, isNil, join, map, match, max, merge, omit, prop, remove, replace, split, test, toPairs, type, update, where} = R = require 'ramda' # auto_require:ramda
{cc, mergeMany, ymap, yreduce, doto, change} = require 'ramda-extras'

{predicates, parameters} = require './query'
utils = require './utils'

# o -> s   Converts a popsiql-query to a rest-url
toRest = (query) ->
	utils.validate query # we want to assume we're working with a valid query

	entity = utils.getEntity query
	switch utils.getOp query
		when 'many'
			if query.id
				return {method: 'GET', url: "#{entity}?id=#{join(',', query.id)}"}

			attrs = _toAttrs query
			{start, max} = query
			s = entity
			if !isNil start then attrs.push("$start=#{start}")
			if !isNil max then attrs.push("$max=#{max}")
			if !isEmpty attrs then s += '?' + join('&', attrs)
			return {method: 'GET', url: s}
		when 'one'
			return {method: 'GET', url: "#{entity}/#{query.id}"}
		when 'create'
			return {method: 'POST', url: entity, body: query.data}
		when 'update'
			body = omit ['id'], query.data
			return {method: 'PUT', url: "#{entity}/#{query.id}", body}
		when 'remove'
			return {method: 'DELETE', url: "#{entity}/#{query.id}"}

# s -> o   Converts a rest-url to a popsiql query
fromRest = ({method, url, body}) ->
	switch method
		when 'GET'
			if test /(\w*)\/(\d*)$/, url
				[_, entity, id] = match /(\w*)\/(\d*)$/, url
				return {one: entity, id: _autoConvert(id)}

			entity =
				if indexOf('?', url) != -1 then url.substr(0, indexOf('?', url))
				else url
			{where, start, max} = _parseQueryString url

			# handling of many ids
			if where && where.id && test /,/, where.id
				id = cc map(_autoConvert), split(','), where.id
				return {many: entity, id}

			query = {many: entity}
			if !isNil(where) && !isEmpty(where) then query.where = where
			if !isNil start then query.start = start
			if !isNil max then query.max = max
			return query
		when 'POST'
			return {create: url, data: body}
		when 'PUT'
			[_, entity, _id] = match /(\w*)\/(\d*)$/, url
			id = _autoConvert _id
			return {update: entity, id, data: merge(body, {id})}
		when 'DELETE'
			[_, entity, _id] = match /(\w*)\/(\d*)$/, url
			return {remove: entity, id: _autoConvert(_id)}
		else
			throw new Error 'fromRest failed, unknown method: ' + method

# o -> [s]   Converts the where-part to a list of attributes for query string
_toAttrs = ({where}) ->
	propToStrs = ([prop, preds]) ->
		if type(preds) != 'Object'
			return ["#{prop}=#{preds}"] # implicit eq

		return doto preds, toPairs,
							map ([k, v]) -> "#{k}(#{v})"
							map (s) -> "#{prop}=#{s}"

	return cc flatten, map(propToStrs), toPairs, where

# a -> a   # optimistically parses to Number or Boolean if needed
_autoConvert = (val) ->
	if !isNaN(val) then Number(val)
	else if val == 'true' then true
	else if val == 'false' then false
	else val

# s -> o   Parses a url and returns where-part, start and max if any found
_parseQueryString = (url) ->
	if !test /\?/, url then return {}

	attrs = doto url, replace(/^.*\?/, ''), split('&')
	where = {}
	start = max = null
	for attr in attrs
		[left, right] = split '=', attr
		[_, k, _v] = match /^(.*)\((.*)\)/, right # ex. gte(123)
		if isNil k
			if left == '$start' then start = _autoConvert right
			else if left == '$max' then max = _autoConvert right
			else where[left] = _autoConvert right # implicit eq
			continue
		v =
			if k == 'in' || k == 'nin' then doto _v, split(','), map(_autoConvert)
			else v = _autoConvert _v
		where[left] ?= {}
		where[left][k] = v
	return {where, start, max}

module.exports = {fromRest, toRest}


