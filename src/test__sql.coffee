import both from "ramda/es/both"; import drop from "ramda/es/drop"; import insert from "ramda/es/insert"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import length from "ramda/es/length"; import map from "ramda/es/map"; import project from "ramda/es/project"; import replace from "ramda/es/replace"; import toLower from "ramda/es/toLower"; import type from "ramda/es/type"; import update from "ramda/es/update"; import values from "ramda/es/values"; #auto_require: esramda
import {$} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, parse1} from './test_mock'

import popsiql from './popsiql'
import popSql from './sql'
import {Client, types} from 'pg'


types.setTypeParser 1700, (val) -> parseFloat val # parse numeric/decimal as float


describe 'sql with postgres', () ->

	client = new Client {host: 'localhost', user: 'victor', database: 'popsiql', port: 5432}
	newPsql = () ->
		history = []
		runner = (sql, params) ->
			# console.log sql, params # comment in to see generated sql
			history.push sql
			history.push params
			return new Promise (resolve) ->
				result = await client.query(sql, params)
				resolve result.rows
		psql = popSql parse1, {runner}
		return [psql, history]

	valToSql = (val) ->
		switch type val
			when 'Number' then val
			when 'String' then "'#{val}'"
			when 'Boolean' then val && 'true' || 'false'
			when 'Null' then 'null'
			else val

	vals = (o) -> $ o, values, map(valToSql), join ','
	cols = (o) -> $ o, keys, map(_camelToSnake), join ','
	table = (k) -> "\"#{toLower k}\""

	_camelToSnake = (s) -> $ s, replace /[A-Z]/g, (s) -> '_' + toLower s

	beforeAll () ->
		await client.connect()

		await client.query('DROP TABLE IF EXISTS customer')
		await client.query('DROP TABLE IF EXISTS client')
		await client.query('DROP TABLE IF EXISTS project')
		await client.query('DROP TABLE IF EXISTS "user"')

		ccu = 'cid TEXT, created_at timestamp with time zone, updated_at timestamp with time zone'

		await client.query("CREATE TABLE customer (id TEXT, name TEXT, PRIMARY KEY (id))")
		await client.query("CREATE TABLE client (id TEXT, name TEXT, archived BOOLEAN, rank TEXT, #{ccu}, PRIMARY KEY (id))")
		await client.query("CREATE TABLE project (id TEXT, name TEXT, rate DECIMAL(10), client_id TEXT, user_id TEXT, #{ccu}, PRIMARY KEY (id))")
		await client.query("CREATE TABLE \"user\" (id TEXT, name TEXT, email TEXT, nickname TEXT, #{ccu}, PRIMARY KEY (id))")


		for entity, os of data
			for k, o of os
				await client.query("INSERT INTO #{table entity} (#{cols o}) VALUES (#{vals o})")

	afterAll () ->
		await client.end()

	it 'easy', () ->
		[psql, history] = newPsql()
		res = await psql clients: _ {:name}
		expected = [{id: '1', name: 'c1'}, {id: '2', name: 'c2'}, {id: '3', name: 'c3'}, {id: '4', name: 'c4'}]
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client', []], history

	it 'easy IN and norm', () ->
		[psql, history] = newPsql()
		query = clients: _ {id: {in: ['1', '2']}, :name}
		[res, resNorm] = await psql query, {result: 'both'}
		expected = [
			[{id: '1', name: 'c1'}, {id: '2', name: 'c2'}]
			{Client: {1: {id: '1', name: 'c1'}, 2: {id: '2', name: 'c2'}}}
		]
		deepEq expected, [res, resNorm]
		deepEq ['SELECT id, \"name\" FROM client WHERE id = ANY($1)', [['1', '2']]], history

	it 'easy one', () ->
		[psql, history] = newPsql()
		res = await psql client: _ {name: {eq: 'c1'}}
		expected = {id: '1', name: 'c1'}
		# deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE name = $1', ['c1']], history

	it 'easy one not found', () ->
		[psql, history] = newPsql()
		res = await psql client: _ {name: {eq: 'c999'}}
		expected = null
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE name = $1', ['c999']], history

	it 'easy one but return many', () ->
		[psql, history] = newPsql()
		res = await psql client: _ {id: {lt: 3}, :name}
		expected = [{id: '1', name: 'c1'}, {id: '2', name: 'c2'}]
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE id < $1', [3]], history


	it 'complex', () ->
		[psql, history] = newPsql()
		safeGuard = (subQuery, ret) ->
			ret.where ?= {}
			if subQuery.entity == 'Customer'
				ret.where.id = {eq: '1'}
			else ret.where.cid = {eq: '1'}

		[res, normRes] = await defuse psql query1, {result: 'both', safeGuard}
		deepEq expected1, res
		deepEq expected1Norm, normRes
		deepEq [
			'SELECT id, "name", nickname FROM "user" WHERE cid = $1 ORDER BY nickname DESC, id', ['1'],
			'SELECT id, "name", archived FROM client WHERE archived = $1 AND cid = $2', [false, '1'],
			'SELECT id, "name", email FROM "user" WHERE id = $1 AND cid = $2', ['1', '1'],
			'SELECT id, "name", rate, client_id, user_id FROM project WHERE rate > \
$1 AND cid = $2 AND client_id = ANY($3)', [100, '1', ['1', '4']]
			'SELECT id, "name" FROM "user" WHERE id = ANY($1) AND cid = $2', [['1'], '1'],
		], history

	describe 'sql injections', () ->

		it 'comment out', ->
			[psql, history] = newPsql()
			query = clients: _ {name: 1, "--\n drop client;--": 1}
			await expect(psql query).rejects.toThrow 'invalid field'
			deepEq [], history


		it 'hex', ->
			[psql, history] = newPsql()
			query = clients: _ {name: 1, "rank0x2d0x2d0x20drop0x20client": 1}
			await expect(psql query).rejects.toThrow 'invalid field'
			deepEq [], history

		it 'quote clause', ->
			[psql, history] = newPsql()
			query = clients: _ {name: 1, rank: {eq: "\'-- drop clients;--"}, archived: 1}
			res = await psql query
			deepEq [], res
			deepEq [
				'SELECT id, "name", "rank", archived FROM client WHERE rank = $1', ["'-- drop clients;--"]
			], history

	describe 'write', ->
		it 'insert easy', ->
			[psql, history] = newPsql()
			delta = Client: {8: {id: '8', name: 'c8'}}
			await psql.write delta
			deepEq ['INSERT INTO client (id, "name") VALUES ($1, $2);', ['8', 'c8']], history

		it 'update easy', ->
			[psql, history] = newPsql()
			delta = Client: {1: {name: 'c1a'}}
			await psql.write delta
			deepEq ['UPDATE client SET "name" = $1 WHERE id = $2;', ['c1a', '1']], history

		it 'complex', ->
			[psql, history] = newPsql()
			delta =
				Project: {1: {name: 'p1a'}, 9: {id: '9', name: 'p9', clientId: '1', userId: '9'}}
				Client: {1: {name: 'c1b'}, 2: {name: 'c2a'}, 9: {id: '9', name: 'c9'}, 4: undefined}
				User: {9: {id: '9', name: 'u9', email: 'u9@a.com'}}

			safeGuard = ({op, delta}) ->
				if op == 'insert' then {...delta, cid: '1'}
				else if op == 'update' then [delta, ['1'], " AND cid = $#{$(delta, keys, length) + 2}"]
				else if op == 'delete' then [['1'], " AND cid = $2"]




			await psql.write delta, {safeGuard}
			expected = [
				'UPDATE client SET "name" = $1 WHERE id = $2 AND cid = $3;', ['c1b', '1', '1'],
				'UPDATE client SET "name" = $1 WHERE id = $2 AND cid = $3;', ['c2a', '2', '1'],
				'DELETE FROM client WHERE id = $1 AND cid = $2;', ['4', '1'],
				'INSERT INTO client (id, "name", cid) VALUES ($1, $2, $3);', ['9', 'c9', '1'],
				'INSERT INTO \"user\" (id, "name", email, cid) VALUES ($1, $2, $3, $4);', ['9', 'u9', 'u9@a.com', '1'],
				'UPDATE project SET "name" = $1 WHERE id = $2 AND cid = $3;', ['p1a', '1', '1'],
				'INSERT INTO project (id, "name", client_id, user_id, cid) VALUES ($1, $2, $3, $4, $5);', ['9', 'p9', '1', '9', '1'],
			]
			deepEq expected, history





