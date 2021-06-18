/* Exploratory Data Analysis on COVID-19 World Data
   Using Microsoft SQL Server 2019 Practice      */

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4
;

-- Select data to be used for the exploratory data analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
;

-- Calculate daily percentage of death in the Philippines
-- Likelihood to die from COVID-19
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location = 'Philippines'
ORDER BY location, date
;

-- Calculate percentage of cases per population in the Philippines
-- Shows how much of the population contracted COVID-19
SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM CovidDeaths
WHERE location = 'Philippines'
ORDER BY location, date
;

-- Total cases and deaths and death percentage per month per year in the Philippines
SELECT 
	YEAR(date) AS year,
	MONTH(date) AS month, 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths as int)) AS TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Philippines' AND continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY YEAR(date), MONTH(date)
;

-- Identify countries with the highest percentage of population infected
SELECT location, MAX(total_cases) AS HighestCaseCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
;

-- Identify countries with the highest death count/rate
SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount, population, MAX((cast(total_deaths as int)/population))*100 AS DeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC
;


/* BY CONTINENT */

-- Identify continent with the highest death count/rate
SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount, population, MAX(cast(total_deaths as int)/population)*100 AS DeathRate
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC
;

-- Highest death counts for each country in each continent
SELECT continent, location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY continent, HighestDeathCount DESC, location
;


/* GLOBAL NUMBERS */

-- Total cases and deaths and death percentage per month per year
SELECT 
	YEAR(date) AS year,
	MONTH(date) AS month, 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths as int)) AS TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY YEAR(date), MONTH(date)
ORDER BY YEAR(date), MONTH(date)
;


/* COVID-19 VACCINATIONS TABLE */

-- Check data in the CovidVaccinations table
SELECT *
FROM CovidVaccinations
ORDER BY location, date
;

-- Join CovidDeaths and CovidVaccinations table
SELECT *
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
;

-- Daily number of people vaccinated vs population in the Philippines
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, cv.total_vaccinations, 
	(cv.total_vaccinations/cd.population)*100 AS PercentVaccinated
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL and cd.location = 'Philippines'
ORDER BY cd.location, cd.date
;

-- Calculate total vaccinations from new vaccinations column using OVER and PARTITION BY
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(int, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
	AS CumulativeVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date
;


/* CALCULATE CUMULATIVE VACCINATIONS USING CTE AND TEMP TABLE */

-- Use CTE
WITH VaccinatedPerPopulation (continent, location, date, population, new_vaccinations, CumulativeVaccinations)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(int, cv.new_vaccinations)) 
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

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	population numeric, 
	new_vaccinations numeric, 
	CumulativeVaccinations numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(int, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
	AS CumulativeVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (CumulativeVaccinations/population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated
WHERE location = 'Philippines'
ORDER BY location, date
;


/* CREATING VIEWS FOR VISUALIZATION USE: */

-- Identify countries with the highest percentage of population infected
CREATE VIEW Countries_PercentPopulationInfected AS
	SELECT location, MAX(total_cases) AS HighestCaseCount, population, MAX((total_cases/population))*100 AS PercentPopulationInfected
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location, population

-- Global total cases and deaths and death percentage per month per year
CREATE VIEW Global_DeathPercentagePerMonth AS
	SELECT 
		YEAR(date) AS year,
		MONTH(date) AS month, 
		SUM(new_cases) AS TotalCases, 
		SUM(cast(new_deaths as int)) AS TotalDeaths,
		(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY YEAR(date), MONTH(date)

-- Total cases and deaths and death percentage per month per year in the Philippines
CREATE VIEW PH_DeathPercentagePerMonth AS
	SELECT 
		YEAR(date) AS year,
		MONTH(date) AS month, 
		SUM(new_cases) AS TotalCases, 
		SUM(cast(new_deaths as int)) AS TotalDeaths,
		(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
	FROM CovidDeaths
	WHERE location = 'Philippines' AND continent IS NOT NULL
	GROUP BY YEAR(date), MONTH(date)

-- Identify continent with the highest death count/rate
CREATE VIEW Continent_HighestDeathCount AS
	SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathCount, population, MAX(cast(total_deaths as int)/population)*100 AS DeathRate
	FROM CovidDeaths
	WHERE continent IS NULL
	GROUP BY location, population
	
-- Calculate Cumulative Vaccinations and Percent Vaccinated in the Philippines
CREATE VIEW PercentPopulationVaccinated AS
	WITH VaccinatedPerPopulation (continent, location, date, population, new_vaccinations, CumulativeVaccinations)
	AS (
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(int, cv.new_vaccinations)) 
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
