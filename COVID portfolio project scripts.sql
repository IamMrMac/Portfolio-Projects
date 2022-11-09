
-- Determine database in use
use PortfolioProjects

-- View table 
select *
from CovidDeaths

--select data for use. The WHERE clause is used to sort the data according to location, eliminating the continents that appeared under the location column

select location, date, total_cases, new_cases, total_deaths, population. 
from CovidDeaths
where continent is not null
order by 1,2;

--Total cases versus Total deaths
--This shows the likelihood of dying one contracts covid, using the The USA as reference
select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) death_rate
from CovidDeaths
where location  like '%states%' 
and continent is not null
order by 1,2 ;


--Total cases versus the population
select location, date, population, total_cases, round((total_cases/population)*100, 1) infection_rate
from CovidDeaths
where location  like '%states%' 
and continent is not null
order by 1,2;

--What country has the highest infection rate compared to population
select location, population, max(total_cases) highestinfectioncount, max((total_cases/population))*100 as infection_rate
from CovidDeaths
group by  location, population
order by infection_rate desc;

--Countries with Highest death rate per population
select location, population, max(total_deaths) highestdeathcount, Round(max((total_deaths/population))*100, 2)as death_rate
from CovidDeaths
group by  location, population
order by death_rate desc;

--Countries with Highest death count per population. total_deaths is CAST as INT because the datatype cannot be aggregated without being cast
select location, max(cast(total_deaths as int)) highestdeathcount
from CovidDeaths
where continent is not null 
group by  location
order by highestdeathcount desc;


--Continent with highest death count. 
select continent, max(cast(total_deaths as int)) highestdeathcount
from CovidDeaths
where continent is not null 
group by  continent
order by highestdeathcount desc;

--GLOBAL NUMBERS
--Total cases and deaths in the world by date
select date, sum(new_cases) as totalnewcases, sum(cast(new_deaths as int)) totalnewdeaths
from CovidDeaths
where continent is not null and new_cases is not null and new_deaths is not null
group by date
order by 1,2 ;

--Percentage of world deaths
select sum(new_cases) totalnewcases, sum(cast(new_deaths as int)) totalnewdeaths, sum(cast(new_deaths as int))/sum(new_cases) *100 death_rate
from CovidDeaths
where continent is not null
order by 1,2 ;


--Total percentage of world population that contracted the virus
select continent, location, population, sum(new_cases) totalnewcases, sum(new_cases)/sum(population) *100 death_rate
from CovidDeaths
--where location  like '%states%' 
where continent is not null and new_cases is not null
group by continent, population, location
order by 1,2; 


--Viewing the CovidVacinations table
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
---- First we create a sum of vaccinations, using windows function and partition by. 

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by RollingPeopleVaccinated desc;   

----Secondly add our statement to a temp table or CTE. This is necessary because we not aggregate a newly created column without a Temp Table or CTE.

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

select location, max(RollingPeopleVaccinated/population)* 100 as percentagevaccinated
from #Percentpopulationvaccinated
group by location
order by 2 desc


--Creating view to store data for later use

create view Percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) RollingPeopleVaccinated
from CovidDeaths dea
join CovidVacinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
  


