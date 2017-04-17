{fromUrl, toUrl} = url = require './url'
{toMongo, execMongo} = mongo = require './mongo'
{toFirebase, toFirebaseAndExecute} = firebase = require './firebase'
{toSuperGlue} = superglue = require './superglue'
# {toRamda} = ramda = require './ramda' TODO: ta bort
{toRamda} = ramda = require './ramda2'
{toSql} = require './sql'
# {toNestedQuery, toFlatQuery, isValidQuery} = require './query'
{getEntity, validate, validateWhere} = require './utils'

module.exports = {
	fromUrl
	toUrl
	toMongo
	execMongo
	toFirebase
	toFirebaseAndExecute
	toSuperGlue
	toRamda
	toSql
	getEntity
	validate
	validateWhere
}
