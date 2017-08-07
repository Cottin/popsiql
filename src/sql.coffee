{compose, equals, flatten, gt, gte, head, insert, into, join, keys, lt, lte, map, pair, replace, set, toLower, toPairs, type, update, values, where} = R = require 'ramda' #auto_require:ramda
{cc} = require 'ramda-extras'
co = compose

# a -> s   Converts a value to its representation in an SQL query
# eg. 't' -> '\'t\'',    [1,2,3] -> '[1,2,3]'
val = (v) ->
	if type(v) == 'Array'
		s = cc replace(/"/g, "'"), JSON.stringify, v
		return cc replace(/^\[/, '('), replace(/\]$/, ')'), s
	else cc replace(/"/g, "'"), JSON.stringify, v

# [k, v] -> s   Converts a key-value pair to its representation in SQL
keyVal = ([k, v]) -> "#{k} = #{val(v)}"

# o -> s   Converts an object to its representation in an SQL query
# eg. {a: 1, b: 't'} -> 'a = 1, b = \'t\''
objToCols = co join(', '), map(keyVal), toPairs

# s -> [s, a] -> s   Builds a predicate string
# eg. 'name' -> (['eq', 'elin']) -> 'name = \'elin\''
toPred = (k0) -> ([k, v]) ->
	switch k
		when 'eq' then "#{k0} = #{val(v)}"
		when 'neq' then "#{k0} <> #{val(v)}"
		when 'gt' then "#{k0} > #{val(v)}"
		when 'gte' then "#{k0} >= #{val(v)}"
		when 'lt' then "#{k0} < #{val(v)}"
		when 'lte' then "#{k0} <= #{val(v)}"
		when 'in' then "#{k0} in #{val(v)}"
		when 'nin' then "#{k0} not in #{val(v)}"
		when 'like' then "#{k0} like #{val(v)}"

# [s, a] -> [s]   Builds an array of predicate strings for the property k
toPreds = ([k, v]) ->
	if R.is Object, v
		cc map(toPred(k)), toPairs, v
	else
		# if no predicate given, we assume an implicit equals
		keyVal [k, v]

# o -> s   Builds the where-part of the SQL query from the query object
# eg. {where: {a: {gt: 1, lt: 5}}} -> ' where a > 1 and a < 5'
_where = (query) ->
	{where} = query
	if !where then return ''
	return ' where ' + cc join(' and '), flatten, map(toPreds), toPairs, where

# o -> s   Builds the SELECT query from the query object
_get = (query) ->
	{fields} = query
	table = toLower(query.many || query.one)
	cols = if fields then join(', ', fields) else '*'
	return "select #{cols} from #{table}" + _where(query)

# o -> s   Builds the UPDATE query from the query object
_set = (query) ->
	table = cc head, keys, query.set
	cols = objToCols query.set[table]
	return "update #{table} set #{cols}" + _where(query)

# o -> s   Builds the INSERT query from the query object
_create = (query) ->
	table = toLower query.create
	cols = cc join(','), keys, query.data
	vals = cc join(','), map(val), values, query.data
	return "insert into #{table} (#{cols}) values (#{vals})"

# o -> s   Converts a popsiql query to a SQL query
exports.toSql = toSql = (query) ->
	if query.many || query.one then return _get query
	else if query.create then return _create query
	# else if query.push then return _push query
