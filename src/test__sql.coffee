import both from "ramda/es/both"; import drop from "ramda/es/drop"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import map from "ramda/es/map"; import project from "ramda/es/project"; import replace from "ramda/es/replace"; import toLower from "ramda/es/toLower"; import type from "ramda/es/type"; import values from "ramda/es/values"; #auto_require: esramda
import {$} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm} from './test_mock'

import popsiql from './popsiql'
import {Client, types} from 'pg'


types.setTypeParser 1700, (val) -> parseFloat val # parse numeric/decimal as float


describe 'sql with postgres', () ->

	client = new Client({host: 'localhost', user: 'victor', database: 'popsiql', port: 5432})
	newPgPopsiql = () ->
		history = []
		runner = (sql, params) ->
			# console.log sql, params # comment in to see generated sql
			history.push sql
			history.push params
			return new Promise (resolve) ->
				result = await client.query(sql, params)
				resolve result.rows
		postgresPopsiql = popsiql model1, {sql: {runner}}
		return [postgresPopsiql, history]

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

		await client.query('DROP TABLE IF EXISTS client')
		await client.query('DROP TABLE IF EXISTS project')
		await client.query('DROP TABLE IF EXISTS "user"')

		await client.query('CREATE TABLE client (id TEXT, name TEXT, archived BOOLEAN, rank TEXT, PRIMARY KEY (id))')
		await client.query('CREATE TABLE project (id TEXT, name TEXT, rate DECIMAL(10), client_id TEXT, user_id TEXT, PRIMARY KEY (id))')
		await client.query('CREATE TABLE "user" (id TEXT, name TEXT, email TEXT, nickname TEXT, PRIMARY KEY (id))')


		for entity, os of data
			for k, o of os
				await client.query("INSERT INTO #{table entity} (#{cols o}) VALUES (#{vals o})")

	afterAll () ->
		await client.end()

	it 'easy', () ->
		[pgPopsiql, history] = newPgPopsiql()
		res = await pgPopsiql.sql clients: _ {:name}
		expected = [{id: '1', name: 'c1'}, {id: '2', name: 'c2'}, {id: '3', name: 'c3'}, {id: '4', name: 'c4'}]
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client', []], history

	it 'easy IN and norm', () ->
		[pgPopsiql, history] = newPgPopsiql()
		[res, resNorm] = await pgPopsiql.sql.options {result: 'both'}, clients: _ {id: {in: ['1', '2']}, :name}
		expected = [
			[{id: '1', name: 'c1'}, {id: '2', name: 'c2'}]
			{Client: {1: {id: '1', name: 'c1'}, 2: {id: '2', name: 'c2'}}}
		]
		deepEq expected, [res, resNorm]
		deepEq ['SELECT id, \"name\" FROM client WHERE id = ANY($1)', [['1', '2']]], history

	it 'easy one', () ->
		[pgPopsiql, history] = newPgPopsiql()
		res = await pgPopsiql.sql client: _ {name: {eq: 'c1'}}
		expected = {id: '1', name: 'c1'}
		# deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE name = $1', ['c1']], history

	it 'easy one not found', () ->
		[pgPopsiql, history] = newPgPopsiql()
		res = await pgPopsiql.sql client: _ {name: {eq: 'c999'}}
		expected = null
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE name = $1', ['c999']], history

	it 'easy one but return many', () ->
		[pgPopsiql, history] = newPgPopsiql()
		res = await pgPopsiql.sql client: _ {id: {lt: 3}, :name}
		expected = [{id: '1', name: 'c1'}, {id: '2', name: 'c2'}]
		deepEq expected, res
		deepEq ['SELECT id, "name" FROM client WHERE id < $1', [3]], history


	it 'complex', () ->
		[pgPopsiql, history] = newPgPopsiql()
		[res, normRes] = await defuse pgPopsiql.sql.options {result: 'both'}, query1
		deepEq expected1, res
		deepEq expected1Norm, normRes
		deepEq [
			'SELECT id, "name", nickname FROM "user" ORDER BY nickname DESC, id', [],
			'SELECT id, "name", archived FROM client WHERE archived = $1', [false],
			'SELECT id, "name", email FROM "user" WHERE id = $1', ['1'],
			'SELECT id, "name", rate, client_id, user_id FROM project WHERE rate > $1 AND client_id = ANY($2)', [100, ['1', '4']]
			'SELECT id, "name" FROM "user" WHERE id = ANY($1)', [['1', '2']],
		], history

	describe 'sql injections', () ->

		it 'comment out', ->
			[pgPopsiql, history] = newPgPopsiql()
			query = clients: _ {name: 1, "--\n drop client;--": 1}
			await expect(pgPopsiql.sql query).rejects.toThrow 'invalid field'
			deepEq [], history


		it 'hex', ->
			[pgPopsiql, history] = newPgPopsiql()
			query = clients: _ {name: 1, "rank0x2d0x2d0x20drop0x20client": 1}
			await expect(pgPopsiql.sql query).rejects.toThrow 'invalid field'
			deepEq [], history

		it 'quote clause', ->
			[pgPopsiql, history] = newPgPopsiql()
			query = clients: _ {name: 1, rank: {eq: "\'-- drop clients;--"}, archived: 1}
			res = await pgPopsiql.sql query
			deepEq [], res
			deepEq [
				'SELECT id, "name", "rank", archived FROM client WHERE rank = $1', ["'-- drop clients;--"]
			], history

	describe 'write', ->
		it 'upsert easy', ->
			[pgPopsiql, history] = newPgPopsiql()
			delta = Client: {1: {id: '1', name: 'c1a'}}
			await pgPopsiql.sql.write delta
			deepEq ['INSERT INTO client (id, "name") VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET "name" = $2 \
WHERE client.id = $1;', ['1', 'c1a']], history

		it 'upsert hard', ->
			[pgPopsiql, history] = newPgPopsiql()
			delta =
				Project: {1: {id: '1', name: 'p1a'}, 9: {name: 'p9', clientId: '1', userId: '9'}}
				Client: {1: {id: '1', name: 'c1b'}, 2: {name: 'c2a'}, 9: {name: 'c9'}}
				User: {9: {name: 'u9', email: 'u9@a.com'}}

			await pgPopsiql.sql.write delta
			expected = [
				'INSERT INTO client (id, "name") VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET "name" = $2 \
WHERE client.id = $1;', ['1', 'c1b'],
				'INSERT INTO client (id, "name") VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET "name" = $2 \
WHERE client.id = $1;', ['2', 'c2a'],
				'INSERT INTO client (id, "name") VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET "name" = $2 \
WHERE client.id = $1;', ['9', 'c9'],
				'INSERT INTO "user" (id, "name", email) VALUES ($1, $2, $3) ON CONFLICT (id) DO UPDATE SET \
"name" = $2, email = $3 WHERE "user".id = $1;', ['9', 'u9', 'u9@a.com'],
				'INSERT INTO project (id, "name") VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET \
"name" = $2 WHERE project.id = $1;', ['1', 'p1a'],
				'INSERT INTO project (id, "name", client_id, user_id) VALUES ($1, $2, $3, $4) ON CONFLICT (id) DO UPDATE SET \
"name" = $2, client_id = $3, user_id = $4 WHERE project.id = $1;', ['9', 'p9', '1', '9'],
			]
			deepEq expected, history





