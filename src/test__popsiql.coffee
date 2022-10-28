import both from "ramda/es/both"; import drop from "ramda/es/drop"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import map from "ramda/es/map"; import omit from "ramda/es/omit"; import project from "ramda/es/project"; import replace from "ramda/es/replace"; import sort from "ramda/es/sort"; import toLower from "ramda/es/toLower"; import type from "ramda/es/type"; import values from "ramda/es/values"; #auto_require: esramda
import {$} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import popsiql from './popsiql'
import {Client, types} from 'pg'


types.setTypeParser 1700, (val) -> parseFloat val # parse numeric/decimal as float

data =
	Client:
		1: {id: 1, name: 'c1', archived: false, rank: 'a'}
		2: {id: 2, name: 'c2', archived: true, rank: 'c'}
		3: {id: 3, name: 'c3', archived: true, rank: 'c'}
		4: {id: 4, name: 'c4', archived: false, rank: 'd'}
	Project:
		1: {id: 1, name: 'p1', rate: null, clientId: 1, userId: 1}
		2: {id: 2, name: 'p2', rate: 102, clientId: 1, userId: 1}
		3: {id: 3, name: 'p3', rate: 89, clientId: 1, userId: 1}
		4: {id: 4, name: 'p4', rate: 102, clientId: 2, userId: 1}
		5: {id: 5, name: 'p5', rate: 101, clientId: 4, userId: 2}
	User:
		1: {id: 1, name: 'u1', email: 'u1@a.com', nickname: 'nick'}
		2: {id: 2, name: 'u2', email: 'u1@a.com', nickname: 'nick'}
		3: {id: 3, name: 'u3', email: 'u1@a.com', nickname: 'sick'}

model1 =
	Client: {projects: 'Project'}
	Project: {client: 'Client', owner: 'User'}
	User: {projects: 'Project'}

query1 =
	users: _ {:name, :nickname, _sort: [{nickname: 'DESC'}, 'id']}
	clients: _ {name: 1, archived: {eq: false}},
		projects: _ {name: 1, rate: {gt: 100}},
			owner: _ {name: 1}
	user: _ {id: {eq: 1}, :name, :email}

expected1 = null
(() ->
	client1 = omit ['rank'], data.Client[1]
	client4 = omit ['rank'], data.Client[4]
	user1 = omit ['email', 'nickname'], data.User[1]
	user2 = omit ['email', 'nickname'], data.User[2]
	expected1 =
		users: [
			{...omit(['email'], data.User[3])}
			{...omit(['email'], data.User[1])}
			{...omit(['email'], data.User[2])}
		]
		clients: [
			{...client1, projects: [{...data.Project[2], owner: user1}]}
			{...client4, projects: [{...data.Project[5], owner: user2}]}
		]
		user: {...omit(['nickname'], data.User[1])})()

expected1Norm = null
(() ->
	expected1Norm =
		Client:
			1: omit [:rank], data.Client[1]
			4: omit [:rank], data.Client[4]
		Project:
			2: data.Project[2]
			5: data.Project[5]
		User:
			1: omit [], data.User[1]
			2: omit [:email], data.User[2]
			3: omit [:email], data.User[3]
	)()

popsiql1 = popsiql model1, {ramda: {getData: () -> data}}


describe 'pop', () ->

	describe 'popsiql', () ->
		it 'constructor', () ->
			expected =
				Client: {projects: {entity: 'Project', theirRel: 'clientId'}}
				Project: {client: {entity: 'Client', rel: 'clientId'}, owner: {entity: 'User', rel: 'userId'}}
				User: {projects: {entity: 'Project', theirRel: 'userId'}}
			res = popsiql(model1, {ramda: {getData: () -> data}})
			deepEq expected, res.model

	describe 'utils', () ->
		it 'queryToString', () ->
			colon = ':'
			expected = """users: _ {#{colon}name, #{colon}nickname, _sort: [{nickname:"DESC"},"id"]}
  clients: _ {#{colon}name, archived: {eq:false}},
    projects: _ {#{colon}name, rate: {gt:100}},
      owner: _ {#{colon}name}
  user: _ {id: {eq:1}, #{colon}name, #{colon}email}"""
			eq expected, popsiql.utils.queryToString query1

	describe 'parse', () ->
		it 'complex', () ->
			expected =
				users:
					entity: 'User'
					key: 'users'
					multiplicity: 'many'
					fields: [:name, :nickname]
					allFields: [:id, :name, :nickname]
					sort: [{field: 'nickname', direction: 'DESC'}, {field: 'id', direction: 'ASC'}]
				clients:
					entity: 'Client'
					key: 'clients'
					multiplicity: 'many'
					fields: ['name', 'archived']
					allFields: ['id', 'name', 'archived']
					where: {archived: {eq: false}}
					subs:
						projects:
							entity: 'Project'
							key: 'projects'
							multiplicity: 'many'
							fields: ['name', 'rate']
							allFields: ['id', 'name', 'rate', 'clientId', 'userId']
							where: {rate: {gt: 100}}
							relParentId: 'clientId'
							subs:
								owner:
									entity: 'User'
									key: 'owner'
									multiplicity: 'one'
									fields: ['name']
									allFields: ['id', 'name']
									relIdFromParent: 'userId'
				user:
					entity: 'User'
					key: 'user'
					multiplicity: 'one'
					fields: [:id, :name, :email]
					allFields: [:id, :name, :email]
					where: {id: {eq: 1}}

			deepEq expected, popsiql1.parse query1

		it 'helpful if bad body', ->
			throws 'body not array', -> popsiql1.parse {clients: {name: 1}}


	describe 'ramda', () ->
		it 'easy', () ->
			expected = [
				{clients: [{id: 1, name: 'c1', rank: 'a'}]},
				{Client: {1: {id: 1, name: 'c1', rank: 'a'}}}
			]
			deepEq expected, popsiql1.ramda.options({result: 'both'}) clients: _ {:name, rank: {eq: 'a'}}

		it 'easy sort', () ->
			expected = {clients: [{id: 4, rank: 'd'}, {id: 2, rank: 'c'}, {id: 3, rank: 'c'}, {id: 1, rank: 'a'}]}
			deepEq expected, popsiql1.ramda clients: _ {:rank, _sort: [{rank: 'DESC'}, 'id']}

		it 'complex', () ->
			[res, normRes] = popsiql1.ramda.options({result: 'both'}) query1

			deepEq expected1, res
			deepEq expected1Norm, normRes

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

			await client.query('CREATE TABLE client (id INT, name TEXT, archived BOOLEAN, rank TEXT)')
			await client.query('CREATE TABLE project (id INT, name TEXT, rate DECIMAL(10), client_id INT, user_id INT)')
			await client.query('CREATE TABLE "user" (id INT, name TEXT, email TEXT, nickname TEXT)')


			for entity, os of data
				for k, o of os
					await client.query("INSERT INTO #{table entity} (#{cols o}) VALUES (#{vals o})")

		afterAll () ->
			await client.end()

		it 'easy', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql clients: _ {:name}
			expected = clients: [{id: 1, name: 'c1'}, {id: 2, name: 'c2'}, {id: 3, name: 'c3'}, {id: 4, name: 'c4'}]
			deepEq expected, res
			deepEq ['SELECT id, "name" FROM client', []], history

		it 'easy IN and norm', () ->
			[pgPopsiql, history] = newPgPopsiql()
			[res, resNorm] = await pgPopsiql.sql.options {result: 'both'}, clients: _ {id: {in: [1, 2]}, :name}
			expected = [
				{clients: [{id: 1, name: 'c1'}, {id: 2, name: 'c2'}]}
				{Client: {1: {id: 1, name: 'c1'}, 2: {id: 2, name: 'c2'}}}
			]
			deepEq expected, [res, resNorm]
			deepEq ['SELECT id, \"name\" FROM client WHERE id = ANY($1)', [[1, 2]]], history

		it 'easy one', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql client: _ {name: {eq: 'c1'}}
			expected = client: {id: 1, name: 'c1'}
			# deepEq expected, res
			deepEq ['SELECT id, "name" FROM client WHERE name = $1', ['c1']], history

		it 'easy one but return many', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql client: _ {id: {lt: 3}, :name}
			expected = client: [{id: 1, name: 'c1'}, {id: 2, name: 'c2'}]
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
				'SELECT id, "name", email FROM "user" WHERE id = $1', [1],
				'SELECT id, "name", rate, client_id, user_id FROM project WHERE rate > $1 AND client_id = ANY($2)', [100, [1, 4]]
				'SELECT id, "name" FROM "user" WHERE id = ANY($1)', [[1, 2]],
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
				deepEq {clients: []}, res
				deepEq [
					'SELECT id, "name", "rank", archived FROM client WHERE rank = $1', ["'-- drop clients;--"]
				], history




