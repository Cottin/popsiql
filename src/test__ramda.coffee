assert = require('assert')
{toRamda} = require './ramda2'
{empty, flip, gt, gte, lt, lte, max, pluck, project, set, sort, values, where} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (re, f) -> assert.throws f, re

MOCK =
  user: [{a: 1, b: 1}, {a: 2, b: 2}, {a: 3, b: 3}]
  customer: [{a: 'victor'}, {a: 'victoria'}, {a: 'elin'}]
  project: {1: {id: 1, a: 'a1'}, 2: {id: 2, a: 'a2'}}
  o: {1: {id: 1, n: 'b'}, 2: {id: 2, n: 'a'}, 3: {id: 3, n: 'c'}, 4: {id: 4, n: 'b'}}


describe 'ramda', ->
  describe 'toRamda', ->
    describe 'special cases', ->
      it 'missing key operation', ->
        throws /no valid operation found in query/, ->
          f = toRamda {xxx: 'user'}
        
    describe 'get', ->
      it 'simple', ->
        f = toRamda {get: 'user'}
        deepEq MOCK.user, f(MOCK)
      it 'fields', ->
        f = toRamda {get: 'user', fields: ['a']}
        deepEq [{a: 1}, {a: 2}, {a: 3}], f(MOCK)
      describe 'where', ->
        it 'eq', ->
          f = toRamda {get: 'user', where: {a: {eq: 1}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'eq (implicit)', ->
          f = toRamda {get: 'user', where: {a: 1}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'neq', ->
          f = toRamda {get: 'user', where: {a: {neq: 1}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'gt', ->
          f = toRamda {get: 'user', where: {a: {gt: 2}}}
          deepEq [{a: 3, b: 3}], f(MOCK)
        it 'gte', ->
          f = toRamda {get: 'user', where: {a: {gte: 2}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'lt', ->
          f = toRamda {get: 'user', where: {a: {lt: 2}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'lte', ->
          f = toRamda {get: 'user', where: {a: {lte: 2}}}
          deepEq [{a: 1, b: 1}, {a: 2, b: 2}], f(MOCK)
        it 'in', ->
          f = toRamda {get: 'user', where: {a: {in: [2, 3]}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'nin', ->
          f = toRamda {get: 'user', where: {a: {nin: [2, 3]}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'like', ->
          f = toRamda {get: 'customer', where: {a: {like: 'vic%'}}}
          deepEq [{a: 'victor'}, {a: 'victoria'}], f(MOCK)
        it 'like (double %', ->
          f = toRamda {get: 'customer', where: {a: {like: '%i%'}}}
          deepEq [{a: 'victor'}, {a: 'victoria'}, {a: 'elin'}], f(MOCK)
        it 'null not empty', ->
          f = toRamda {get: 'user', where: {a: {eq: 9}}}
          eq null, f(MOCK)
          
      describe 'id', ->
        it 'one', ->
          f = toRamda {get: 'project', id: 1}
          deepEq {1: {id: 1, a: 'a1'}}, f(MOCK)
        it 'multiple', ->
          f = toRamda {get: 'project', id: [1, 2]}
          deepEq {1: {id: 1, a: 'a1'}, 2: {id: 2, a: 'a2'}}, f(MOCK)

      describe 'sort', ->
        it 'asc', ->
          f = toRamda {get: 'o', sort: 'n'}
          deepEq ['a', 'b', 'b', 'c'], pluck('n', f(MOCK))
        it 'desc', ->
          f = toRamda {get: 'o', sort: [{n: 'desc'}]}
          deepEq ['c', 'b', 'b', 'a'], pluck('n', f(MOCK))
        it 'deXXsc', ->
          f = toRamda {get: 'o', sort: [{n: 'deXXsc'}]}
          throws /sort direction must be asc or desc/, -> f(MOCK)
        it 'asc + desc', ->
          f = toRamda {get: 'o', sort: [{n: 'asc'}, {id: 'desc'}]}
          deepEq [2, 4, 1, 3], pluck('id', f(MOCK))
        it 'asc (implicit) + desc', ->
          f = toRamda {get: 'o', sort: ['n', {id: 'desc'}]}
          deepEq [2, 4, 1, 3], pluck('id', f(MOCK))
        it 'sort + fields', ->
          f = toRamda {get: 'o', sort: 'n', fields: ['id']}
          deepEq [{id: 2}, {id: 1}, {id: 4}, {id: 3}], f(MOCK)

      describe 'pagination', ->
        it 'max', ->
          f = toRamda {get: 'o', max: 2}
          deepEq [1, 2], pluck('id', values(f(MOCK)))
        it 'max + start', ->
          f = toRamda {get: 'o', max: 2, start: 1}
          deepEq [2, 3], pluck('id', values(f(MOCK)))
        it 'start', ->
          f = toRamda {get: 'o', start: 1}
          deepEq [2, 3, 4], pluck('id', values(f(MOCK)))

      describe 'special cases', ->
        it 'data is null (where)', ->
          f = toRamda {get: 'user', where: {a: {eq: 9}}}
          eq null, f(null)
        it 'data is null (fields)', ->
          f = toRamda {get: 'user', fields: ['a']}
          eq null, f(null)
        it 'data is empty (where)', ->
          f = toRamda {get: 'user', where: {a: {eq: 9}}}
          eq null, f({})
        it 'data is empty (fields)', ->
          f = toRamda {get: 'user', fields: ['a']}
          eq null, f({})
    describe 'set', ->
      it 'simple', ->
        f = toRamda {set: {user: {a: 2, b: 't'}}, where: {a: 1}}
        newData = f MOCK
        deepEq {a: 2, b: 't'}, newData.user[0]
    describe 'push', ->
      it 'simple', ->
        f = toRamda {push: {user: {a: 4, b: 't'}}}
        newData = f MOCK
        deepEq {a: 4, b: 't'}, newData.user[3]




