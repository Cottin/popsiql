{add, all, any, both, call, compose, contains, dec, drop, equals, flatten, gt, gte, head, identity, insert, into, isNil, join, keys, last, length, lt, lte, map, match, max, min, pair, partial, path, remove, repeat, replace, set, sum, test, toLower, toPairs, trim, type, union, update, values, view, where, without} = R = require 'ramda' #auto_require:ramda
{cc} = require 'ramda-extras'
co = compose

# a -> s   Converts a value to its representation in an SQL query
# eg. 't' -> '\'t\'',    [1,2,3] -> '[1,2,3]'
val = (v) ->
	if type(v) == 'Array'
		s = cc replace(/"/g, "'"), JSON.stringify, v
		return cc replace(/^\[/, '('), replace(/\]$/, ')'), s
	else cc replace(/"/g, "'"), JSON.stringify, v


# https://www.drupal.org/docs/develop/coding-standards/list-of-sql-reserved-words
reservedWords = ['absolute', 'action', 'add', 'all', 'allocate', 'alter', 'and', 'any', 'are', 'as', 'asc', 'assertion', 'at', 'authorization', 'avg', 'begin', 'between', 'bit', 'bit_length', 'both', 'by', 'call', 'cascade', 'cascaded', 'case', 'cast', 'catalog', 'char', 'char_length', 'character', 'character_length', 'check', 'close', 'coalesce', 'collate', 'collation', 'column', 'commit', 'condition', 'connect', 'connection', 'constraint', 'constraints', 'contains', 'continue', 'convert', 'corresponding', 'count', 'create', 'cross', 'current', 'current_date', 'current_path', 'current_time', 'current_timestamp', 'current_user', 'cursor', 'date', 'day', 'deallocate', 'dec', 'decimal', 'declare', 'default', 'deferrable', 'deferred', 'delete', 'desc', 'describe', 'descriptor', 'deterministic', 'diagnostics', 'disconnect', 'distinct', 'do', 'domain', 'double', 'drop', 'else', 'elseif', 'end', 'escape', 'except', 'exception', 'exec', 'execute', 'exists', 'exit', 'external', 'extract', 'false', 'fetch', 'first', 'float', 'for', 'foreign', 'found', 'from', 'full', 'function', 'get', 'global', 'go', 'goto', 'grant', 'group', 'handler', 'having', 'hour', 'identity', 'if', 'immediate', 'in', 'indicator', 'initially', 'inner', 'inout', 'input', 'insensitive', 'insert', 'int', 'integer', 'intersect', 'interval', 'into', 'is', 'isolation', 'join', 'key', 'language', 'last', 'leading', 'leave', 'left', 'level', 'like', 'local', 'loop', 'lower', 'match', 'max', 'min', 'minute', 'module', 'month', 'names', 'national', 'natural', 'nchar', 'next', 'no', 'not', 'null', 'nullif', 'numeric', 'octet_length', 'of', 'on', 'only', 'open', 'option', 'or', 'order', 'out', 'outer', 'output', 'overlaps', 'pad', 'parameter', 'partial', 'path', 'position', 'precision', 'prepare', 'preserve', 'primary', 'prior', 'privileges', 'procedure', 'public', 'read', 'real', 'references', 'relative', 'repeat', 'resignal', 'restrict', 'return', 'returns', 'revoke', 'right', 'rollback', 'routine', 'rows', 'schema', 'scroll', 'second', 'section', 'select', 'session', 'session_user', 'set', 'signal', 'size', 'smallint', 'some', 'space', 'specific', 'sql', 'sqlcode', 'sqlerror', 'sqlexception', 'sqlstate', 'sqlwarning', 'substring', 'sum', 'system_user', 'table', 'temporary', 'then', 'time', 'timestamp', 'timezone_hour', 'timezone_minute', 'to', 'trailing', 'transaction', 'translate', 'translation', 'trim', 'true', 'undo', 'union', 'unique', 'unknown', 'until', 'update', 'upper', 'usage', 'user', 'using', 'value', 'values', 'varchar', 'varying', 'view', 'when', 'whenever', 'where', 'while', 'with', 'work', 'write', 'year', 'zone']
# s -> s   Quotes a string if it feels needed
q = (s) ->
	isReserved = contains toLower(s), reservedWords
	hasUpper = test /[A-Z]/, s # in postgres camelCase needs quotes
	if isReserved || hasUpper then '"' + s + '"'
	else s

# [k, v] -> s   Converts a key-value pair to its representation in SQL
keyVal = ([k, v]) -> "#{q(k)} = #{val(v)}"

# o -> s   Converts an object to its representation in an SQL query
# eg. {a: 1, b: 't'} -> 'a = 1, b = \'t\''
objToCols = co join(', '), map(keyVal), toPairs

# s -> [s, a] -> s   Builds a predicate string
# eg. 'name' -> (['eq', 'elin']) -> 'name = \'elin\''
toPred = (k0) -> ([k, v]) ->
	switch k
		when 'eq' then "#{q(k0)} = #{val(v)}"
		when 'neq' then "#{q(k0)} <> #{val(v)}"
		when 'gt' then "#{q(k0)} > #{val(v)}"
		when 'gte' then "#{q(k0)} >= #{val(v)}"
		when 'lt' then "#{q(k0)} < #{val(v)}"
		when 'lte' then "#{q(k0)} <= #{val(v)}"
		when 'in' then "#{q(k0)} in #{val(v)}"
		when 'nin' then "#{q(k0)} not in #{val(v)}"
		when 'like' then "#{q(k0)} like #{val(v)}"

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
	{where, id} = query
	if id
		if type(id) == 'Array' then return " where id in #{val(id)}"
		else return " where id = #{val(id)}"

	if !where then return ''
	return ' where ' + cc join(' and '), flatten, map(toPreds), toPairs, where

# o -> s   Builds the SELECT query from the query object
_get = (query) ->
	{fields} = query
	table = toLower(query.many || query.one)
	cols =
		if fields then cc join(', '), map(q), fields
		else '*'
	return "select #{cols} from #{q(table)}" + _where(query)

# o -> s   Builds the UPDATE query from the query object
_set = (query) ->
	table = cc head, keys, query.set
	cols = objToCols query.set[table]
	return "update #{q(table)} set #{cols}" + _where(query)

# o -> s   Builds the INSERT query from the query object
_create = (query) ->
	table = toLower query.create
	cols = cc join(','), map(q), keys, query.data
	vals = cc join(','), map(val), values, query.data
	return "insert into #{q(table)} (#{cols}) values (#{vals})"

# o -> s   Builds the UPDATE query from the query object
_update = (query) ->
	if isNil query.id then throw new Error 'update query missing id'
	table = toLower query.update
	kvs = cc join(', '), map(keyVal), toPairs, query.data
	return "update #{q(table)} set #{kvs} where id = #{query.id}"

# o -> s   Builds the DELETE query from the query object
_remove = (query) ->
	if isNil query.id then throw new Error 'remove query missing id'
	table = toLower query.remove
	return "delete from #{q(table)} where id = #{query.id}"

# o -> s   Builds a DELETE query without any where clause
_removeAll = (query) -> "delete from #{q(query.removeAll)}"

# o -> s   Converts a popsiql query to a SQL query
exports.toSql = toSql = (query) ->
	if query.many || query.one then return _get query
	else if query.create then return _create query
	else if query.update then return _update query
	else if query.remove then return _remove query
	else if query.removeAll then return _removeAll query
	# else if query.push then return _push query
