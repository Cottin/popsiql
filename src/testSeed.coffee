module.exports =
	Company:
		1: {id: 1, name: 'Vandelay Industries', turnover: 1000000}
		2: {id: 2, name: 'Pendent Publishing', turnover: 7500000}
		3: {id: 3, name: 'Globex Corporation', turnover: 55000000}
		4: {id: 4, name: 'Initech', turnover: 500000000}
		5: {id: 5, name: 'Gekko & Co', turnover: 999000000}
		6: {id: 6, name: 'Acme Corporation', turnover: 820000000}

	Person:
		1: {id: 1, name: 'Gordon Gekko', age: 42, sex: 'M'}
		2: {id: 2, name: 'George Costanza', age: 36, sex: 'M'}
		3: {id: 3, name: 'Elaine Benes', age: 34, sex: 'F'}
		4: {id: 4, name: 'H.E. Pennypacker', age: 52, sex: 'M'}
		5: {id: 5, name: 'Kel Vernsen', age: 42, sex: 'M'}
		6: {id: 6, name: 'Bud Fox', age: 30, sex: 'M'}
		7: {id: 7, name: 'Hank Scorpio', age: 62, sex: 'M'}
		8: {id: 8, name: 'Homer Simpson', age: 43, sex: 'M'}
		9: {id: 9, name: 'Samir Nagheenanajar', age: 32, sex: 'M'}
		10: {id: 10, name: 'Michael Bolton', age: 32, sex: 'M'}
		11: {id: 11, name: 'Milton Waddams', age: 47, sex: 'M'}
		12: {id: 12, name: 'Peter Gibbons', age: 34, sex: 'M'}
		13: {id: 13, name: 'Bill Lumbergh', age: 45, sex: 'M'}
		14: {id: 14, name: 'Bugs Bunny', age: 12, sex: 'M'}
		15: {id: 15, name: 'Daffy Duck', age: 7, sex: 'M'}
		16: {id: 16, name: 'Titi', age: 2, sex: 'F'}
		17: {id: 17, name: 'Taz', age: 16, sex: 'M'}
		18: {id: 18, name: 'Elmer Fudd', age: 34, sex: 'M'}

	Employment:
		1: {id: 1, personId: 1, companyId: 4, salary: 900000000, position: 'Börshaj'}
		2: {id: 2, personId: 2, companyId: 1, salary: 40000, position: 'Salesman'}
		3: {id: 3, personId: 3, companyId: 2, salary: 100000, position: 'Editor and Manager'}
		4: {id: 4, personId: 5, companyId: 1, salary: 100000, position: 'Manager'}
		5: {id: 5, personId: 4, companyId: 1, salary: 123456789, position: 'Manager'}
		6: {id: 6, personId: 6, companyId: 4, salary: 2000000, position: 'Stockbroker'}
		7: {id: 7, personId: 7, companyId: 2, salary: 480000, position: 'Founder'}
		8: {id: 8, personId: 8, companyId: 3, salary: 60000, position: 'Manager of Nudclear Generator (temp)'}
		9: {id: 9, personId: 9, companyId: 4, salary: 35000, position: 'Programmer'}
		10: {id: 10, personId: 10, companyId: 4, salary: 36000, position: 'Programmer'}
		11: {id: 11, personId: 11, companyId: 4, salary: 16000, position: 'Staple lover'}
		12: {id: 12, personId: 12, companyId: 4, salary: 31000, position: 'Programmer'}
		13: {id: 13, personId: 13, companyId: 4, salary: 1800000, position: 'Vice President'}
		14: {id: 14, personId: 14, companyId: 6, salary: 1000, position: 'Carrot eater'}
		15: {id: 15, personId: 15, companyId: 6, salary: 400, position: 'Speach trainer'}
		16: {id: 16, personId: 16, companyId: 6, salary: 550, position: 'Joyspreader'}
		17: {id: 17, personId: 17, companyId: 6, salary: 300, position: 'Bill collection'}
		18: {id: 18, personId: 18, companyId: 6, salary: 23000, position: 'Hunter'}

	Project:
		1:
			id: 1
			name: 'Georges Bachelor Party'
			type: 'Fixed price'
			price: 1000
			dueDate: '1993-04-12'
			companyId: 2
		2:
			id: 2
			name: 'Autumn Rabbit Hunt'
			type: 'Time and Materials'
			dueDate: '2018-10-22'
			companyId: 6
		3:
			id: 3
			name: 'Jerrys Engagement Party'
			type: 'Fixed price'
			price: 500
			dueDate: '1993-05-20'
			companyId: 1

	Role:
		1: {id: 1, name: 'Best man / Project leader', personId: 5, projectId: 1}
		2: {id: 2, name: 'Guest', personId: 3, projectId: 1}
		3: {id: 3, name: 'Main character', personId: 2, projectId: 1}
		4: {id: 4, name: 'Guest', personId: 4, projectId: 1}

		5: {id: 5, name: 'Lead Hunter', personId: 18, projectId: 2}
		6: {id: 6, name: 'Target', personId: 14, projectId: 2}
		7: {id: 7, name: 'Distractor', personId: 15, projectId: 2}
		8: {id: 8, name: 'Spectator', personId: 16, projectId: 2}

		9: {id: 9, name: 'Project leader', personId: 5, projectId: 3}
		10: {id: 10, name: 'Guest', personId: 4, projectId: 3}
		11: {id: 11, name: 'Guest', personId: 3, projectId: 3}

	Task:
		1: {id: 1, name: 'Booking'}
		2: {id: 2, name: 'Planning'}
		3: {id: 3, name: 'Speach writing'}
		4: {id: 4, name: 'Purchase'}

	WorkEntry:
		1: {id: 1, date: '1993-02-03', amount: 2.5, text: 'Planning kidnap',
		personId: 5, taskId: 2, projectId: 1}
		2: {id: 2, date: '1993-02-03', amount: 2.5, text: 'Planning kidnap',
		personId: 3, taskId: 2, projectId: 1}
		3: {id: 3, date: '1993-02-10', amount: 0.5, text: 'Booking of strippers',
		personId: 4, taskId: 1, projectId: 1}
		4: {id: 4, date: '1993-03-01', amount: 4.0, text: 'Speach draft no. 1',
		personId: 5, taskId: 3, projectId: 1}
		5: {id: 5, date: '1993-03-02', amount: 5.0, text: 'Speach draft no. 1',
		personId: 5, taskId: 3, projectId: 1}
		6: {id: 6, date: '1993-03-08', amount: 2.0, text: 'Speach draft no. 2',
		personId: 5, taskId: 3, projectId: 1}
		7: {id: 7, date: '1993-03-08', amount: 1.5, text: 'Speach draft no. 2',
		personId: 5, taskId: 3, projectId: 1}
		8: {id: 8, date: '1993-03-20', amount: 8.0, text: 'Speach draft no. 3',
		personId: 5, taskId: 3, projectId: 1}
		9: {id: 9, date: '1993-03-21', amount: 8.0, text: 'Speach draft no. 4',
		personId: 5, taskId: 3, projectId: 1}
		10: {id: 10, date: '1993-02-10', amount: 1.0, text: 'Buying schnaps',
		personId: 3, taskId: 2, projectId: 1}
		11: {id: 11, date: '1993-02-11', amount: 2.5, text: 'Planning kidnap',
		personId: 3, taskId: 4, projectId: 1}










