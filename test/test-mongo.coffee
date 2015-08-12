assert = require('assert')
{toMongo, toMongoAndExecute} = mongo = require '../src/mongo'
{eq, find, gt, gte, identity, lt, lte, where} = require 'ramda' #auto_require:ramda

mockCollection =
  find: identity

describe 'mongo', ->
  describe 'toMongo', ->
    it 'should be able to transform eq', ->
      fn = toMongoAndExecute {where: {a: {eq: 123}}}
      query = fn mockCollection
      assert.equal query.a.$eq, 123

    it 'should be able to tranform neq', ->
      fn = toMongoAndExecute {where: {a: {neq: 123}}}
      query = fn mockCollection
      assert.equal query.a.$ne, 123

    it 'should be able to tranform in', ->
      fn = toMongoAndExecute {where: {a: {in: [1, 23, 456]}}}
      query = fn mockCollection
      assert.deepEqual query.a.$in, [1, 23, 456]

    it 'should be able to tranform notIn', ->
      fn = toMongoAndExecute {where: {a: {notIn: [1, 23, 456]}}}
      query = fn mockCollection
      assert.deepEqual query.a.$nin, [1, 23, 456]

    it 'should be able to tranform gt', ->
      fn = toMongoAndExecute {where: {a: {gt: 123}}}
      query = fn mockCollection
      assert.equal query.a.$gt, 123

    it 'should be able to tranform gte', ->
      fn = toMongoAndExecute {where: {a: {gte: 123}}}
      query = fn mockCollection
      assert.equal query.a.$gte, 123

    it 'should be able to tranform lt', ->
      fn = toMongoAndExecute {where: {a: {lt: 123}}}
      query = fn mockCollection
      assert.equal query.a.$lt, 123

    it 'should be able to tranform lte', ->
      fn = toMongoAndExecute {where: {a: {lte: 123}}}
      query = fn mockCollection
      assert.equal query.a.$lte, 123

    it 'should be able to tranform like', ->
      fn = toMongoAndExecute {where: {a: {like: '%abc%'}}}
      query = fn mockCollection
      assert.equal query.a.$regex, '.*abc.*'
