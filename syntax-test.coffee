[ːamount, ːsex, ːID_Int_Seq, ːtext, ːid〳COUNT, ːnumConnections, ːh1, ːh3, ːnumCompanies, ːage, ːcount, ːname, ːdate, ːid, ːStr, ːtype] = ['amount', 'sex', 'ID_Int_Seq', 'text', 'id〳COUNT', 'numConnections', 'h1', 'h3', 'numCompanies', 'age', 'count', 'name', 'date', 'id', 'Str', 'type'] #auto_sugar

aggregations:
  Company:
    numEmployees:
      1:
        empty:
          id〳COUNT: 3
      2:
        empty:
          id〳COUNT: 2
    managers:
      1:
        a:
          query: {salary: {lt: 10000}}
          id〳COUNT: 4

aggregations:
  Company:
    numEmployees:
      1: 
        {ref: 1, fields: {id: {value: 3, op: 'count'}}}
      2:
        {ref: 2, fields: {id: {value: 2, op: 'count'}}}
    managers:
      1:
        {ref: 3, fields: {id: {value: 2, op: 'count'}}}
    numRichManagers:
      1:
        {ref: 4, fields: {id: {value: 2, op: 'count'}}}

refs:
  1: 'Company/numEmployees/1'
  2: 'Company/numEmployees/2'

Employee: [
  {query: {companyId: 1, salary: {lt: 10000}}, refs: [1]}
]

Project: [
  [
    {price: {gt: 50000}}
    {roles〳name: 'Lead developer'}}
    {Person: }
  ]
]


Person: _ {name: {ilike: 'el%'}, ːage}
1,2,3,4
Role: _ {personId: {in: [1,2,3,4]}, name: 'Lead developer'},
1,4,6 = 3,5,7
Project: _ {id: {in: [3,5,7]}, price: {gt: 50000}, ːname},
3,5 = 5,7
Company: _ {id: {in: [5,7]}},
5,7
numEmployees〳Employee: _ {companyId: {in: [5,7]}, ːid〳COUNT}
= 9
numManagers〳Employee: _ {companyId: {in: [5,7]}, position: 'Manager'}
= 3
femaleEmployees〳Employee: _ {person〳sex: 'F'}




U Project: {id: 3, price: 40000}
# trigger Project -> 5 = 7 -> trigger Company -> trigger aggr

U Project: {id: 2, price: 60000}
# trigger inget

U Project: {id: 7, price: 60000}
# trigger Project -> 3,5,7 = 5,7,8 -> trigger Company -> trigger aggr

C Employee: {companyId: 5, position: 'Manager', name: 'Elin'}
# trigger numEmployees〳Employee -> = 10
# trigger numManagers〳Employee -> = 4

query = 
	Person: _ {id: {gte: 3, lte: 4}, ːname, ːsex, ːage},
		entries: _ {ːid, ːamount, ːdate, ːtext},
			task: _ {ːname}
			project: _ {ːname}
		roles: _ {name: 'Guest'},
			project: _ {ːid, ːname, ːtype}

query = 
  Person: _ {id: {gte: 3, lte: 4}, ːname, ːsex, ːage},
    entries: _ {ːid, ːamount, ːdate, ːtext},
      task: ːname
      project: _ {ːname}
    roles: _ {name: 'Guest'},
      project: _ {ːid, ːname, ːtype}


# Möjlig lösning men mindre kräver import-plugin
Person {id: {gte: 3, lte: 4}, ːname, ːsex, ːage},
	entries {ːid, ːamount, ːdate, ːtext},
		task {ːname}
		project {ːname}
	roles {name: 'Guest'},
		project {id, name}




ConnectionType:
  id: ːID_Int_Seq
  name: ːStr

  companies: {oneToMany〳: 'ConnectionType.id = Company.connectionTypeId'}
  connections: {oneToMany〳: 'ConnectionType.id = Connection.connectionTypeId'}

  numCompanies: companies: _ {ːid〳COUNT}
  numConnections: connections: _ {ːid〳COUNT}


ConnectionType:
  D: ({id}) ->
    {numCompanies, numConnections} = R ConnectionType1: _ {id, ːnumCompanies, ːnumConnections} 
    if numCompanies != 0 then throw new VErr 'Kan inte ta bort för den används av företag'
    if numConnections != 0 then throw new VErr 'Kan inte ta bort för den används av anslutningar'










comp = ->
  data = Cache.readPE
    cts: ConnectionType: _ {ːid, ːname, ːcount}
    caps: Capacities: _ {ːid, ːname, ːcount}
    sls: ServiceLevel: _ {ːid, ːname, ːcount}

  _ Page, {},
    _ Section, {},
      _ ːh1, {}, 'Anslutningstyp, Kapacitet, Servicenivå'
      _ renderEdit
      _ {s: 'xrb__1'},
        _ renderList, {data: cts, title: 'Anslutningstyp'}
        _ renderList, {data: caps, title: 'Capacitet'}
        _ renderList, {data: sls, title: 'Servicenivå'}

DetailsPanel = ->
  {path2: type, path3, path4: isEdit} = Url() #

  _ Edit.PE, {type, id: path3}, (id, isNew) -> # exponerar o genom context (alternative type och id)
    if isEdit || isNew
      _ {},
        _ Edit.Textbox, {f: ːname} # får o genom context
        _ Link.Button, {url: isNew && '//' || {path4: undefined}}, 'Avbryt'
        _ Button.Flat, {onClick: Cache.commit(type, id)}, 'Spara'
    else
      _ {},
        _ Edit.Label {f: ːname}
        _ Link.Button, {url: '//'}, 'Avbryt'
        _ Button.Flat, onClick: ->
            if await Confirm.show('Är du säker?')
              Cache.deletePE(type, id)
          , 'Avbryt'

renderList = ({data, title}) ->
  _ {s: 'xg1 mr40-last'}, # -last = not last, +last = only last
    _ ːh3, title
    _ List.Line
    fmap data, ({id, name, count}) ->
      _ List.Row, {key: id}
        _ {}, name
        _ {}, "#{count} st"

  # o = Cache.edit {type, id}

        # _ Confirm, {f: (yesNo) ->
        #     if !yesNo then return
        #     await Cache.delete(type, id)
        #     Url.change '//'
        #   }, (onClick) ->
        #   _ Button.Flat, {onClick}, 'Avbryt'

