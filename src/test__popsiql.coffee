import drop from "ramda/es/drop"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import map from "ramda/es/map"; import omit from "ramda/es/omit"; import project from "ramda/es/project"; import replace from "ramda/es/replace"; import toLower from "ramda/es/toLower"; import type from "ramda/es/type"; import values from "ramda/es/values"; #auto_require: esramda
import {$} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import popsiql from './popsiql'
import {Client, types} from 'pg'

types.setTypeParser 1700, (val) -> parseFloat val # parse numeric/decimal as float

data =
	Client:
		1: {id: 1, name: 'c1', archived: false, rank: 'a'}
		2: {id: 2, name: 'c2', archived: true, rank: 'b'}
		3: {id: 3, name: 'c3', archived: true, rank: 'c'}
		4: {id: 4, name: 'c4', archived: false, rank: 'd'}
	Project:
		1: {id: 1, name: 'p1', rate: null, clientId: 1, userId: 1}
		2: {id: 2, name: 'p2', rate: 102, clientId: 1, userId: 1}
		3: {id: 3, name: 'p3', rate: 89, clientId: 1, userId: 1}
		4: {id: 4, name: 'p4', rate: 102, clientId: 2, userId: 1}
		5: {id: 5, name: 'p5', rate: 101, clientId: 4, userId: 2}
	User:
		1: {id: 1, name: 'u1', email: 'u1@a.com'}
		2: {id: 2, name: 'u2', email: 'u1@a.com'}

model1 =
	Client: {projects: 'Project'}
	Project: {client: 'Client', owner: 'User'}
	User: {projects: 'Project'}

query1 =
	clients: _ {name: 1, archived: {eq: false}},
		projects: _ {name: 1, rate: {gt: 100}},
			owner: _ {name: 1}

expected1 = null
(() ->
	client1 = omit ['rank'], data.Client[1]
	client4 = omit ['rank'], data.Client[4]
	user1 = omit ['email'], data.User[1]
	user2 = omit ['email'], data.User[2]
	expected1 =
		clients: [
			{...client1, projects: [{...data.Project[2], owner: user1}]}
			{...client4, projects: [{...data.Project[5], owner: user2}]}
		])()

popsiql1 = popsiql model1, {ramda: {data}}


describe 'pop', () ->

	describe 'popsiql', () ->
		it '1', () ->
			expected =
				Client: {projects: {entity: 'Project', theirRel: 'clientId'}}
				Project: {client: {entity: 'Client', rel: 'clientId'}, owner: {entity: 'User', rel: 'userId'}}
				User: {projects: {entity: 'Project', theirRel: 'userId'}}
			res = popsiql(model1, {ramda: {data}})
			expect(res.model).toEqual expected

	describe 'parse', () ->
		it '1', () ->
			expected =
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

			expect(popsiql1.parse query1).toEqual expected

		it 'helpful if bad body', ->
			expect(() -> popsiql1.parse {clients: {name: 1}}).toThrow 'body not array'


	describe 'ramda', () ->
		it '1', () ->
			expect(popsiql1.ramda query1).toEqual expected1

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
			await client.query('CREATE TABLE "user" (id INT, name TEXT, email TEXT)')


			for entity, os of data
				for k, o of os
					await client.query("INSERT INTO #{table entity} (#{cols o}) VALUES (#{vals o})")

		afterAll () ->
			await client.end()

		it 'easy', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql clients: _ {:name}
			expected = clients: [{id: 1, name: 'c1'}, {id: 2, name: 'c2'}, {id: 3, name: 'c3'}, {id: 4, name: 'c4'}]
			expect(res).toEqual expected
			expect(history).toEqual ['SELECT id, "name" FROM client', []]

		it 'easy IN', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql clients: _ {id: {in: [1, 2]}}
			expected = clients: [{id: 1}, {id: 2}]
			expect(res).toEqual expected
			expect(history).toEqual ['SELECT id FROM client WHERE id = ANY($1)', [[1, 2]]]

		it 'medium', () ->
			[pgPopsiql, history] = newPgPopsiql()
			res = await pgPopsiql.sql query1
			expect(res).toEqual expected1
			expect(history).toEqual [
				'SELECT id, "name", archived FROM client WHERE archived = $1', [false],
				'SELECT id, "name", rate, client_id, user_id FROM project WHERE rate > $1 AND client_id = ANY($2)', [100, [1, 4]]
				'SELECT id, "name" FROM "user" WHERE id = ANY($1)', [[1, 2]],
			]

		describe 'sql injections', () ->

			it 'comment out', ->
				[pgPopsiql, history] = newPgPopsiql()
				query = clients: _ {name: 1, "--\n drop client;--": 1}
				await expect(pgPopsiql.sql query).rejects.toThrow 'invalid field'
				expect(history).toEqual []

			it 'hex', ->
				[pgPopsiql, history] = newPgPopsiql()
				query = clients: _ {name: 1, "rank0x2d0x2d0x20drop0x20client": 1}
				await expect(pgPopsiql.sql query).rejects.toThrow 'invalid field'
				expect(history).toEqual []

			it 'quote clause', ->
				[pgPopsiql, history] = newPgPopsiql()
				query = clients: _ {name: 1, rank: {eq: "\'-- drop clients;--"}, archived: 1}
				res = await pgPopsiql.sql query
				expect(res).toEqual {clients: []}
				expect(history).toEqual [
					'SELECT id, "name", "rank", archived FROM client WHERE rank = $1', ["'''-- drop clients;--'"]
				]





	# describe 'sql with sqllite', () ->

	# 	db = new sqlite3.Database(':memory:')

	# 	valToSql = (val) ->
	# 		switch type val
	# 			when 'Number' then val
	# 			when 'String' then "'#{val}'"
	# 			when 'Boolean' then val && 'true' || 'false'
	# 			when 'Null' then 'null'
	# 			else val

	# 	vals = (o) -> $ o, values, map(valToSql), join ','
	# 	cols = (o) -> $ o, keys, join ','
	# 	table = (k) -> toLower k

	# 	before (done) ->

	# 		db.serialize () ->
	# 			db.run("CREATE TABLE client (id INT, name TEXT, archived BOOLEAN, rank TEXT)")
	# 			db.run("CREATE TABLE project (id INT, name TEXT, rate DECIMAL, clientId INT, userId INT)")
	# 			db.run("CREATE TABLE user (id INT, name TEXT, email TEXT)")

	# 			for entity, os of data
	# 				for k, o of os
	# 					db.run("INSERT INTO #{table entity} (#{cols o}) VALUES (#{vals o})")

	# 			done()

	# 	it '1', () ->
	# 		runner = (sql) ->
	# 			return new Promise (resolve) ->
	# 				console.log sql 
	# 				db.all sql, (err, rows) -> resolve rows

	# 		myPopsiql = pop.popsiql model1, {sql: runner}
	# 		res = await myPopsiql.sql query1
	# 		deepEq expected1_sqllite, clone res

	# 	after () ->
	# 		db.close()

