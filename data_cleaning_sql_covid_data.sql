/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views
*/


---------------------------------------------	
-- Create a table named covid_deaths --------
---------------------------------------------

CREATE TABLE public.covid_deaths
(
	iso_code character varying(50),	
	continent character varying(50),
	location1 character varying(50),	
	date1 date,	
	population numeric,
	total_cases numeric,
	new_cases numeric,
	new_cases_smoothed numeric,
	total_deaths numeric,
	new_deaths numeric,
	new_deaths_smoothed numeric,
	total_cases_per_million numeric,
	new_cases_per_million numeric,
	new_cases_smoothed_per_million numeric,
	total_deaths_per_million numeric,
	new_deaths_per_million numeric,
	new_deaths_smoothed_per_million numeric,	
	reproduction_rate numeric,
	icu_patients numeric,
	icu_patients_per_million numeric,
	hosp_patients numeric,
	hosp_patients_per_million numeric,	
	weekly_icu_admissions numeric,
	weekly_icu_admissions_per_million numeric,
	weekly_hosp_admissions numeric,
	weekly_hosp_admissions_per_million numeric
)

ALTER TABLE public.covid_deaths
	OWNER TO postgres;
	
	
---------------------------------------------	
-- Create a table named covid_vaccinations---	
---------------------------------------------

CREATE TABLE public.covid_vaccinations
(
	iso_code character varying(50),
	continent character varying(50),
	location1 character varying(50),
	date1 date,
	new_tests numeric,
	total_tests numeric,
	total_tests_per_thousand numeric,
	new_tests_per_thousand numeric,
	new_tests_smoothed numeric,
	new_tests_smoothed_per_thousand numeric,
	positive_rate numeric,
	tests_per_case numeric,
	tests_units character varying(50),
	total_vaccinations numeric,
	people_vaccinated numeric,
	people_fully_vaccinated numeric,
	total_boosters numeric,
	new_vaccinations numeric,
	new_vaccinations_smoothed numeric,
	total_vaccinations_per_hundred numeric,
	people_vaccinated_per_hundred numeric,
	people_fully_vaccinated_per_hundred numeric,
	total_boosters_per_hundred numeric,
	new_vaccinations_smoothed_per_million numeric,
	stringency_index numeric,
	population_density numeric,
	median_age numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita numeric,
	extreme_poverty numeric,
	cardiovasc_death_rate numeric,
	diabetes_prevalence numeric,
	female_smokers numeric,
	male_smokers numeric,
	handwashing_facilities numeric,
	hospital_beds_per_thousand numeric,
	life_expectancy numeric,
	human_development_index numeric,
	excess_mortality_cumulative_absolute numeric,
	excess_mortality_cumulative numeric,
	excess_mortality numeric,
	excess_mortality_cumulative_per_million numeric
)

ALTER TABLE public.covid_vaccinations
	OWNER TO postgres;

------------------------------------------------	
-- Check if the data has populated the table ---	
------------------------------------------------

Select *
From covid_deaths
Where continent is not null 
order by 3,4


---------------------------------------------------
--- Select the main categories in the dataset -----	
---------------------------------------------------

Select Location, date, total_cases, new_cases, total_deaths, population
From covid_deaths
Where continent is not null 
order by location, date


--------------------------------------------------
-- Total Cases vs Total Deaths -------------------
-- Shows case fatality rate in each country ------
--------------------------------------------------

Select Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) as percentage_deaths
From covid_deaths
Where location like '%States%'
order by 1,2

Select Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) as percentage_deaths
From covid_deaths
Where location like '%Germany%'
order by 1,2

Select Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) as percentage_deaths
From covid_deaths
Where location like '%Croatia%'
order by 1,2

----------------------------------------------------------------
-- Total Cases vs Population------------------------------------
-- Shows what percentage of population infected with Covid -----
----------------------------------------------------------------

Select Location, date, Population, total_cases,  ROUND((total_cases/population)* 100, 2) AS percent_population_infected
From covid_deaths
order by 1,2

----------------------------------------------------------------
-- Countries with Highest Infection Rate compared to Population
----------------------------------------------------------------

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid_deaths
--Where location like '%States%'
Group by Location, Population
order by PercentPopulationInfected desc

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid_deaths
--Where location like '%Germany%'
Group by Location, Population
order by PercentPopulationInfected desc

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid_deaths
--Where location like '%Croatia%'
Group by Location, Population
order by PercentPopulationInfected desc

-----------------------------------------------------------------
-- Countries with highest death count per population ------------
-----------------------------------------------------------------

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid_deaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc



----------------------------------------------------------------
-- BREAKING THINGS DOWN BY CONTINENT ---------------------------
----------------------------------------------------------------

---------------------------------------------------------------------
-- Showing contintents with the highest death count per population --
---------------------------------------------------------------------

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid_deaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


----------------------------------------------------------------
-- GLOBAL NUMBERS ----------------------------------------------
----------------------------------------------------------------

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid_deaths
where continent is not null 
--Group By date
order by 1,2


---------------------------------------------------------------------------------
-- Total population vs vaccinations ---------------------------------------------
-- Shows percentage of population that has recieved at least one COVID Vaccine --
---------------------------------------------------------------------------------

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

---------------------------------------------------------------------------
-- Using CTE to perform calculation on Partition By in previous query -----
---------------------------------------------------------------------------

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-------------------------------------------------------------------------------
-- Using Temp Table to perform calculation on Partition By in previous query --
-------------------------------------------------------------------------------

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



----------------------------------------------------------------
-- Creating View to store data for later visualizations --------
----------------------------------------------------------------

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 