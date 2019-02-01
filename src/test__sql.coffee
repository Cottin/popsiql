assert = require('assert')
{toSql} = require './sql'
{add, all, flip, insert, into, join, remove, set, sort, test, update, values, where} = require 'ramda' #auto_require:ramda

eq = flip assert.strictEqual
deepEq = flip assert.deepStrictEqual
throws = (re, f) -> assert.throws f, re


describe 'sql', ->
  describe 'toSql', ->
    describe 'one', ->
      it 'simple', ->
        eq 'select * from tbl where id = 1', toSql {one: 'Tbl', id: 1}
    describe 'many', ->
      it 'simple', ->
        eq 'select * from "user"', toSql {many: 'User'}
      it 'fields', ->
        res = toSql {many: 'User', fields: ['id', 'name']}
        eq 'select id, name from "user"', res
      it 'where (all predicates and multiple predicates per column)', ->
        where =
          a: {eq: 1, neq: 1, gt: 1, gte: 1, lt: 1, lte: 1}
          b: {in: [1,2], nin: [1,2], like: 'test%'}

        res = toSql {many: 'User', where}
        sql = 'select * from "user"
        where a = 1 and a <> 1 and a > 1 and a >= 1 and a < 1 and
        a <= 1 and b in (1,2) and b not in (1,2) and b like \'test%\''
        eq sql, res
      it 'implicit eq', ->
        res = toSql {many: 'User', where: {a: 1}}
        eq 'select * from "user" where a = 1', res
      it 'many ids', ->
        res = toSql {many: 'o', id: [1,2,3,4,5]}
        eq 'select * from o where id in (1,2,3,4,5)', res
      describe 'sort', ->
        it 'asc', ->
          res = toSql {many: 'o', sort: 'n'}
          eq 'select * from o order by n', res
        it 'desc', ->
          res = toSql {many: 'o', sort: [{n: 'desc'}, {k: 'asc'}]}
          eq 'select * from o order by n desc, k asc', res

    describe 'relations', ->
      CONFIG =
        A:
          id: 'int'
          a1: 'str'
          a2: 'int'
          links:
            B: 'hasOne'
        B:
          id: 'int'
          b1: 'bool'
          b2: 'int'
          links: 
            A: 'belongsTo'


      describe 'hasOne', ->
        it.only 'simple', ->
          res = toSql {CONFIG, many: 'a', link: ['B']}
          eq 'select * from a inner join b on a.id = b.aId', res

        # it 'include without config', ->
        #   throws /\'include\' in query but no CONFIG/, ->
        #     toSql {many: 'a', include: ['B']}


    describe 'create', ->
      it 'simple', ->
        sql = 'insert into "user" (a,b)
        values (1,\'t\')'
        res = toSql {create: 'user', data: {a: 1, b: 't'}}
        eq sql, res
      it 'simple with id', ->
        sql = 'insert into tbl (id,a,b)
        values (1,1,\'t\')'
        res = toSql {create: 'tbl', data: {id: 1, a: 1, b: 't'}}
        eq sql, res
    describe 'update', ->
      it 'simple', ->
        sql = 'update "user" set a = 1, b = \'t\' where id = 1'
        res = toSql {update: 'user', id: 1, data: {a: 1, b: 't'}}
        eq sql, res
      it 'no id', ->
        throws /update query missing id/, ->
          toSql {update: 'tbl', data: {id: 1, a: 1, b: 't'}}
    describe 'reserved keywords', ->
      it 'select', ->
        res = toSql {one: 'User', fields: ['alter'], where: {add: 1}}
        eq 'select "alter" from "user" where "add" = 1', res
      it 'create', ->
        res = toSql {create: 'User', data: {add: 1, all: 't'}}
        eq 'insert into "user" ("add","all") values (1,\'t\')', res
    describe 'camelCase', ->
      it 'select', ->
        res = toSql {one: 'Image', fields: ['imageUrl']}
        eq 'select "imageUrl" from image', res
      it 'create', ->
        res = toSql {create: 'User', data: {camelCase: 1}}
        eq 'insert into "user" ("camelCase") values (1)', res
    describe 'remove', ->
      it 'simple', ->
        res = toSql {remove: 'user', id: 1}
        eq 'delete from "user" where id = 1', res
      it 'no id', ->
        throws /remove query missing id/, ->
          toSql {remove: 'tbl', where: {id: 1}}
    describe 'removeAll', ->
      it 'simple', ->
        res = toSql {removeAll: 'user'}
        eq 'delete from "user"', res

    # describe 'push', ->
    #   it 'simple', ->
    #     sql = 'insert into user (a, b)
    #     values (1, \'t\')'
    #     eq sql, toSql {push: {user: {a: 1, b: 't'}}}


