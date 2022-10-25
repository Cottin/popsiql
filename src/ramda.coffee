import contains from "ramda/es/contains"; import gt from "ramda/es/gt"; import gte from "ramda/es/gte"; import lt from "ramda/es/lt"; import lte from "ramda/es/lte"; import pick from "ramda/es/pick"; import pluck from "ramda/es/pluck"; import replace from "ramda/es/replace"; import test from "ramda/es/test"; #auto_require: esramda
import {mapO, $} from "ramda-extras" #auto_require: esramda-extras

read = (config, fullSpec, parent=null) ->
	return $ fullSpec, mapO (spec, key) ->
		if spec.multiplicity == 'many'
			res = []
			resById = {}
			Where = {...spec.where}

			if spec.relParentId
				Where[spec.relParentId] = {in: pluck 'id', parent.res}

			for id, o of config.data[spec.entity]
				if whereTest Where, o
					r = pick spec.allFields, o
					res.push r
					resById[r.id] = r

					if spec.relParentId
						parent.resById[r[spec.relParentId]][key] ?= []
						parent.resById[r[spec.relParentId]][key].push r

			if spec.subs
				read config, spec.subs, {res, resById}

			return res
		else
			if !parent then throw new Error 'one-queries at root is not yet implemented'
			if spec.relIdFromParent
				for r in parent.res
					r[key] = pick spec.allFields, config.data[spec.entity][r[spec.relIdFromParent]]



export default ramda = (config) -> (query) ->
	spec = config.parse query
	return read config, spec
	
whereTest = (Where, o) ->
	for k,preds of Where
		for op, v of preds
			switch op
				when 'eq' then if o[k] != v then return false
				when 'neq' then if o[k] == v then return false
				when 'gt' then if o[k] <= v then return false
				when 'gte' then if o[k] < v then return false
				when 'lt' then if o[k] >= v then return false
				when 'lte' then if o[k] > v then return false
				when 'in' then if !contains o[k], v then return false
				when 'like' then if !test new RegExp(replace(/%/g, '.*', v)), o[k] then return false
				when 'ilike' then if !test new RegExp(replace(/%/g, '.*', v), 'i'), o[k] then return false
				when 'notlike' then if test new RegExp(replace(/%/g, '.*', v)), o[k] then return false
				when 'notilike' then if test new RegExp(replace(/%/g, '.*', v), 'i'), o[k] then return false

	return true
