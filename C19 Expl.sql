/**This dataset was obtained from OurWorldinData.org and contains global information about COVID-19 health information. 

In this project, I pulled data from this dataset and uncover several insights about the impact of COVID-19 across the world.

This dataset contains two tables: CovidDeaths and CovidVaccinations**/

--First making sure that the data was pulled from both tables accurately, ordering by location and date
SELECT *
FROM CovidPortProj..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

SELECT *
FROM CovidPortProj..CovidVaccinations
WHERE continent is NOT NULL
ORDER BY 1,2


--Selecting data being used from CovidDeath Table

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortProj..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

--Examine Total Cases vs. Total Deaths as a percentage (PercentDeaths) by Country & Date
i.e., Shows the estimated likelihood that a person will die from contracting COVID-19 based on the country they live in.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentDeaths
FROM CovidPortProj..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

--Show PercentDeaths in the United States (U.S.) only
Can see that U.S. rates were the highest around May 2020 where PercentDeaths was nearly 6%, but luckily decreases to under 2% by end of 2020.

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS PercentDeaths
FROM CovidPortProj.dbo.CovidDeaths
WHERE location LIKE '%states' 
and continent is NOT NULL
ORDER BY 1,2


--Show PercentCases in U.S. population with Covid (i.e., What percentage of the U.S. population contracted Covid-19?)

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentCases
FROM CovidPortProj..CovidDeaths
WHERE location LIKE '%states'
and continent is NOT NULL
ORDER BY 1,2


--Examining countries with the highest infection rate (HighInfectionCt) relative to the population
Can see that Andora has the highest PercentCases with 17% followed by Montenegro with 15% 

SELECT location, population, MAX(total_cases) as HighInfectionCt, Max((total_cases/population))*100 AS PercentCases
FROM CovidPortProj..CovidDeaths
GROUP BY continent, population 
ORDER BY PercentCases DESC


--Examining countries with the highest death count (TotalDeathCt) relative to population
--Note: total_deaths is a nvarchar in dataset and needs to be cast as integer to perform calculation
--Note: Also Need to add 'where continent is not null' to pull correct data because some continents/locations are referenced incorrectly
-Can see that U.S. has highest death count relative to the population followed by Brazil & Mexico 

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCt
FROM CovidPortProj..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCt DESC


--Examining highest death count (TotalDeathCt) relative to population by *continent*

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCt
FROM CovidPortProj..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCt DESC



/**GATHERING GLOBAL DATA INFORMATION**/

--Examining the total daily number of cases, deaths, and PercentDeath across the entire world

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as PercentDeath
From CovidPortProj..CovidDeaths
where continent is not null 
Group By date
order by 1,2


--Examining the total number of cases, deaths, and PercentDeath across the entire world (across all dates in dataset)
Can see that the global death percentage is about 2% with over 150 million cases and over 3 million deaths

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as PercentDeath
From CovidPortProj..CovidDeaths
where continent is not null 
order by 1,2


******To this point, queries have only included data from the CovidDeaths table. The next section incorporates the CovidVaccinations table******

--Joining tables

Select *
From CovidPortProj..CovidDeaths dth
Join CovidPortProj..CovidVaccinations vac
  On dth.location = vac.location
  and dth.date = vac.date
  

--Examining Total Vaccinations vs. Total Population (What percentage of the world's population is vaccinated?) 
Creates a rolling count of the new vaccinations (RollingPplVax) each day by location
Note: Unable to perform a calculation for a total percentage for because the RollingPplVax variable is a newly created column. Must create a CTE or Temp Table. See below.

Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dth.Location Order by dth.location, dth.Date) as RollingPplVax, (RollingPplVax/population)*100
From CovidPortProj..CovidDeaths dth
Join CovidPortProj..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null 
order by 2,3


--Using a CTE (Common Table Expression) to perform a calculation for total world vaccination percentage on partition by query above.

With WrldVacPct (Continent, Location, Date, Population, new_vaccinations, RollingPplVax)
as
(
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dth.Location Order by dth.location, dth.Date) as RollingPplVax
--, (RollingPplVax/population)*100
From CovidPortProj..CovidDeaths dth
Join CovidPortProj..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null 
)
Select *, (RollingPplVax/Population)*100
From WrldVacPct


--Creating a Temp Table to perform calculation for total world vaccination percentage on partition by query above.

DROP Table if exists #WrldVacPct
Create Table #WrldVacPct
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPplVax numeric
)

Insert into #WrldVacPct
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dth.Location Order by dth.location, dth.Date) as RollingPplVax
--, (RollingPplVax/population)*100
From CovidPortProj..CovidDeaths dth
Join CovidPortProj..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null 

Select *, (RollingPplVax/Population)*100
From #WrldVacPct


--Creating a View to Store for Future Visualizations

Create View WrldVacPct as
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dth.Location Order by dth.location, dth.Date) as RollingPplVax
--, (RollingPplVax/population)*100
From CovidPortProj..CovidDeaths dth
Join CovidPortProj..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null 






