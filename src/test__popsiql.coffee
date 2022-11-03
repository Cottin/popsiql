 #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, write1} from './test_mock'

import popsiql from './popsiql'
import {Client, types} from 'pg'

myParse = popsiql model1


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
user: _ {id: {eq:\"1\"}, #{colon}name, #{colon}email}"""
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
				where: {cid: {eq: '1'}}
			clients:
				entity: 'Client'
				key: 'clients'
				multiplicity: 'many'
				fields: ['name', 'archived']
				allFields: ['id', 'name', 'archived']
				where: {archived: {eq: false}, cid: {eq: '1'}}
				subs:
					projects:
						entity: 'Project'
						key: 'projects'
						multiplicity: 'many'
						fields: ['name', 'rate']
						allFields: ['id', 'name', 'rate', 'clientId', 'userId']
						where: {rate: {gt: 100}, cid: {eq: '1'}}
						relParentId: 'clientId'
						subs:
							owner:
								entity: 'User'
								key: 'owner'
								multiplicity: 'one'
								fields: ['name']
								allFields: ['id', 'name']
								relIdFromParent: 'userId'
								where: {cid: {eq: '1'}}
			user:
				entity: 'User'
				key: 'user'
				multiplicity: 'one'
				fields: [:id, :name, :email]
				allFields: [:id, :name, :email]
				where: {id: {eq: '1'}, cid: {eq: '1'}}

		safeGuard = (subQuery, ret) ->
			ret.where ?= {}
			if subQuery.entity == 'Customer' then ret.where.id = {eq: '1'}
			else ret.where.cid = {eq: '1'}

		deepEq expected, myParse query1, safeGuard

	it 'helpful if bad body', ->
		throws 'body not array', -> myParse {clients: {name: 1}}

	describe 'orders', ->
		parse2 = popsiql
			Record: {project: 'Project'}
			Project: {client: 'Client', records: 'Record'}
			Client: {projects: 'Project'}
			User: {}

		it 'createOrder', ->
			expected = ['Client', 'User', 'Project',  'Record']
			deepEq expected, parse2.createOrder

		it 'deleteOrder', ->
			expected = ['Record', 'Project', 'User', 'Client']
			deepEq expected, parse2.deleteOrder

