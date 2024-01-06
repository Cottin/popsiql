import omit from "ramda/es/omit"; import project from "ramda/es/project"; #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import popsiql from './popsiql'

export data =
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

export model1 =
	Client: {projects: 'Project', ceo: 'User', employees: 'User'}
	Project: {client: 'Client', owner: 'User'}
	User: {projects: 'Project', clients: 'Client'}

# export model1test =
# 	Client:
# 		projects: ['Project', 'Project.clientId']
# 		ceo: ['User', 'Client.ceoId']
# 		employees: ['User', 'ClientEmployee.clientId']
# 	Project: {client: 'Client', owner: 'User'}
# 	User: {projects: 'Project', clients: 'Client'}

# 	ClientEmployee: {client}

# export model1test =
# 	Client:
# 		projects: {entity: 'Project', key: 'Project.clientId'}
# 		ceo: {entity: 'User', key: 'Client.ceoId'}
# 		employees: ['User', 'ClientEmployee.clientId']
# 	Project: {client: 'Client', owner: 'User'}
# 	User: {projects: 'Project', clients: 'Client'}

# 	ClientEmployee: {client}

# export model1test =
# 	Client:
# 		projects: 'Project.clientId'
# 		ceo: 'User'
# 		employees: ['User', 'ClientEmployee.clientId']
# 	Project: {client: 'Client', owner: 'User'}
# 	User: {projects: 'Project', clients: 'Client', ceos: }

# 	ClientEmployee: {client}

export query1 =
	# users: _ {:name, :nickname, _sort: [{nickname: 'DESC'}, 'id']}
	clients: _ {name: 1, archived: {eq: false}},
		projects: _ {name: 1, rate: {gt: 100}},
			owner: _ {name: 1}
	# user: _ {id: {eq: '1'}, :name, :email}

export query2 =
	projects: _ {id: {eq: '1'}, name: 1},
		client: _ {name: 1},
			ceo: _ {name: 1}


# This could work but isn't that nice and can't be stringified easily to send to the server
query1_experimental =
	users: ({name, nickname, _sort = [{nickname: 'DESC'}], id}) ->
	clients: ({name, archived = {eq: false}}) ->
		projects: ({name, rate = {gt: 100}}) ->
			owner: ({name}) ->
	user: ({id = '1', name, email}) ->

export expected1 = null
(() ->
	client1 = omit ['rank', 'cid'], data.Client[1]
	client4 = omit ['rank', 'cid'], data.Client[4]
	user1 = omit ['email', 'nickname', 'cid'], data.User[1]
	user2 = omit ['email', 'nickname', 'cid'], data.User[2]
	expected1 =
		users: [
			{...omit(['email', 'cid'], data.User[3])}
			{...omit(['email', 'cid'], data.User[1])}
			{...omit(['email', 'cid'], data.User[2])}
		]
		clients: [
			{...client1, projects: [ {...omit(['cid'], data.Project[2]), owner: user1}]}
			{...client4, projects: [{...omit(['cid'], data.Project[5]), owner: null}]}
		]
		user: {...omit(['nickname', 'cid'], data.User[1])})()

export expected1Norm = null
(() ->
	expected1Norm =
		Client:
			1: omit [:rank, :cid], data.Client[1]
			4: omit [:rank, :cid], data.Client[4]
		Project:
			2: omit [:cid], data.Project[2]
			5: omit [:cid], data.Project[5]
		User:
			1: omit [:cid], data.User[1]
			2: omit [:email, :cid], data.User[2]
			3: omit [:email, :cid], data.User[3]
	)()

export expected2 = null
(() ->
	client1 = omit [:rank, :cid, :archived], data.Client[1]
	project1 = omit [:rate, :cid], data.Project[1]
	user1 = omit [:email, :nickname, :cid], data.User[1]
	expected2 = [{...project1, client: {...client1, ceo: {...user1}}}]
	)()

export write1 = client: {id: 1, name: 'c1a'}


# export parse1 = popsiql model1
