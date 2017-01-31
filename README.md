# popsiql

Plain Objects Producing Simply Implementable Query Languages

Popsiql is a way of expressing a data-query as a simple javascript object. Popsiql consists of 2 things: the guidlines below and a core-specification of general purpose data-querying.

## Guidlines

	1. The data-query should be represented as a javascript object
	2. Since there is no standardized way of how properties in an object is ordered across javascript engines (nor in the spec), naming of operations allowed in the data-query should be done so operations names don't collide.

## Core specification

### Operations
The four core operations are `read`, `create`, `update` and `remove`.

### Where-clasue
eq | equals
neq | not equals
gt
...






# TO MOVE: Experimental:

# När man läser
1. Returnera det som finns lokalt och var nöjd (även med tomt resultat)
{shiftType: {$get: {}}, _:'localOnly'}  {local: true, server: false}
2. Returnera det som finns lokalt och kolla också med server
{shiftType: {$get: {}}, _:'localFirst'}  {local: true, server: false}
3. Returnera inte det som finns lokalt utan bara det som finns på server
{shiftType: {$get: {}}, _:'serverOnly'}  {local: false, server: true}

4. Returnera det som finns lokalt om t > 10 min och var nöjd (även med tomt resultat)
{shiftType: {$get: {}}, _:{localOnly: 10*60}}  {local: 10x60, server: false}
5. Returnera det som finns lokalt om t > 10 min och kolla också med server
{shiftType: {$get: {}}, _:{localFirst: 10*60}} {local: 10x60, server: true}

6. Returnera det som finns lokalt och kolla också med server. Om saker inte finns lokalt
och samma fråga har exikverats tidigare ta svaret från den och återanvänd.
{shiftType: {$get: {}}, _:'localFirstTrustSelf'}  {local: true, server: trustSelf(...)}
**7. Returnera det som finns lokalt och kolla också med server. Om saker inte finns lokalt
och samma fråga har exikverats t < 10 min tidigare ta svaret från den och återanvänd.
{shiftType: {$get: {}}, _:{localFirstTrustSelf: 10*60}}  {local: 10x60, server: trustSelf(...)}

8. Specificera vilka id'n du vill åt (IN-query) och returnera det som finns lokalt
		om allt finns, var nöjd, om det saknas något ladda de id'n som saknas från server
{shiftType: {$get: {in: [1,2,3]}}, _:'localFirstOnlyMissing'}   {local: true, server: onlyMissing(...)}
**9. Specificera vilka id'n du vill åt (IN-query) om t > 10 min och returnera det som finns lokalt
		om allt finns, var nöjd, om det saknas något ladda de id'n som saknas från server
{shiftType: {$get: {in: [1,2,3]}}, _:{localFirstOnlyMissing: 10*60}}   {local: 10x60, server: onlyMissing(...)}
10. Specificera vilka id'n du vill åt... returnera lokalt men skicka också till server
{shiftType: {$get: {in: [1,2,3]}}, _:'localFirst'}   {local: true, server: true}
11. Specificera vilka id'n du vill åt om t > 10... returnera lokalt men skicka också till server
{shiftType: {$get: {in: [1,2,3]}}, _:{localFirst: 10*60}}   {local: true, server: true}
12. Specificera vilka id'n du vill åt... men hämta bara från server
{shiftType: {$get: {in: [1,2,3]}}, _:'serverOnly'}  {local: false, server: true}

# Om man skulle vända på cachningen (när man läser)
1. Returnera det som finns lokalt och var nöjd (även med tomt resultat)
{shiftType: {$get: {}}, _:'localOnly'}
// test för om man skulle ange cache här:
{shiftType: {$get: {}}, _meta:{type: 'localOnly', cache: 10*60, cacheChildren: 0}
2. Returnera det som finns lokalt och kolla också med server
{shiftType: {$get: {}}, _:'localFirst'}
3. Returnera inte det som finns lokalt utan bara det som finns på server
{shiftType: {$get: {}}, _:'serverOnly'}

4. Returnera det som finns lokalt och kolla också med server. Om saker inte finns lokalt
och samma fråga har exikverats tidigare ta svaret från den och återanvänd.
{shiftType: {$get: {}}, _:'localFirstTrustSelf'}

5. Specificera vilka id'n du vill åt (IN-query) och returnera det som finns lokalt
		om allt finns, var nöjd, om det saknas något ladda de id'n som saknas från server
{shiftType: {$get: {in: [1,2,3]}}, _:'localFirstOnlyMissing'}
6. Specificera vilka id'n du vill åt... returnera lokalt men skicka också till server
{shiftType: {$get: {in: [1,2,3]}}, _:'localFirst'}
7. Specificera vilka id'n du vill åt... men hämta bara från server
{shiftType: {$get: {in: [1,2,3]}}, _:'serverOnly'}

Känns enklare och därför som ett bättre api, summa summarum:
'localOnly'
'serverOnly'
'localFirst' 
{localFirstTrustSelf: 10:60}
'localFirstMissingOnly'

och för mutationer:
'localOnly'
'diffOnly'  // for new objects 'diffOnly' is the same as localOnly
'dismissDiff'
'applyDiff'

'syncToServer' ?

skulle kunna ha:
{type: 'localOnly', includeDiff: true}


Man kan ha ett mer reaktivt tänk och förenkla apiet till:

trustSelf: 10*60
missingOnly

och för mutationer:
// om inget anges är default "local only"
'diff'  // for new objects 'diffOnly' is the same as localOnly
'dismissDiff'
'applyDiff'

# Saker man vill stödja
- hålla koll på status för ett server request (läsa & skriva)
- ändra i en lokal kopia
- 



OBS! Kolla på och ta inspiration av denna: https://github.com/heroku/react-refetch



# namn
layaway
trésor
querybag
chamberlain


# mutationer
1. Mutera bara lokalt
{shift__2: {$merge: {start: 123123123}}, _:'localOnly'}
2. Mutera bara lokalt i en kopia
{shift__2: {$merge: {start: 123123123}}, _:'trackChanges'}
3. Återställ kopian (bara lokalt)
{shift__2: {$do: 'dismissChanges'}}
4. Använd kopia (bara lokalt)
{shift__2: {$do: 'applyChanges'}}
5. Synkronisera lokala mutationer (Använd kopia och sync)
{shift__2: {}, _:'syncToServer'}
6. Mutera lokalt och sen på server
{shift__2: {}, _:'syncToServer'}
7. Mutera bara på server

# objekt
diffs =
	shift:
		123:


1. get shifts for dates for unit
		bonus: some shifttypes and employees are included

{shift: {$get: {start: '2015-04-01', end: '2015-04-01'}}}
# unit is handled by statefull backend

2. when user clicks on add new shift, load shifttypes

{shiftType: {$get: {}}}
# unit is handled by statefull backend

3. ...and employees

{employee: {$get: {}}}
# unit is handled by statefull backend


employee:
	get: (q) -> api.get '/employee' + toUrl(q)
	set: (k, v) -> api.put '/employee/' + k, v
	push: (o) -> api.post '/employee' + o
	remove: (k) -> api.del '/employee/' + k

shiftType:
	get: (q) -> api.get '/shifttype' + toUrl(q)
	set: (k, v) -> api.put '/shifttype/' + k, v
	push: (o) -> api.post '/shifttype' + o
	remove: (k) -> api.del '/shifttype/' + k

shift:
	get: (q) ->
		schema = {shiftType: {entity: 'shiftType', cache: 0}, worker: 'employee'}
		api.get '/shift' + toUrl(q), {cache: 10*60}, schema
	// alternativ om allt var normaliserat (type per default är 'normalize')
	get: (q) ->
		schema = {shiftType: {entity: 'shiftType', type: 'getById'}, worker: 'employee'}
		api.get '/shift' + toUrl(q), {cache: 10*60}, schema
	set: (k, v) -> api.put '/shift/' + k, v
	push: (o) -> api.post '/shift' + o
	remove: (k) -> api.del '/shift/' + k



transaction:
	get: (q) -> api.get '/connection' + toUrl(q)

receipt:
	get: (q) -> api.get '/receipt' + toUrl(q)

connection:
	set: (k, v) -> api.put "/connection/#{v}", v
	get: (q) -> api.get '/connection' + toUrl(q)

{workouts__2: {remove: true},}

workouts/2, remove, sync

{workouts__2: {$remove: true}, _meta: "local'}
{workouts: {$push: {type: 1, text: 'good sweat'}}, _meta: 'local'}
{all: {$do: 'sync'}}

## Local changes (edit form)
{workouts__3: {$merge: {text: '...'}}, _meta: 'local_diff'} # keep changes in diff
{workouts__3: {$merge: {text: '...'}}, _meta: 'local_dirty'} # changes seen everywhere but dirty flag
{workouts__3: {$do: 'sync'}} # save
{workouts__3: {$do: 'revert'}} # cancel


{workouts__3: {$merge: {completed: true}}, _meta: 'optimistic'} # change locally and sync with server
{workouts__3: {$merge: {completed: true}}, _meta: 'pessemistic'} # change locally and lock cache until server confirm

{workouts__3: {$merge: {completed: true}}, _:{local: 'update'} } # change locally and lock cache until server confirm

## in views we separate statuses for reads and mutations

props:
	workouts: arrayOfShape shape
		# status field of a specific object tells if create, update, delete is in progress or their status
		_status: object
		text: string
	# if we are interested in the status for reading workouts in general, we have to subscribe to
	# a separate thing
	workouts_status: object













SELECT A.FrDt AS FrDt, A.OrdNo, A.R2, A.ProdNo, A.CustNo, '' as Nm_ASCustName, A.Descr, A.ToTm, A.FrTm, A.AgrActNo, A.AgrNo, A.R1, 0 as Seller, A.TransGr as OB, A.Txt1, A.Txt2, A.NoInvoAb/60 as NoInvoAb, '' as Notes, O.Inf, '' as CreatedOnIphone, A.AgrNo AS SortId, 1 as Transferred, O.OrdTp as Ord_OrdTp, A.Fin as Agr_Fin, O.Gr3 as Ord_Gr3, A.Gr5 as Phase
FROM VISMA_Agr A 
LEFT JOIN VISMA_Ord O On A.OrdNo = O.OrdNo
WHERE A.AgrActNo=@AgrActNo and A.CustNo = 0 and A.FrDt >= @from and A.FrDt <= @to


{agreement:
  $get: {}
  $where: {}}

query 














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

Here are some **example queries for reading**:



Simple query
```
{users: {age: {eq: 30}}}
toUrl         # users?age=eq(30)
toMSSQL       # select * from users where age = 30
toMongo       # {users: {find: {age: {$eq: 30}}}}
runMongo      # cols['users'].find({age: {$eq: 30}})
toFirebase    # {users: {orderByChild: 'age', equalTo: 30}}
runFirebase   # ref.child('users').orderByChild('age').equalTo(30)
```

Like-query
```
{users: {name: {like: 'an%'}}}
toUrl         # users?name=like(an%)
toMSSQL       # select * from users where name like 'an%'
toMongo       # {users: {find: {name: {$regex: 'jo.*'}}}}
runMongo      # cols['users'].find({name: {$regex: 'jo.*'}})
toFirebase    # {users: {orderByChild: 'name', startAt: 'an', endAt: 'an\uf8ff'}}
runFirebase   # ref.child('users').orderByChild('name').startAt('an').endAt('an\uf8ff')
```

In-query
```
{users: {id: {in: [1, 2, 3]}}}
toUrl         # users?id=in(1,2,3)
toMSSQL       # select * from users where id in (1,2,3)
toMongo       # {users: {find: {_id: {$in: [1,2,3]}}}}
runMongo      # cols['users'].find({_id: {$in: [1,2,3]}})
toFirebase    # {users: [1, 2, 3]}
runFirebase   # [ref.child('users/1'), ref.child('users/2'), ref.child('users/3')]
```

Multiple predicates
```
{users: {age: {gt: 25, lt: 30}}}
toUrl         # users?age=gt(25)&age=lt(30)
toMSSQL       # select * from users where age > 25 and age < 30
toMongo       # {users: {find: {age: {$gt: 25, $lt: 30}}}}
runMongo      # cols['users'].find({age: {$gt: 25, $lt: 30}})
toFirebase    # Error 'Firebase adapter only supports one predicate in where for the moment'
runFirebase   # Error 'Firebase adapter only supports one predicate in where for the moment'
```

Multiple properties
```
{users: {age: {lt: 30}, sex: {eq: 'female'}}}
toUrl         # users?age=lt(30)&sex=eq(female)
toMSSQL       # select * from users where age < 30 and sex = 'female'
toMongo       # {users: {find: {age: {$lt: 30}, sex: {$eq: 'female'}}}}
runMongo      # cols['users'].find({age: {$lt: 30}, sex: {$eq: 'female'}})
toFirebase    # Error 'Firebase only supports one key in where clause'
runFirebase   # Error 'Firebase only supports one key in where clause'
```

Order by
```
{users: {age: {gt: 25}}, orderBy: 'name'}
toUrl         # users?age=gt(25)&orderBy=(name)
toMSSQL       # select * from users where age > 25 order by 'name'
toMongo       # {users: {find: {age: {$gt: 25}}, sort: {name: 1}}}
runMongo      # cols['users'].find({age: {$gt: 25}}).sort({name: 1})
toFirebase    # Error 'Firebase does not support order by'
runFirebase   # Error 'Firebase does not support order by'
```


Here are some **example queries for mutation**:
```
# Simple set (in "SQL-lingo" and "REST-lingo" probably called an "update")
['users.1', 'set', {name: 'Elin', age: 29}]
{users: {set: [1, {name: 'Elin', age: 29}]}}
{users__1: {$set: {name: 'Elin', age: 29}}}
{set: {users: [1, {name: 'Elin', age: 29}]}}
{set: {users__1: {name: 'Elin', age: 29}}}
{set: {users: {name: 'Elin', age: 29}, where: 1}}
{users__1: {$set: {name: 'Elin', age: 29}}}
{users__1: {$remove: {name: 'Elin', age: 29}}}
toUrl				# not yet implemented
toMSSQL			# Error 'MSSQL does not support set, try update instead'
toMongo			# {users: {query: {_id: 1}, update: {name: 'Elin', age: 29}, options: {upsert: true}}}
runMongo		# cols['users'].update({_id: 1}, {name: 'Elin', age: 29}, {upsert: true})
toFirebase	# {users: {set: [1, {name: 'Elin', age: 29}]}}
toFirebase	# {set: {user: [1, {name: 'Elin', age: 29}]}}
runFirebase # ref.child('1').set({name: 'Elin', age: 29})
toRamda			# R.over(R.lensPath(['users']), R.merge({1: {name: 'Elin', age: 29}}))
runRamda		# R.over(R.lensPath(['users']), R.merge({1: {name: 'Elin', age: 29}}), ref)
toSuperGlue # [['users', 1], {name: 'Elin', age: 29}]
runSuperGlue# ref.set ['users', 1], {name: 'Elin', age: 29}

# Simple update (in "REST-lingo" probably called a "patch", in "SQL-lingo probably called "selective update")
# TODO: borde inte Firebase bara supporta en av set och update?
# ...nu beter den sig lika på bägge dessa, lite svårt att förstå.
# NEJ NEJ NEJ, firebase set och update är olika! set är update och update är patch
# ...maybe rename these to update and patch instead of set and update?
['users.1', 'update', {name: 'Elin', age: 29}]
{users: {update: [1, {name: 'Elin', age: 29}]}}
{users: {update: [1, {name: 'Elin', age: 29}]}}
{update: {users: {name: 'Elin', age: 29}}, where: 1}
{update: {users: [1, {name: 'Elin', age: 29}]}}
{users__1: {$merge: {name: 'Elin', age: 29}}}
{$at: ['users', 1], {$merge: {name: 'Elin', age: 29}}}  ? 
toUrl				# not yet implemented
toMSSQL			# update users set name='Elin',age=29 where id = 1
toMongo			# {users: {query: {_id: 1}, update: {$set: {name: 'Elin', age: 29}}}}
runMongo		# cols['users'].update({_id: 1}, {$set: {name: 'Elin', age: 29}})
toFirebase	# {users: {update: [1, {name: 'Elin', age: 29}]}}
runFirebase # ref.child('user/1').update({name: 'Elin', age: 29})
```

# Simple insert/create
['users', 'create', {name: 'Elin', age: 29}]
{users: {create: {name: 'Elin', age: 29}}}
{users: {$push: {name: 'Elin', age: 29}}}
toUrl				# not yet implemented
toMSSQL			# insert into users (name,age) values ('Elin',29)
toMongo			# {users: {insert: {name: 'Elin', age: 29}}}
runMongo		# cols['users'].insert({name: 'Elin', age: 29})
toFirebase	# {users: {create: {name: 'Elin', age: 29}}}
runFirebase # ref.child('users').push().set({name: 'Elin', age: 29})




