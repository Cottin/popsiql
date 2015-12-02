assert = require('assert')
{toFirebase, toFirebase2, toFirebaseAndExecute} = require '../src/firebase'
{any, eq, flip, gt, gte, last, length, lt, lte, max, where} = require 'ramda' #auto_require:ramda
{mergeMany} = require 'ramda-extras'

eq = flip assert.equal
deepEq = flip assert.deepEqual

mockRef =
  child: (x) -> mergeMany @, {__child: x}
  orderByChild: (x) -> mergeMany @, {__orderByChild: x}
  equalTo: (x) -> mergeMany @, {__equalTo: x}
  startAt: (x) -> mergeMany @, {__startAt: x}
  endAt: (x) -> mergeMany @, {__endAt: x}
  limitToFirst: (x) -> mergeMany @, {__limitToFirst: x}

describe 'firebase', ->
  console.log new Date() # to make it more obvious that tests are run in terminal
  describe 'toFirebase', ->
    it 'should throw an error for more than one property', ->
      fn = -> toFirebase {x: {a: 1, b: 2}}
      assert.throws fn, Error

    it 'should throw an error for more than one collection', ->
      fn = -> toFirebase {x: {a: 1}, y: {b: 2}}
      assert.throws fn, Error

    it 'should throw an error for more than one predicate', ->
      fn = -> toFirebase {x: {a: {eq: 1, gt: 2}}}
      assert.throws fn, Error

    it 'should handle eq', ->
      res = toFirebase {x: {a: {eq: 123}}}
      eq res.x.orderByChild, 'a'
      eq res.x.equalTo, 123

    it 'neq should throw error', ->
      fn = -> toFirebase {x: {a: {neq: 123}}}
      assert.throws fn, Error

    it 'should throw error when using in for other property than id', ->
      fn = -> toFirebase {x: {a: {in: [1, 23, 456]}}}
      assert.throws fn, Error

    it 'should handle in', ->
      res = toFirebase {x: {id: {in: [1, 23, 456]}}}
      deepEq [1, 23, 456], res.x

    it 'not in should throw error', ->
      fn = -> toFirebase {x: {a: {notIn: [1, 23, 456]}}}
      assert.throws fn, Error

    it 'gt should throw error', ->
      fn = -> toFirebase {x: {a: {gt: 123}}}
      assert.throws fn, Error

    it 'should be able to tranform gte', ->
      res = toFirebase {x: {a: {gte: 123}}}
      eq res.x.orderByChild, 'a'
      eq res.x.startAt, 123

    it 'lt should throw error', ->
      fn = -> toFirebase {x: {a: {lt: 123}}}
      assert.throws fn, Error

    it 'should be able to tranform lte', ->
      res = toFirebase {x: {a: {lte: 123}}}
      eq res.x.orderByChild, 'a'
      eq res.x.endAt, 123

    it 'should throw error for like having % in any other place than last', ->
      # ie. only startsWith queries are ok
      fn = -> toFirebase {x: {a: {like: '%abc'}}}
      assert.throws fn, Error
      fn = -> toFirebase {x: {a: {like: '%abc%'}}}
      assert.throws fn, Error

    it 'should be able to tranform like', ->
      res = toFirebase {x: {a: {like: 'abc%'}}}
      eq res.x.orderByChild, 'a'
      eq res.x.startAt, 'abc'
      eq res.x.endAt, 'abc\uf8ff'

    it 'should be able to tranform start and end', ->
      res = toFirebase {x: {}, start: 5, end: 15}
      eq res.x.startAt, 5
      eq res.x.endAt, 15

    it 'should be able to tranform nested query', ->
      res = toFirebase {x: {'a/b': {eq: 1}}}
      eq res.x.orderByChild, 'a/b'
      eq res.x.equalTo, 1

    it 'should throw error if where clause collides with start or end', ->
      fn1 = -> toFirebase {x: {a: {gte: 123}}, start: 1}
      assert.throws fn1, Error

      fn2 = -> toFirebase {x: {a: {lte: 123}}, end: 1}
      assert.throws fn2, Error

    it 'should be able to trasform max', ->
      res = toFirebase {x: {}, max: 10}
      eq res.x.limitToFirst, 10

  describe 'toFirebaseAndExecute', ->
    it 'should handle case with startAt parts', ->
      query = {x: {a: {gte: 123}}, max: 10}
      res = toFirebaseAndExecute(query)(mockRef)
      eq 'x', res.__child
      eq 'a', res.__orderByChild
      eq 123, res.__startAt
      eq 10, res.__limitToFirst

    it 'should handle in case', ->
      query = {x: {id: {in: [1, 23, 4]}}}
      res = toFirebaseAndExecute(query)(mockRef)
      eq 3, length(res)
      eq 'x/1', res[0].__child
      eq 'x/23', res[1].__child
      eq 'x/4', res[2].__child

