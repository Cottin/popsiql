{over, __, always, assocPath, gt, head, keys, last, length, lens, merge, omit, path, remove, split} = R = require 'ramda' #auto_require:ramda
{cc, dropLast} = require 'ramda-extras'

toRamda = (query) ->
	if cc gt(__, 1), length, keys, query
		throw new Error "toRamda only supports one key for the moment,
		your keys: #{keys(query)}"

	k = cc head, keys, query
	innerQuery = query[k]

	if cc gt(__, 1), length, keys, innerQuery
		throw new Error "toRamda only supports one mutation per query key,
		your keys: #{keys(innerQuery)}"

	mutation = cc head, keys, innerQuery
	path_ = split '__', k
	v = innerQuery[mutation]
	f =
		switch mutation
			when '$set'
				pathLens = lens path(path_), assocPath(path_)
				over pathLens, always(v)
			when '$merge'
				pathLens = lens path(path_), assocPath(path_)
				over pathLens, merge(__, v)
			when '$remove'
				if path_.length > 1
					path__ = dropLast 1, path_
					keyToRemove = last path_
					pathLens = lens path(path__), assocPath(path__)
					over pathLens, omit(keyToRemove)
				else
					omit path_
			else throw new Error "toRamda only supports mutations
			(no reads) for the moment and only some mutations"

	return f

module.exports = {toRamda}
