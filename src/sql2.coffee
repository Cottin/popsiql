{empty, props, type} = require 'ramda' #auto_require:ramda
{} = require 'ramda-extras' #auto_require:ramda-extras
{deepEq} = require 'testhelp' #auto_require:testhelp

sql = require './sql2'

{calcProps: short} = shortstyle()
{calcProps: short2} = shortstyle {}, {}, (x) ->
    if type(x) == 'Number' then x + 'rem'
    else x


describe 'shortstyle', ->

    describe 'as string', ->

        describe 'edge cases', ->
            it 'empty props', -> deepEq [{}, {}], short({})
            it 'undefined props', -> deepEq [{}, {}], short(undefined)
