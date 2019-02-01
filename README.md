För JS:
const query = {
	Person: {where: {name: {ilike: 'el%'}}, fields: 'name,id',
		roles: {where: {name: 'Lead developer'},
			project: {where: {price: {gt: 50000}}, fields: 'name,price',
				company: {fields: 'name',
					femaleEmployees: {fields: 'salary'}
				}
			}
		}
	}
}

〳〳

x query 2.0
	x query
	x sql
x create db
x seed
x sql create
x new alter interface
x expose endpoint

on/to
x build result
x ramda
x smarter sql for conditions

fr
x sublime integration

lö
x improve sublime integration

sö

3 dec = starta BEACH!



SUBQUERIES
- Utan beroenden
- Med beroenden

AGGREGATIONS

- vanliga utan beroenden
	count, sum, min, max, avg
	noWomen: {employees: {person〳sex: 'F', ːid〳count}}

- vanliga med beroenden
	count, sum, min, max, avg

- enkla
	noWeeksPassed: ({start, {global: {now}}}) -> df.differenceInWeeks(now, start)

- nya frågor
	workouts: ({userId, group: {start, end}}) ->
		Workout: {userId, date: {gt: start, lt: end}}

- komponerade
	avg: ({noWorkouts, {group: {noWeeksPassed}}}) -> noWorkouts / noWeeksPassed


	lateEntries: ({dueDate}) ->
		{entries: _ {date: {gt: dueDate}}}




# NEXT, MVP!

Group:
	noWeeks: local
	noWeeksPassed: similar state
	isMember: similar state

Member:
	self: similar state
	noWorkouts: this.workouts.count 
	avg: / this.group.noWeeksPassed
	workouts: workouts userId: this.user.id, date > this.group.start



---

(1)me:
	User: _ {id: 1}, 'id name avatar'
		memberships: _ {}, 'id color goal'
			group: _ {}, 'id name'

{type: 'User', query: {id: {eq: 1}}, fields: 'id name avatar'} self.id == 1
{type: 'Membership', query: {userId: 1}, fields: 'id color goal'} 0.id
{type: 'group', query: {id: {in: [1,3,4]}}, fields: 'id name'} [1].groupId


(3)members:
	Member: _ {groupId: 4}, 'id, color, goal, avg, noWorkouts, workouts'
		user: _ {}, 'id, name, avatar'


{type: 'Member', query: {groupId: {eq: 4}}, fields: 'id, color, goal, avg, noWorkouts'} group.id == self.groupIds
{type: 'User', query: {id: {in: [1,3,5,2]}}, fields: 'id, name, avatar'}
{type: 'Workout', query: {userId: {in: [1,3,5,2]}, date: {gt: '10apr', lt: '18nov'}},
fields: 'id, date, activity'} 0.[userId] AND group(4).start, group(4).end

select * from workout w
join r_group_user m on w."user" = m."user"
join "group" g on m."group" = g.id
where w."user" in (1,2,3) and g.id in (select "group" from r_group_user m2 where m2."user" = 1)

1. owner tar bort member
{type: 'Member', op: 'd', id: 11} {id: 11, color: 2, userId: 1, ...}
-> self.groupIds: [2, 3] ta bort 11
2. owner byter namn på grupp
{type: 'Group', op: 'u', id: 1} {id: 1, name: 'Children of Linköping'}


clients:
	c1:
		queries:
			3: 
		self:
			userId: 1
			userIds: [1,3,4,5]
			groupIds: [4,5,11]

entities:
	Member:
		groupId:
			4:
				c1: ['members']
				OR
				c1: [3]
		userId:
			1:
				c1: [1]

	User:
		id:
			1: [c1]
			3: [c1]
			5: [c1]
			2: [c1]

	Workout:
		userId:
			1: [c1]
			3: [c1]
			5: [c1]
			2: [c1]





{op: 'update', type: 'User', id: 3, fields: {avatar: ['a.jpg', 'b.jpg']}}


User/3 avatar





https://cloud.google.com/solutions/real-time-gaming-with-node-js-websocket



























































































# popcorn test
week:
- soft start, en tom vecka, en helt full vecka, mål 1 och mål 7 och current 7 och current över mål
- 2 användare
- 6 användare
- 12 användare (eller maxantal som det finns färger)


- Kolla på projektvyn "Project Progress" i Harvest. Det konceptet kanske skulle funka för någon sorts historik-vy, speciellt bra på desktop

- Den gamla versionen finns på commits from tom	Aug 20, 2017
- Här finns den väldigt gamla versionen: /Users/victor/Dropbox/_backups/workout-buddies/wobu2

# Namnförslag

beachup

# Aktiviteter
FITNESS
- Löpning
- Gym
- Cykel
- Gång
- Gruppträning
- Blandat (vart för komplicerat med svg-filen, avvaktar)
- Simning
- Dans

BOLLSPORTER
- Basket
- Bandy
- Vollyboll
- Fotboll
---
- Rugby
- Cricket

RACKETSPORTER
- Tennis
- Badminton
- Pingpong
- Squash

VINTERSPORTER
- Slalom
- Längd
- Snowboard
- Hockey
- Skridskor

OUTDOORS
- Klättring
- Vandring

ÖVRIGT
- Yoga
- Kampsport
- Golf
- Ridning
- Friidrott
---
- Skateboard

VATTENSPORTER
- Vindsurf
- Segling
- Padding
- Kitesurf
---
- Dykning
- Vågsurf
- Rodd
- Vattenskidor
