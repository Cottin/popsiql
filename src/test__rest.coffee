assert = require 'assert'
{all, flip, gt, gte, lt, lte, max, props, remove, type, update, where} = require 'ramda' #auto_require:ramda
{fromRest, toRest} = url = require '../src/rest'

eq = flip assert.strictEqual
deepEq = flip assert.deepStrictEqual
throws = (re, f) -> assert.throws f, re

describe 'rest', ->

  describe 'toRest', ->
    describe 'many', ->
      it 'only entity', ->
        res = toRest {many: 'o'}
        deepEq {method: 'GET', url: 'o'}, res

      it 'all preds', ->
        where =
          a:
            eq: 'abc'
            neq: 'qwe'
            lt: 13
            lte: 12
            gt: 10
            gte: 11
            in: [1, 23]
            nin: [4, 56]
            like: '%a%'
        res = toRest {many: 'o', where}
        eq "o?a=eq(abc)&a=neq(qwe)&a=lt(13)&a=lte(12)&a=gt(10)&a=gte(11)&a=in(1,23)&a=nin(4,56)&a=like(%a%)", res.url

      it 'multi props and multi preds', ->
        res = toRest {many: 'o', where: {a: {gt: 10, lt: 20}, b: {gte: 11, lte: 21}}}
        eq 'o?a=gt(10)&a=lt(20)&b=gte(11)&b=lte(21)', res.url

      it 'implicit eq', ->
        res = toRest {many: 'o', where: {a: 123, b: 'abc'}}
        eq 'o?a=123&b=abc', res.url

      it 'start and max', ->
        res = toRest {many: 'o', start: 5, max: 15}
        eq 'o?$start=5&$max=15', res.url

      it 'many ids', ->
        res = toRest {many: 'o', id: [1,2,3,4,5]}
        eq 'o?id=1,2,3,4,5', res.url

    describe 'one', ->
      it 'id', ->
        res = toRest {one: 'o', id: 2}
        eq 'o/2', res.url

      it 'where', ->
        res = toRest {one: 'o', where: {a: 1, b: '2'}}
        eq 'o?a=1&b=2', res.url

    describe 'create', ->
      it 'simple', ->
        res = toRest {create: 'o', data: {a: 1, b: 'abc'}}
        deepEq {method: 'POST', url: 'o', body: {a: 1, b: 'abc'}}, res

    describe 'update', ->
      it 'simple', ->
        res = toRest {update: 'o', id: 1, data: {id: 1, a: 1, b: 'abc'}}
        deepEq {method: 'PUT', url: 'o/1', body: {a: 1, b: 'abc'}}, res

    describe 'remove', ->
      it 'simple', ->
        res = toRest {remove: 'o', id: 1}
        deepEq {method: 'DELETE', url: 'o/1'}, res

  describe 'fromRest', ->
    describe 'many', ->
      it 'only entity', ->
        deepEq {many: 'o'}, fromRest({url: 'o', method: 'GET'})

      it 'all preds', ->
        res = fromRest {url: "o?a=eq(abc)&a=neq(qwe)&a=lt(13)&a=lte(12)&a=gt(10)&a=gte(11)&a=in(1,23)&a=nin(4,56)&a=like(%a%)", method: 'GET'}
        where =
          a:
            eq: 'abc'
            neq: 'qwe'
            lt: 13
            lte: 12
            gt: 10
            gte: 11
            in: [1, 23]
            nin: [4, 56]
            like: '%a%'
        deepEq {many: 'o', where}, res
        eq 12, res.where.a.lte # make sure type is auto-converted

      it 'multi props and multi preds', ->
        res = fromRest {url: 'o?a=gt(10)&a=lt(20)&b=gte(11)&b=lte(21)', method: 'GET'}
        exp = {many: 'o', where: {a: {gt: 10, lt: 20}, b: {gte: 11, lte: 21}}}
        deepEq exp, res

      it 'implicit eq', ->
        res = fromRest {url: 'o?a=123&b=abc', method: 'GET'}
        deepEq {many: 'o', where: {a: 123, b: 'abc'}}, res
        eq 123, res.where.a # make sure type is auto-converted

      it 'start and max', ->
        res = fromRest {url: 'o?$start=5&$max=15', method: 'GET'}
        deepEq {many: 'o', start: 5, max: 15}, res

      it 'assume number and strings', ->
        query = fromRest {url: 'o?a=in(10,23.5,abc,false)', method: 'GET'}
        eq query.where.a.in[0], 10
        eq query.where.a.in[1], 23.5
        eq query.where.a.in[2], 'abc'
        eq query.where.a.in[3], false

      it 'many ids', ->
        res = fromRest {url: 'o?id=1,2,3,4,5', method: 'GET'}
        deepEq {many: 'o', id: [1,2,3,4,5]}, res

    describe 'one', ->
      it 'id', ->
        res = fromRest({url: 'o/2', method: 'GET'}) 
        deepEq {one: 'o', id: 2}, res
        eq 2, res.id # needs to auto-convert

    describe 'create', ->
      it 'simple', ->
        res = fromRest {method: 'POST', url: 'o', body: {a: 1, b: 'abc'}}
        deepEq {create: 'o', data: {a: 1, b: 'abc'}}, res

    describe 'update', ->
      it 'simple', ->
        res = fromRest {method: 'PUT', url: 'o/1', body: {a: 1, b: 'abc'}}
        deepEq {update: 'o', id: 1, data: {id: 1, a: 1, b: 'abc'}}, res
        eq 1, res.id

    describe 'remove', ->
      it 'simple', ->
        res = fromRest {method: 'DELETE', url: 'o/1'}
        deepEq {remove: 'o', id: 1}, res
        eq 1, res.id




