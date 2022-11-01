import both from "ramda/es/both"; import sort from "ramda/es/sort"; #auto_require: esramda
import {change} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, write1} from './test_mock'

import popsiql from './popsiql'


popsiql1 = popsiql model1, {ramda: {
	getData: () -> data
	changeData: (delta) -> data = change delta, data
}}


describe 'ramda', () ->
	it 'easy', () ->
		expected = [
			[{id: '1', name: 'c1', rank: 'a'}],
			{Client: {1: {id: '1', name: 'c1', rank: 'a'}}}
		]
		deepEq expected, popsiql1.ramda.options({result: 'both'}) clients: _ {:name, rank: {eq: 'a'}}

	it 'easy sort', () ->
		expected = [{id: '4', rank: 'd'}, {id: '2', rank: 'c'}, {id: '3', rank: 'c'}, {id: '1', rank: 'a'}]
		deepEq expected, popsiql1.ramda clients: _ {:rank, _sort: [{rank: 'DESC'}, 'id']}

	it 'complex', () ->
		[res, normRes] = popsiql1.ramda.options({result: 'both'}) query1

		deepEq expected1, res
		deepEq expected1Norm, normRes

	it.skip 'write easy', ->
		
		popsiql1.ramda.write write1
		console.log data 
		eq 2, 1

