import ascend from "ramda/es/ascend"; import both from "ramda/es/both"; import descend from "ramda/es/descend"; import equals from "ramda/es/equals"; import gt from "ramda/es/gt"; import gte from "ramda/es/gte"; import head from "ramda/es/head"; import includes from "ramda/es/includes"; import keys from "ramda/es/keys"; import length from "ramda/es/length"; import lt from "ramda/es/lt"; import lte from "ramda/es/lte"; import map from "ramda/es/map"; import pick from "ramda/es/pick"; import pluck from "ramda/es/pluck"; import prop from "ramda/es/prop"; import replace from "ramda/es/replace"; import sort from "ramda/es/sort"; import sortWith from "ramda/es/sortWith"; import test from "ramda/es/test"; import values from "ramda/es/values"; #auto_require: esramda
import {mapO, $} from "ramda-extras" #auto_require: esramda-extras


export default ramda = (parse, config) ->

	read = (options, fullSpec, parent=null) ->
		# console.log 'fullSpec', fullSpec
		# console.log 'parent', parent
		norm = if !parent then {} else parent.norm
		fullRes = $ fullSpec, mapO (spec, key) ->
			if spec.relIdFromParent
				# console.log 'a1_1' 
				# console.log 'parent.res', parent.res
				for r in parent.res
					# console.log 'a1_2' 
					# console.log 'spec', spec
					# console.log 'r', r 
					# console.log config.getData()[spec.entity]
					# console.log r[spec.relIdFromParent]
					# console.log config.getData()[spec.entity][r[spec.relIdFromParent]]
					fullData = config.getData()[spec.entity][r[spec.relIdFromParent]]
					if !fullData then r[key] = null
					else r[key] = pick spec.allFields, fullData
					# console.log 'fullData', fullData
					# console.log 'r[key]', r[key]
					# try
					# 	r[key] = pick spec.allFields, config.getData()[spec.entity][r[spec.relIdFromParent]]
					# catch err
					# 	console.error err 
					# console.log r[key]


				# TOGO: Premature exiting. Add data that has both spec.relIdFromParent and spec.subs


				# console.log 'return 1'
				# return

			# console.log 'a1_3' 
			resById = {}
			Where = {...spec.where}

			# console.log 'a2' 
			if spec.relParentId
				Where[spec.relParentId] = {in: pluck 'id', parent.res}

			res_ = []
			for id, o of config.getData()[spec.entity]
				if whereTest Where, o
					r = pick spec.allFields, o
					res_.push r
					resById[r.id] = r
					# console.log 'a3' 

					if options.result == :both
						norm[spec.entity] ?= {}
						if norm[spec.entity][r.id]
							norm[spec.entity][r.id] = {...norm[spec.entity][r.id], ...r}
						else norm[spec.entity][r.id] = {...r}

					if spec.subs
						for ___, sub of spec.subs
							if sub.multiplicity == 'many' then r[sub.key] = []
							else r[sub.key] = null

					if spec.relParentId
						parent.resById[r[spec.relParentId]][key].push r

			# console.log 'a4' 
			res = if spec.sort then sortWith sorter(spec.sort), res_ else res_

			if spec.subs
				read options, spec.subs, {res, resById, norm}
			# console.log 'a5' 

			if spec.multiplicity == 'one' && length(res) == 1
				# console.log 'return 2';
				return res[0]
			else
				# console.log 'return 3';
				return res

		return if !parent && options.result == :both then [fullRes, norm] else fullRes

	fn = (query, options = {}) ->
		spec = parse query
		try	
			res = read options, spec
		catch err
			throw err # for some reason error are swallowed in the read code, but re-throwing them here seems to work

		if options.result == 'both'
			[denorm, norm] = res
			return if $ spec, keys, length, equals 1 then [$(denorm, values, head), norm] else [denorm, norm]
		else
			return if $ spec, keys, length, equals 1 then $ res, values, head else res

	return fn
	
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
				when 'in' then if !includes o[k], v then return false
				when 'like' then if !test new RegExp(replace(/%/g, '.*', v)), o[k] then return false
				when 'ilike' then if !test new RegExp(replace(/%/g, '.*', v), 'i'), o[k] then return false
				when 'notlike' then if test new RegExp(replace(/%/g, '.*', v)), o[k] then return false
				when 'notilike' then if test new RegExp(replace(/%/g, '.*', v), 'i'), o[k] then return false

	return true

sorter = (sortSpec) ->
	$ sortSpec, map ({field, direction}) ->
		if direction == 'DESC' then descend prop field
		else if direction == 'ASC' then ascend prop field
		else throw new Error "invalid direction given for sort #{direction} (should be ASC or DESC)"

