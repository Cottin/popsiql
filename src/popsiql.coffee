import difference from "ramda/es/difference"; import filter from "ramda/es/filter"; import has from "ramda/es/has"; import includes from "ramda/es/includes"; import isEmpty from "ramda/es/isEmpty"; import join from "ramda/es/join"; import keys from "ramda/es/keys"; import map from "ramda/es/map"; import nth from "ramda/es/nth"; import omit from "ramda/es/omit"; import repeat from "ramda/es/repeat"; import replace from "ramda/es/replace"; import reverse from "ramda/es/reverse"; import test from "ramda/es/test"; import toLower from "ramda/es/toLower"; import toPairs from "ramda/es/toPairs"; import type from "ramda/es/type"; #auto_require: esramda
import {mapO, $, sf0} from "ramda-extras" #auto_require: esramda-extras


capitalize = (s) -> s.charAt(0).toUpperCase() + s.slice(1)

fieldRegex = /^[a-zA-Z\d_]+$/
fieldHex = /0x/
validateField = (field) ->
	if !test(fieldRegex, field) || test(fieldHex, field) then throw new Error "invalid field #{field}"

calcCreateOrder = (model) ->
	ks = keys model
	resolved = []

	while true
		for k in ks

			shouldResolve = true
			for key, relDef of model[k]
				if relDef.rel && !includes relDef.entity, resolved
					shouldResolve = false 
					break
			if shouldResolve then resolved.push k

		ks = difference ks, resolved
		if isEmpty ks then break

	return resolved

# Returns a parser based on the supplied model definition
export default popsiql = (modelDef, config = {}) ->
	model = $ modelDef, mapO (spec, k) ->
		$ spec, mapO (entity, key) ->
			ret = {entity}
			if ! test /s$/, key then ret.rel = "#{toLower entity}Id"
			else ret.theirRel = "#{toLower k}Id"
			return ret

	
	extractEntityAndMultiplicity = (key, parentEntity) ->
		entity =
			if parentEntity then model[parentEntity][key].entity
			else $ key, replace(/s$/, ''), capitalize
		multiplicity = if test /s$/, key then 'many' else 'one'
		return {entity, multiplicity}

	parse = (query, safeGuard=null, parentEntity=null) ->
		return $ query, mapO (fieldsAndChildren, key) ->
			if type(fieldsAndChildren) != 'Array' then throw new Error "body not array for #{key}"
			{entity, multiplicity} = extractEntityAndMultiplicity key, parentEntity
			[fieldSpec_, children] = fieldsAndChildren
			{_sort} = fieldSpec_
			fieldSpec = omit ['_sort'], fieldSpec_
			fields = $ fieldSpec, keys
			allFields = [...fields]
			if !includes 'id', allFields then allFields.unshift 'id'

			ret = {key, entity, multiplicity, fields, allFields}

			Where = $ fieldSpec, filter (spec) -> type(spec) == 'Object'
			if !isEmpty Where then ret.where = Where

			if _sort
				ret.sort = $ _sort, map (x) ->
					if type(x) == 'String' then {field: x, direction: 'ASC'}
					else if type(x) == 'Object'
						$ x, toPairs, map(([field, direction]) -> {field, direction}), nth(0)
					else throw new Error '_sort has to be array of strings and objects'

			if parentEntity
				if model[parentEntity][key].theirRel
					# We are many in 1-to-many to our parent
					allFields.push model[parentEntity][key].theirRel
					ret.relParentId = model[parentEntity][key].theirRel

				if model[parentEntity][key].rel
					ret.relIdFromParent = model[parentEntity][key].rel

				# We are 1 in 1-to-many: TODO
				# We are 1 in 1-to-1: TODO
				# We are many in many-to-many: TODO

			for field in allFields
				validateField field


			if children
				ret.subs = {}
				for k, v of children
					if model[entity][k].rel
						# We are many in 1-to-many to our child
						allFields.push model[entity][k].rel

					subRes = parse {[k]: v}, safeGuard, entity
					Object.assign ret.subs, subRes


			if safeGuard then safeGuard query, ret

			return ret

	parse.createOrder = calcCreateOrder model
	parse.deleteOrder = reverse parse.createOrder

	parse.model = model

	return parse


jsonRegEx = new RegExp '"([^"]+)":', 'g' # https://stackoverflow.com/a/11233515/416797
queryToString = (query, indent = 0) ->
	fieldsToStr = (fieldSpec) ->
		mapper = ([k, v]) ->
			if v == 1 then ':' + k
			else "#{k}: #{sf0(v).replace(jsonRegEx, '$1:')}"
		return $ fieldSpec, toPairs, map(mapper), join(', '), (res) -> "{#{res}}"

	mapper = (fieldsAndChildren) ->
		[fieldSpec, children] = fieldsAndChildren
		ret = fieldsToStr fieldSpec
		if children
			ret += ',\n' + queryToString children, indent + 1

		return ret

	toStr = ([k, result]) -> "#{$ indent, repeat('  '), join ''}#{k}: _ #{result}"

	return $ query, map(mapper), toPairs, map(toStr), join '\n'


utils = {queryToString}

popsiql.utils = utils
