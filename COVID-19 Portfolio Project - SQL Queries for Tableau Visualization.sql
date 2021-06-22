/* SQL Queries for Tableau Visualization */

-- 1. Global_TotalCases_TotalDeaths
SELECT 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths as int)) AS TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
;

-- 2. Countries_PercentPopulationInfected
SELECT location, MAX(total_cases) AS HighestCaseCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestCaseCount DESC
;

-- 3. Global_DeathPercentagePerMonth
SELECT 
	YEAR(date) AS year,
	MONTH(date) AS month, 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths as int)) AS TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY year, month
;

-- 4. Global_PercentPopulationVaccinated
WITH VaccinatedPerPopulation (continent, location, date, population, new_vaccinations_smoothed, CumulativeVaccinations)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations_smoothed,
	SUM(CONVERT(int, cv.new_vaccinations_smoothed)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
	AS CumulativeVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, (CumulativeVaccinations/population)*100 AS PercentVaccinated
FROM VaccinatedPerPopulation
ORDER BY location, date
;

-- COUNTRY-SPECIFIC QUERIES:

-- 5. PH_DeathPercentagePerMonth
SELECT 
	YEAR(date) AS year,
	MONTH(date) AS month, 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths as int)) AS TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Philippines' AND continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY year, month
;

-- 5. PH_PercentPopulationVaccinated
WITH VaccinatedPerPopulation (continent, location, date, population, new_vaccinations_smoothed, CumulativeVaccinations)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations_smoothed,
	SUM(CONVERT(int, cv.new_vaccinations_smoothed)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
	AS CumulativeVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, (CumulativeVaccinations/population)*100 AS PercentVaccinated
FROM VaccinatedPerPopulation
WHERE location = 'Philippines'
ORDER BY location, date
;