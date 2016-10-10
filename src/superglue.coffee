{__, always, apply, gt, head, keys, length, merge, path, remove, split} = R = require 'ramda' #auto_require:ramda
{cc} = require 'ramda-extras'

toSuperGlue = (query) ->
	if cc gt(__, 1), length, keys, query
		throw new Error "toSuperGlue only supports one key for the moment,
		your keys: #{keys(query)}"

	k = cc head, keys, query
	innerQuery = query[k]

	if cc gt(__, 1), length, keys, innerQuery
		throw new Error "toSuperGlue only supports one mutation per query key,
		your keys: #{keys(innerQuery)}"

	mutation = cc head, keys, innerQuery
	v = innerQuery[mutation]
	f =
		switch mutation
			when '$set' then always v
			when '$merge' then merge __, v
			when '$remove' then always null
			when '$apply' then v
			else throw new Error "toSuperGlue only supports mutations
			(no reads) for the moment and only some mutations"

	return {path: split('__', k), f}

module.exports = {toSuperGlue}
