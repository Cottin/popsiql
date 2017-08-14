assert = require 'assert'
{empty, flip, merge, set} = require 'ramda' #auto_require:ramda
{toNestedQuery, toFlatQuery, toQueryList, isValidQuery} = require './query'
util = require 'util'

eq = flip assert.equal
deepEq = flip assert.deepStrictEqual
throws = (f) -> assert.throws f, Error

describe 'query', ->
  describe 'toNestedQuery', ->
    it 'already nested', ->
      o1 = {a: {b: 1}}
      deepEq o1, toNestedQuery(o1)

    it '1 level', ->
      deepEq {a: {b: 1}}, toNestedQuery({a__b: 1})

    it '2 levels', ->
      deepEq {a: {b: {c: 1}}}, toNestedQuery({a__b__c: 1})

    it 'no overwrite', ->
      expected = {a: {a1: 1, a2: {a21: 1}}}
      deepEq expected, toNestedQuery({a__a2__a21: 1, a__a1: 1})

  describe 'toFlatQuery', ->
    it 'already flat', ->
      o1 = {a__b: {$get: 1}}
      res = toFlatQuery(o1)
      deepEq o1, res

    it '1 level', ->
      res = toFlatQuery({a: {b: {$get: 1}}})
      deepEq {a__b: {$get: 1}}, res

    it '2 levels', ->
      res = toFlatQuery({a: {b: {c: {$get: 1}}}})
      deepEq {a__b__c: {$get: 1}}, res

    it 'multiple paths', ->
      res = toFlatQuery({a: {b: {c: {$get: 1}}, b2: {$get: 2}}})
      deepEq {a__b__c: {$get: 1}, a__b2: {$get: 2}}, res

    it 'error if not valid operations used', ->
      throws -> toFlatQuery({a: {b: {c: {$get: 1}}, b2: {xxx: 2}}})

    it 'error if not valid operations with empty obj', ->
      throws -> toFlatQuery({a: {b: {c: {$get: 1}}, b2: {}}})

    it 'error if not valid operations with array', ->
      throws -> toFlatQuery({a: {b: {c: {$get: 1}}, b2: []}})

  describe 'toQueryList', ->
    it 'error if not $get, $', ->

  describe 'isValidQuery', ->
    it 'false if not $get, $set, $merge, $push or $do', ->
      eq false, isValidQuery({a: {b: 1}})

    it 'simple valid case', ->
      eq true, isValidQuery({a: {b: {$get: 1}}})


