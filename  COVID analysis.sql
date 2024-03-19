-- Covid 19 Data Exploration 
-- Techniques employed: database joins, CTEs, temporary storage, window functions, data aggregation, view generation, and datatype manipulation.

-- Selecting initial dataset for analysis
-- Using parameters for flexibility and error handling
DECLARE @ContinentFilter NVARCHAR(255) = '%%';

SELECT 
    Location, 
    Date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE @ContinentFilter
ORDER BY Location, Date;

-- Calculating death percentage using a CTE
WITH DeathRates AS (
    SELECT 
        Location, 
        Date, 
        total_cases,
        total_deaths,
        (total_deaths * 100.0 / total_cases) AS DeathPercentage
    FROM PortfolioProject..CovidDeaths
    WHERE continent LIKE @ContinentFilter
)

-- Comparing Total Cases with Total Deaths to assess fatality rate
SELECT 
    Location, 
    Date, 
    total_cases,
    total_deaths,
    DeathPercentage
FROM DeathRates
WHERE Location LIKE '%states%'
ORDER BY Location, Date;

-- Analyzing Total Cases relative to Population to determine infection rates
SELECT 
    Location, 
    Date, 
    Population, 
    total_cases,  
    (total_cases * 100.0 / population) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE @ContinentFilter
ORDER BY Location, Date;

-- Identifying countries with the highest infection rates compared to their populations
SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX(total_cases * 100.0 / population) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Identifying countries with the highest death counts per capita
SELECT 
    Location, 
    MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE @ContinentFilter
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Analysis segmented by Continent to assess regional trends
-- Showing continents with the highest death count per population
SELECT 
    continent, 
    MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE @ContinentFilter
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL STATISTICS: Summarizing global COVID-19 cases and deaths
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(cast(new_deaths as int)) AS total_deaths, 
    SUM(cast(new_deaths as int)) * 100.0 / SUM(New_Cases) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE @ContinentFilter;

-- Using CTE to calculate vaccination rates per population
WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent LIKE @ContinentFilter
)
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- Constructing a View to retain data for future visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent LIKE @ContinentFilter;

-- Time-Series Analysis: Visualizing trends in COVID-19 metrics over time
-- Let's plot the total cases, total deaths, and total vaccinations over time for a selected location
DECLARE @SelectedLocation NVARCHAR(255) = 'South Africa'; -- Change this to the desired location

SELECT 
    Date,
    SUM(total_cases) OVER (ORDER BY Date) AS CumulativeCases,
    SUM(total_deaths) OVER (ORDER BY Date) AS CumulativeDeaths,
    SUM(new_vaccinations) OVER (ORDER BY Date) AS CumulativeVaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.Location = @SelectedLocation;
