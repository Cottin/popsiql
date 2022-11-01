 #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import {deepEq, eq, throws, defuse} from 'comon/shared/testUtils'

import {data, model1, query1, expected1, expected1Norm, write1} from './test_mock'

import popsiql from './popsiql'
import {Client, types} from 'pg'

popsiql1 = popsiql model1


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
				where: {id: {eq: '1'}}

		deepEq expected, popsiql1.parse query1

	it 'helpful if bad body', ->
		throws 'body not array', -> popsiql1.parse {clients: {name: 1}}

	describe 'orders', ->
		pop2 = popsiql
			Record: {project: 'Project'}
			Project: {client: 'Client', records: 'Record'}
			Client: {projects: 'Project'}
			User: {}

		it 'createOrder', ->
			expected = ['Client', 'User', 'Project',  'Record']
			deepEq expected, pop2.parse.createOrder

		it 'deleteOrder', ->
			expected = ['Record', 'Project', 'User', 'Client']
			deepEq expected, pop2.parse.deleteOrder


# describe 'parse write', () ->
# 	# 1. single object full
# 	client: {id: 1, name: 'c1a', rank: 'a'}

# 	# 2. single object merge
# 	client: {id: 1, name: 'c1a'}

# 	# 3. composed object
# 	client:
# 		{id: -1, name: 'c5', projects: [
# 			{id: -2, name: 'p6', rate: 105, owner: {id: 1, name: 'u1a'}}
# 		]}

# 	# 4. composed but normalized
# 	Client: {"-1": {name: 'c5'}}
# 	Project: {"-2": {name: 'p6', rate: 105, clientId: -1, userId: -3}}
# 	User: {"-3": {name: 'u1a'}}

# 	[
# 		{entity: 'Client', operation: 'create', tempId: -1, data: {name: 'c5'}}
# 	]

# 	# 5. bulk edits
# 	clients: [
# 		{id: -1, name: 'c5', projects: [
# 				{id: -2, name: 'p6', rate: 105, owner: {id: 1, name: 'u1a'}}
# 			]}
# 		{id: -3, name: 'c6', projects: [
# 				{id: -4, name: 'p7', rate: 107, owner: {id: -51, name: 'u1a'}}
# 			]}
# 	]

# 	# 6. hard
# 	clients: [
# 		{id: -1, name: 'c5', projects: [
# 				{id: -2, name: 'p6', rate: 105, owner: {id: 1, name: 'u1a'}}
# 			]}
# 		{id: -3, name: 'c6', projects: [
# 				{id: -4, name: 'p7', rate: 107, owner: {id: -51, name: 'u1a'}}
# 			]}
# 	]

# 	it 'easy', () ->
# 		expected = [
# 			{}
# 		]
# 		deepEq expected, popsiql1.parseWrite write1



