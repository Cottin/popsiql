import both from "ramda/es/both"; import sort from "ramda/es/sort"; #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, write1, parse1} from './test_mock'

import popRamda from './ramda'


rsql = popRamda parse1, {
	getData: () -> data
}


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

	it 'complex', () ->
		[res, normRes] = rsql query1, {result: 'both'}

		deepEq expected1, res
		deepEq expected1Norm, normRes

	# describe 'write', ->
	# 	# TODO

	# 	it.only 'upsert easy', ->
	# 		[rasql, myData] = newRsql()
	# 		delta = Client: {1: {id: '1', name: 'c1a'}}
	# 		rasql.write delta
	# 		expected = {id: '1', name: 'c1a'}
	# 		deepEq expected, myData.Client['1']

