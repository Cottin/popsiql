assert = require 'assert'
mongo = require './mongo'
{find, flip, gt, gte, lt, lte, max, where} = require 'ramda' #auto_require:ramda
{mergeMany} = require 'ramda-extras'

eq = flip assert.strictEqual
deepEq = flip assert.deepEqual
throws = (re, f) -> assert.throws f, re

mae = (query) ->
	mongoQuery = mongo.toMongo query
	mongo.execMongo mongoQuery, colls

colls =
	o:
		find: (x) -> mergeMany @, {__find: x}
		skip: (x) -> mergeMany @, {__skip: x}
		limit: (x) -> mergeMany @, {__limit: x}

describe 'mongo', ->
	describe 'toMongo + execMongo', ->
		describe 'predicates', ->
			it 'eq, neq', ->
				res = mae {many: 'o', where: {a: {eq: 123, neq: 321}}}, colls
				deepEq {$eq: 123, $ne: 321}, res.__find.a

			it 'in, nin', ->
				res = mae {many: 'o', where: {a: {in: [1,2], nin: [3,4]}}}, colls
				deepEq {$in: [1,2], $nin: [3,4]}, res.__find.a

			it 'gt, gte, lt, lte', ->
				res = mae {many: 'o', where: {a: {gt: 1, gte: 2, lt: 3, lte: 4}}}, colls
				deepEq {$gt: 1, $gte: 2, $lt: 3, $lte: 4}, res.__find.a

			it 'like', ->
				res = mae {many: 'o', where: {a: {like: '%abc%'}}}, colls
				eq new RegExp('.*abc.*', 'i').toString(), res.__find.a.$regex.toString()

		describe 'extras', ->
			it 'start and max', ->
				res = mae {many: 'o', start: 5, max: 15}, colls
				eq 5, res.__skip
				eq 15, res.__limit

		describe 'edge cases', ->
			it 'throws if no key in colls', ->
				throws /no collection 'a' in colls/, ->
					mae {many: 'a', where: {a: 1}}, colls

			it 'implicit eq', ->
				res = mae {many: 'o', where: {a: 123}}, colls
				deepEq {$eq: 123}, res.__find.a

			it 'translate id to _id', ->
				res = mae {many: 'o', where: {id: {neq: 1}}}, colls
				deepEq {$ne: 1}, res.__find._id
				eq undefined, res.__find.id

			it 'translate id to _id implicit', ->
				res = mae {many: 'o', where: {id: 1}}, colls
				deepEq {$eq: 1}, res.__find._id
				eq undefined, res.__find.id
