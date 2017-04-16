{difference, gt, gte, isEmpty, isNil, keys, lt, lte, merge, none, remove, update, where} = require 'ramda' #auto_require:ramda
{ymap} = require 'ramda-extras'

# o -> s   # returns the entity from a popsiql query object
getEntity = ({one, many, create, update, remove, merge}) ->
	return one || many || create || update || remove || merge


# o -> void   # throws an error if query isn't a valid popsiql query
validate = (query) ->
	if isNil getEntity(query)
		throw new Error 'missing valid operation (one, many, create, update, remove, merge)'
	validateWhere query.where

_preds = ['eq', 'neq', 'in', 'nin', 'gt', 'gte', 'lt', 'lte', 'like']

# o -> void   # throws an error if where part isn't valid in popsiql
validateWhere = (where) ->
	if isNil where then return
	ymap where, (preds) ->
		diff = difference keys(preds), _preds
		if !isEmpty diff
			throw new Error "'#{diff[0]}' is not a valid popsiql predicate"

#auto_export:none_
module.exports = {getEntity, validate, validateWhere}