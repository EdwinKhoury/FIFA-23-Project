
--1) Best Position (Number of players that play in each position)

SELECT Best_Position, COUNT (Best_Position) AS COUNT
FROM Fifa23Project..PlayerData
GROUP BY Best_Position
ORDER BY COUNT DESC
--CB is the position with the most players, and CF has the least.


----------------


--2) Nationality (Number of players from each country)

SELECT Nationality, COUNT (Nationality) AS COUNT
FROM Fifa23Project..PlayerData
GROUP BY Nationality
ORDER BY COUNT DESC
--England is the country with the most active players.


----------------


--3) Wages by Club (Wages paid by each team on different time scales)

SELECT Club_Name, CONCAT('€',SUM ([Wage(in Euro)])/(7*24*3600)) AS Total_wages_per_second,
	CONCAT('€',SUM ([Wage(in Euro)])/(7*24*60)) AS Total_wages_per_minute,
	CONCAT('€',SUM ([Wage(in Euro)])/(7*24)) AS Total_wages_per_hour,
	CONCAT('€',SUM ([Wage(in Euro)])/7) AS Total_wages_per_day,
	CONCAT('€', SUM ([Wage(in Euro)])/1000000, ' million') AS Total_wages_per_week, 
	CONCAT('€', (SUM ([Wage(in Euro)])*52)/1000000, ' million') AS Total_wages_per_year
FROM Fifa23Project..PlayerData
GROUP BY Club_Name
ORDER BY Total_wages_per_second DESC;
--Real Madrid CF has the highest total yearly wages with 224 million Euros.


----------------


--4) Club rating (Average rating of the club, their defense, midfield and attack)
SELECT
    Club_Name,
	COUNT (Club_Name) AS num_of_players,
	AVG(Overall) AS Club_Rating,
    AVG(CASE WHEN Best_Position IN ('LB', 'CB', 'RB', 'LWB', 'RWB') THEN Overall ELSE NULL END) AS Defense_Rating,
    AVG(CASE WHEN Best_Position IN ('CDM', 'CAM', 'CM', 'RM', 'LM') THEN Overall ELSE NULL END) AS Midfield_Rating,
    AVG(CASE WHEN Best_Position IN ('LW', 'RW', 'ST', 'CF') THEN Overall ELSE NULL END) AS Forward_Rating
	--,AVG(Potential) AS Club_Pot_Rating,
 --   AVG(CASE WHEN Best_Position IN ('LB', 'CB', 'RB', 'LWB', 'RWB') THEN Potential ELSE NULL END) AS Defense_Rating,
 --   AVG(CASE WHEN Best_Position IN ('CDM', 'CAM', 'CM', 'RM', 'LM') THEN Potential ELSE NULL END) AS Midfield_Rating,
 --   AVG(CASE WHEN Best_Position IN ('LW', 'RW', 'ST', 'CF') THEN Potential ELSE NULL END) AS Forward_Rating
FROM Fifa23Project..PlayerData 
GROUP BY Club_Name
--ORDER BY Club_Pot_Rating DESC;
ORDER BY Club_Rating DESC;
--FC Bayern Munchen has the highest club rating as well as the highest defense, and midfield.
--However, compared to the other top 5 clubs, it has the least number of players, which explains the high rating.


----------------


--5) Average rating per club for top 20 rated players the room for improvement

WITH RankedPlayersClub AS (
	SELECT Club_Name, Overall, Potential,  
		ROW_NUMBER () OVER (PARTITION BY Club_Name ORDER BY overall DESC) AS player_overall_rank,
		ROW_NUMBER () OVER (Partition BY Club_Name ORDER BY potential DESC) AS player_potential_rank
	FROM Fifa23Project..PlayerData
)

SELECT Club_Name, 
		AVG(overall) AS average_overall_rating,
		AVG(potential) AS average_potential_rating,
		((AVG(potential)-AVG(overall)) / AVG(potential)) * 100 AS improvement_percentage

FROM RankedPlayersClub
WHERE player_overall_rank <= 20
	AND player_potential_rank <=20
GROUP BY Club_Name
--ORDER BY improvement_percentage desc
--ORDER BY average_potential_rating desc
ORDER BY average_overall_rating DESC
--Here only the 20 top players are considered when calculating the average rating of the team. So it is higher than the above code.
--Real Madrid FC has the highest average overall rating of 85. In the above code, Real Madrid FC had an average of 76.7 since it was counting 34 players.
--Real Madrid FC also has the highest average potential rating of 87.8, considering their top 20 players.
--FC Nordsjaelland has the highest improvement percentage rate at 16.45%


----------------


--6) Country rating (Average rating of the country, their defense, midfield and attack)
SELECT
    Nationality,
	COUNT (Nationality) AS COUNT,
	AVG(Overall) AS Nation_Rating,
    AVG(CASE WHEN Best_Position IN ('LB', 'CB', 'RB', 'LWB', 'RWB') THEN Overall ELSE NULL END) AS Defence_Rating,
    AVG(CASE WHEN Best_Position IN ('CDM', 'CAM', 'CM', 'RM', 'LM') THEN Overall ELSE NULL END) AS Midfield_Rating,
    AVG(CASE WHEN Best_Position IN ('LW', 'RW', 'ST', 'CF') THEN Overall ELSE NULL END) AS Forward_Rating
		--,AVG(Potential) AS Nation_Pot_Rating,
  --  AVG(CASE WHEN Best_Position IN ('LB', 'CB', 'RB', 'LWB', 'RWB') THEN Potential ELSE NULL END) AS Defense_Rating,
  --  AVG(CASE WHEN Best_Position IN ('CDM', 'CAM', 'CM', 'RM', 'LM') THEN Potential ELSE NULL END) AS Midfield_Rating,
  --  AVG(CASE WHEN Best_Position IN ('LW', 'RW', 'ST', 'CF') THEN Potential ELSE NULL END) AS Forward_Rating
FROM Fifa23Project..PlayerData 
GROUP BY Nationality
--ORDER BY Nation_Pot_Rating DESC;
ORDER BY Nation_Rating DESC;
--Libya has the best nation rating. But this is because the number of players that is very low (3). Brazil completes the top 3 with an average of 71.6
--Good teams such as Spain, England, and France are very low in the ranking since they have a lot of players. England has 1632 players with an average rating of 64
--It does not reflect the ranking of the team. 


----------------


--7) Average rating per country for top 20 rated players and the room for improvement

WITH RankedPlayersCountry AS (
	SELECT Nationality, Overall, Potential,  
		ROW_NUMBER () OVER (PARTITION BY Nationality ORDER BY overall DESC) AS player_overall_rank,
		ROW_NUMBER () OVER (PARTITION BY Nationality ORDER BY potential DESC) AS player_potential_rank
	FROM Fifa23Project..PlayerData
)

SELECT Nationality, 
		AVG(overall) AS average_overall_rating,
		AVG(potential) AS average_potential_rating,
		((AVG(potential)-AVG(overall)) / AVG(potential)) * 100 AS improvement_percentage

FROM RankedPlayersCountry
WHERE player_overall_rank <= 20
	AND player_potential_rank <=20
GROUP BY Nationality
--ORDER BY improvement_percentage DESC
--ORDER BY average_potential_rating DESC
ORDER BY average_overall_rating DESC
--This code reflects much more the ranking of the national team compared to the above one. 
--Considering only the top 20 players in each country, France has the highest average overall rating (87) as well as the highest average potential rating (89.5).
--Singapore is the country that has the highest improvement percentage rate at 23.6%


----------------


--8) Optimal squad formation based on the overall rating 

WITH RankedPlayers AS (
    SELECT Known_As, Overall, Best_Position, Value_in_Euro, Age, ROW_NUMBER() OVER (PARTITION BY Best_Position ORDER BY Overall DESC) AS Overall_rank
    FROM Fifa23Project..PlayerData
    WHERE Best_Position IN ('GK', 'CB', 'LB', 'RB', 'CM', 'CAM', 'RW', 'LW', 'ST')
),
Formation AS (
    SELECT 'GK' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'GK'
    UNION ALL

	SELECT 'LB' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'LB'
    UNION ALL

    SELECT 'CB' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank <= 2 and best_position = 'CB'
    UNION ALL

    SELECT 'RB' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'RB'
    UNION ALL

    SELECT 'CM' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank <= 2 and best_position = 'CM'
    UNION ALL

    SELECT 'CAM' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'CAM'
    UNION ALL

    SELECT 'RW' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'RW'
    UNION ALL

    SELECT 'LW' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'LW'
    UNION ALL

    SELECT 'ST' AS Position, Known_As, Overall, Age, Value_in_Euro
    FROM RankedPlayers
    WHERE Overall_rank = 1 and best_position = 'ST'
)
    SELECT *
	FROM Formation;
--For a 4-3-3 formation, the following players are the best-rated at their respective positions.


----------------


--9) Optimal squad formation based on the potential rating 

WITH RankedPlayersPot AS (
    SELECT Known_As, Potential, Best_Position, Value_in_Euro, Age, ROW_NUMBER() OVER (PARTITION BY Best_Position ORDER BY Potential DESC) AS Potential_rank
    FROM Fifa23Project..PlayerData
    WHERE Best_Position IN ('GK', 'CB', 'LB', 'RB', 'CM', 'CAM', 'RW', 'LW', 'ST')
),
PotFormation AS (
    SELECT 'GK' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'GK'
    UNION ALL

	SELECT 'LB' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'LB'
    UNION ALL

    SELECT 'CB' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank <= 2 and best_position = 'CB'
    UNION ALL

    SELECT 'RB' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'RB'
    UNION ALL

    SELECT 'CM' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank <= 2 and best_position = 'CM'
    UNION ALL

    SELECT 'CAM' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'CAM'
    UNION ALL

    SELECT 'RW' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'RW'
    UNION ALL

    SELECT 'LW' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'LW'
    UNION ALL

    SELECT 'ST' AS Position, Known_As, Potential, Age, Value_in_Euro
    FROM RankedPlayersPot
    WHERE Potential_rank = 1 and best_position = 'ST'
)
    SELECT *
	FROM PotFormation
--For a 4-3-3 formation, the following players have the best potential at their respective positions.


----------------


--10) Compare the present TOTY and the Potential TOTY

SELECT Position , Known_As , Age, Overall, NULL AS Known_As, NULL AS Age, NULL AS Potential
FROM Fifa23Project..TOTY
UNION All

SELECT Position, NULL AS Known_As, Null AS Age, NULL AS Overall, Known_As, Age, Potential
FROM Fifa23Project..Pot_TOTY

SELECT 'Actual_TOTY' AS Team, SUM(value_in_euro) AS Total_Value, AVG(Overall) as avg_Overall, NULL AS avg_Potential, AVG(age) AS avg_Age
FROM Fifa23Project..TOTY
UNION ALL

SELECT 'Potential_TOTY' AS Team, SUM(value_in_euro) AS Total_Value, NULL as avg_Overall, AVG(Potential) AS avg_Potential, AVG(age) AS avg_Age
FROM Fifa23Project..Pot_TOTY
--The actual team of the year is less expensive (€948 million) than the potential team of the year (€ 1.196 billion)
--However, with a higher average rating (91.1) than the actual team (89.2), and a lower average age (24.3 years) than the actual team (30.5 years) it is maybe worth the investment


----------------


--11) Correlation between position played and potential rating

SELECT Known_As,Positions_Played, Best_Position, Overall, Potential, Age,
    CASE
        WHEN CHARINDEX(',', Positions_Played) = 0 -- Single position
            THEN
                CASE
                    WHEN Positions_Played = Best_Position AND Overall = Potential
                        THEN 'The player has reached his potential in the perfect conditions'
                    WHEN Positions_Played = Best_Position AND Overall <> Potential
                        THEN
                            CASE
                                WHEN Age <= 27 THEN 'Player likely to reach potential'
                                ELSE 'The player is unlikely to reach his potential'
                            END
                    WHEN Positions_Played <> Best_Position AND Overall = Potential
                        THEN 'The player has reached his potential'
                    ELSE 'With a change of position, the player might reach his potential'
                END
        ELSE -- Multiple positions
            CASE
                WHEN CHARINDEX(Best_Position, Positions_Played) > 0 AND Overall = Potential
                    THEN 'The player has reached his potential in the perfect conditions'
                WHEN CHARINDEX(Best_Position, Positions_Played) > 0 AND Overall <> Potential
                    THEN
                        CASE
                            WHEN Age <= 27 THEN 'The player is likely to reach his potential'
                            ELSE 'The player is unlikely to reach his potential'
                        END
                WHEN CHARINDEX(Best_Position, Positions_Played) = 0 AND Overall = Potential
                    THEN 'The player has reached his potential'
                ELSE 'With a change of position, the player might reach his potential'
            END
    END AS Outcome
FROM Fifa23Project..PlayerData
--For every player, there is an outcome that analyses their career.
--For most of the young players (27 years or less), they did not reach their potential: this might be due to the lack of experience.
--Some players do not reach their potential because they are playing in a position that is not their best. Potential might be reached if he changes his playing position.
--Some players are playing at their ideal position and are older than 27. Usually, those players are unlikely to reach their potential. 

