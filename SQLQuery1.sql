-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
ORDER BY 1,2

-- Afghanistan
-- 1st death noted on 3/24/2020, death ratio 2.5%

SELECT TOP 10 location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
AND location = 'Afghanistan'
ORDER BY date 

-- As of 6/7/2023, death ratio is 3.57%

SELECT TOP 10 location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
AND location = 'Afghanistan'
ORDER BY date desc

-- Filtering for the United States, Total Cases vs Total Deaths
-- 2/29/2020, death ratio is 1.45%, 69 cases and 1 death
-- 6/7/2023, death radio is 1.09%, 103,436,829 total cases and 1,127,152 deaths
-- Shows the likelihood of dying if you contract covid in US

SELECT location, date, total_cases, total_deaths, population, (CAST(total_deaths AS float)/CAST(total_cases AS float))* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
AND location = 'United States'
ORDER BY 2

-- Looking at Total Cases vs Population
-- The data reveals the percentage of the population that has been affected by Covid

SELECT location, date, total_cases, population, (CAST(total_cases AS float)/CAST(population AS float))* 100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE total_deaths IS NOT NULL
AND location = 'United States' 
ORDER BY 2

--  Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(CAST(total_cases AS int)) AS HighestInfectionCount, MAX(CAST(total_cases AS float)/CAST(population AS float))* 100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY  TotalDeathCount DESC

-- LET'S ANALYZE THE GLOBAL BREAKDOWN BY CONTINENT

-- Let's analyze the data by continent and examine the breakdown of COVID

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY  TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(ISNULL(new_deaths,0))/SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE new_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- TOTAL CASES
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(ISNULL(new_deaths,0))/SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE new_cases IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVacs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE

WITH PopVsVac (Continent, Location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVacs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePeopleVaccinated
FROM PopVsVac

-- TEMP TABLE

--DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVacs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVacs vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

-- OPENING VIEW TABLE

SELECT *
FROM PercentPopulationVaccinated