import contains from "ramda/es/contains"; import filter from "ramda/es/filter"; import isEmpty from "ramda/es/isEmpty"; import keys from "ramda/es/keys"; import replace from "ramda/es/replace"; import test from "ramda/es/test"; import toLower from "ramda/es/toLower"; import type from "ramda/es/type"; #auto_require: esramda
import {mapO, $} from "ramda-extras" #auto_require: esramda-extras

import ramda from './ramda'
import sql from './sql'


capitalize = (s) -> s.charAt(0).toUpperCase() + s.slice(1)

fieldRegex = /^[a-zA-Z\d_]+$/
fieldHex = /0x/
validateField = (field) ->
	if !test(fieldRegex, field) || test(fieldHex, field) then throw new Error "invalid field #{field}"

export default popsiql = (modelDef, config) ->
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

	parse = (query, parentEntity=null) ->
		return $ query, mapO (fieldsAndChildren, key) ->
			if type(fieldsAndChildren) != 'Array' then throw new Error "body not array for #{key}"
			{entity, multiplicity} = extractEntityAndMultiplicity key, parentEntity
			[fieldSpec, children] = fieldsAndChildren
			fields = $ fieldSpec, keys
			allFields = [...fields]
			if !contains 'id', allFields then allFields.unshift 'id'

			ret = {key, entity, multiplicity, fields, allFields}

			Where = $ fieldSpec, filter (spec) -> type(spec) == 'Object'
			if !isEmpty Where then ret.where = Where

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

					subRes = parse {[k]: v}, entity
					Object.assign ret.subs, subRes

			return ret


	return {model, parse, ramda: ramda({parse, ...config.ramda}), sql: sql({parse, ...config.sql})}
