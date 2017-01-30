assert = require('assert')
{toRamda} = require './ramda2'
{empty, flip, gt, gte, lt, lte, project, set, where} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (re, f) -> assert.throws f, re

MOCK =
  user: [{a: 1, b: 1}, {a: 2, b: 2}, {a: 3, b: 3}]
  customer: [{a: 'victor'}, {a: 'victoria'}, {a: 'elin'}]
  project: {1: {id: 1, a: 'a1'}, 2: {id: 2, a: 'a2'}}


describe 'ramda', ->
  describe 'toRamda', ->
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




