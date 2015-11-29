# popsiql

**Sweet and delicious "data"-queries in javascript**

If you have simple querying needs and want to have a unified way of querying your data independent of what data layer you choose, popsiql might be a tasty treat for you.

The idea is not to try to support complex queries, but instead the most simple ones that ofter are enough for small applications.

You should be able to write an adapter that takes a popsiql-query as input and produce whatever output you need in a quite simple way. There are existing adapters for "url", MS SQL, mongo and firebase which are all between 40-80 lines of code long, have a look at them!

Your client side code:

```
onClick: ->
	query = {where: {name: {like: 'jo%'}}}
	urlQuery = popsiql.toUrl(query) # "name=like(jo%)"
	xhr.get('/api/employee?' + urlQuery)
```

Your server side code:

```
app.get '/api/employee', (req, res) ->
	query = popsiql.fromUrl(req.query) # {where: {name: {like: 'jo%'}}}

	# if you use SQL
	sqlQuery = popsiql.toSQL(query) # "SELECT ... WHERE name LIKE 'jo%'"
	db.execute(sqlQuery)

	# if you use mongo
	{find} = popsiql.toMongo(query) # {find: {name: {$regex: 'jo.*'}}}
	db.collection('...').find(find)
```

Here is ___a spec___ some example queries:

```
{users: {age: {eq: 30}}}
toUrl 			# users?age=eq(30)
toMSSQL			# select * from users where age = 30
toMongo			# {users: {find: {age: {$eq: 30}}}}
runMongo		# cols['users'].find({age: {$eq: 30}})
toFirebase	# {users: {orderByChild: 'age', equalTo: 30}}
runFirebase	# ref.child('users').orderByChild('age').equalTo(30)

{users: {name: {like: 'an%'}}}
toUrl 			# users?name=like(an%)
toMSSQL			# select * from users where name like 'an%'
toMongo			# {users: {find: {name: {$regex: 'jo.*'}}}}
runMongo		# cols['users'].find({name: {$regex: 'jo.*'}})
toFirebase	# {users: {orderByChild: 'name', startAt: 'an', endAt: 'an\uf8ff'}}
runFirebase	# ref.child('users').orderByChild('name').startAt('an').endAt('an\uf8ff')

{users: {id: {in: [1, 2, 3]}}}
toUrl 			# users?id=in(1,2,3)
toMSSQL			# select * from users where id in (1,2,3)
toMongo			# {users: {find: {_id: {$in: [1,2,3]}}}}
runMongo		# cols['users'].find({_id: {$in: [1,2,3]}})
toFirebase	# {users: {1, 2, 3}
runFirebase	# {1: ref.child('users/1'), 2: ref.child('users/2'), 3: ref.child('users/3')}
```

