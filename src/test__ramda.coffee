{F, gt, gte, join, length, lt, lte, pluck, where} = R = require 'ramda' # auto_require: ramda
{$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːid, ːtext, ːamount, ːage, ːsex, ːname, ːALL] = ['id', 'text', 'amount', 'age', 'sex', 'name', 'ALL'] #auto_sugar
{eq, deepEq} = require 'testhelp' #auto_require: testhelp

{read} = require './ramda'
model = require './testModel'
seed = require './testSeed'


f = (query) -> read query, seed, model

_ = (...xs) -> xs

describe 'ramda', ->

	describe 'read', ->

		it 'simple', ->
			deepEq [{id: 1, sex: 'M'}], f Person: _ {id: 1, ːsex}

		it 'no where', ->
			res = f Person: _ {ːid, ːsex, ːage}
			eq 18, $ res, length
			deepEq {id: 3, sex: 'F', age: 34}, res[2]

		it 'ALL', ->
			res = f Person: _ {ːALL}
			eq 18, $ res, length
			deepEq {id: 3, sex: 'F', age: 34, name: 'Elaine Benes'}, res[2]

		# TODO
		# it.only 'date', ->
		# 	res = f WorkEntry: _ {date: {gt: '1993-03-05', lt: '1993-03-21'}}
		# 	console.log res
		# 	eq 3, $ res, length
		# 	# deepEq {id: 3, sex: 'F', age: 34}, res[2]

		describe 'predicates', ->
			it 'gt, lt, gte, lte', ->
				deepEq [{id: 3, age: 34}], f Person: _ {id: {gt: 2, lt: 8}, age: {lte: 34, gte: 31}}

			it 'ne', ->
				deepEq [{sex: 'F'}, {sex: 'F'}], f Person: _ {sex: {ne: 'M'}}

			it 'in', ->
				deepEq [{age: 32}, {age: 32}, {age: 12}], f Person: _ {age: {in: [32, 12]}}

			it 'like', ->
				res = f Person: _ {name: {like: '%Mi%'}}
				deepEq [{name: 'Michael Bolton'}, {name: 'Milton Waddams'}], res

			it 'ilike', ->
				res = f Person: _ {name: {ilike: '%Mi%'}}
				deepEq [{name: 'Samir Nagheenanajar'},
				{name: 'Michael Bolton'}, {name: 'Milton Waddams'}], res

			it 'notlike', ->
				res = f Person: _ {name: {notlike: '%S%'}, ːid}
				deepEq [1, 2, 3, 4, 5, 6, 10, 11, 12, 13, 14, 15, 16, 17, 18], pluck 'id', res

			it 'notilike', ->
				res = f Person: _ {name: {notilike: '%S%'}, ːid}
				deepEq [1, 4, 6, 10, 13, 15, 16, 17, 18], pluck 'id', res

		it 'deep join', ->
			query =
				Person: _ {id: {in: [3, 4]}, ːname},
					roles: _ {name: 'Guest'},
						project: _ {ːid, ːname},
							company: _ {ːname}
					entries: _ {date: {gt: '1993-02-03'}, ːamount}
			res = f query
			eq 1, res[0].roles.length
			eq 2, res[0].entries.length
			eq 'Vandelay Industries', res[1].roles[1].project.company.name

		it 'multiple join', ->
			query =
				adults:
					Person: _ {age: {gte: 18}, ːname},
						roles: _ {ːname}
						entries: _ {ːid, ːtext}
				children:
					Person: _ {age: {lt: 18}, ːname},
						roles: _ {ːname}
						entries: _ {ːid, ːtext}

			res = f query
			eq 14, res.adults.length
			eq 4, res.children.length
			eq 'Project leader', res.adults[4].roles[1].name

