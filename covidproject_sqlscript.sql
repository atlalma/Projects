CREATE TABLE CovidDeaths (
	iso_code varchar(10),
	continent varchar(40),
	country varchar (40),
	date_recorded date,
	total_cases double precision,
	new_cases double precision,
	new_cases_smoothed double precision,
	total_deaths double precision,
	new_deaths double precision,
	new_deaths_smoothed double precision,
	total_cases_per_million double precision,
	new_cases_per_million double precision,
	new_cases_smoothed_per_million double precision,
	total_deaths_per_million double precision,
	new_deaths_per_million double precision,
	new_deaths_smoothed_per_million double precision,
	reproduction_rate double precision,
	icu_patients double precision,
	icu_patients_per_million double precision,
	hosp_patients double precision,
	hosp_patients_per_million double precision,
	weekly_icu_admissions double precision,
	weekly_icu_admissions_per_million double precision,
	weekly_hosp_admissions double precision,
	weekly_hosp_admissions_per_million double precision,
	new_tests double precision);
	
	SELECT * FROM CovidDeaths;
	
	CREATE TABLE CovidVaccinations (
		iso_code varchar(10),
		continent varchar(40),
		country varchar(40),
		date_recorded date,
		new_tests int,
		total_tests int,
		total_tests_per_thousand double precision,
		new_tests_per_thousand double precision,
		new_tests_smoothed double precision,
		new_tests_smoothed_per_thousand double precision,
		positive_rate double precision,
		tests_per_case double precision,
		tests_units varchar (40),
		total_vaccinations double precision,
		people_vaccinated double precision,
		people_fully_vaccinated double precision,
		new_vaccinations double precision,
		new_vaccinations_smoothed double precision,
		total_vaccinations_per_hundred double precision,
		people_vaccinated_per_hundred double precision,
		people_fully_vaccinated_per_hundred double precision,
		new_vaccinations_smoothed_per_million double precision,
		stringency_index numeric,
		population_density numeric,
		median_age numeric,
		aged_65_older numeric,
		aged_70_older numeric,
		gdp_per_capita double precision,
		extreme_poverty numeric,
		cardiovasc_death_rate double precision,
		diabetes_prevalence numeric,
		female_smokers numeric,
		male_smokers numeric,
		handwashing_facilities double precision,
		hospital_beds_per_thousand double precision,
		life_expectancy double precision,
		human_development_index double precision
);

SELECT * FROM CovidDeaths
ORDER BY 3,4;
-- select data that we are going to be using

SELECT country, date_recorded, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

DROP TABLE CovidDeaths;

CREATE TABLE CovidDeaths (
	iso_code varchar(10),
	continent varchar(40),
	place varchar (40),
	date_recorded date,
	population double precision,
	total_cases double precision,
	new_cases double precision,
	new_cases_smoothed double precision,
	total_deaths double precision,
	new_deaths double precision,
	new_deaths_smoothed double precision,
	total_cases_per_million double precision,
	new_cases_per_million double precision,
	new_cases_smoothed_per_million double precision,
	total_deaths_per_million double precision,
	new_deaths_per_million double precision,
	new_deaths_smoothed_per_million double precision,
	reproduction_rate double precision,
	icu_patients double precision,
	icu_patients_per_million double precision,
	hosp_patients double precision,
	hosp_patients_per_million double precision,
	weekly_icu_admissions double precision,
	weekly_icu_admissions_per_million double precision,
	weekly_hosp_admissions double precision,
	weekly_hosp_admissions_per_million double precision,
	);
	
	SELECT place, date_recorded, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- looking at total cases v total deaths
-- shows likelihood of dying from covid in your country
CREATE VIEW CovidDeathRate as
SELECT place, date_recorded, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM CovidDeaths
Where place = 'United States'
ORDER BY 1,2;
--looking at total cases v pop
SELECT place, date_recorded, total_cases, population, (total_cases/population)*100 AS casepercentage
FROM CovidDeaths
Where place = 'United States'
ORDER BY 1,2;

-- looking at countries with highest infection rate compared to population
CREATE VIEW RateOfInfection as
SELECT place, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopInfected
FROM CovidDeaths
WHERE total_cases IS NOT NULL 
AND population IS NOT NULL
Group by place, population
ORder by PercentagePopInfected desc;

-- showing countries with highest death count per pop
CREATE VIEW CountryMortalityCount as
SELECT place, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE total_deaths IS not NULL
AND continent is null
Group by place
ORder by TotalDeathCount desc;
-- places grouped by entire continents sometimes, when continent is null (puts continent in places column)
-- FIX: add 'where continent is not null' to script

-- and by continent:
CREATE VIEW ContinentMortalityCount as
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE total_deaths IS NOT NULL
AND continent is not null
Group by continent
ORder by TotalDeathCount desc;
-- small issues with continent accuracies i.e NA not including Canada

-- global no by dates
CREATE VIEW CovidTimeline as
SELECT date_recorded, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/sum(new_cases)*100 as DeathPercentage -- total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM CovidDeaths
WHERE continent is not null
and new_cases is not null
group by date_recorded
ORDER BY 1,2;

-- global no. percentage
CREATE VIEW GlobalPrecentageInfected as SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/sum(new_cases)*100 as DeathPercentage -- total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM CovidDeaths
WHERE continent is not null
and new_cases is not null
--group by date_recorded
ORDER BY 1,2;

-- looking at total pop v vacc


SELECT dea.continent, dea.place, dea.date_recorded, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.place Order by dea.place, dea.date_recorded) as RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.place = vac.place
AND dea.date_recorded = vac.date_recorded
WHERE dea.continent is not null
order by 2,3;

--cte
WITH PopvsVac (Continent, Place, Date_recorded, Population, New_Vaccinations, RollingPeopleVaccinated)
as (SELECT dea.continent, dea.place, dea.date_recorded, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.place Order by dea.place, dea.date_recorded) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.place = vac.place
AND dea.date_recorded = vac.date_recorded
WHERE dea.continent is not null)
SELECT *, (RollingPeopleVaccinated/Population *100) FROM PopvsVac
--learning rolling count
--use cte

--temptable -- drop table if exists #percentpopvaccinated
CREATE TABLE PercentPopulationVaccinated
(Continent varchar(255), place varchar(255), date_recorded date, population double precision, new_vaccinations double precision, RollingPeopleVaccinated double precision);

INSERT INTO PercentPopulationVaccinated
(SELECT dea.continent, dea.place, dea.date_recorded, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.place Order by dea.place, dea.date_recorded) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.place = vac.place
AND dea.date_recorded = vac.date_recorded
WHERE dea.continent is not null);

SELECT *, (RollingPeopleVaccinated/Population *100) 
FROM PercentPopulationVaccinated

-- creating view to store data for later vis

CREATE VIEW PercentagePopulationVaccinated as
SELECT dea.continent, dea.place, dea.date_recorded, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.place Order by dea.place, dea.date_recorded) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.place = vac.place
AND dea.date_recorded = vac.date_recorded
WHERE dea.continent is not null

