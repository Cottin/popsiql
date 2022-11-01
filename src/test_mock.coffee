import omit from "ramda/es/omit"; #auto_require: esramda
import {} from "ramda-extras" #auto_require: esramda-extras
_ = (...xs) -> xs

import popsiql from './popsiql'

export data =
	Client:
		1: {id: '1', name: 'c1', archived: false, rank: 'a'}
		2: {id: '2', name: 'c2', archived: true, rank: 'c'}
		3: {id: '3', name: 'c3', archived: true, rank: 'c'}
		4: {id: '4', name: 'c4', archived: false, rank: 'd'}
	Project:
		1: {id: '1', name: 'p1', rate: null, clientId: '1', userId: '1'}
		2: {id: '2', name: 'p2', rate: 102, clientId: '1', userId: '1'}
		3: {id: '3', name: 'p3', rate: 89, clientId: '1', userId: '1'}
		4: {id: '4', name: 'p4', rate: 102, clientId: '2', userId: '1'}
		5: {id: '5', name: 'p5', rate: 101, clientId: '4', userId: '2'}
	User:
		1: {id: '1', name: 'u1', email: 'u1@a.com', nickname: 'nick'}
		2: {id: '2', name: 'u2', email: 'u1@a.com', nickname: 'nick'}
		3: {id: '3', name: 'u3', email: 'u1@a.com', nickname: 'sick'}

export model1 =
	Client: {projects: 'Project'}
	Project: {client: 'Client', owner: 'User'}
	User: {projects: 'Project'}

export query1 =
	users: _ {:name, :nickname, _sort: [{nickname: 'DESC'}, 'id']}
	clients: _ {name: 1, archived: {eq: false}},
		projects: _ {name: 1, rate: {gt: 100}},
			owner: _ {name: 1}
	user: _ {id: {eq: '1'}, :name, :email}

export expected1 = null
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

export expected1Norm = null
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

export write1 = client: {id: 1, name: 'c1a'}


export parse1 = popsiql model1
