many: 'Company'
include: 'Group'
where: {OR: {Company__name: {like: '%ab%'}, Company__id: {like: '%ab%'}}}
order: 'Company.name, Company.id'


Person_Company
PersonID CompanyID Relationship
1					2					'employee'

SELECT "groupId", count("groupId") AS "count" FROM "company" AS "company" GROUP BY "groupId"

select manufacturer, avg(price), max(price), min(price), count(price), sum(price) as tot, count(manufacturer) as test1 from car
group by manufacturer
having sum(price) > 200000 and min(price) > 100000

bigQuery




subselect



Company: {
	groupId, groupId: $count
	$groupBy: [groupId]
}

Cars: {
	id, manufacturer, prizze: {price}
}

Cars: {
	id, manufacturer, price: $sum
}

Cars: {
	id, manufacturer, prizze: {price, $sum}
}

Cars: {
	id, manufacturer, price_$avg: {as: prizze, gt: 100}
}

Cars: {
	id, manufacturer, prizze: {price: $avg}
}

Cars: {
	id, manufacturer, prizze: {price: $avg, gt: }
}

Cars: {
	id, manufacturer, price: $avg
	$having: {$and: [{price: $avg}]}
}

Cars: {
	id, manufacturer, price: $avg
	$having: {$and: [{price_$avg: {gt: 1000}}, ]}
}

Cars: {
	id, manufacturer, price: $avg
}

Car: {
	manufacturer, 
}

select manufacturer, avg(price), max(price), min(price), count(price), sum(price), count(manufacturer) as test1
from car group by manufacturer



model
	Company:
		id: ID.int
		name: Str
		address: Str
		nationality: {oneToOne: 'Country', link: 'Country.id->Country.id'}
		group: {manyToOne: 'Group', link: 'Company.groupId->Group.id'}
		employees: {manyToMany: 'Person', joinTable: 'r_Person_Company',
			link: {CompanyID: 'Contry.id', PersonID: 'Person.id', relationship: 'employment'}}
		bordMembers: {manyToMany: 'Person', joinTable: 'r_Person_Company'}
		$config: {tableName: 'company'}

	Group:
		id: ID.int
		name: Str
		companies: {oneToMany: 'Company'}

	Country:
		id: ID.int
		name: Str

	Person:
		id: ID.int
		name: Str
		employments: [Company]


Company: {
	id, name, address, revenue: {gt: 2000000}
	employees: {id, name, salary: {gt: 10000}}
	$order: [revenue, employees.salary]
}

Company: {
	id, name, address, revenue: {gt: 2000000}
	employees: {id, name, salary: {gt: 10000}}
	$: {order: [revenue, employees.salary]}
}

Company:
	fields: {id, name}
	employee: {id, name}

Company: {
	id, name,
	employees: {id, name}
}

Company: {
	id, name,
	employees: {innerJoin: 'Person'}
}


companies:
	Company: {
		id, name, address, revenue: {gt: 2000000}
		employees: {id, name, salary: {gt: 10000}}
		$order: [revenue, employees.salary]
	}
countries:
	Country: {id, name}


Company: {
	employees: {Person: }
}


many Company,
	id, name, address, revenue: {gt: 2000000}
	employees: {id, name, salary: {gt: 10000}}
	boardMembers: {id, name}
	$order: [revenue, employees.salary]

many Company,
	id, name, address,
	employees: {id, name}


Company:
	fields: {}

Company: {
	id, name, address, revenue: {gt: 200000},
	emp
}

many Company,
	id, name, address, revenue,
	employees: many a,
		id, name

Company1:
	fields id, name, address, revenue: {gt: 2000000}


Company1:
	id, name, address, revenue: {gt: 2000000}
	employees:
		id, name, salary: {gt: 10000}

Company1:
	fields: {id, name, address, revenue: {gt: 2000000}}
	employees:
		fields: {id, name, salary: {gt: 100000}}
		join: {from: 'Person', on: [Person.id, '=', ]}
	bordMembers:
		fields: {id, name}
		join: {from: 'Person'}

	order: [name, Employee.name]

Company: {
	id, name, address, revenue: {gt: 200000},
	employees: {id, name, salary: }
}

# manual, modelbased, auto-name
Company1:
	fields: {id, name, address, revenue: {gt: 2000000}}
	employees: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]

many: Company
	fields: {id, name, address, revenue: {gt: 2000000}}
	Employee: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]

Company1:
	fields: {id, name, address, revenue: {gt: 2000000}}
	join:
		Person:
			as: 'Employee'
			on: {id: id}
			fields: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]


Company1:
	fields: {id, name, address, revenue: {gt: 2000000}}
	join:
		Person:
			as: [Employee, {id:}]
			as: 'Employee'
			on: {id: id}
			fields: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]




# in api, modelbased, auto-name
Company:
	fields: fields
	where: {revenue: {gt: 2000000}}
	Employee:
		fields: fields.Employee
		where: {salary: {gt: 100000}}
	order: [name, Group.name]


Company: $ {fullSearch: false},
	fields: {id, name, address, revenue: {gt: 2000000}}
	Employee: $ {fullSearch: true}, {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]




# manual, modelbased, auto-name
Company:
	fields: {id, name, address, revenue, profit}
	where: {OR: {	revenue: {gt: 20000},
								profit: {gt: 1000}}}
	Employee: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]

# in api, modelbased, auto-name
Company:
	fields: fields
	where: {revenue: {gt: 2000000}}
	Employee:
		fields: fields.Employee
		where: {salary: {gt: 100000}}
	order: [name, Group.name]



# manual, modelbased, obj=1
Company:
	fields: {id: 1, name: 1, address: 1, revenue: {gt: 2000000}}
	Employee: {id, name, salary: {gt: 100000}}
	order: [name, Employee.name]


# manual, modelbased, vanilla
Company:
	fields: ['id', 'name', 'address', revenue: {gt: 2000000}]
	Employee: ['id', 'name', salary: {gt: 100000}]
	order: ['name', 'Employee.name']

# in api, modelbased, vanilla
Company:
	fields: fields
	where: {revenue: {gt: 2000000}}
	Employee:
		fields: fields.Employee
		where: {salary: {gt: 100000}}
	order: ['name', 'Group.name']



# manual, modelbased, string-based
Company:
	fields: 'id, name, address, revenue'
	where: {revenue: {gt: 2000000}}
	Employee:
		fields: 'id, name, salary'
		where: {salary: {gt: 100000}}
	order: 'name, Employee.name'

# in api, modelbased, string-based
Company:
	fields: fields
	where: {revenue: {gt: 2000000}}
	Employee:
		fields: fields.Employee
		where: {salary: {gt: 100000}}
	order: [name, Group.name]





name = 1 # auto-query

# Beach
Group: {
	OP20
	id: 2
	Members: {
		Workouts
		User
	}
}

Group:
	OP20: __
	id: 2
	Members:
		OP20: _
		Workouts: {OP5: ___}
		User: {OP20: _}

Group:
	OP20: __
	id: 2
	Members:
		Workouts: ___
		User: _

Group:
	id: 2
	Members:
		Workouts: ___
		User: _
		avg: $$



# TR

# SLL

User =

	oneUserDetailsView:
		User: {id: id, name, department, phone, isAdmin
			Role: [{type,
				Company: {id, name}
			}]}
	user: (query, self) ->
		users = db.exec query

		if !self.isAdmin
			selfIds = Self.companiesForRole 4, self
			roles = await Q {Role: [{userId: user.id, companyId}]}
			roleIds = doto(roles, pluck('companyId'), uniq)

			if isEmpty intersection(selfIds, roleIds)
				throw new Error('Du har inte rättighet att se användaren')

		roles = await Q {Role: [userId: user.id]}

	UserOne: (query, self) ->
		user = db.exec query

		if !self.isAdmin
			selfIds = Self.companiesForRole 4, self
			roles = await Q {Role: [{userId: user.id, companyId}]}
			roleIds = doto(roles, pluck('companyId'), uniq)

			if isEmpty intersection(selfIds, roleIds)
				throw new Error('Du har inte rättighet att se användaren')

		roles = await Q {Role: [{userId: user.id, Company: {id, name}}]}

		roles = await many 'Role',
			where: {userId: userId}
			fields: query.Role
			include: {Company: {on: 'companyId->id', fields: query.Role.Company}]}

		roles = await many 'Role',
			where: {userId: userId}
			include: ['Company']

		roles = await db.Role {userId: user.Id}, query.Role, 
















query =
	hero: [{
		name: {$gt: 1}
		friends: [{name, age, city}, {$limit: 10, $outer: ['id', 'friendId']}]
		bestFriend: 
	}]




	
const name = id = 1 // auto-query

const listQuery = {
	incident: [{
		id: 123123123,
		number,
		shortDesc,
		state,
		prio,
		prioText,
		location: {name}
		createdBy: {name}
	}]
}

const resolve = {
	incident: (fields, clauses, children) => {
		
	}
}


query =
	get: {agreement: 'a'}
	where:
		a: {agrActNo, custNo, frDt: {gte: from}, frDt: {lte: to}}
	leftJoin: [{ord: 'o'}, {ordNo: 'ordNo'}]
	fields:
		a: ['frDt', 'ordNo', 'R2', 'ProdNo', 'CustNo', 'Desc', 'ToTm', 'FrTm',
				'AgrActNo', 'AgrNo', 'R1', 'TransGr', 'Txt1', 'Txt2', 'NoInvoAb', 'Fin']
		o: ['OrdTp', 'Gr3', 'Gr5']





	fields:
		a: "frDt.ordNo.R2.ProdNo.CustNo.Desc.ToTm.FrTm.AgrActNo.AgrNo.R1.TransGr.
				Txt1.Txt2.NoInvoAb.Fin"
		o: "OrdTp.Gr3.Gr5"
















_ {s: '', p: 'btn full'}

Gör för komponenter vad shortstyle gör för css

_btn 'full mt10', tap: onCommit









txt user.name, 'full', mand: hot
btn 'Avbryt', tap: onCancel
btn 'Spara', tap: onCommit









