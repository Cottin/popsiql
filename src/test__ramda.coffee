assert = require('assert')
{toRamda, nextId} = require './ramda2'
{empty, flip, gt, gte, has, lt, lte, map, max, pluck, project, remove, sort, type, update, values, where} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepStrictEqual
throws = (re, f) -> assert.throws f, re

MOCK =
  user: [{a: 1, b: 1}, {a: 2, b: 2}, {a: 3, b: 3}]
  customer: [{a: 'victor'}, {a: 'victoria'}, {a: 'elin'}]
  project: {'1': {id: 1, a: 'a1'}, '2': {id: 2, a: 'a2'}, '11': {id: 11, a: 'a11'}}
  o: {1: {id: 1, n: 'b'}, 2: {id: 2, n: 'a'}, 3: {id: 3, n: 'c'}, 4: {id: 4, n: 'b'}}


describe 'ramda', ->
  describe 'toRamda', ->
    describe 'one', ->
      it 'simple id', ->
        f = toRamda {one: 'project', id: 1}
        deepEq {id: 1, a: 'a1'}, f(MOCK)

      it 'where multiple', ->
        f = toRamda {one: 'user', where: {a: {neq: 1}}}
        throws /one-query returned more than one item/, -> f(MOCK)

      it 'where', ->
        f = toRamda {one: 'user', where: {a: {eq: 1}}}
        deepEq {a: 1, b: 1}, f(MOCK)
          
    describe 'many', ->
      it 'simple', ->
        f = toRamda {many: 'user'}
        deepEq MOCK.user, f(MOCK)
      # it 'fields', ->
      #   f = toRamda {get: 'user', fields: ['a']}
      #   deepEq [{a: 1}, {a: 2}, {a: 3}], f(MOCK)
      describe 'where', ->
        it 'eq', ->
          f = toRamda {many: 'user', where: {a: {eq: 1}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'eq (map)', ->
          f = toRamda {many: 'o', where: {n: 'a'}}
          deepEq {2: {id: 2, n: 'a'}}, f(MOCK)

        it 'eq (implicit)', ->
          f = toRamda {many: 'user', where: {a: 1}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'neq', ->
          f = toRamda {many: 'user', where: {a: {neq: 1}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'gt', ->
          f = toRamda {many: 'user', where: {a: {gt: 2}}}
          deepEq [{a: 3, b: 3}], f(MOCK)
        it 'gte', ->
          f = toRamda {many: 'user', where: {a: {gte: 2}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'lt', ->
          f = toRamda {many: 'user', where: {a: {lt: 2}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'lte', ->
          f = toRamda {many: 'user', where: {a: {lte: 2}}}
          deepEq [{a: 1, b: 1}, {a: 2, b: 2}], f(MOCK)
        it 'in', ->
          f = toRamda {many: 'user', where: {a: {in: [2, 3]}}}
          deepEq [{a: 2, b: 2}, {a: 3, b: 3}], f(MOCK)
        it 'nin', ->
          f = toRamda {many: 'user', where: {a: {nin: [2, 3]}}}
          deepEq [{a: 1, b: 1}], f(MOCK)
        it 'like', ->
          f = toRamda {many: 'customer', where: {a: {like: 'vic%'}}}
          deepEq [{a: 'victor'}, {a: 'victoria'}], f(MOCK)
        it 'like (double %)', ->
          f = toRamda {many: 'customer', where: {a: {like: '%i%'}}}
          deepEq [{a: 'victor'}, {a: 'victoria'}, {a: 'elin'}], f(MOCK)
        it 'null not empty', ->
          f = toRamda {many: 'user', where: {a: {eq: 9}}}
          eq null, f(MOCK)

      describe 'id', ->
        it 'multiple', ->
          f = toRamda {many: 'project', id: [1, 2]}
          deepEq {1: {id: 1, a: 'a1'}, 2: {id: 2, a: 'a2'}}, f(MOCK)

      describe 'sort', ->
        it 'asc', ->
          f = toRamda {many: 'o', sort: 'n'}
          deepEq ['a', 'b', 'b', 'c'], pluck('n', f(MOCK))
        it 'desc', ->
          f = toRamda {many: 'o', sort: [{n: 'desc'}]}
          deepEq ['c', 'b', 'b', 'a'], pluck('n', f(MOCK))
        it 'desc2', ->

          mock2 =
            o:
              2:
                id: 2
                a: 'a2'
              4:
                id: 4
                a: 'a4'

          f = toRamda {many: 'o', sort: [{a: 'desc'}]}
        it 'deXXsc', ->
          f = toRamda {many: 'o', sort: [{n: 'deXXsc'}]}
          throws /sort direction must be asc or desc/, -> f(MOCK)
        it 'asc + desc', ->
          f = toRamda {many: 'o', sort: [{n: 'asc'}, {id: 'desc'}]}
          deepEq [2, 4, 1, 3], pluck('id', f(MOCK))
        it 'asc (implicit) + desc', ->
          f = toRamda {many: 'o', sort: ['n', {id: 'desc'}]}
          deepEq [2, 4, 1, 3], pluck('id', f(MOCK))
        it 'sort + fields', ->
          f = toRamda {many: 'o', sort: 'n', fields: ['id']}
          deepEq [{id: 2}, {id: 1}, {id: 4}, {id: 3}], f(MOCK)

      describe 'pagination', ->
        it 'max', ->
          f = toRamda {many: 'o', max: 2}
          deepEq [1, 2], pluck('id', values(f(MOCK)))
        it 'max + start', ->
          f = toRamda {many: 'o', max: 2, start: 1}
          deepEq [2, 3], pluck('id', values(f(MOCK)))
        it 'start', ->
          f = toRamda {many: 'o', start: 1}
          deepEq [2, 3, 4], pluck('id', values(f(MOCK)))

      describe 'special cases', ->
        it 'data is null (where)', ->
          f = toRamda {many: 'user', where: {a: {eq: 9}}}
          eq null, f(null)
        it 'data is null (fields)', ->
          f = toRamda {many: 'user', fields: ['a']}
          eq null, f(null)
        it 'data is empty (where)', ->
          f = toRamda {many: 'user', where: {a: {eq: 9}}}
          eq null, f({})
        it 'data is empty (fields)', ->
          f = toRamda {many: 'user', fields: ['a']}
          eq null, f({})

    describe 'update', ->
      it 'simple', ->
        f = toRamda {update: 'o', id: 1, data: {id: 1, n: 'bb'}}
        [newData, _] = f MOCK
        deepEq {id: 1, n: 'bb'}, newData.o[1]

      it 'throws if no data', ->
        throws /data has no entity called 'qwe'/, ->
          toRamda({update: 'qwe', id: 1})(MOCK)

      it 'throws if no entity with id', ->
        throws /no entity of type 'o' with id=999/, ->
          toRamda({update: 'o', id: 999})(MOCK)

    describe 'remove', ->
      it 'simple', ->
        f = toRamda {remove: 'o', id: 2}
        [newData, _] = f MOCK
        eq null, newData.o[2]

      it 'throws if no data', ->
        throws /data has no entity called 'qwe'/, ->
          toRamda({remove: 'qwe', id: 1})(MOCK)

      it 'throws if no entity with id', ->
        throws /no entity of type 'o' with id=999/, ->
          toRamda({remove: 'o', id: 999})(MOCK)

    describe 'create = update', ->
      it 'simple', ->
        f = toRamda {create: 'o', data: {id: 6, n: 'r'}}
        [newData, _] = f MOCK
        deepEq {id: 6, n: 'r'}, newData.o[6]

      it 'no id', ->
        f = toRamda {create: 'o', data: {n: 'r'}}
        [newData, newId] = f MOCK
        deepEq {id: 5, n: 'r'}, newData.o[newId]

      it 'already exists', ->
        throws /cannot create 'o', id=4 already exists/, ->
          toRamda({create: 'o', data: {id: 4, n: 'r'}})(MOCK)

  describe 'nextId', ->
    it 'int', ->
      res = nextId [1, 2, 4, 3]
      eq 5, res

    it 'int string', ->
      res = nextId ['1', '2', '13', '3', '8', '10', '12']
      eq 14, res

    it 'string', ->
      res = nextId ['abc1', 'abc2', 'abc4', 'abc3']
      eq 'abc4_1', res



