{F, add, project, sum, test, type, where} = R = require 'ramda' # auto_require: ramda
{$, $$} = RE = require 'ramda-extras' # auto_require: ramda-extras
[ːpersonId, ːnumEmployees, ːid〳COUNT, ːStr, ːEmployment, ːid〳sum, ːid, ːprice, ːposition, ːPerson, ːDateTime, ːInt, ːsex, ːDate, ːage〳, ːFloat, ːCompany, ːprojectId, ːtypeAAA, ːsalary〳AVG, ːALL, ːsalary〳MAX, ːtype, ːID_Int_Seq, ːcompanyId, ːsalary〳SUM, ːtext, ːRole, ː〳roles〳project〳company〳id, ːsalary〳MIN, ːturnover, ːname, ːsalary, ːamount, ːID〳COUNT, ːsexX, ː〳id, ːBool, ːProject, ːid〳SUM, ːage, ːdate, ːoneToMany〳, ːmanyToOne] = ['personId', 'numEmployees', 'id〳COUNT', 'Str', 'Employment', 'id〳sum', 'id', 'price', 'position', 'Person', 'DateTime', 'Int', 'sex', 'Date', 'age〳', 'Float', 'Company', 'projectId', 'typeAAA', 'salary〳AVG', 'ALL', 'salary〳MAX', 'type', 'ID_Int_Seq', 'companyId', 'salary〳SUM', 'text', 'Role', '〳roles〳project〳company〳id', 'salary〳MIN', 'turnover', 'name', 'salary', 'amount', 'ID〳COUNT', 'sexX', '〳id', 'Bool', 'Project', 'id〳SUM', 'age', 'date', 'oneToMany〳', 'manyToOne'] #auto_sugar
{eq, deepEq, fdeepEq, throws, fit, ffit} = RE = require 'testhelp' # auto_require: testhelp

{createModel, comp, _expandQuery, _expandWrite, _isSimple, _camelToSnake} = require './query'
model = require './testModel'

sf = (o) -> JSON.stringify o, ((k, v) => if v == undefined then '__UNDEFINED__' else v), 0
sf2 = (o) -> JSON.stringify(o, ((k, v) => if v == undefined then '__UNDEFINED__' else v), 2)

# todo: move to test help?
console.clear()
console.log((new Date).toISOString())
dots = ''
dots += '.' for num in [0..Date.now() % 50]
console.log dots
console.log dots
console.log dots

# _ = (x, ...xs) -> if type(x) == 'Array' then concat x, xs else prepend x, xs
_ = (...xs) -> xs


describe 'query', ->
	describe 'utils', ->
		describe '_camelToSnake', ->
			it 'simple', -> eq 'hello_world', _camelToSnake 'HelloWorld'

		describe '_isSimple', ->
			it 'simple', ->
				query =
					Person: _ {name: {ilike: 'el%'}, ːid, ːposition},
						roles: _ {ːname},
							project: _ {ːid, ːname},
						entries: _ {ːid, ːdate, ːamount}
				eq true, _isSimple query

			it 'multiQuery', ->
				query =
					adults: {Person: _ {age: {gte: 18}}}
					children: {Person: _ {age: {lt: 18}}}
				eq false, _isSimple query

		# describe 'comp', ->
		# 	it 'simple', ->

		describe.only '_expandQuery', ->

			# it.only 'subs correct', ->
			# 	query =
			# 		Person: _ {name: {ilike: 'el%'}, ːage},
			# 			roles: _ {name: 'Lead developer'},
			# 				project: _ {price: {gt: 50000}, ːname},
			# 			entries: _ {date: {gt: '2018-01-01'}, ːamount}
			# 	res = _expandQuery query, model
			# 	fdeepEq res,
			# 		query:
			# 			entity: ːPerson 
			# 			where: {name: {ilike: 'el%'}}
			# 			fields: [ːname, ːage]
			describe 'or and explicit and', ->
				it 'simple', ->
					allowedToEnterBar =
						Person: _ {OR: [{AND: [{age: {gt: 18}}, {sex: 'F'}]}, {age: {gt: 22}}], ːname}

					res = _expandQuery allowedToEnterBar, model
					fdeepEq res,
						query:
							entity: ːPerson
							where: {OR: [{AND: [{age: {gt: 18}}, {sex: {eq: 'F'}}]}, {age: {gt: 22}}]}
							fields: [ːage, ːsex, ːname]
							allFields: [ːage, ːsex, ːname, ːid]
							blockedFields: []
							topLevel: true


			describe 'composed', ->
				# employeesVandaley = Employment: _ {companyId: 1}
				# managers = _ employeesVandaley,
				# 	Employment: _ {position: 'Manager'}
				# richManagers = _ managers,
				# 	Employment: _ {salary: {gt: 100000}}
				employeesVandaley =
					Employment: _ {companyId: 1},
						person: _ {ːage〳},
							entries: undefined

				managers =
					_ employeesVandaley, {position: 'Manager'},
						person: _ {ːname, ːsex}

				richManagers =
					_ managers, {salary: {gt: 100000}}

				veryRichManagers =
					_ richManagers, {salary: {gt: 200000}},
						person: _ {ːname}

				it 'simple', ->
					select =
						_ veryRichManagers, {},
							person: _ {ːname},
								roles: _ {ːname}

					res = _expandQuery select, model
					fdeepEq res.query.where,
						{AND:
							[{AND:
								[
									{AND: [{companyId: {eq: 1}}, {position: {eq: 'Manager'}}] },
									{salary: {gt: 100000}}
								]}
							{salary: {gt: 200000}}
							]}
					fdeepEq res.query.rels.person.blockedFields, ['age']

				it 'blocked fields', ->
					select =
						_ veryRichManagers, {},
							person: _ {ːage}

					throws /is blocked/, -> _expandQuery select, model

				it 'blocked rels', ->
					select =
						_ veryRichManagers, {},
							person: _ {ːname},
								entries: _ {}

					throws /is blocked/, -> _expandQuery select, model

			describe 'aggregations', ->
				it 'invalid op (lowercase)', ->
					query =
						Company: _ {ːname},
							employees: _ {ːid〳sum}

					throws /invalid aggregation/, -> _expandQuery query, model

				it 'mixing', ->
					query =
						Company: _ {ːname},
							employees: _ {ːid〳SUM, ːposition}

					throws /mixing/, -> _expandQuery query, model

				it 'simple', ->
					query =
						Company: _ {ːname},
							employees: _ {ːid〳COUNT, ːsalary〳SUM, ːsalary〳AVG, ːsalary〳MAX, ːsalary〳MIN}

					res = _expandQuery query, model
					eq true, res.query.rels.employees.isAggregation
					deepEq [ːid〳COUNT, ːsalary〳SUM, ːsalary〳AVG, ːsalary〳MAX, ːsalary〳MIN],
						res.query.rels.employees.fields

			it 'full correct', ->
				query =
					Person: _ {name: {ilike: 'el%'}, ːage},
						roles: _ {name: 'Lead developer'},
							project: _ {price: {gt: 50000}, ːname},
								company: _ {ːname},
									managers: _ {ːsalary}
									# numRichManagers: _ {ːsalary}
						entries: _ {date: {gt: '2018-01-01'}, ːamount}
				res = _expandQuery query, model
				fdeepEq res,
					query:
						entity: ːPerson 
						where: {name: {ilike: 'el%'}}
						fields: [ːname, ːage]
						allFields: [ːname, ːage, ːid]
						blockedFields: []
						topLevel: true
						rels:
							roles:
								entity: ːRole 
								where: {name: {eq: 'Lead developer'}}
								parentOn: [ːid, ːpersonId]
								parentMultiplicity: ːoneToMany〳
								fields: [ːname]
								allFields: [ːname, ːprojectId, ːpersonId, ːid]
								blockedFields: []
								rels:
									project:
										entity: ːProject
										where: {price: {gt: 50000}}
										parentOn: [ːprojectId, ːid]
										parentMultiplicity: ːmanyToOne
										fields: [ːprice, ːname]
										allFields: [ːprice, ːname, ːcompanyId, ːid]
										blockedFields: []
										rels:
											company:
												entity: ːCompany
												parentOn: [ːcompanyId, ːid]
												where: {}
												parentMultiplicity: ːmanyToOne
												fields: [ːname]
												allFields: [ːname, ːid]
												blockedFields: []
												subs:
													managers:
														deps:
															fields: [ːid]
														rel:
															{employees: _ {position: 'Manager'}}


															# entity: ːEmployment
															# where:
															# 	AND: [
															# 		{position: {eq: 'M'}}
															# 		{companyId: {in: id}}
															# 	]
															# fields: [ːID〳COUNT]
															# allFields: [ːID〳COUNT]

													# importantEmployees:
													# 	deps:
													# 		fields: [ːturnover]
													# 		subs: [ːnumEmployees]
													# 	fn: ({turnover, numEmployees}) ->
													# 		avgEmpTurnover = turnover / numEmployees
													# 		{employees: _ {salary: {gt: avgEmpTurnover}}}
															
														# fn: ({id}) ->
														# 	entity: ːEmployment
														# 	where:
														# 		AND: [
														# 			{position: {eq: 'M'}}
														# 			{companyId: {in: id}}
														# 		]
														# 	fields: [ːsalary]
														# 	allFields: [ːsalary, ːposition, ːcompanyId, ːid]
							entries:
								entity: 'WorkEntry'
								where: {date: {gt: '2018-01-01'}}
								parentOn: [ːid, ːpersonId]
								parentMultiplicity: ːoneToMany〳
								fields: [ːdate, ːamount]
								allFields: [ːdate, ːamount, ːpersonId, ːid]
								blockedFields: []











													# subs0:
													# 	managers:
													# 		deps:
													# 			fields: [ːid]
													# 		fn: ({id}) ->
													# 			entity: ːEmployment
													# 			where:
													# 				AND: [
													# 					{position: {eq: 'M'}}
													# 					{companyId: {in: id}}
													# 				]
													# 			fields: [ːsalary]
													# 			allFields: [ːsalary, ːposition, ːcompanyId, ːid]
													# 	noRichManagers:
													# 		deps:
													# 			fields: [ːid]
													# 		fn: ({id}) ->
													# 			entity: ːEmployment
													# 			where:
													# 				AND: [
													# 					{salary: {gt: 100000}}
													# 					AND: [
													# 						{position: {eq: 'M'}}
													# 						{companyId: {in: id, res}}
													# 					]
													# 				]
													# 			fields: [ːid〳COUNT]
													# 			allFields: [ːsalary, ːposition, ːcompanyId, ːid]
													# 	noEmployees:
													# 		fn: ({id}) ->
													# 			entity: ːEmployment
													# 			where: {companyId: {in: id}}
													# 			fields: [ːid〳COUNT]
													# 			allFields: [ːcompanyId, ːid]
													# subs1:
													# 	noImportantEmployees:
													# 		fn: ({turnover, noEmployees}) ->




													# 	managers:
													# 		entity: ːEmployment
													# 		where:
													# 			AND: [
													# 				{position: {eq: 'M'}}
													# 				{companyId: {in: ː〳id, res}}
													# 			]
													# 		fields: [ːsalary]
													# 		allFields: [ːsalary, ːposition, ːcompanyId, ːid]
													# 	noRichManagers:
													# 		entity: ːEmployment
													# 		where:
													# 			AND: [
													# 				{salary: {gt: 100000}}
													# 				AND: [
													# 					{position: {eq: 'M'}}
													# 					{companyId: {in: ː〳id, res}}
													# 				]
													# 			]
													# 		fields: [ːid〳COUNT]
													# 		allFields: [ːsalary, ːposition,,ːcompanyId, ːid]


							# entries:
							# 	entity: 'WorkEntry'
							# 	where: {date: {gt: '2018-01-01'}}
							# 	parentOn: [ːid, ːpersonId]
							# 	parentMultiplicity: ːoneToMany〳
							# 	fields: [ːdate, ːamount]
							# 	allFields: [ːdate, ːamount, ːpersonId, ːid]
							# ,
							# 	(res1) ->
							# 		query2:
							# 			entity: ːEmployment
							# 			where: {AND: [
							# 				{position: {eq: 'M'}}
							# 				{companyId: {in: pluckDeep ː〳roles〳project〳company〳id, res}}]}
							# 			fields: [ːsalary]
							# 			allFields: [ːsalary, ːposition, ːid]
							# ]

			it 'no query', ->
				throws /query cannot/, -> _expandQuery null, model

			it 'no model', ->
				query = Person: _ {ːname}
				throws /model cannot/, -> _expandQuery query

			it 'no entity', ->
				query = PersonX: _ {ːname}
				throws /no entity/, -> _expandQuery query, model

			it 'invalid body', ->
				query = Person: {name: 'x'}
				throws /the body/, -> _expandQuery query, model

			it 'missing where clause', ->
				query = Person: []
				throws /fields clause/, -> _expandQuery query, model

			it 'invalid where clause', ->
				query = Person: _ 'name'
				throws /fields clause/, -> _expandQuery query, model

			it 'no explicit fields', ->
				query = Person: _ {name: 1}
				res = _expandQuery query, model
				fdeepEq res,
					query:
						entity: ːPerson
						topLevel: true
						where: {name: {eq: 1}}
						fields: [ːname]
						allFields: [ːname, ːid]
						blockedFields: []


			it 'multiQuery', ->
				query =
					adults: {Person: _ {age: {gte: 18}}}
					children: {Person: _ {age: {lt: 18}}}

				res = _expandQuery query, model
				fdeepEq res,
					adults:
						entity: ːPerson
						topLevel: true
						where: {age: {gte: 18}}
						fields: [ːage]
						allFields: [ːage, ːid]
						blockedFields: []
					children:
						entity: ːPerson 
						topLevel: true
						where: {age: {lt: 18}}
						fields: [ːage]
						allFields: [ːage, ːid]
						blockedFields: []

			it 'simple query with name query', ->
				query =
					query: {Person: _ {sex: 'F'}}

				res = _expandQuery query, model
				fdeepEq res,
					query:
						entity: ːPerson
						topLevel: true
						where: {sex: {eq: 'F'}}
						fields: [ːsex]
						allFields: [ːsex, ːid]
						blockedFields: []

			it 'ALL flag', ->
				query = Person: _ {sex: 'F', ːALL}

				res = _expandQuery query, model
				fdeepEq res,
					query:
						entity: ːPerson
						topLevel: true
						where: {sex: {eq: 'F'}}
						fields: [ːid, ːname, ːsex, ːage]
						allFields: [ːid, ːname, ːsex, ːage]
						blockedFields: []
						allFlag: true

			it 'wrong fields', ->
				query = Person: _ {ːname, ːsexX}
				throws /invalid field/, -> _expandQuery query, model

			it 'wrong field on rela 1', ->
				query = Person: _ {ːname},
									roles: _ {id: 1, ːname},
										project: _ {ːname, ːtypeAAA}
									entries: _ {date: {gt: '2018-11-01'}, ːtext}

				throws /invalid field/, -> _expandQuery query, model

			it 'wrong field on where clause', ->
				query = Person: _ {ːname},
									roles: _ {id: 1, ːname},
										project: _ {nameAAA: 1, ːtype}
									entries: _ {date: {gt: '2018-11-01'}, ːtext}
				throws /invalid field/, -> _expandQuery query, model

			it 'no rela', ->
				query = Person: _ {ːname},
									rolesXXX: _ {ːname}
				throws /no rela/, -> _expandQuery query, model

		describe '_expandWrite', ->
			it 'no multi query', ->
				query = {p1: {CREATE: {Person: _ {name: 'a'}}}, p2: {CREATE: {Person: _ {name: 'a'}}}}
				throws /multi/, -> _expandWrite query, model

			it 'unsupported write', ->
				query = {CREATEAAA: {Person: _ {name: 'a'}}}
				throws /unsupported write/, -> _expandWrite query, model

			it 'no multi query inside', ->
				query = {CREATE: {p1: {Person: _ {name: 'a'}}, p2: {Person: _ {name: 'a'}}}}
				throws /multi/, -> _expandWrite query, model

			it 'no named', ->
				query = {CREATE: {p1: {Person: _ {name: 'a'}}}}
				throws /named/, -> _expandWrite query, model

			it 'no multi level', ->
				query =
					CREATE:
						Person: _ {name: 'test'},
							roles: _ {name: 'test2'}

				throws /multi level/, -> _expandWrite query, model

			it 'no where clause', ->
				query = CREATE: Person: _ {name: 'Elin', age: {gt: 2}}
				throws /no where/, -> _expandWrite query, model

			it 'simple', ->
				query = CREATE: Person: _ {name: 'Elin', age: 2}

				res = _expandWrite query, model
				fdeepEq res,
					query:
						entity: ːPerson
						type: 'create'
						topLevel: true
						fields: [ːname, ːage]
						allFields: [ːname, ːage, ːid]
						values: {name: 'Elin', age: 2}


	# NOTE: if testModel throws before you can run createModel tests below,
	# add a -> before createModel in testModel and use .only below
	describe 'createModel', ->
		console.log 'NOTE: add a -> before createModel in testModel and use .only below'
		it 'unknown field type', ->
			throws /unknown field type/, -> createModel {User: {id: Int8Array}}

		it 'field types', ->
			res = createModel {User: {id: ːID_Int_Seq, name: ːStr, gpa: ːFloat, single: ːBool,
			dob: ːDateTime, favouriteHoliday: ːDate}}

			fit {User: {id: ːID_Int_Seq, name: ːStr, gpa: ːFloat, single: ːBool,
			dob: ːDateTime, favouriteHoliday: ːDate}}, res

		it 'invalid', ->
			throws /invalid rela/, -> createModel {User: {id: {manyToMany: 1}}}

		it 'lower', ->
			throws /must begin with upper/, -> createModel {user: {id: ːInt}}

		it 'invalid relation', ->
			throws /invalid rela/, -> createModel {User: {id: {oneToMany: 1}}}

		it 'invalid link 1', ->
			model = User: {id: ːStr, bff: {oneToOne: 'UserX.bff = User.what'}}
			throws /invalid link/, -> createModel model

		it 'invalid link 2', ->
			model = User: {id: ːStr, bff: {oneToOne: 'UserX.bff = User.what'}}
			throws /invalid link/, -> createModel model

		it 'invalid link 3', ->
			model =
				User: {id: ːStr, favoriteCourse: {oneToOne: 'Course.id = User.courseId'}}
				Course: {id: ːStr}
			throws /first entity/, -> createModel model

		it 'invalid link 4', ->
			model = User: {id: ːStr, bff: {oneToOne: 'User.bff = User.what'}}
			throws /same name as rela/, -> createModel model

		it 'linking fields 1', ->
			model = User: {id: ːStr, bff: {oneToOne: 'User.bffId = User.id'}}
			res = createModel model
			eq res.User.bffId, ːStr
			deepEq {multiplicity: 'oneToOne', entity: 'User', on: ['bffId', 'id']}, res.User.$rels.bff

		it 'linking fields 2', ->
			model =
				User: {id: ːStr}
				Course: {id: ːStr, usersFavorite: {manyToOne: 'Course.id = User.courseId'}}
			res = createModel model
			eq res.User.courseId, ːStr

		it 'linking fields big', ->
			model =
				User:
					id: ːID_Int_Seq
					name: ːStr
					favoriteCourse: {oneToOne: 'User.favoriteCourseId = Course.id'}
					didFail: {oneToMany: 'User.id = FailedCourse.userId'}
					bff: {oneToOne: 'User.bffId = User.id'}

				FailedCourse:
					id: ːID_Int_Seq
					userId: ːInt
					courseId: ːInt
					attempts: ːInt

				Course:
					id: ːID_Int_Seq
					name: ːStr
					teacher: {oneToOne: 'Course.teacherId = User.id'}


			res = createModel model
			ffit res.User,
				$rels:
					favoriteCourse: {entity: 'Course'}
					didFail: {entity: 'FailedCourse'}
					bff: {entity: 'User'}
				bffId: ːInt


		it 'linking fields 3', ->
			model = User: {id: ːID_Int_Seq, bff: {oneToOne: 'User.bffId = User.id'}}
			res = createModel model
			eq res.User.bffId, ːInt

		describe 'subqueries', ->
			it 'invalid subquery', ->
				model =
					Company:
						id: ːID_Int_Seq
						employees: {oneToMany〳: 'Company.id = Employment.companyId'}
						femaleEmployees: {employees: _ {positXion: 'F'}}

					Employment:
						id: ːID_Int_Seq
						company: {manyToOne: 'Employment.companyId = Company.id'}

				throws /for subquery/, -> createModel model

			it 'simple', ->
				model =
					Company:
						id: ːID_Int_Seq
						name: ːStr

						employees: {oneToMany〳: 'Company.id = Employment.companyId'}
						femaleEmployees: {employees: _ {position: 'F'}}
						femaleEmployeesWithHighSalary: {femaleEmployees: _ {salary: {gt: 100000}}}
						noFemaleEmployees: {employees: _ {ːid〳COUNT}}

					Employment:
						id: ːID_Int_Seq
						person: {oneToOne: 'Employment.personId = Person.id'}
						company: {manyToOne: 'Employment.companyId = Company.id'}
						position: ːStr
						salary: ːInt

					Person:
						id: ːID_Int_Seq
						name: ːStr
						sex: ːStr


				console.log '1231231231'
				res = createModel model
				console.log '---res\n', sf2 res
				deepEq {employees: _ {position: 'F'}}, res.Company.$subs.femaleEmployees








