

[user] = await ctx.sql"select id, cid, email, created_at as \"createdAt\" from \"user\" where firebase_id = #{firebaseId}"
[user] = await ctx.sql {User: {id: 1, cid: 1, email: 1, createdAt: 1, firebaseId: {eq: firebaseId}}}


[user] = await ctx.sql {User: ['id', 'cid', 'email', 'createdAt'], where: {firebaseId: firebaseId}}

[user] = await ctx.sql {User: {:id, :cid, :email, :createdAt, firebaseId: firebaseId}


[user] = await ctx.db.User {id: 1, cid: 1, email: 1, createdAt: 1, firebaseId: {eq: firebaseId}}},
								ctx.db.


[user] = await ctx.sql {User: {id: 1, cid: 1, email: 1, createdAt: 1, firebaseId: {eq: firebaseId}}}

[clients] = await ctx.sql clients: _ {name: 1, archived: {eq: false}},
														projects: _ {name: 1, rate: {gt: 100}},
															owner: _ {name: 1}


															
export model1 =
	Client: {projects: 'Project', ceo: 'User', employees: 'User'}
	Project: {client: 'Client', owner: 'User'}
	User: {projects: 'Project', clients: 'Client'}
