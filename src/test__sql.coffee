assert = require('assert')
{toSql} = require './sql'
{add, all, flip, gt, gte, insert, into, lt, lte, test, values, where} = require 'ramda' #auto_require:ramda

eq = flip assert.strictEqual
deepEq = flip assert.deepStrictEqual
throws = (f) -> assert.throws f, Error


describe 'sql', ->
  describe 'toSql', ->
    describe 'one', ->
      it 'simple', ->
        eq 'select * from tbl where id = 1', toSql {one: 'Tbl', where: {id: 1}}
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
    describe 'removeAll', ->
      it 'simple', ->
        res = toSql {removeAll: 'user'}
        eq 'delete from "user"', res

    # describe 'push', ->
    #   it 'simple', ->
    #     sql = 'insert into user (a, b)
    #     values (1, \'t\')'
    #     eq sql, toSql {push: {user: {a: 1, b: 't'}}}


