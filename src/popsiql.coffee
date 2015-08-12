{eq, gt, gte, lt, lte} = require 'ramda' # auto_require:ramda

# supported predicates
predicates = ['eq', 'neq', 'in', 'notIn', 'lt', 'lte', 'gt', 'gte', 'like']

module.exports = {predicates}
