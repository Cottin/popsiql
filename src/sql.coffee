import both from "ramda/es/both"; import difference from "ramda/es/difference"; import equals from "ramda/es/equals"; import has from "ramda/es/has"; import head from "ramda/es/head"; import includes from "ramda/es/includes"; import isEmpty from "ramda/es/isEmpty"; import isNil from "ramda/es/isNil"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import length from "ramda/es/length"; import map from "ramda/es/map"; import omit from "ramda/es/omit"; import pick from "ramda/es/pick"; import pluck from "ramda/es/pluck"; import replace from "ramda/es/replace"; import toLower from "ramda/es/toLower"; import toUpper from "ramda/es/toUpper"; import type from "ramda/es/type"; import values from "ramda/es/values"; import where from "ramda/es/where"; import without from "ramda/es/without"; #auto_require: esramda
import {mapI, mapO, $, PromiseProps} from "ramda-extras" #auto_require: esramda-extras

_camelToSnake = (s) -> $ s, replace /[A-Z]/g, (s) -> '_' + toLower s
_snakeToCamel = (s) -> $ s, replace /_[a-z]/g, (s) -> toUpper s[1]

defaultConfig =
	keyToDb: _camelToSnake,
	keyFromDb: _snakeToCamel
	runner: () -> throw new Error 'Must supply a runner'

export default popSql = (parse, config_) ->
	{keyToDb, keyFromDb} = config = {...defaultConfig, ...config_}

	# https://www.postgresql.org/docs/8.1/sql-keywords-appendix.html
	# All except "non-reserved" from list
	keywords = ['A', 'ABS', 'ADA', 'ALIAS', 'ALL', 'ALLOCATE', 'ALWAYS', 'ANALYSE', 'ANALYZE', 'AND', 'ANY', 'ARE', 'ARRAY', 'AS', 'ASC', 'ASENSITIVE', 'ASYMMETRIC', 'ATOMIC', 'ATTRIBUTE', 'ATTRIBUTES', 'AUTHORIZATION', 'AVG', 'BERNOULLI', 'BETWEEN', 'BINARY', 'BITVAR', 'BIT_LENGTH', 'BLOB', 'BOTH', 'BREADTH', 'C', 'CALL', 'CARDINALITY', 'CASCADED', 'CASE', 'CAST', 'CATALOG', 'CATALOG_NAME', 'CEIL', 'CEILING', 'CHARACTERS', 'CHARACTER_LENGTH', 'CHARACTER_SET_CATALOG', 'CHARACTER_SET_NAME', 'CHARACTER_SET_SCHEMA', 'CHAR_LENGTH', 'CHECK', 'CHECKED', 'CLASS_ORIGIN', 'CLOB', 'COBOL', 'COLLATE', 'COLLATION', 'COLLATION_CATALOG', 'COLLATION_NAME', 'COLLATION_SCHEMA', 'COLLECT', 'COLUMN', 'COLUMN_NAME', 'COMMAND_FUNCTION', 'COMMAND_FUNCTION_CODE', 'COMPLETION', 'CONDITION', 'CONDITION_NUMBER', 'CONNECT', 'CONNECTION_NAME', 'CONSTRAINT', 'CONSTRAINT_CATALOG', 'CONSTRAINT_NAME', 'CONSTRAINT_SCHEMA', 'CONSTRUCTOR', 'CONTAINS', 'CONTINUE', 'CORR', 'CORRESPONDING', 'COUNT', 'COVAR_POP', 'COVAR_SAMP', 'CREATE', 'CROSS', 'CUBE', 'CUME_DIST', 'CURRENT', 'CURRENT_DATE', 'CURRENT_DEFAULT_TRANSFORM_GROUP', 'CURRENT_PATH', 'CURRENT_ROLE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP', 'CURRENT_TRANSFORM_GROUP_FOR_TYPE', 'CURRENT_USER', 'CURSOR_NAME', 'DATA', 'DATE', 'DATETIME_INTERVAL_CODE', 'DATETIME_INTERVAL_PRECISION', 'DEFAULT', 'DEFERRABLE', 'DEFINED', 'DEGREE', 'DENSE_RANK', 'DEPTH', 'DEREF', 'DERIVED', 'DESC', 'DESCRIBE', 'DESCRIPTOR', 'DESTROY', 'DESTRUCTOR', 'DETERMINISTIC', 'DIAGNOSTICS', 'DICTIONARY', 'DISCONNECT', 'DISPATCH', 'DISTINCT', 'DO', 'DYNAMIC', 'DYNAMIC_FUNCTION', 'DYNAMIC_FUNCTION_CODE', 'ELEMENT', 'ELSE', 'END', 'END-EXEC', 'EQUALS', 'EVERY', 'EXCEPT', 'EXCEPTION', 'EXCLUDE', 'EXEC', 'EXISTING', 'EXP', 'FALSE', 'FILTER', 'FINAL', 'FLOOR', 'FOLLOWING', 'FOR', 'FOREIGN', 'FORTRAN', 'FOUND', 'FREE', 'FREEZE', 'FROM', 'FULL', 'FUSION', 'G', 'GENERAL', 'GENERATED', 'GET', 'GO', 'GOTO', 'GRANT', 'GROUP', 'GROUPING', 'HAVING', 'HIERARCHY', 'HOST', 'IDENTITY', 'IGNORE', 'ILIKE', 'IMPLEMENTATION', 'IN', 'INDICATOR', 'INFIX', 'INITIALIZE', 'INITIALLY', 'INNER', 'INSTANCE', 'INSTANTIABLE', 'INTERSECT', 'INTERSECTION', 'INTO', 'IS', 'ISNULL', 'ITERATE', 'JOIN', 'K', 'KEY_MEMBER', 'KEY_TYPE', 'LATERAL', 'LEADING', 'LEFT', 'LENGTH', 'LESS', 'LIKE', 'LIMIT', 'LN', 'LOCALTIME', 'LOCALTIMESTAMP', 'LOCATOR', 'LOWER', 'M', 'MAP', 'MATCHED', 'MAX', 'MEMBER', 'MERGE', 'MESSAGE_LENGTH', 'MESSAGE_OCTET_LENGTH', 'MESSAGE_TEXT', 'METHOD', 'MIN', 'MOD', 'MODIFIES', 'MODIFY', 'MODULE', 'MORE', 'MULTISET', 'MUMPS', 'NAME', 'NATURAL', 'NCLOB', 'NESTING', 'NEW', 'NORMALIZE', 'NORMALIZED', 'NOT', 'NOTNULL', 'NULL', 'NULLABLE', 'NULLS', 'NUMBER', 'OCTETS', 'OCTET_LENGTH', 'OFF', 'OFFSET', 'OLD', 'ON', 'ONLY', 'OPEN', 'OPERATION', 'OPTIONS', 'OR', 'ORDER', 'ORDERING', 'ORDINALITY', 'OTHERS', 'OUTER', 'OUTPUT', 'OVER', 'OVERLAPS', 'OVERRIDING', 'PAD', 'PARAMETER', 'PARAMETERS', 'PARAMETER_MODE', 'PARAMETER_NAME', 'PARAMETER_ORDINAL_POSITION', 'PARAMETER_SPECIFIC_CATALOG', 'PARAMETER_SPECIFIC_NAME', 'PARAMETER_SPECIFIC_SCHEMA', 'PARTITION', 'PASCAL', 'PATH', 'PERCENTILE_CONT', 'PERCENTILE_DISC', 'PERCENT_RANK', 'PLACING', 'PLI', 'POSTFIX', 'POWER', 'PRECEDING', 'PREFIX', 'PREORDER', 'PRIMARY', 'PUBLIC', 'RANGE', 'RANK', 'READS', 'RECURSIVE', 'REF', 'REFERENCES', 'REFERENCING', 'REGR_AVGX', 'REGR_AVGY', 'REGR_COUNT', 'REGR_INTERCEPT', 'REGR_R2', 'REGR_SLOPE', 'REGR_SXX', 'REGR_SXY', 'REGR_SYY', 'RESULT', 'RETURN', 'RETURNED_CARDINALITY', 'RETURNED_LENGTH', 'RETURNED_OCTET_LENGTH', 'RETURNED_SQLSTATE', 'RIGHT', 'ROLLUP', 'ROUTINE', 'ROUTINE_CATALOG', 'ROUTINE_NAME', 'ROUTINE_SCHEMA', 'ROW_COUNT', 'ROW_NUMBER', 'SCALE', 'SCHEMA_NAME', 'SCOPE', 'SCOPE_CATALOG', 'SCOPE_NAME', 'SCOPE_SCHEMA', 'SEARCH', 'SECTION', 'SELECT', 'SELF', 'SENSITIVE', 'SERVER_NAME', 'SESSION_USER', 'SETS', 'SIMILAR', 'SIZE', 'SOME', 'SOURCE', 'SPACE', 'SPECIFIC', 'SPECIFICTYPE', 'SPECIFIC_NAME', 'SQL', 'SQLCODE', 'SQLERROR', 'SQLEXCEPTION', 'SQLSTATE', 'SQLWARNING', 'SQRT', 'STATE', 'STATIC', 'STDDEV_POP', 'STDDEV_SAMP', 'STRUCTURE', 'STYLE', 'SUBCLASS_ORIGIN', 'SUBLIST', 'SUBMULTISET', 'SUM', 'SYMMETRIC', 'SYSTEM_USER', 'TABLE', 'TABLESAMPLE', 'TABLE_NAME', 'TERMINATE', 'THAN', 'THEN', 'TIES', 'TIMEZONE_HOUR', 'TIMEZONE_MINUTE', 'TO', 'TOP_LEVEL_COUNT', 'TRAILING', 'TRANSACTIONS_COMMITTED', 'TRANSACTIONS_ROLLED_BACK', 'TRANSACTION_ACTIVE', 'TRANSFORM', 'TRANSFORMS', 'TRANSLATE', 'TRANSLATION', 'TRIGGER_CATALOG', 'TRIGGER_NAME', 'TRIGGER_SCHEMA', 'TRUE', 'UESCAPE', 'UNBOUNDED', 'UNDER', 'UNION', 'UNIQUE', 'UNNAMED', 'UNNEST', 'UPPER', 'USAGE', 'USER', 'USER_DEFINED_TYPE_CATALOG', 'USER_DEFINED_TYPE_CODE', 'USER_DEFINED_TYPE_NAME', 'USER_DEFINED_TYPE_SCHEMA', 'USING', 'VALUE', 'VARIABLE', 'VAR_POP', 'VAR_SAMP', 'VERBOSE', 'WHEN', 'WHENEVER', 'WHERE', 'WIDTH_BUCKET', 'WINDOW', 'WITHIN']
	esc = (s) -> if includes toUpper(s), keywords then "\"#{s}\"" else s
	value = (x) ->
		if isNil x then "null"
		else if type(x) == 'Date' then "'#{x.toISOString()}'"
		else if type(x) == 'String' then "'#{x.replace(/'/g, "''")}'"
		else x

	getField = (field) -> $ field, keyToDb, esc
	getFields = (allFields) -> $ allFields, map(getField), join ', '
	getTable = (entity) -> toLower esc entity
	getWhere = (where) ->
		clauses = []
		params = []
		for k, preds of where
			for op, val of preds
				if op == 'in' then clauses.push "#{keyToDb k} = ANY($#{params.length + 1})"
				else clauses.push "#{keyToDb k} #{ops[op]} $#{params.length + 1}"
				params.push val
		return [clauses.join(' AND '), params]

	getOrderBy = (specSort) ->
		return $ specSort,
			map ({field, direction}) -> "#{field}#{direction == 'DESC' && ' DESC' || ''}"
			join ', '

	ops = {eq: '=', ne: '<>', gt: '>', gte: '>=', lt: '<', lte: '<=',
	like: 'LIKE', ilike: 'ILIKE', notlike: 'NOT LIKE', notilike: 'NOT ILIKE'}

	byId = (xs) ->
		ret = {}
		for x in xs then ret[x.id] = x
		return ret

	parseResult = (r) ->
		# Note: här kan vi nog optimera endel
		ret = {}
		for k, v of r
			ret[keyFromDb k] = v
		return ret


	read = (options, fullSpec, parent=null) ->
		runner = options.runner || config.runner
		norm = if !parent then {} else parent.norm
		fullRes = await PromiseProps $ fullSpec, mapO (spec, key) ->
			if spec.relIdFromParent
				Where = {id: {in: $ parent.res, pluck spec.relIdFromParent}, ...(spec.where || {})}
				params = []
				[whereClause, whereParams] = getWhere Where
				params.push ...whereParams
				sql = "SELECT #{getFields spec.allFields} FROM #{getTable spec.entity} WHERE #{whereClause}"

				res = await runner sql, params
				resById = byId res

				for r in parent.res
					r[key] = pick spec.allFields, resById[r[spec.relIdFromParent]]

				return res


			Where = {...spec.where}

			if spec.relParentId
				Where[spec.relParentId] = {in: pluck 'id', parent.res}

			sql = "SELECT #{getFields spec.allFields} FROM #{getTable spec.entity}"
			params = []
			if !isEmpty Where
				[whereClause, whereParams] = getWhere Where
				params.push ...whereParams
				sql += " WHERE #{whereClause}"

			if spec.sort
				sql += " ORDER BY #{getOrderBy spec.sort}"

			res_ = await runner sql, params
			res = map parseResult, res_
			resById = byId res

			if options.result == 'both'
				norm[spec.entity] ?= {}
				for r in res
					if norm[spec.entity][r.id]
						norm[spec.entity][r.id] = {...norm[spec.entity][r.id], ...r}
					else norm[spec.entity][r.id] = {...r}

			if spec.relParentId
				for r in res
					parent.resById[r[spec.relParentId]][key] ?= []
					parent.resById[r[spec.relParentId]][key].push r

			if spec.subs
				await read options, spec.subs, {res, resById, norm}
			
			if spec.multiplicity == 'one'
				if length(res) == 1 then return res[0]
				else if length(res) == 0 then return null
			
			return res

		return if !parent && options.result == 'both' then [fullRes, norm] else fullRes


	fn = (query, options = {}) ->
		safeGuard = options.safeGuard || config.safeGuard
		spec = parse query, safeGuard
		res = await read options, spec
		if options.result == 'both'
			[denorm, norm] = res
			return if $ spec, keys, length, equals 1 then [$(denorm, values, head), norm] else [denorm, norm]
		else
			return if $ spec, keys, length, equals 1 then $ res, values, head else res

	write = (options, entity, id, delta) ->
		runner = options.runner || config.runner
		safeGuard = options.safeGuard || config.safeGuard

		entityTable = getTable entity

		if delta == undefined then throw new Error 'deletes not yet supported'
		else 
			if !has id, delta
			else 
			if !safeGuard
				delta = {id, ...(omit(['id'], delta))}
				fields = keys delta
				params = values delta
				dollars = $ params, mapI((___, i) -> "$#{i+1}"), join ', '

				sets = $ fields, without(['id']), mapI((field, i) -> "#{getField field} = $#{i+2}"), join ', '

				sql = "INSERT INTO #{entityTable} (#{getFields fields}) VALUES (#{dollars})
	ON CONFLICT (id) DO UPDATE SET #{sets} WHERE #{entityTable}.id = $1;";
			else
				[sql, params] = safeGuard {delta, entity, id, entityTable, getFields, getField}


			res = await runner sql, params
			return res

	fn.write = (delta, options = {}) ->
		independent = difference keys(delta), parse.createOrder
		createOrder = [...independent, ...parse.createOrder]

		for entity in createOrder
			for id, subDelta of delta[entity]
				res = await write options, entity, id, subDelta

		return 1

	return fn

	
popSql.presetSafeGuardCCU = ({cid, createdAt, updatedAt}) ->

	return ({delta, entity, id, entityTable, getFields, getField}) ->
		if delta.cid && delta.cid != cid then throw new Error 'trying to edit others cust id'
		if has('createdAt', delta) || has('updatedAt', delta) then throw new Error 'invalid delta'
		delta = {id, ...(omit(['id'], delta))} # ensure id and id is first key
		paramsDelta = {...delta, updatedAt, createdAt, cid}
		cidParamNum = $ paramsDelta, values, length
		params = values paramsDelta

		insertFields = $ paramsDelta, keys, getFields
		insertDollars = $ paramsDelta, keys, mapI((___, i) -> "$#{i+1}"), join ', '

		paramsDelta = {...delta, updatedAt}
		sets = $ paramsDelta, keys, without(['id']), mapI((field, i) -> "#{getField field} = $#{i+2}"), join ', '

		sql = "INSERT INTO #{entityTable} (#{insertFields}) VALUES (#{insertDollars})
					ON CONFLICT (id) DO UPDATE SET #{sets} 
					WHERE #{entityTable}.id = $1 AND #{entityTable}.cid = $#{cidParamNum};";
		return [sql, params]




