assert = require('assert')
{fromUrl, toUrl} = url = require '../src/url'

describe 'url', ->
  describe 'fromUrl', ->
    it 'should nest stuff under where key', ->
      query = fromUrl {a: 'eq(123)'}
      assert.equal typeof(query.where), 'object'

    it 'should be able to parse eq', ->
      query = fromUrl {a: 'eq(123)'}
      assert.equal query.where.a.eq, 123

    it 'should be able to parse neq', ->
      query = fromUrl {a: 'neq(123)'}
      assert.equal query.where.a.neq, 123

    it 'should be able to parse in', ->
      query = fromUrl {a: 'in(1,23,456)'}
      assert.deepEqual query.where.a.in, [1,23,456]

    it 'should be able to parse notIn', ->
      query = fromUrl {a: 'notIn(1,23,456)'}
      assert.deepEqual query.where.a.notIn, [1,23,456]

    it 'should be able to parse lt', ->
      query = fromUrl {a: 'lt(123)'}
      assert.equal query.where.a.lt, 123

    it 'should be able to parse lte', ->
      query = fromUrl {a: 'lte(123)'}
      assert.equal query.where.a.lte, 123

    it 'should be able to parse gt', ->
      query = fromUrl {a: 'gt(123)'}
      assert.equal query.where.a.gt, 123

    it 'should be able to parse gte', ->
      query = fromUrl {a: 'gte(123)'}
      assert.equal query.where.a.gte, 123

    it 'should be able to parse like', ->
      query = fromUrl {a: 'like(%abc%)'}
      assert.equal query.where.a.like, '%abc%'

    it 'should be able to parse start and max parameters', ->
      query = fromUrl {start: 0, max: 15}
      assert.equal query.start, 0
      assert.equal query.max, 15

    it 'should be able to handle multiple properties', ->
      query = fromUrl {a: 'abc', b: 123}
      assert.equal query.where.a, 'abc'
      assert.equal query.where.b, 123

    it 'should be able to handle multiple predicates', ->
      query = fromUrl {a: {'0': 'gte(1)', '1':'lte(3)'}}
      assert.equal query.where.a.gte, 1
      assert.equal query.where.a.lte, 3

    # it 'should be able to handle implicit eq', ->
    #   url = toUrl {where: {a: 1, b: 'abc', c: 123}}
    #   assert.equal url, 'a=1&b=abc&c=123'



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

    it 'should be able to handle start and max parameters', ->
      url = toUrl {start: 5, max: 15}
      assert.equal url, 'start=5&max=15'

    it 'should be able to handle multiple properties', ->
      url = toUrl {where: {a: {lt: 123}, b: {gt: 2}}}
      assert.equal url, 'a=lt(123)&b=gt(2)'

    it 'should be able to handle implicit eq', ->
      url = toUrl {where: {a: 1, b: 'abc', c: 123}}
      assert.equal url, 'a=1&b=abc&c=123'

    it 'should be able to handle multiple predicates', ->
      url = toUrl {where: {a: {gte: 1, lte: 3}}}
      assert.equal url, 'a=gte(1)&a=lte(3)'


