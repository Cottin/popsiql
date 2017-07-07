{fromRest, toRest} = rest = require './rest'
{toMongo, execMongo} = mongo = require './mongo'
{toFirebase, toFirebaseAndExecute} = firebase = require './firebase'
{toSuperGlue} = superglue = require './superglue'
# {toRamda} = ramda = require './ramda' TODO: ta bort
{toRamda, nextId} = ramda = require './ramda2'
{toSql} = require './sql'
# {toNestedQuery, toFlatQuery, isValidQuery} = require './query'
{getEntity, getOp, validate, validateWhere} = require './utils'

module.exports = {
	fromRest
	toRest
	toMongo
	execMongo
	toFirebase
	toFirebaseAndExecute
	toSuperGlue
	toRamda
	nextId
	toSql
	getEntity
	getOp
	validate
	validateWhere
}
