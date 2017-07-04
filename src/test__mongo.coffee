assert = require 'assert'
mongo = require './mongo'
{find, flip, gt, gte, lt, lte, map, max, sort, where} = require 'ramda' #auto_require:ramda
{mergeMany, changedPaths, pickRec} = require 'ramda-extras'

eq = flip assert.strictEqual
deepEq = flip assert.deepEqual
throws = (re, f) -> assert.throws f, re
peq = (val, promise) -> promise.then (v) -> eq val, v
pdeepEq = (val, promise) -> promise.then (v) -> deepEq val, v
fit = (o, spec) ->
	paths = changedPaths spec
	subO = pickRec paths, o
	deepEq spec, subO
pfit = (promise, spec) -> promise.then (v) -> fit v, spec

# like fit but assumes an array an asserts towards it's first element
fit0 = (arr, spec) ->
	o = arr[0]
	paths = changedPaths spec
	subO = pickRec paths, o
	deepEq spec, subO
pfit0 = (promise, spec) -> promise.then (v) -> fit0 v, spec

mae = (query) ->
	mongoQuery = mongo.toMongo query
	mongo.execMongo mongoQuery, colls

mae2 = (query) ->
	mongoQuery = mongo.toMongo query
	mongo.execMongo mongoQuery, colls2

colls =
	o:
		find: (x) -> mergeMany @, {__find: x}
		skip: (x) -> mergeMany @, {__skip: x}
		limit: (x) -> mergeMany @, {__limit: x}
		findOne: (x) -> mergeMany @, {__findOne: x}
		toArray: () -> new Promise (res) =>
			res [@] # we want to return @ but we need an array because of execMongo

colls2 =
	o:
		find: (x) -> mergeMany @, {__find: x}
		toArray: () -> new Promise (res) -> res [{_id: 1, a: 1}, {_id: 2, a: 2}]

# note: because of the promised-based api of node.js mongo drive and some
# 			magic happening in execMongo, we need some special ways of testing

describe 'mongo', ->
	describe 'toMongo + execMongo', ->
		describe 'predicates', ->
			it 'eq, neq', ->
				res = mae {many: 'o', where: {a: {eq: 123, neq: 321}}}, colls
				pfit0 res, {__find: {a: {$eq: 123, $ne: 321}}}

			it 'in, nin', ->
				res = mae {many: 'o', where: {a: {in: [1,2], nin: [3,4]}}}, colls
				pfit0 res, {__find: {a: {$in: [1,2], $nin: [3,4]}}}

			it 'gt, gte, lt, lte', ->
				res = mae {many: 'o', where: {a: {gt: 1, gte: 2, lt: 3, lte: 4}}}, colls
				pfit0 res, {__find: {a: {$gt: 1, $gte: 2, $lt: 3, $lte: 4}}}

			it 'like', (done) ->
				res = mae {many: 'o', where: {a: {like: '%abc%'}}}, colls
				(res.then (val) ->
					str = new RegExp('.*abc.*', 'i').toString()
					eq str, val[0].__find.a.$regex.toString()
					done()
				).catch(done)

			it 'implicit eq', ->
				res = mae {many: 'o', where: {a: 123}}, colls
				pfit0 res, {__find: {a: {$eq: 123}}}

		describe 'extras', ->
			it 'start and max', ->
				res = mae {many: 'o', start: 5, max: 15}, colls
				pfit0 res, {__skip: 5, __limit: 15}

		describe 'execution', ->
			it 'one uses findOne', ->
				res = mae {one: 'o', where: {a: 1}}
				deepEq {a: {$eq: 1}}, res.__findOne

			it 'many uses find and toArray and returns map', (done) =>
				res = mae2 {many: 'o', where: {a: 1}}
				console.log {res}
				(res.then (val) =>
					deepEq {1: {id: 1, a: 1}, 2: {id: 2, a: 2}}, val
					done()
				).catch(done)

			it 'many uses find and toArray and returns array if we sort', (done) ->
				res = mae2 {many: 'o', where: {a: 1}, sort: 'qwe'}
				console.log {res}
				(res.then (val) =>
					deepEq [{id: 1, a: 1}, {id: 2, a: 2}], val
					done()
				).catch(done)

		describe 'edge cases', ->
			it 'throws if no key in colls', ->
				throws /no collection 'a' in colls/, ->
					mae {many: 'a', where: {a: 1}}, colls

			it 'implicit eq', ->
				res = mae {many: 'o', where: {a: 123}}, colls
				pfit0 res, {__find: {a: {$eq: 123}}}

			it 'translate id to _id', ->
				res = mae {many: 'o', where: {id: {neq: 1}}}, colls
				pfit0 res, {__find: {_id: {$ne: 1}}}

			it 'translate id to _id implicit', ->
				res = mae {many: 'o', where: {id: 1}}, colls
				pfit0 res, {__find: {_id: {$eq: 1}}}
