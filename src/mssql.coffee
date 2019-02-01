

# :: o -> o
# Takes a popsiql query and returns a sql query string.
# Optionally you can pass mappings to table and column names.
toMSSQL = (query, mappings) ->
	return null



# User
# 	id: 1
# 	name: 'Elin Essner'
# 	age: 31
# 	$initials: 'EE'

# Project
# 	id: 1
# 	name: 'Cerdics bachelor party'
# 	dueDate: '2018-06-01'

# User_Project
# 	id: 1
# 	userId: 1
# 	projectId: 1
# 	role: 'Project leader'

# 	id: 2
# 	userId: 1
# 	projectId: 1
# 	role: 'Backup stripper'

# Roles = [1, 2, 3, 4]


{many: 'Person', where: {name: {like: '%g%'}}, sort: 'age'}

{many: 'Person', fields: ['id', 'name', '$initials'],
with: {Project: {fields: ['name']}},
}


{Person: 
	hasOne: 'Address'
	hasMany: 'Email'
	belongsTo: 'Account'
	belongsToMany: '...'
	manyToMany: ['Post', 'User_Post']
	transforms: {
		$initials: (x) -> ...
	}
}
