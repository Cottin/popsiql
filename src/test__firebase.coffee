assert = require('assert')
{toFirebase, toFirebase2, toFirebaseAndExecute} = require '../src/firebase'
{any, both, eq, flip, gt, gte, last, lt, lte, max, where} = require 'ramda' #auto_require:ramda
{mergeMany} = require 'ramda-extras'

eq = flip assert.equal
deepEq = flip assert.deepEqual

mockRef =
  orderByChild: (x) -> mergeMany @, {__orderByChild: x}
  equalTo: (x) -> mergeMany @, {__equalTo: x}
  startAt: (x) -> mergeMany @, {__startAt: x}
  endAt: (x) -> mergeMany @, {__endAt: x}
  limitToFirst: (x) -> mergeMany @, {__limitToFirst: x}

describe 'firebase', ->
  console.log new Date() # to make it more obvious that tests are run in terminal
  describe 'toFirebase', ->
    it 'should throw an error for more than one key in where', ->
      fn = -> toFirebase {where: {a: 1, b: 2}}
      assert.throws fn, Error

    it 'should throw an error for more than one predicate', ->
      fn = -> toFirebase {where: {a: {eq: 1, gt: 2}}}
      assert.throws fn, Error

    it 'should be able to transform eq', ->
      res = toFirebase {where: {a: {eq: 123}}}
      eq res.orderByChild, 'a'
      eq res.equalTo, 123

    it '2 should be able to transform eq', ->
      res = toFirebase {a: {eq: 123}}
      eq res.orderByChild, 'a'
      eq res.equalTo, 123

    it 'neq should throw error', ->
      fn = -> toFirebase {where: {a: {neq: 123}}}
      assert.throws fn, Error

    it 'in should throw error', ->
      fn = -> toFirebase {where: {a: {in: [1, 23, 456]}}}
      assert.throws fn, Error

    it 'not in should throw error', ->
      fn = -> toFirebase {where: {a: {notIn: [1, 23, 456]}}}
      assert.throws fn, Error

    it 'gt should throw error', ->
      fn = -> toFirebase {where: {a: {gt: 123}}}
      assert.throws fn, Error

    it 'should be able to tranform gte', ->
      res = toFirebase {where: {a: {gte: 123}}}
      eq res.orderByChild, 'a'
      eq res.startAt, 123

    it 'lt should throw error', ->
      fn = -> toFirebase {where: {a: {lt: 123}}}
      assert.throws fn, Error

    it 'should be able to tranform lte', ->
      res = toFirebase {where: {a: {lte: 123}}}
      eq res.orderByChild, 'a'
      eq res.endAt, 123

    it 'should throw error for like having % in any other place than last', ->
      # ie. only startsWith queries are ok
      fn = -> toFirebase {where: {a: {like: '%abc'}}}
      assert.throws fn, Error
      fn = -> toFirebase {where: {a: {like: '%abc%'}}}
      assert.throws fn, Error

    it 'should be able to tranform like', ->
      res = toFirebase {where: {a: {like: 'abc%'}}}
      eq res.orderByChild, 'a'
      eq res.startAt, 'abc'
      eq res.endAt, 'abc\uf8ff'

    it 'should be able to tranform start and end', ->
      res = toFirebase {start: 5, end: 15}
      eq res.startAt, 5
      eq res.endAt, 15

    it 'should be able to tranform nested query', ->
      res = toFirebase {where: {'a/b': {eq: 1}}}
      eq res.orderByChild, 'a/b'
      eq res.equalTo, 1

    it 'should throw error if where clause collides with start or end', ->
      fn1 = -> toFirebase {where: {a: {gte: 123}}, start: 1}
      assert.throws fn1, Error

      fn2 = -> toFirebase {where: {a: {lte: 123}}, end: 1}
      assert.throws fn2, Error

    it 'should be able to trasform max', ->
      res = toFirebase {max: 10}
      eq res.limitToFirst, 10

    # it 'should trow error if using both child and where query', ->
    #   fn = -> toFirebase {where: {a: {eq: 1}}, b: {eq: 2}}
    #   assert.throws fn, Error

    # it 'should be able to handle child query with eq', ->
    #   res = toFirebase {a: {where: {b: {eq: 123}}}}
    #   eq res.child, 'a'
    #   eq res.orderByChild, 'b'
    #   eq res.equalTo, 123

  describe 'toFirebaseAndExecute', ->
    it 'should handle case with startAt parts', ->
      query = {where: {a: {gte: 123}}, max: 10}
      res = toFirebaseAndExecute(query)(mockRef)
      eq res.__orderByChild, 'a'
      eq res.__startAt, 123
      eq res.__limitToFirst, 10
