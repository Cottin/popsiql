assert = require('assert')
{toSuperGlue} = require './superglue'
{__, apply, eq, flip, inc, keys, merge, path, remove} = require 'ramda' #auto_require:ramda

eq = flip assert.equal
deepEq = flip assert.deepEqual
throws = (f) -> assert.throws f, Error


describe 'superglue', ->
  describe 'toSuperGlue', ->
    it 'error for more than one keys', ->
      throws -> toSuperGlue({x: 1, y: 2})

    it 'error for more keys in inner query', ->
      throws -> toSuperGlue {x: {$set: 1, $merge: 2}}

    it 'error for other than $set, $merge, $remove', ->
      throws -> toSuperGlue {x: {$setx: 1}}
      throws -> toSuperGlue {x: {a: 1}}

    it '$set', ->
      {path, f} = toSuperGlue {x: {$set: 1}}
      eq 'x', path
      eq 1, f({a:1})

    it '$merge', ->
      {path, f} = toSuperGlue {x: {$merge: {b: 2}}}
      deepEq {a: 1, b: 2}, f({a: 1, b: 1})

    it '$remove', ->
      {path, f} = toSuperGlue {x: {$remove: true}}
      deepEq null, f({a: 1, b: 2})

    it '$apply', ->
      {path, f} = toSuperGlue {x: {$apply: inc}}
      eq 2, f(1)

    it 'nested paths with __', ->
      {path, f} = toSuperGlue {x__y__z: {$set: 1}}
      deepEq ['x', 'y', 'z'], path

