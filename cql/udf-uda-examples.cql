CREATE KEYSPACE football with replication =  { 'class' : 'SimpleStrategy', 'replication_factor' : 1};

CREATE TABLE football.games_by_round (
	league_id text,
	season text,
	round int,
	team text,
	against text,
	home boolean,
	goals_for int,
	goals_against int,
	PRIMARY KEY ((league_id, season), round, team));

CREATE TABLE football.games_by_team (
	league_id text,
	season text,
	round int,
	team text,
	against text,
	home boolean,
	goals_for int,
	goals_against int,
	PRIMARY KEY ((league_id, season), team, round));

-- Note Inserts Can be found in football-insert.cql if you want to see example data.

USE football;

-- Simple Funtion to return the margin / difference in scores
CREATE OR REPLACE FUNCTION football.margin (goals_for int, goals_against int)
RETURNS NULL ON NULL INPUT
RETURNS int LANGUAGE java AS '
return Integer.valueOf(Math.abs(goals_for - goals_against));
';

SELECT margin(goals_for, goals_against) FROM games_by_team
WHERE league_id='English Premier League' AND season='2015/16' and team = 'Tottenham Hotspur';

SELECT avg(football.margin(goals_for, goals_against)) FROM football.games_by_team
WHERE league_id='English Premier League' AND season='2015/16' AND team = 'Manchester United';

SELECT avg(football.margin(goals_for, goals_against)) FROM football.games_by_team
WHERE league_id='English Premier League' AND season='2015/16' AND team = 'Newcastle United';

SELECT avg(football.margin(goals_for, goals_against)) FROM football.games_by_team
WHERE league_id='English Premier League' AND season='2015/16';

SELECT max(margin(goals_for, goals_against)) FROM games_by_team
WHERE league_id='English Premier League' AND season='2015/16';

-- Aggreagte that can be used to sum the toal of goals and the group via team
CREATE OR REPLACE FUNCTION group_and_sum_state (state map<text,int>, group text, score int)
CALLED ON NULL INPUT
RETURNS map<text,int>
LANGUAGE java AS '
	state.put(group, score + state.getOrDefault(group, 0));
	return state;
';

CREATE AGGREGATE IF NOT EXISTS group_and_sum (text, int) 
SFUNC group_and_sum_state
STYPE map<text,int> 
INITCOND {};

SELECT group_and_sum (team, goals_for) FROM football.games_by_team
WHERE league_id='English Premier League' AND season='2015/16';

SELECT group_and_sum (team, goals_for) FROM football.games_by_team
WHERE league_id='English Premier League' AND season='2015/16';

-- Aggregate That uses Final Funtion
-- Used to calculate the mode score. Most common score.

CREATE OR REPLACE FUNCTION football.mode_state (state map<ascii,int>, goals_for int, goals_against int)
CALLED ON NULL INPUT RETURNS map<ascii,int> LANGUAGE java AS '	
	String key = new String (goals_for + " - " + goals_against);
	state.put(key, 1 + state.getOrDefault(key, 0));
	return state;
';

CREATE OR REPLACE FUNCTION football.mode_final (state map<ascii,int>)
CALLED ON NULL INPUT RETURNS ascii LANGUAGE JAVA AS '
	String mostCommon = null;
	int max_count = 0;
	for (String key : state.keySet()) {
	int value = state.get(key);
if (value > max_count) { mostCommon = key;max_count = value; }}
	return mostCommon;
';

CREATE AGGREGATE IF NOT EXISTS football.mode (int, int) 
  SFUNC mode_state
  STYPE map<ascii,int>
  FINALFUNC mode_final 
  INITCOND {};

SELECT football.mode(goals_for,goals_against) FROM football.games_by_team WHERE league_id='English Premier League' AND season='2015/16' AND team = 'Leicester City';
SELECT football.mode(goals_for,goals_against) FROM football.games_by_team WHERE league_id='English Premier League' AND season='2015/16';

-- Using Schema Table to get info about aggregates and functions

SELECT function_name FROM system_schema.functions where keyspace = 'football';
SELECT aggregate_name FROM system_schema.aggregates where keyspace_name = 'football';
SELECT body FROM system_schema.functions where keyspace_name = 'football' AND function_name = 'margin';



