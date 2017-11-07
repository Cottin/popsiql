{any, flatten, gte, head, indexOf, isEmpty, isNil, join, keys, map, match, max, merge, omit, prop, remove, replace, sort, split, test, toPairs, type, update, where} = R = require 'ramda' # auto_require:ramda
{cc, mergeMany, ymap, yreduce, doto, change} = require 'ramda-extras'

{predicates, parameters} = require './query'
utils = require './utils'

# o -> s   Converts a popsiql-query to a rest-url
toRest = (query) ->
	utils.validate query # we want to assume we're working with a valid query

	entity = utils.getEntity query
	op = utils.getOp query
	switch op
		when 'many', 'one'
			if query.id && op == 'many'
				return {method: 'GET', url: "#{entity}?id=#{join(',', query.id)}"}
			else if query.id && op == 'one'
				return {method: 'GET', url: "#{entity}/#{query.id}"}

			attrs = _toAttrs query
			{start, max, sort} = query
			s = entity
			if !isNil start then attrs.push("$start=#{start}")
			if !isNil max then attrs.push("$max=#{max}")
			if sort
				if type(sort) == 'Array'
					sort_ = ymap sort, (o) ->
						k = cc head, keys, o
						if o[k] == 'desc' then "#{k}--desc"
						else k
					attrs.push("$sort=#{join(',', sort_)}")
				else
					attrs.push("$sort=#{sort}")
			if !isEmpty attrs then s += '?' + join('&', attrs)
			return {method: 'GET', url: s}
		when 'create'
			return {method: 'POST', url: entity, body: query.data}
		when 'update'
			body = omit ['id'], query.data
			return {method: 'PUT', url: "#{entity}/#{query.id}", body}
		when 'remove'
			return {method: 'DELETE', url: "#{entity}/#{query.id}"}
		when 'at'
			{at, exec, data} = query
			if isNil exec
				throw new Error "missing 'exec' for operation 'at', query: " + JSON.stringify(query)
			return {method: 'POST', url: "#{at}/exec/#{exec}", body: data}

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
			{where, start, max, sort} = _parseQueryString url

			# handling of many ids
			if where && where.id && test /,/, where.id
				id = cc map(_autoConvert), split(','), where.id
				return {many: entity, id}

			query = {many: entity}
			if !isNil(where) && !isEmpty(where) then query.where = where
			if !isNil start then query.start = start
			if !isNil max then query.max = max
			if sort
				if test /,|--desc/, sort
					query.sort = ymap split(',', sort), (s) ->
						if test /--desc$/, s then {"#{replace(/--desc$/, '', s)}": 'desc'}
						else {"#{s}": 'asc'}
				else query.sort = sort
			return query
		when 'POST'
			RE = /(.*)\/exec\/(.*)/
			if test RE, url
				[_, at, exec] = match RE, url
				return {at, exec, data: body}
			else
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
	start = max = sort = null
	for attr in attrs
		[left, right] = split '=', attr
		[_, k, _v] = match /^(.*)\((.*)\)/, right # ex. gte(123)
		if isNil k
			if left == '$start' then start = _autoConvert right
			else if left == '$max' then max = _autoConvert right
			else if left == '$sort' then sort = right
			else where[left] = _autoConvert right # implicit eq
			continue
		v =
			if k == 'in' || k == 'nin' then doto _v, split(','), map(_autoConvert)
			else v = _autoConvert _v
		where[left] ?= {}
		where[left][k] = v
	return {where, start, max, sort}

module.exports = {fromRest, toRest}


