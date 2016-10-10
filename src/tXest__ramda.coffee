assert = require('assert')
{toRamda} = require './ramda'
{eq, flip, keys, merge, remove} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (f) -> assert.throws f, Error


describe 'ramda', ->
  describe 'toRamda', ->
    it 'error for more than one keys', ->
      throws -> toRamda({x: 1, y: 2})

    it 'error for more keys in inner query', ->
      throws -> toRamda {x: {$set: 1, $merge: 2}}

    it 'error for other than $set, $merge, $remove', ->
      throws -> toRamda {x: {$setx: 1}}
      throws -> toRamda {x: {a: 1}}

    it '$set', ->
      f = toRamda {x: {$set: 1}}
      eq 1, f({x: {a:1}}).x

    it '$merge', ->
      f = toRamda {x: {$merge: {b: 2}}}
      deepEq {a: 1, b: 2}, f({x: {a: 1, b: 1}}).x

    it '$remove', ->
      f = toRamda {x: {$remove: true}}
      deepEq {}, f({x: {a: 1, b: 2}})

    it '$set nested ', ->
      f = toRamda {x__y__z: {$set: 1}}
      eq 1, f({x: {y: {z: {a:1}}}}).x.y.z

    it '$merge nested', ->
      f = toRamda {x__y__z: {$merge: {b: 2}}}
      deepEq {a: 1, b: 2}, f({x: {y: {z: {a: 1, b: 1}}}}).x.y.z

    it '$remove nested', ->
      f = toRamda {x__y__z: {$remove: true}}
      deepEq {}, f({x: {y: {z: {a: 1, b: 2}}}}).x.y
