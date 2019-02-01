{F, T, join, keys, length, project, type, where} = R = require 'ramda' # auto_require: ramda
{doto, $, $$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ː00ː00, ːamount, ːid, ːtype, ːposition, ːdate, ːname, ːALL, ːid〳COUNT, ːtext, ːsalary, ːage, ːsex, ːsalary〳SUM] = ['0000', 'amount', 'id', 'type', 'position', 'date', 'name', 'ALL', 'id〳COUNT', 'text', 'salary', 'age', 'sex', 'salary〳SUM'] #auto_sugar
{eq, feq, deepEq, deepEq_, fdeepEq} = require 'testhelp' #auto_require: testhelp
$ = doto

{read, buildResult, write, createTables} = require './sql'
model = require './testModel'


fnl = (dataArrays, query) ->
	res = []
	count = 0
	exec = (sql) ->
		res.push sql
		return dataArrays[count++]
	data = await read query, model, exec, {newLine: true}
	return {sql: res, data}

f = (dataArrays, query) ->
	res = []
	count = 0
	exec = (sql) ->
		res.push sql
		return dataArrays[count++]
	data = await read query, model, exec
	return {sql: res, data}

fm = () -> createTables model
fw = (query) -> write query, model
fb = (query, data) -> buildResult query, data, model


_ = (...xs) -> xs

describe 'sql', ->

	describe 'read', ->

		it 'simple', ->
			res = await f [[[1, 'M']]], Person: _ {id: 1, ːsex}
			deepEq ['SELECT "id", "sex" FROM "person" WHERE "id" = 1'], res.sql
			deepEq {Person: {1: {id: 1, sex: 'M'}}}, res.data

		it 'no where', ->
			res = await f [[[1, 'M'], [2, 'M'], [3, 'F']]], Person: _ {ːid, ːsex}
			deepEq ['SELECT "id", "sex" FROM "person"'], res.sql
			deepEq [{id: 1, sex: 'M'}, {id: 2, sex: 'M'}, {id: 3, sex: 'F'}], res.data

		it '*', ->
			data = [[[1, '1993-02-03', 2.5, 'Planning kidnap', 5, 1, 2]]]
			res = await f data, WorkEntry: _ {id: 1, ːALL}
			deepEq ['SELECT * FROM "work_entry" WHERE "id" = 1'], res.sql
			expected = [{id: 1, date: '1993-02-03', amount: 2.5, text: 'Planning kidnap',
			personId: 5, projectId: 1, taskId: 2}]
			deepEq_ expected, res.data

		it 'predicates', ->
			preds = {gt: 1, gte: 2, lt: 3, lte: 2, ne: 5,
			in: ['a', 'b', 'c'],
			like: 'Elin%', ilike: 'elin%',
			notlike: 'Isa%', notilike: 'isa%'}
			res = await f [[[]]], Person: _ {id: preds, age: {gt: 30}}

			deepEq res.sql, ["""SELECT "id", "age" \
			FROM "person" WHERE "id" > 1 AND "id" >= 2 \
			AND "id" < 3 AND "id" <= 2 AND "id" <> 5 \
			AND "id" IN ('a','b','c') AND "id" LIKE 'Elin%' \
			AND "id" ILIKE 'elin%' AND "id" NOT LIKE 'Isa%' \
			AND "id" NOT ILIKE 'isa%' AND "age" > 30
			"""]

		it 'deep join', ->
			query =
				Person: _ {name: {ilike: 'el%'}, ːage},
					roles: _ {name: 'Guest'},
						project: _ {price: {gt: 500}, ːname},
					entries: _ {date: {gt: '1992-01-01'}, ːamount}
			u = undefined
			data1 = [
				['Elaine Benes', 34, 3, 'Guest', 3, 3, 11, u, u, u, '1993-02-03', 2.5, 3, 2]
				['Elaine Benes', 34, 3, 'Guest', 1, 3, 2, 1000, 'Georges Bachelor Party', 1, '1993-02-03', 2.5, 3, 2]
				['Elaine Benes', 34, 3, 'Guest', 3, 3, 11, u, u, u, '1993-02-10', 1, 3, 10]
				['Elaine Benes', 34, 3, 'Guest', 1, 3, 2, 1000, 'Georges Bachelor Party', 1, '1993-02-10', 1, 3, 10]
				['Elaine Benes', 34, 3, 'Guest', 3, 3, 11, u, u, u, '1993-02-11', 2.5, 3, 11]
				['Elaine Benes', 34, 3, 'Guest', 1, 3, 2, 1000, 'Georges Bachelor Party', 1, '1993-02-11', 2.5, 3, 11]
				['Elmer Fudd', 34, 18, u, u, u, u, u, u, u, u, u, u, u]
			]
			res = await fnl [data1], query

			fdeepEq res.sql,
				["""
				SELECT p."name", p."age", p."id", \
				r."name", r."projectId", r."personId", r."id", \
				pr."price", pr."name", pr."id", \
				w."date", w."amount", w."personId", w."id"
				FROM "person" as p
				left outer join "role" as r on p."id" = r."personId" AND r."name" = 'Guest'
				left outer join "work_entry" as w on p."id" = w."personId" AND w."date" > '1992-01-01'
				left outer join "project" as pr on r."projectId" = pr."id" AND pr."price" > 500
				WHERE p."name" ILIKE 'el%'
				"""]

			cache =
				Person:
					3: {id: 3, name: 'Elaine Benes', age: 34}
					18: {id: 18, name: 'Elmer Fudd', age: 34}
				Role:
					2: {id: 2, name: 'Guest', projectId: 1, personId: 3}
					11: {id: 11, name: 'Guest', projectId: 3, personId: 3}
				Project:
					1: {id: 1, name: 'Georges Bachelor Party', price: 1000}
				WorkEntry:
					2: {id: 2, date: '1993-02-03', amount: 2.5, personId: 3}
					10: {id: 10, date: '1993-02-10', amount: 1, personId: 3}
					11: {id: 11, date: '1993-02-11', amount: 2.5, personId: 3}

			deepEq cache, res.data




		it.only 'multiple join', ->
			query =
				adults:
					Person: _ {age: {gte: 18}, name: {ilike: '%be%'}},
						roles: _ {ːname}
						entries: _ {ːid, ːtext}
				children:
					Person: _ {age: {lt: 18}, ːname, ːsex},
						roles: _ {ːname}
						entries: _ {ːid, ːtext}

			u = undefined
			data1 = [
				[34, 'Elaine Benes', 3, 'Guest', 3, 2, 11, 'Planning kidnap', 3],
				[34, 'Elaine Benes', 3, 'Guest', 3, 2, 10, 'Buying schnaps', 3],
				[34, 'Elaine Benes', 3, 'Guest', 3, 2, 2, 'Planning kidnap', 3],
				[34, 'Elaine Benes', 3, 'Guest', 3, 11, 11, 'Planning kidnap', 3],
				[34, 'Elaine Benes', 3, 'Guest', 3, 11, 10, 'Buying schnaps', 3],
				[34, 'Elaine Benes', 3, 'Guest', 3, 11, 2, 'Planning kidnap', 3],
				[45, 'Bill Lumbergh', 13, u, u, u, u, u, u],
			]
			data2 = [
				[12, 'Bugs Bunny', 'M', 14, 'Target', 14, 6, u, u, u],
				[7, 'Daffy Duck', 'M', 15, 'Distractor', 15, 7, u, u, u],
				[2, 'Titi', 'F', 16, 'Spectator', 16, 8, u, u, u],
				[16, 'Taz', 'M', 17, u, u, u, u, u, u],
			]
			res = await f [data1, data2], query
			cache =
				Person:
					'3': age: 34, id: 3, name: 'Elaine Benes'
					'13': age: 45, id: 13, name: 'Bill Lumbergh'
					'14': age: 12, id: 14, name: 'Bugs Bunny', sex: 'M'
					'15': age: 7, id: 15, name: 'Daffy Duck', sex: 'M'
					'16': age: 2, id: 16, name: 'Titi', sex: 'F'
					'17': age: 16, id: 17, name: 'Taz', sex: 'M'
				Role:
					'2': id: 2, name: 'Guest', personId: 3
					'6': id: 6, name: 'Target', personId: 14
					'7': id: 7, name: 'Distractor', personId: 15
					'8': id: 8, name: 'Spectator', personId: 16
					'11': id: 11, name: 'Guest', personId: 3
				WorkEntry:
					'2': id: 2, personId: 3, text: 'Planning kidnap'
					'10': id: 10, personId: 3, text: 'Buying schnaps'
					'11': id: 11, personId: 3, text: 'Planning kidnap'
			fdeepEq res.data, cache
			fdeepEq res.sql, [
					"""SELECT p."age", p."name", p."id", \
					r."name", r."personId", r."id", \
					w."id", w."text", w."personId" \
					FROM "person" as p \
					left outer join "role" as r on p."id" = r."personId" \
					left outer join "work_entry" as w on p."id" = w."personId" \
					WHERE p."age" >= 18 AND p."name" ILIKE '%be%'
					"""
				,
					"""SELECT p."age", p."name", p."sex", p."id", \
					r."name", r."personId", r."id", \
					w."id", w."text", w."personId" \
					FROM "person" as p \
					left outer join "role" as r on p."id" = r."personId" \
					left outer join "work_entry" as w on p."id" = w."personId" \
					WHERE p."age" < 18
					"""
				]


		it 'full correct', ->
			query =
				Person: _ {name: {ilike: 'el%'}, ːage},
					roles: _ {name: 'Lead developer'},
						project: _ {price: {gt: 50000}, ːname},
							company: _ {ːname},
								managers: _ {ːsalary}
								numEmployees: _
								richManagers: _ {ːsalary〳SUM}
								managers: _ {salary: {lt: 10000}, ːid〳COUNT} # not allowed (yet?)
					entries: _ {date: {gt: '2018-01-01'}, ːamount}

			u = undefined
			data1 = [
				['Elmer Fudd', 34, 18, u, u, u, u, u, u, u, u, u, u, u, u, u, u],
				['Elaine Benes', 34, 3, 'Guest', 1, 3, 2, u, u, u, u, u, u, u, u, u, u],
				['Elaine Benes', 34, 3, 'Guest', 3, 3, 11, 500, 'Jerrys Engagement Party', 1, 3, 'Vandelay Industries', 1, u, u, u, u],
			]
			res = fnl [data1, []], query
			console.log res.sql[0]
			eq 1, res

		# it 'aggregate list', ->
		# 	query =
		# 		User: _ {gpa: {gt: 4.4}}, 'name',
		# 			bff: _ {}, 'name'
		# 			failedExams2018: _ {}, 'id, name, date'
		# 	res = f1(query)
		# 	fdeepEq res[0],
		# 		"""SELECT u."name" as u_name, c."name" as c_name, us."name" as us_name \
		# 		FROM "User" as u \
		# 		inner join "Course" as c on u."favoriteCourseId" = c."id" \
		# 		inner join "User" as us on u."bffId" = us."id" \
		# 		inner join "FailedCourse" as f on u."favoriteCourseId" = c."id" \
		# 		WHERE u."gpa" > 4.4
		# 		"""

		# 	({didFail}) ->
		# 		"""SELECT e."id" as e_id, e."name" as e_name, e."date" as e_date \
		# 		FROM "Exam" as e \
		# 		WHERE e.courseId in (#{pluck('courseId', didFail)}) and e.date > "2018-01-01"
		# 		"""

		# describe 'subqueries', ->
		# 	it.only 'simple', ->
		# 		query =
		# 			Company: _ {id: 1},
		# 				femaleEmployees: _ {ːposition, ːsalary}
		# 		res = f query
		# 		console.log res
		# 		eq 0, 1


	describe 'write', ->

		it 'simple', ->
			str = 'INSERT INTO "person" ("name", "sex", "age") VALUES (\'Elin\', \'F\', 32) RETURNING "id", "name", "sex", "age";'
			eq str, fw CREATE: Person: _ {name: 'Elin', sex: 'F', age: 32}

	describe 'buildResult', ->

		it 'simple', ->
			query = 
				Person: _ {id: {gte: 3, lte: 4}, ːname, ːsex, ːage},
					entries: _ {ːid, ːamount, ːdate, ːtext},
						task: _ {ːname}
						project: _ {ːname}
					roles: _ {name: 'Guest'},
						project: _ {ːid, ːname, ːtype}

			data = [
				[3, "Elaine Benes", "F", 34, 2, 2.5, "1993-02-02T23ː00ː00.000Z", "Planning kidnap", 2, 1, 3, "Planning", 2, "Georges Bachelor Party", 1, "Guest", 3, 3, 11, 3, "Jerrys Engagement Party", "Fixed price"],
				[4, "H.E. Pennypacker", "M", 52, 3, 0.5, "1993-02-09T23ː00ː00.000Z", "Booking of strippers", 1, 1, 4, "Booking", 1, "Georges Bachelor Party", 1, "Guest", 3, 4, 10, 3, "Jerrys Engagement Party", "Fixed price"],
				[4, "H.E. Pennypacker", "M", 52, 3, 0.5, "1993-02-09T23ː00ː00.000Z", "Booking of strippers", 1, 1, 4, "Booking", 1, "Georges Bachelor Party", 1, "Guest", 1, 4, 4, 1, "Georges Bachelor Party", "Fixed price"],
				[3, "Elaine Benes", "F", 34, 10, 1, "1993-02-09T23ː00ː00.000Z", "Buying schnaps", 2, 1, 3, "Planning", 2, "Georges Bachelor Party", 1, "Guest", 3, 3, 11, 3, "Jerrys Engagement Party", "Fixed price"],
				[3, "Elaine Benes", "F", 34, 11, 2.5, "1993-02-10T23ː00ː00.000Z", "Planning kidnap", 4, 1, 3, "Purchase", 4, "Georges Bachelor Party", 1, "Guest", 3, 3, 11, 3, "Jerrys Engagement Party", "Fixed price"]
			]

			res = fb query, data
			eq 'Elaine Benes', res.Person[3].name
			eq 5, $ res, keys, length
			eq 'Fixed price', res.Project[1].type






	describe 'createTables', ->

		it 'simple', ->
			res = fm()
			feq res, """\
			CREATE TABLE "public"."company" (
				"id" serial, PRIMARY KEY ("id"),
				"name" text NOT NULL,
				"turnover" integer NOT NULL
			);
			CREATE TABLE "public"."person" (
				"id" serial, PRIMARY KEY ("id"),
				"name" text NOT NULL,
				"sex" text NOT NULL,
				"age" integer NOT NULL
			);
			CREATE TABLE "public"."employment" (
				"id" serial, PRIMARY KEY ("id"),
				"position" text NOT NULL,
				"salary" integer NOT NULL,
				"companyId" integer NOT NULL,
				"personId" integer NOT NULL
			);
			CREATE TABLE "public"."project" (
				"id" serial, PRIMARY KEY ("id"),
				"name" text NOT NULL,
				"type" text NOT NULL,
				"price" integer,
				"dueDate" date NOT NULL,
				"companyId" integer NOT NULL
			);
			CREATE TABLE "public"."role" (
				"id" serial, PRIMARY KEY ("id"),
				"name" text NOT NULL,
				"personId" integer NOT NULL,
				"projectId" integer NOT NULL
			);
			CREATE TABLE "public"."task" (
				"id" serial, PRIMARY KEY ("id"),
				"name" text NOT NULL
			);
			CREATE TABLE "public"."work_entry" (
				"id" serial, PRIMARY KEY ("id"),
				"date" date NOT NULL,
				"amount" float NOT NULL,
				"text" text,
				"personId" integer NOT NULL,
				"projectId" integer NOT NULL,
				"taskId" integer NOT NULL
			);
			"""









