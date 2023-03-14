SELECT date
FROM CovidProject..VaccinesCovid
--WHERE date >= '2021-01-01'
ORDER BY date ASC

SELECT *
FROM CovidProject..DeathsCovid

-- Percentage of total deaths in the US.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidProject..DeathsCovid
WHERE location LIKE 'United States'
ORDER BY 1,2

-- Showing what percentage of the population got Covid.
SELECT location, date, total_cases, population, (total_cases/population)*100
FROM CovidProject..DeathsCovid
WHERE continent IS NOT null
ORDER BY 1,2

-- Infection rate vs population.
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopInfection
FROM CovidProject..DeathsCovid
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PercentPopInfection DESC

-- Highest Death Count per Pop. 
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..DeathsCovid
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Breaking things down by continent. 
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidProject..DeathsCovid
WHERE continent IS NOT null 
GROUP BY continent 
ORDER BY TotalDeathCount DESC

-- Global numbers.
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject..DeathsCovid
WHERE continent IS NOT null
--GROUP BY date
ORDER BY 1,2

-- Looking at total pop vs vaccinations. 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..DeathsCovid dea
JOIN CovidProject..VaccinesCovid vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

-- A different way to change the data type.
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location)
--FROM CovidProject..DeathsCovid dea
--JOIN CovidProject..VaccinesCovid vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent IS NOT null
--ORDER BY 2,3

--- CTE in order to perform more calculations. 
WITH PopvsVac (continent, location, date, population, new_vacciantions, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..DeathsCovid dea
JOIN CovidProject..VaccinesCovid vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--Temp Table.
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..DeathsCovid dea
JOIN CovidProject..VaccinesCovid vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations.

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..DeathsCovid dea
JOIN CovidProject..VaccinesCovid vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

ALTER TABLE CovidProject.dbo.DeathsCovid
ADD DateConverted Date;

UPDATE CovidProject.dbo.DeathsCovid
SET DateConverted = CONVERT(Date, date)

-- Curious to see some data about 2023 specifically.
SELECT DateConverted, continent, location, total_cases, total_deaths
FROM CovidProject..DeathsCovid
WHERE date >= 01/01/2023
AND continent IS NOT null
AND location IS NOT null
AND total_cases IS NOT null
AND total_deaths IS NOT null
AND continent LIKE 'Europe'
ORDER BY DateConverted

-- Death info based on income. 
SELECT 
	location AS income, 
	SUM(CAST(total_deaths AS int)) AS total_deaths
FROM CovidProject..DeathsCovid
WHERE location LIKE '%income%'
AND total_deaths IS NOT null
GROUP BY location
ORDER BY location