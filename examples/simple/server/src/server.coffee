require('dotenv').config()

{drop, flatten, test, type, where} = R = require 'ramda' # auto_require: ramda
{$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːamount, ːALL, ːid, ːtype, ːsex, ːage, ːtext, ːdate, ːname] = ['amount', 'ALL', 'id', 'type', 'sex', 'age', 'text', 'date', 'name'] #auto_sugar

express = require 'express'
bodyParser = require 'body-parser'
cors = require 'cors'
morgan = require 'morgan'
{Pool} = require 'pg'

model = require '../../../../src/testModel'
seed = require '../../../../src/testSeed'
popsiql = require '../../../../src/popsiql'


_ = (...xs) -> xs

pool = new Pool
	database: 'popsiql_simple'
	port: 5432,
	user: 'victor'
	max: 20
	idleTimeoutMillis: 30000
	connectionTimeoutMillis: 2000
	rowMode: 'array'

pool.on 'error', (err, client) ->
	console.error('Postgres: Unexpected error on idle client', err)
	process.exit(-1)


execRawQuery = (q) ->
	try
		console.log 'RAW:\n', q
		res = await pool.query {text: q, rowMode: 'array'}
		# console.log JSON.stringify res, null, 2
		return res.rows
	catch err
		console.error 'execRawQuery', err


execRead = (q, model) ->
	try
		console.log 'READ:\n', q
		sql = popsiql.sql.read q, model
		res = await execRawQuery sql
		return res
	catch err
		console.error 'execRead', err



app = express()

app.use morgan('combined')
app.use bodyParser.urlencoded({extended: true})
app.use bodyParser.json()

app.use cors()

app.get '/popsiql/test', (req, resp) ->
	resp.send('ok')

app.get '/popsiql/reset', (req, resp) ->
	tablesToDrop = await execRawQuery "select tablename from pg_tables where schemaname = 'public';"
	for tableName in flatten tablesToDrop
		await execRawQuery "drop table #{tableName}"

	sql = popsiql.sql.createTables model
	res = await execRawQuery sql

	for k, v of seed
		for kʹ, vʹ of v
			await execRawQuery popsiql.sql.write {CREATE: {[k]: _ vʹ}}, model

	resp.send 'ok'

app.post '/popsiql/read', (req, resp) ->
	console.log req

	query = req.body
	# query =
	# 	Person: _ {id: {in: [3, 4]}, ːname},
	# 		roles: _ {ːname},
	# 			project: _ {ːid, ːname},
	# 				company: _ {ːname}
	# 		entries: _ {ːdate, ːamount}
	# query = 
	# 	Person: _ {id: {gte: 3, lte: 4}, ːname, ːsex, ːage},
	# 		entries: _ {ːid, ːamount, ːdate, ːtext},
	# 			task: _ {ːname}
	# 			project: _ {ːname}
	# 		roles: _ {name: 'Guest'},
	# 			project: _ {ːid, ːname, ːtype}
	# query =
	# 	Person: _ {id: {gte: 3, lte: 4}, ːALL},
	# 		entries: _ {ːALL},
	# 			task: _ {ːALL}
	# 			project: _ {ːALL}
	# 		roles: _ {ːALL},
	# 			project: _ {ːALL}
	# query =
	# 	Person: _ {id: {gte: 3, lte: 4}, ːALL},
	# 		# entries: _ {ːid, ːamount, ːdate, ːtext},
	# 		# 	task: _ {ːid, ːname}
	# 		# 	project: _ {ːid, ːname}
	# 		roles: _ {ːid, ːALL},
	# 			project: _ {ːid, ːALL}



	try
		rows = await execRead query, model
		console.log '-----------------------'
		cache = popsiql.sql.buildResult query, rows, model
		console.log cache
		console.log '-----------------------'
		result = popsiql.ramda.read query, cache, model
		console.log result
		resp.send result
	catch err
		console.log err
		resp.send 'error'


app.listen process.env.PORT, () ->
	console.log 'Listening on ' + process.env.PORT
