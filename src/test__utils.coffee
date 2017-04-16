assert = require 'assert'
utils = require './utils'
{flip, test, where} = require 'ramda' #auto_require:ramda

eq = flip assert.strictEqual
deepEq = flip assert.deepEqual
throws = (re, f) -> assert.throws f, re


describe 'utils', ->
  describe 'validateWhere', ->
  	it 'unsupported predicates', ->
  		throws /'xx' is not a valid popsiql predicate/, ->
  			utils.validateWhere {a: {eq: 1, xx: 2}}

  	it 'handles nil', ->
			utils.validateWhere null # if it throws, the test will fail

  describe 'validate', ->
  	it 'no valid operation', ->
  		throws /missing valid operation/, ->
  			utils.validate {maXny: 'o', where: {a: {eq: 1}}}

  	it 'unsupported predicates', ->
  		throws /'xx' is not a valid popsiql predicate/, ->
  			utils.validate {many: 'o', where: {a: {eq: 1, xx: 2}}}

