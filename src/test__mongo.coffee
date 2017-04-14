assert = require('assert')
{toMongo, toMongoAndExecute} = mongo = require '../src/mongo'
{find, gt, gte, lt, lte, max, where} = require 'ramda' #auto_require:ramda
{mergeMany} = require 'ramda-extras'

mockCollection =
  find: (x) -> mergeMany @, {__find: x}
  skip: (x) -> mergeMany @, {__skip: x}
  limit: (x) -> mergeMany @, {__limit: x}

describe.only 'mongo', ->
  describe 'toMongo', ->
    # it 'should be able to handle nulls', ->
    #   toMongoAnd null

    it 'should be able to transform eq', ->
      fn = toMongoAndExecute {where: {a: {eq: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$eq, 123

    it 'should be able to tranform neq', ->
      fn = toMongoAndExecute {where: {a: {neq: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$ne, 123

    it 'should be able to tranform in', ->
      fn = toMongoAndExecute {where: {a: {in: [1, 23, 456]}}}
      query = fn mockCollection
      assert.deepEqual query.__find.a.$in, [1, 23, 456]

    it 'should be able to tranform notIn', ->
      fn = toMongoAndExecute {where: {a: {notIn: [1, 23, 456]}}}
      query = fn mockCollection
      assert.deepEqual query.__find.a.$nin, [1, 23, 456]

    it 'should be able to tranform gt', ->
      fn = toMongoAndExecute {where: {a: {gt: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$gt, 123

    it 'should be able to tranform gte', ->
      fn = toMongoAndExecute {where: {a: {gte: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$gte, 123

    it 'should be able to tranform lt', ->
      fn = toMongoAndExecute {where: {a: {lt: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$lt, 123

    it 'should be able to tranform lte', ->
      fn = toMongoAndExecute {where: {a: {lte: 123}}}
      query = fn mockCollection
      assert.equal query.__find.a.$lte, 123

    it 'should be able to tranform like', ->
      fn = toMongoAndExecute {where: {a: {like: '%abc%'}}}
      query = fn mockCollection
      assert.equal query.__find.a.$regex.toString(), new RegExp('.*abc.*', 'i')

    it 'should be able to tranform start and max', ->
      fn = toMongoAndExecute {start: 5, max: 15}
      query = fn mockCollection
      assert.equal query.__skip, 5
      assert.equal query.__limit, 15
