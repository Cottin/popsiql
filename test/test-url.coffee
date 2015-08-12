assert = require('assert')
{fromUrl, toUrl} = url = require '../src/url'

describe 'url', ->
  describe 'fromUrl', ->
    it 'should nest stuff under where key', ->
      cql = fromUrl {a: 'eq(123)'}
      assert.equal typeof(cql.where), 'object'

    it 'should be able to parse eq', ->
      cql = fromUrl {a: 'eq(123)'}
      assert.equal cql.where.a.eq, 123

    it 'should be able to parse neq', ->
      cql = fromUrl {a: 'neq(123)'}
      assert.equal cql.where.a.neq, 123

    it 'should be able to parse in', ->
      cql = fromUrl {a: 'in(1,23,456)'}
      assert.deepEqual cql.where.a.in, [1,23,456]

    it 'should be able to parse notIn', ->
      cql = fromUrl {a: 'notIn(1,23,456)'}
      assert.deepEqual cql.where.a.notIn, [1,23,456]

    it 'should be able to parse lt', ->
      cql = fromUrl {a: 'lt(123)'}
      assert.equal cql.where.a.lt, 123

    it 'should be able to parse lte', ->
      cql = fromUrl {a: 'lte(123)'}
      assert.equal cql.where.a.lte, 123

    it 'should be able to parse gt', ->
      cql = fromUrl {a: 'gt(123)'}
      assert.equal cql.where.a.gt, 123

    it 'should be able to parse gte', ->
      cql = fromUrl {a: 'gte(123)'}
      assert.equal cql.where.a.gte, 123

    it 'should be able to parse like', ->
      cql = fromUrl {a: 'like(%abc%)'}
      assert.equal cql.where.a.like, '%abc%'



  describe 'toUrl', ->
    it 'should be able to handle eq', ->
      url = toUrl {where: {a: {eq: 'abc'}}}
      assert.equal url, 'a=eq(abc)'

    it 'should be able to handle neq', ->
      url = toUrl {where: {a: {neq: 'abc'}}}
      assert.equal url, 'a=neq(abc)'

    it 'should be able to handle in', ->
      url = toUrl {where: {a: {in: [1, 23, 456]}}}
      assert.equal url, 'a=in(1,23,456)'

    it 'should be able to handle notIn', ->
      url = toUrl {where: {a: {notIn: [1, 23, 456]}}}
      assert.equal url, 'a=notIn(1,23,456)'

    it 'should be able to handle lt', ->
      url = toUrl {where: {a: {lt: 123}}}
      assert.equal url, 'a=lt(123)'

    it 'should be able to handle lte', ->
      url = toUrl {where: {a: {lte: 123}}}
      assert.equal url, 'a=lte(123)'

    it 'should be able to handle gt', ->
      url = toUrl {where: {a: {gt: 123}}}
      assert.equal url, 'a=gt(123)'

    it 'should be able to handle gte', ->
      url = toUrl {where: {a: {gte: 123}}}
      assert.equal url, 'a=gte(123)'

    it 'should be able to handle like', ->
      url = toUrl {where: {a: {like: '%abc%'}}}
      assert.equal url, 'a=like(%abc%)'

