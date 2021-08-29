select * 
from PortfolioProject..CovidDeaths 
order by 3,4;

--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4;

--select data that we are going to be using 

select location,date,total_cases,new_cases,total_deaths,population 
from PortfolioProject..CovidDeaths
order by 1,2;

--conversion of datatypes for total_cases and total_deaths to float so that we wont get error while calculating

alter table [dbo].[CovidDeaths]
alter column [total_cases] FLOAT
go

alter table [dbo].[CovidDeaths]
alter column [total_deaths] FLOAT
go

-- Looking at total_cases vs total_deaths
--shows likelihood of dying if you get covid

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where Location like '%states%'
order by 1,2;


--looking at total_cases vs population
--shows what percentage of population got covid

select Location, date, population, total_cases, (total_cases/population)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where Location like '%states%'
order by 1,2;

--looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected 
from PortfolioProject..CovidDeaths
group by location, population
order by PercentPopulationInfected desc


-- showing Countries with Highest Death Count per Population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
group by location 
order by TotalDeathCount desc

-----%%%%%%%%%%%%%%
select * from PortfolioProject..CovidDeaths
where [continent] is not null
order by 3,4

---let's break down things by continent
--showing continents with highest death count per population

select continent, max(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent 
order by TotalDeathCount desc

alter table PortfolioProject..CovidDeaths
alter column [new_deaths] float
go

alter table PortfolioProject..CovidDeaths
alter column [new_cases] float
go
--Global Numbers

select sum(new_cases) as Total_cases, sum(new_deaths) as Total_deaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
--group by date
order by 1,2

--join

select * 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date

--converting nvarchar to float 

alter table PortfolioProject..CovidVaccinations
alter column [new_vaccinations] float
go

--looking at total population vs vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--use CTE 

With PopvsVac (continent,location,date,population,new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

---temp table

create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

alter table PortfolioProject..CovidVaccinations
alter column [new_vaccinations] int
go
---inserting data

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
