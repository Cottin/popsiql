import both from "ramda/es/both"; import sort from "ramda/es/sort"; #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, write1, parse1} from './test_mock'

import popsiql from './popsiql'
import popRamda from './ramda'


# rsql = popRamda parse1, {
# 	getData: () -> data
# }


# newRsql = () ->
# 	myData = clone data
# 	rasql = popRamda parse1, {
# 		getData: () -> myData
# 		changeData: (delta) -> myData = change delta, myData
# 	}
# 	return [rasql, myData]


describe 'ramda', () ->
	it 'easy', () ->
		expected = [
			[{id: '1', name: 'c1', rank: 'a'}],
			{Client: {1: {id: '1', name: 'c1', rank: 'a'}}}
		]
		query = clients: _ {:name, rank: {eq: 'a'}}
		deepEq expected, rsql query, {result: 'both'}

	it 'easy sort', () ->
		expected = [{id: '4', rank: 'd'}, {id: '2', rank: 'c'}, {id: '3', rank: 'c'}, {id: '1', rank: 'a'}]
		deepEq expected, rsql clients: _ {:rank, _sort: [{rank: 'DESC'}, 'id']}

	it 'easy missing', () ->
		expected = [
			{id: '2', archived: true, projects: [{id: '4', name: 'p4', clientId: '2'}]},
			{id: '3', archived: true, projects: []}
		]
		query =
			clients: _ {archived: {eq: true}},
				projects: _ {:name}

		deepEq expected, rsql query

	it 'complex', () ->
		[res, normRes] = rsql query1, {result: 'both'}

		deepEq expected1, res
		deepEq expected1Norm, normRes

	it.only 'expected 2', () ->
		# res = rsql query2
		model =
			Client:
				projects: {entity: 'Project', key: 'Project.clientId'}
			Project:
				client: {entity: 'Client', key: 'Project.clientId'}

		parse2 = popsiql.newF model, {}

		data2 =
			Customer:
				1: {id: '1', name: 'cust1'}
				2: {id: '2', name: 'cust1'}
			Client:
				1: {id: '1', name: 'c1', archived: false, rank: 'a', userId: '1', cid: '1'}
				2: {id: '2', name: 'c2', archived: true, rank: 'c', cid: '1'}
				3: {id: '3', name: 'c3', archived: true, rank: 'c', cid: '1'}
				4: {id: '4', name: 'c4', archived: false, rank: 'd', cid: '1'}
			Project:
				1: {id: '1', name: 'p1', rate: null, clientId: '1', userId: '1', cid: '1'}
				2: {id: '2', name: 'p2', rate: 102, clientId: '1', userId: '1', cid: '1'}
				3: {id: '3', name: 'p3', rate: 89, clientId: '1', userId: '1', cid: '1'}
				4: {id: '4', name: 'p4', rate: 102, clientId: '2', userId: '1', cid: '1'}
				# 5: {id: '5', name: 'p5', rate: 101, clientId: '4', userId: '2', cid: '1'}
				5: {id: '5', name: 'p5', rate: 101, clientId: '4', userId: null, cid: '1'}
			User:
				1: {id: '1', name: 'u1', email: 'u1@a.com', nickname: 'nick', cid: '1'}
				2: {id: '2', name: 'u2', email: 'u1@a.com', nickname: 'nick', cid: '1'}
				3: {id: '3', name: 'u3', email: 'u1@a.com', nickname: 'sick', cid: '1'}

		rsql2 = popRamda parse2, {getData: () -> data}

		query2 =
			clients: _ {name: 1},
				projects: _ {name: 1}

		res = rsql2 query2

		deepEq {}, res

	# describe 'write', ->
	# 	# TODO

	# 	it.only 'upsert easy', ->
	# 		[rasql, myData] = newRsql()
	# 		delta = Client: {1: {id: '1', name: 'c1a'}}
	# 		rasql.write delta
	# 		expected = {id: '1', name: 'c1a'}
	# 		deepEq expected, myData.Client['1']

