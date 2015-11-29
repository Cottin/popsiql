{eq, gt, gte, lt, lte, max} = require 'ramda' # auto_require:ramda

# supported predicates
predicates = ['eq', 'neq', 'in', 'notIn', 'lt', 'lte', 'gt', 'gte', 'like']

parameters = ['start', 'max']


module.exports = {predicates, parameters}
