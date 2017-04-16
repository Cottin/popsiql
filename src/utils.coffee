{difference, gt, gte, has, isEmpty, isNil, keys, length, lt, lte, merge, none, remove, type, update, where} = require 'ramda' #auto_require:ramda
{ymap} = require 'ramda-extras'

sify = JSON.stringify

# o -> s   # returns the entity from a popsiql query object
getEntity = ({one, many, create, update, remove, merge}) ->
	return one || many || create || update || remove || merge


# o -> void   # throws an error if query isn't a valid popsiql query
validate = (query) ->
	if isNil getEntity(query)
		throw new Error 'missing valid operation (one, many, create, update, remove, merge)'
	if has('one', query) && type(query.id) == 'Array' && length(query.id) != 1
		throw new Error "'one'-query cannot ask for more than one id:" + sify(query)
	if has('many', query) && !isNil(query.id)
		if type(query.id) != 'Array' || length(query.id) < 2
			throw new Error "'many'-query cannot ask for only one id:" + sify(query)

	validateWhere query.where

	# todo: validate id for update, delete, merge

_preds = ['eq', 'neq', 'in', 'nin', 'gt', 'gte', 'lt', 'lte', 'like']

# o -> void   # throws an error if where part isn't valid in popsiql
validateWhere = (where) ->
	if isNil where then return
	ymap where, (preds) ->
		diff = difference keys(preds), _preds
		if !isEmpty diff
			throw new Error "'#{diff[0]}' is not a valid popsiql predicate"

#auto_export:none_
module.exports = {sify, getEntity, validate, validateWhere}