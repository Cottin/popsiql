assert = require('assert')
{toSql} = require './sql'
{all, flip, gt, gte, insert, into, lt, lte, set, test, update, values, where} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (f) -> assert.throws f, Error


describe 'sql', ->
  describe 'toSql', ->
    describe 'get', ->
      it 'simple', ->
        eq 'select * from users', toSql {get: 'users'}
      it 'fields', ->
        res = toSql {get: 'users', fields: ['id', 'name']}
        eq 'select id, name from users', res
      it 'where (all predicates and multiple predicates per column)', ->
        where =
          a: {eq: 1, neq: 1, gt: 1, gte: 1, lt: 1, lte: 1}
          b: {in: [1,2], nin: [1,2], like: 'test%'}

        res = toSql {get: 'users', where}
        sql = 'select * from users
        where a = 1 and a <> 1 and a > 1 and a >= 1 and a < 1 and
        a <= 1 and b in [1,2] and b not in [1,2] and b like \'test%\''
        eq sql, res
      it 'implicit eq', ->
        res = toSql {get: 'user', where: {a: 1}}
        eq 'select * from user where a = 1', res
    describe 'set', ->
      it 'simple', ->
        sql = 'update user
        set a = 1, b = \'t\'
        where id = 5'
        eq sql, toSql {set: {user: {a: 1, b: 't'}}, where: {id: 5}}
    # describe 'push', ->
    #   it 'simple', ->
    #     sql = 'insert into user (a, b)
    #     values (1, \'t\')'
    #     eq sql, toSql {push: {user: {a: 1, b: 't'}}}


