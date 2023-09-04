Select *
From PortfolioProject..CovidDeaths
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4

--Data to be used

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by location, date

--Exploring Total Cases vs Total Deaths in Australia
--Shows the likelihood of dying if you catch COVID
Select location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
WHERE location like '%Australia%'
order by location, date

-- Looking at Total Cases vs Population
-- What percentage of the population caught COVID?
Select location, date, population, total_cases, (total_cases/population)*100 AS ContractionPercentage
From PortfolioProject..CovidDeaths
WHERE location like '%Australia%'
AND continent is not null
order by location, date

-- Countries with Highest Infection Rate/Population
-- Australia ranked #41 at 44.24% as of 9 Aug 23
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS
	ContractionPercentage
From PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY ContractionPercentage desc

-- Countries with the Highest Deaths/Population
-- Australia ranked #44 at 22781 deaths as of 9 Aug 23
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathCount desc

-- Continents with Highest Death Count
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
AND location NOT IN ('High income','Low income','Lower middle income','Upper middle income')
GROUP BY location
ORDER BY TotalDeathCount desc

-- Global Numbers of New Cases and Deaths each day + Percentage
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, NULLIF(SUM(new_deaths),0)/NULLIF(SUM(cast(new_cases as int)),0)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Amount of People Vaccinated in Australia - Rolling count
SELECT d.continent, d.location, d.date, d.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations vac
	ON d.location = vac.location
	AND d.date = vac.date
WHERE d.continent is not null
AND d.location like '%Australia%'
ORDER BY 2,3

-- Use CTE to see Population vs Vaccinated

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVacCount)
AS
(
SELECT d.continent, d.location, d.date, d.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations vac
	ON d.location = vac.location
	AND d.date = vac.date
WHERE d.continent is not null
AND d.location like '%Australia%'
)
SELECT *, (RollingVacCount/population)*100
FROM PopvsVac

-- Use Temp Table to see Population vs Vaccinated
DROP TABLE if exists #PercentPopVac
CREATE TABLE #PercentPopVac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVacCount numeric,
)
INSERT INTO #PercentPopVac
SELECT d.continent, d.location, d.date, d.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations vac
	ON d.location = vac.location
	AND d.date = vac.date
WHERE d.continent is not null
AND d.location like '%Australia%'

SELECT *, (RollingVacCount/population)*100
FROM #PercentPopVac



-- Creating views to store data for visualisations

CREATE VIEW PercentPopVac AS
SELECT d.continent, d.location, d.date, d.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations vac
	ON d.location = vac.location
	AND d.date = vac.date
WHERE d.continent is not null
AND d.location like '%Australia%'

CREATE VIEW AussieVacCount AS
SELECT d.continent, d.location, d.date, d.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingVacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations vac
	ON d.location = vac.location
	AND d.date = vac.date
WHERE d.continent is not null
AND d.location like '%Australia%'

CREATE VIEW AussieContractionPercentage AS
Select location, date, population, total_cases, (total_cases/population)*100 AS ContractionPercentage
From PortfolioProject..CovidDeaths
WHERE location like '%Australia%'
AND continent is not null