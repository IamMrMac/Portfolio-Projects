-- Determine database in use
use PortfolioProjects

-- View table 
select *
from CovidDeaths

--select data for use. We added the where clause to sort the data according to countries, eliminating the continents that appeared under the location column

select location, date, total_cases, new_cases, total_deaths, population. 
from CovidDeaths
where continent is not null
order by 1,2;

--Total cases versus Total deaths
--This shows the likelihood of dying if you contract covid. Using the The USA as reference
select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 1) death_rate
from CovidDeaths
where location  like '%states%' 
and continent is not null
order by 1,2 ;


--Total cases versus the population
select location, date, population, total_cases, round((total_cases/population)*100, 1) infection_rate
from CovidDeaths
where location  like '%states%' and continent is not null
order by 1,2;

--What country has the highest infection rate compared to population
select location, population, max(total_cases) highestinfectioncount, max((total_cases/population))*100 as infection_rate
from CovidDeaths
group by  location, population
order by infection_rate desc;

--Countries with Highest death rate per population
select location, population, max(total_deaths) highestdeathcount, max((total_deaths/population))*100 as death_rate
from CovidDeaths

group by  location, population
order by death_rate desc;

--Countries with Highest death count per population
select location, max(cast(total_deaths as int)) highestdeathcount
from CovidDeaths
where continent is not null 
group by  location
order by highestdeathcount desc;

select location, max(cast(total_deaths as int)) highestdeathcount
from CovidDeaths
where continent is null 
group by  location
order by highestdeathcount desc;


--BREAKING IT DWON BY CONTINENT


--Showing continent with highest death count
select continent, max(cast(total_deaths as int)) highestdeathcount
from CovidDeaths
where continent is not null 
group by  continent
order by highestdeathcount desc;

--Global Numbers
select location date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 1) death_rate
from CovidDeaths
--where location  like '%states%' 
where continent is not null
order by 1,2 ;

--Total cases and deaths in the world by date
select date, sum(new_cases) as totalnewcases, sum(cast(new_deaths as int)) totalnewdeaths--, total_deaths, round((total_deaths/total_cases)*100, 1) death_rate
from CovidDeaths
--where location  like '%states%' 
where continent is not null and new_cases is not null and new_deaths is not null
group by date
order by 1,2 ;

--Percentage of world deaths
select sum(new_cases) totalnewcases, sum(cast(new_deaths as int)) totalnewdeaths, sum(cast(new_deaths as int))/sum(new_cases) *100 death_rate
from CovidDeaths
--where location  like '%states%' 
where continent is not null
--group by date
order by 1,2 ;


--Total percentage of world population that contracted the virus
select continent, location, population, sum(new_cases) totalnewcases, sum(new_cases)/sum(population) *100 death_rate
from CovidDeaths
--where location  like '%states%' 
where continent is not null and new_cases is not null
group by continent, population, location
order by 1,2; 


--Lets bring our second table into consideration
select *
from CovidVacinations
order by 3,4;

--Joining both tables 
select *
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date;

--Looking at the total population versus vaccination

---- First we create a sum of vaccinations, using windows function and partition by
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by RollingPeopleVaccinated desc;   

----Secondly we create temp tables or CTE's

---- First we create a sum of vaccinations, using windows function and partition by. We do this because we canot use a column that we just created in the same 
----select statement without getting an error

-- USING A CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
( 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--order by 2,3;  
)
select *, (RollingPeopleVaccinated/population)* 100 as percentagevaccianted
from popvsvac



-- USING A TEMP TABLE

drop table if exists #Percentpopulationvaccinated
CREATE table #Percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #Percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--order by 2,3;  

select location, max(RollingPeopleVaccinated/population)* 100 as percentagevaccinated
from #Percentpopulationvaccinated
group by location
--where location like '%Nigeria%' and new_vaccinations is not null
order by 2 desc


--create view to store data for later use


drop table  Percentpopulationvaccinated
create view Percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--order by 2,3;   
