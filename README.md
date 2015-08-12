# popsiql - Sweet and delicious "data"-queries in javascript

If you have simple querying needs and want to have a unified way of querying your data independent of what data layer you choose, popsiql might be a tasty treat for you.

It has adapter functions for "url", MS SQL and mongo so you could do something like this:

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
	db.execute sqlQuery

	# if you use mongo
	{find} = popsiql.toMongo(query) # {find: {name: {$regex: 'jo.*'}}}
```



