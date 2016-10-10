assert = require('assert')
{toFirebase, toFirebase2, toFirebaseAndExecute} = require '../src/firebase'
{any, flip, gt, gte, last, lt, lte, max, merge, set, test, update} = require 'ramda' #auto_require:ramda
{mergeMany} = require 'ramda-extras'

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (f) -> assert.throws f, Error

mockRef =
  child: (x) -> mergeMany @, {__child: x}
  orderByChild: (x) -> mergeMany @, {__orderByChild: x}
  equalTo: (x) -> mergeMany @, {__equalTo: x}
  startAt: (x) -> mergeMany @, {__startAt: x}
  endAt: (x) -> mergeMany @, {__endAt: x}
  limitToFirst: (x) -> mergeMany @, {__limitToFirst: x}
  update: (x) -> mergeMany @, {__update: x}
  set: (x) -> mergeMany @, {__set: x}
  push: (x) -> mergeMany @, {__push: true, key: -> 'abc'}

describe 'firebase', ->
  console.log new Date() # to make it more obvious that tests are run in terminal
  describe 'toFirebase', ->

    it 'error for more than 1 collection', ->
      throws -> toFirebase {a: 1, b: 2}

    # now $start, $end, $max is allowed so this is not in play
    # it 'error for more than 1 operation', ->
    #   throws -> toFirebase {a: {b: 1, c: 2}}

    describe '$get', ->
      it 'error for more than 1 key in $get clause', ->
        throws -> toFirebase {a: {$get: {a: 1, b: 2}}}

      it 'error for more than 1 predicate in $get clause', ->
        throws -> toFirebase {a: {$get: {a: {gt: 1, lt: 2}}}}

      it 'eq', ->
        res = toFirebase {x: {$get: {a: {eq: 123}}}}
        eq 'a', res.get.orderByChild
        eq 123, res.get.equalTo

      it 'error for neq', ->
        throws -> toFirebase {x: {$get: {a: {neq: 123}}}}

      it 'error when using in for other property than id', ->
        throws -> toFirebase {x: {$get: {a: {in: [1, 23, 456]}}}}

      it 'in', ->
        res = toFirebase {x: {$get: {id: {in: [1, 23, 456]}}}}
        deepEq 'x', res.get.path
        deepEq [1, 23, 456], res.get.inArray

      it 'error for not in', ->
        throws -> toFirebase {x: {$get: {a: {notIn: [1, 23, 456]}}}}

      it 'error for gt ', ->
        throws -> toFirebase {x: {$get: {a: {gt: 123}}}}

      it 'gte', ->
        res = toFirebase {x: {$get: {a: {gte: 123}}}}
        eq res.get.orderByChild, 'a'
        eq res.get.startAt, 123

      it 'error for lt', ->
        throws -> toFirebase {x: {$get: {a: {lt: 123}}}}

      it 'lte', ->
        res = toFirebase {x: {$get: {a: {lte: 123}}}}
        eq res.get.orderByChild, 'a'
        eq res.get.endAt, 123

      it 'error for like having % in any other place than last', ->
        # ie. only startsWith queries are ok
        throws -> toFirebase {x: {$get: {a: {like: '%abc'}}}}
        throws -> toFirebase {x: {$get: {a: {like: '%abc%'}}}}

      it 'like', ->
        res = toFirebase {x: {$get: {a: {like: 'abc%'}}}}
        eq res.get.orderByChild, 'a'
        eq res.get.startAt, 'abc'
        eq res.get.endAt, 'abc\uf8ff'

      it 'start and end', ->
        res = toFirebase {x: {$get: {}, $start: 5, $end: 15}}
        eq res.get.startAt, 5
        eq res.get.endAt, 15

      it 'error if $get clause collides with start or end', ->
        throws -> toFirebase {x: {$get: {a: {gte: 123}}, $start: 1}}
        throws -> toFirebase {x: {$get: {a: {lte: 123}}, $end: 1}}

      it 'max', ->
        res = toFirebase {x: {$get: {}, $max: 10}}
        eq res.get.limitToFirst, 10

    it 'should be able to tranform nested query', ->
      res = toFirebase {x: {$get: {'a/b': {eq: 1}}}}
      eq res.get.orderByChild, 'a/b'
      eq res.get.equalTo, 1


    describe '$set', ->
      it 'simple case', ->
        query = {x__1: {$set: {a: 1, b: 2}}}
        res = toFirebase query
        deepEq 'x/1', res.set.path
        deepEq {a: 1, b: 2}, res.set.value

      it '2 levels', ->
        query = {x__y__1: {$set: {a: 1, b: 2}}}
        res = toFirebase query
        deepEq 'x/y/1', res.set.path
        deepEq {a: 1, b: 2}, res.set.value

    describe '$merge', ->
      it 'simple case', ->
        query = {x__1: {$merge: {a: 1, b: 2}}}
        res = toFirebase query
        deepEq 'x/1', res.update.path
        deepEq {a: 1, b: 2}, res.update.value

    describe '$push', ->
      it 'simple case', ->
        query = {x__y: {$push: {a: 1, b: 2}}}
        res = toFirebase query
        deepEq 'x/y', res.push.path
        deepEq {a: 1, b: 2}, res.push.value


  describe 'toFirebaseAndExecute', ->
    it 'should handle case with startAt parts', ->
      query = {x: {$get: {a: {gte: 123}}, $max: 10}}
      res = toFirebaseAndExecute(query)(mockRef)
      eq 'x', res.__child
      eq 'a', res.__orderByChild
      eq 123, res.__startAt
      eq 10, res.__limitToFirst

    it 'should handle in case', ->
      query = {x: {$get: {id: {in: [1, 23, 'a']}}}}
      res = toFirebaseAndExecute(query)(mockRef)
      eq 'x/1', res[1].__child
      eq 'x/23', res[23].__child
      eq 'x/a', res['a'].__child

    # NOTE: now returns promise, more advanced mocking needed to test this
    # it 'set', ->
    #   query = {x__y__1: {$set: {a: 1, b: 2}}}
    #   res = toFirebaseAndExecute(query)(mockRef)
    #   eq 'x/y/1', res.__child
    #   deepEq {a: 1, b: 2}, res.__set

    # NOTE: now returns promise, more advanced mocking needed to test this
    # it 'merge', ->
    #   query = {x__y__1: {$merge: {a: 1, b: 2}}}
    #   res = toFirebaseAndExecute(query)(mockRef)
    #   console.log 'res', sify(res)
    #   eq 'x/y/1', res.__child
    #   deepEq {a: 1, b: 2}, res.__update

    describe 'push', ->
      # We can't test create like this. We need to create a smarter mock
      # it 'simple case', ->
        # res = toFirebaseAndExecute({create: {x: {a: 1, b: 2}}})(mockRef)
        # eq 'x', res.__child
        # eq true, res.__push
        # deepEq {a: 1, b: 2}, res.__set

      it 'returns new key', ->
        res = toFirebaseAndExecute({x: {$push: {a: 1, b: 2}}})(mockRef)
        eq 'abc', res.key


