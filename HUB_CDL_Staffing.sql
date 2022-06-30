USE [RRD]
GO
/****** Object:  StoredProcedure [dbo].[HUB_sp_CDL_Staffing]    Script Date: 6/30/2022 9:05:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER procedure [dbo].[HUB_sp_CDL_Staffing_MA]

as

  INSERT INTO rrd.dbo.HUBDependencyRefreshCheck (HUB_Name) SELECT 'HUB_CDL_Staffing' -- ae 06042019

  /*ERROR INSERT NOT IN THIS PROCEDURE DUE TO THE HR TABLES THAT GET UPDATED BY DELTAS*/

--=============================================================================================================================
--========================VARIABLES============================================================================================
--=============================================================================================================================
Declare @date date
Set @date = rrd.dbo.udf_FirstDayOfMonth(DATEADD(YEAR,-3,GETDATE()))
-------------------------------------------------------------------------------------------------------------------------------
Declare @period int
Set @period = rrd.dbo.udf_MonthYear_Int(@date)
--=============================================================================================================================
--========================LOA END DATE NEEDED FOR MISMATCH EMAILS==============================================================
--=============================================================================================================================
IF OBJECT_ID ('tempdb..#LOA') is not null
DROP TABLE #LOA

SELECT
	EmployeeId,
	EmployeeName,
	ManagerName,
	EmploymentStatus,
	Period,
	GETDATE() AS RunDateTime

INTO #LOA

FROM rrd.dbo.HUB_CDL_Staffing (NOLOCK)

WHERE
Period = CONVERT(VARCHAR(6),GETDATE()-1,112) and
TitleGrouping in ('Account Executive', 'Loan Officer') and
EmploymentStatus = 'LOA'

CREATE INDEX IDX_EmployeeName ON #LOA(EmployeeName)
-------------------------------------------------------------------------------------------------------------------------------
INSERT INTO rrd.dbo.HUB_CDL_Staffing_LOA
SELECT * FROM #LOA
--=============================================================================================================================
--========================LOAN OFFICER NMLS IDs================================================================================
--=============================================================================================================================
If OBJECT_ID('tempdb..#AELicense') Is Not Null
drop table #AELicense

Select
distinct
IndividualId,
FirstName + ' ' + LastName as OfficerName

Into #AELicense

From dw_org.dbo.nmls_individual (nolock)

CREATE INDEX IDX_IndividualId ON #AELicense(IndividualId)
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'John Fayad'
Where OfficerName = 'Nouhad Fayad'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Nick Bergh'
Where OfficerName = 'Nicholas Bergh'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Adriana Gonzalez'
Where OfficerName = 'Adriana Gonzalez de la Garza'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Angelo Perera'
Where OfficerName = 'Angelo Perera'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Chuck Littlejohn'
Where OfficerName = 'Danika Littlejohn'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Rob Arias'
Where OfficerName = 'Roberto Arias Gonzalez'
-------------------------------------------------------------------------------------------------------------------------------
Update #AELicense
Set OfficerName = 'Timothy Ortiz'
Where OfficerName = 'Timmy Ortiz'
--=============================================================================================================================
--========================HUB TEMP TABLE=======================================================================================
--=============================================================================================================================
If OBJECT_ID('tempdb..#EmpTemp') is not null
drop table #EmpTemp

Create table #EmpTemp

(
EmployeeId varchar(100),
NetworkLogin varchar(100),
EmployeeName varchar(100),
EmployeeFirstName varchar(100),
EmployeeLastName varchar(100),
EmployeeEmail varchar(100),
OfficePhoneNumber numeric(18,0),
OfficeExtension numeric(18,0),
ManagerId varchar(100),
ManagerName varchar(100),
ManagerEmail varchar(100),
ManagerTitle varchar(100),
ManagerCity varchar(100),
ManagerOfficePhoneNumber numeric(18,0),
ManagerOfficeExtension numeric(18,0),
ManagerName_TwoUp varchar(100),
Title varchar(100),
TitleGrouping varchar(100),
EmploymentStatus varchar(100),
LOALastMonth char,
NewDepartmentFlag char,
NewDivisionFlag char,
TenuredFlag char,
TenuredDate date,
TenuredNextMoFlag char,
AE_NMLS_ID bigint,
RowDate date,
RowPeriod int,
TerminationDate date,
TermPeriod int,
HireDate date,
HirePeriod int,
HireDate_Original DATE,
JobCode int,
LOADate date,
LOAPeriod int,
LO_Location varchar(25),
City varchar(100),
City_OfficeLocation varchar(100),
Department varchar(100),
DepartmentGrouping varchar(100),
DivisionName varchar(100),
DivisionGroup varchar(3),
CostCenter varchar(100),
NegEqFlag char(1),
PurchaseFlag char(1),
HelocFlag char(1),
SLPTeamFlag char(1),
Period int,
DepartmentId int,
TrainingStartDate date,
TrainingEndDate date,
LOAEndDate DATE,
LOAEndPeriod INT,
TransferDate DATE,
NCAFlag CHAR(1),
OriginalTenuredDate DATE,
OriginalTenuredFlag CHAR,
OriginalTenuredNextMoFlag CHAR,
EmployeeRanking INT,
ChannelManager VARCHAR(100),
SiteLead VARCHAR(100),
ManagerName_ThreeUp VARCHAR(100),
SpecialProjectsFlag CHAR(1),
CDLSales CHAR(1),
CSRFlag CHAR(1),
--INSERT NEW FIELD NAME HERE WITH DATATYPE NEXT TO IT (First of 3 sections to include)
WorkStateName CHAR(100),--field was added on 1/20/21
CDLSales_CollegeLOProgram CHAR(1),
TrainingClass INT,
CDLAgentType VARCHAR(100),
NCAFlag_Agent CHAR(1),
BlendFlag CHAR(1),
MFDBenchFlag char(1),
BlendTrainingDate date,
OrgTierDescription VARCHAR(100),
RunDateTime datetime
)
--=============================================================================================================================
--========================LOOP FOR TEMP TABLE==================================================================================
--=============================================================================================================================
While @period <= rrd.dbo.udf_MonthYear_Int(GetDate())

BEGIN

Insert into #EmpTemp

Select
EmployeeId,
NetworkLogin,
ltrim(rtrim(
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(PreferredName,
' JR',''),'Jose Rodriguez Flores','Jose Rodriguez'),'Mark Stevens Tempongko','Mark Tempongko'),'Elizabeth Boyle','Beth Boyle'),
'Minh Hien Nguyen','Minh Nguyen'),'Juan Perez-Saldana','Juan Saldana'),'Bobby Ouji','Abdolvahab Ouji'),'Rose Grigoryan','Roza Grigoryan'),
'Zach Varney','Zachary Varney'),'Manny Mempin','Emmanuel Mempin'),'Princess Wells','Princess Harvey'),'Paula Zuniga','Pabla Zuniga'),
'Teresa Cruz','Maria Teresa Cruz')
)) as EmployeeName,
Null as EmployeeFirstName,
Null as EmployeeLastName,
Main.Email as EmployeeEmail,
--cast(replace(Main.OfficePhoneNumber,'.','') as bigint) as OfficePhoneNumber,
cast(replace(replace(replace(Main.OfficePhoneNumber,'\\pnmac.com\userdata\users\ndailey',''),'SpecI,HomeLoan',''),'.','') as bigint) as OfficePhoneNumber,
cast(case
		when ISNUMERIC(Main.OfficePhoneExtension) <> 1 then Null
		else Main.OfficePhoneExtension
	 end as numeric(18,0)) as OfficePhoneExtension,
ManagerId,
ISNULL(case
		when PreferredName in ('Merrill Tapia','Richard Helali','Adam Adoree','Alfred Wiggins')
		and @period between 201409 and 201506 and ManagerName = 'Grant Mills' then 'Grant Mills Non-Neg Eq'
		when PreferredName in ('Shelly Begue') and EmploymentStatus = 'Active' and ManagerName = 'Grant Mills' then 'Grant Mills Non-Neg Eq'
		else ManagerName
	end,'Name Unavailable') as ManagerName,
ManagerEmail,
ManagerTitle,
ISNULL(ManagerCity,'City Unavailable') as ManagerCity,
cast(replace(ManagerOfficePhoneNumber,'.','') as bigint) as ManagerOfficePhoneNumber,
cast(case
		when ISNUMERIC(OfficePhoneExtension) <> 1 then Null
		else OfficePhoneExtension
	 end as numeric(18,0)) as ManagerOfficeExtension,
cast(Null as varchar(100)) as ManagerName_TwoUp,
Title,

--CASE
--WHEN CDLFlag = 'Y' and Title in ('xyz') THEN 'Dispatcher'
--WHEN BDLFlag = 'Y' and Title in ('xyz') THEN 'BDL Title Grouping'
--WHEN ......
--END AS TitleGrouping

case
	when DepartmentId = '7841' then 'Underwriter'
	when PreferredName in ('Anca Enache', 'Anthony Jaraski') then  'Data & Reporting'
	when Title in ('Project Manager', 'Sr Project Manager', 'AVP, Project Management') then 'Project Manager'
	when Title in ('Intern', 'Corporate Intern') then 'Intern'
    when PreferredName in ('Fredrick Weaver', 'Brian Davidson') and @period >= 201702 then 'Account Executive'
	----THIS IS WHAT WE NEED TO UPDATE ONCE WE HAVE THE REPORTS UPDATE APPROPRIATELY
	--when Title in ('Specialist, Leads Support') then 'Dispatch Agent'

	when Title in ('Specialist, Leads Support', 'Specialist I, Lead', 'Specialist II, Lead', 'Specialist I, Leads Support', 'Specialist II, Leads Support') and OfficeLocation2 like '%Atlanta%' and @period < 201904 then 'Dispatch Agent - Infosys'
	when OfficeLocation2 like '%Atlanta%' and @period < 201904 then 'Dispatch Agent - Infosys'


	when (Title in ('Specialist, Leads Support', 'Specialist I, Lead', 'Specialist II, Lead', 'Specialist II, Lead ', 'Specialist I, Leads Support', 'Specialist II, Leads Support')
		or Title like 'Specialist II, Lead%' or Title like 'Specialist I, Lead%' or Title like 'Spec I, Lead%'
		or Title like '%Spec%II%Lead%' or Title like '%Spec%I%Lead%') and (ManagerEmail not in ('glenn.boyd@pnmac.com') or ManagerEmail is null) and EmployeeId not like 'O%'
		then 'Dispatch Agent'  --- ae changed 4/11/18, KP hangout
	/*ADDED 'Specialist II, Lead ' TO DISPATCH BECAUSE 2 DISPATCHERS HAD A SPACE AFTER THEIR TITLE*/
	when Title = 'Contractor, Dispatch' or (Title = 'Contractor' and Main.Email = 'norman.aves@pnmac.com') then 'DispatchOffshore Agent'
	when Title in ('Specialist, Purchase Loan') then Title
	when Title in ('Specialist, Loan Refinance','Spec, Loan Refi') then 'Specialist, Loan Refinance'

	when Title in ('Specialist I, Purchase Loan','Specialist II, Purchase Loan','Coordinator, Transaction') then 'Client Coordinator'     --

	--when Title in ('Specialist II, Purchase Loan') then 'Coordinator, Transaction'
	when Title in ('Assistant II, Admin Support') then 'Assistant II, Administrative'

	when Title in('Specialist I, Mtge Fulfl Qual', 'Specialist II, Mtge Fulfl Qual') then 'Fulfillment Specialist'
	--when PreferredName = 'Anna Barrera' then 'Manager - Shared Services'
	when title in ('AVP, Compliance', 'AVP, Compliance/Bus Support', 'Mgr, Policies & Procedures') then 'Manager - Compliance'
	when Title in( 'AVP, Business Ops', 'AVP, Control Tower', 'Mgr, Campaign') then 'Manager - Sales Support'
	when ManagerEmployeeID = '001359' then 'Admin - Control Tower'
    when Title in ('Mgr, Business Operations', 'Mgr, Retail Operations') and DeptName = 'Retail Shared Services' then 'Manager - Shared Services'
	when Title in ('AVP, Pricing Operations') then 'Manager - Sales Support'
	when Title in ('Manager, Sales','Manager, Reg Sales','VP, Rtl Sales & Chnl','Mgr, Sales','Manger, Sales', 'Sales Manager',
					'Mgr, E-Commerce Purchase','FVP, Regional Call Center','FVP, Retail Call Ctr Ops', 'FVP, Bus Development Officer', 'FVP, Regional Call Center'
					,'VP, Retail Sales & Chnnl Mgmt','Manager, E-Commerce Purchase') then 'Manager - Sales'
	when Title in ('Team Manager','Mgr, Project Management','Manager, Bus Ops & Strategy',
		           'Mgr, Bus Ops & Strat','Sr Mgr, Bus Ops & Strat', 'Manager, Business Systems', 'Sr Manager, Bus Ops & Strategy',
                    'Mgr, Data Mgmt & Analytics', 'Mgr, Control Tower', 'Mgr, Call Monitoring',
                    'Mgr, Business Systems', 'AVP, Pricing Operations', 'VP, Business Ops & Strategy',
                    'VP, Business Development','Manager, Control Tower','Manager, Call Monitoring', 'FVP, Retail Business Ops') then 'Manager - Sales Support'
	when PreferredName = 'Andrea Pecson' and @period = 201406 then 'QC Closer'
	when PreferredName = 'Debora Munoz' and @period = 201504 then 'Dispatch Agent'
	when Title = 'Call Center Agent' then 'Dispatch Agent'
	when Title = 'Chief, Consumer Direct Lending' then Title
	when Title like '%EVP%' then 'Executive Vice President'
	when Title like '%SVP%' then 'Senior Vice President'
	when Title like '%FVP%' then 'First Vice President'
	when PreferredName = 'Lisa Woltz' then 'Manager - Compliance'
	when Title like '%AVP%' then 'Assistant Vice President'
	when Title like '%VP%' then 'Vice President'



	--when Title in ('AE, Rtl', 'Account Executive, Retail','Retail Account Executive','Account Executive, Retails','Account Executive, Retail Loan', 'Account Executive. Retail')
	--or Title like '%AE%Retail%' or Title = 'Sr Account Executive' then 'Account Executive'

	when Title in ('AE, Rtl', 'Account Executive, Retail','Loan Officer','Retail Account Executive',
					'Account Executive, Retails','Account Executive, Retail Loan', 'Account Executive. Retail',
					'Sr Loan Officer','Sr. Loan Officer', 'Sr Loan Officer', 'Sr Account Executive',
					'Sr LO, New Customer Acquisition',
					'Loan Origination, New Customer Acquisition',
					'LO, Special Projects','Sr LO, New Customer Acq'
					)
	or Title like '%AE%Retail%'
	or Title like 'LO, New Customer Acq%' /*ADDED 202101*/ then 'Account Executive'  -- eff 7/19/16 ae

	when Title like '%Jr%Proce%' then 'Jr Processor'
	when Title like '%Processor%' or Title = 'Aerotek' or Title = 'Procr, Rtl Loan' then 'Processor'
	When Title in ('Procesor, Retail Loan','Procr, Retail Loan') then 'Processor'

	when Title in ('Analyst IV, Bus','Analyst IV, Bus Sys','Analyst IV, Business','Business Analyst IV',
				   'Analyst II, Bus', 'Analyst II, Business' ) then 'Data & Reporting'

	when Title in ('Sr Mgr, Data Mgt & Analytics') then 'Manager - Data & Reporting'

	when Title in ('Business Dev Officer','Business Development Officer','Bus Dev Ofcr', 'Bus Development Officer',
			       'Affinity Business Dev Officer','Retail BDO/Business Dev Ofcr') then 'Business Development Officer'

	when Title in ('Opener, Retail Loan','Opener,Retail Loan','Opener, Rtl Loan','Retail Loan Opener', 'Opener, Retail oan') then 'Opener'
	when Title in ('Closer, Retail Loan QC','Closer, Rtl Loan QC','Closer, Rtl Loan','Closer. Rtl Loan','Closer, Retails Loan') then 'QC Closer'
	when Title = 'Closer, Retail Loan DD' then 'Doc Drawer'
	when Title in ('Closer, Retail Loan Fun','Closer, Loan Retail', 'Sac, CA Fulfill/CL Rtl loan','Closer. Rtl Loan Fund','Closer, Retail Loan', 'Closer, Retail Loan Funding',
					'Closer, Rtl Loan Fund', 'Retail Loan Closer','Funder, Retail Loan') then 'Funder'

	when Title in ('FVP, Retail Operations','FVP, Retail Ops','Manager, Retail Operations','Mgr, Retail Ops',
				   'Sup, Closing','Supervisor, Closing','Manager, Retail Ops', 'Mgr, Rtl Ops', 'Mgr, Retail Operations','Retail Operations Manager','Sup, Purchase Rev Audit',
				   'Sup, Training & Escalation','FVP, Retail Operations', 'VP, Retail Operations', 'Mgr, Mortgage Fulfillment', 'Sup, Mortgage Fulfillment') then 'Manager - Fulfillment'


	when Title in ('Mgr, Shared Services','Sup, Shared Serv Ops','Sup, Shared Services','Manager, Shared Services / TO', 'Mgr, Shared Services Ops') then 'Manager - Shared Services'
	when Title in ('Specialist, Retail Dis','Specialist, Retail Disclosure','Spec, Retail Dis','Specialist II, Corr Quality',
					'Spec, Retail Disclosure', 'Spec, Rtl Dis') then 'Disclosure Specialist'

	when Title in ('Mgr, Compliance','Manager, Retail Compliance','Manager, Compliance','Mgr, Retail Compliance','AVP, Retail Compliance', 'Mgr, Business Controls'
					,'Manager, Policy & Procedure', 'AVP, Compliance/Bus Support', 'AVP, Compliance/Bus Support') then 'Manager - Compliance'
	when Title in ('Auditor, Compliance Rev','Comp Program Mgr, CDL','Mgr, CDL P & P', 'Auditor, Compliance Review',
					'Manager, Compliance Prgm, CDL','Auditor, Compliance Review','Auditor, Comp Review', 'Compliance Review Auditor',
					'Adm, Policy & Procedure','Audr, Compliance Rvw', 'Admin, Policy & Procedure','Admin, Policies & Procedures') then 'Compliance Review/P&P'

	when Title in ('Lead Manager, Retail Lending','Lead Manager, Retail Lend') then 'Lead Manager'

	when Title in ('Manager, Retail Training') then 'Manager - Retail Training'
	when Title in ('Trainer, Loan Servicing','Train, Loan Svc','Senior, Trainer','Trainer I','Trainer II', 'Designer I, Instructional', 'Developer I, WBT', 'Developer I, WB Training',
					'Designer II, Instructional','Manager, Training','Mgr, Training','Associate I, Learning'
					,'Developer II, WB Training') then 'Retail Training'

	when Title in ('Analyst, Call Monitor','Analyst, Call Monitoring','Analyst, Call Monitor', 'Team Leader, Call Monitoring','Sr Analyst, Call Monitoring') then 'Analyst, Call Monitor'
	when Title in ('Manager, pricing/product','Mgr, Rtl Pric/Prod', 'Mgr, Retail Pricing & Products') then 'Manager - Product & Pricing'
	when Title in ('Analyst, Product/Pricing','Analyst, Pricing/Product','Analyst, Pric/Prod','
					Analyst, Pricing & Products','Analyst, Pricing & Product','Analyst, Pricing & Products','Analyst, Product & Pricing',
					'Analyst II, Pricing', 'Analyst II, Pricing & Products') then 'Pricing Analyst'
	when Title in ('Analyst, Bus Retail Prod','Sr Analyst, Business', 'Business Analyst', 'Analyst, Bus Support', 'Analyst, Business Support') then 'Analyst - Business Ops'
	when Title in ('Coordinator, Client','Coord, Client') then 'Client Coordinator'

	when Title like '%Sup%Dispatch%' then 'Supervisor - Dispatch'

	when Title like '%Dispatch%' and Title <> 'Mgr, Dispatch' then 'Dispatch Agent'
	when Title in ('Team Manager','Mgr, Project Management','Manager, Bus Ops & Strategy',
		           'Mgr, Bus Ops & Strat','Sr Mgr, Bus Ops & Strat', 'Manager, Business Systems', 'Sr Manager, Bus Ops & Strategy',
                    'Mgr, Data Mgmt & Analytics', 'Mgr, Control Tower', 'Mgr, Call Monitoring',
                    'Mgr, Business Systems', 'AVP, Pricing Operations', 'VP, Business Ops & Strategy',
                    'VP, Business Development','Manager, Control Tower','Manager, Call Monitoring', 'FVP, Retail Business Ops') then 'Manager - Sales Support'

	when Title in ('Sr Mgr, Affinity Relat') then 'Manager - Affinity Relations'

	when Title in ('Specialist, Process Supp','Specialist, Process Support', 'Sr. Analyst, Mtge Bus Sys','Sr. Analyst, Mtge Bus System','Sr Analyst, Mtge Business Sys',
	                'Sr Analyst, Mtge Bus Systems') then 'Analyst, Business Sys'
	when Title in ('Specialist, File Assig') then 'File Assign Specialist'
	when Title in ('Clerk, Imaging/Scanner') then 'Imaging/Scanning'
	when Title in ('Adm I, Ctrl Tower', 'Administrator I, Control Tower','Admin I, Ctrl Tower','Aministrator I, Ctrl Tower', 'Admin I, Control Tower') then 'Admin - Control Tower'
	when Title in ('Adm, Policy & Procedure') then 'Adm, Policy & Procedure'
	when Title in ('Sr. Manager, Business Analysis') then 'Sr. Manager, Business Analysis'
	when Title in ('Spec II, Business Controls', 'Spec II, Business Control', 'Specialist II, Business Ctrl', 'Specialist II, Bus Controls',
					'Specialist I, Business Control', 'Spec I, Business Control', 'Specialist I, Bus Controls') then 'Business Control Specialist'


	else Title
end as TitleGrouping,
EmploymentStatus,
case
	when LastMonthStatus = 'LOA' then 'Y'
	else 'N'
end as LOALastMonth,

Null as NewDepartmentFlag,
Null as NewDivisionFlag,

Null as Tenured,
Null as TenuredDate,

Null as TenuredNextMoFlag,

AE.IndividualId as AE_NMLS_ID,
CAST(RowStartDate as date) as RowDate,
rrd.dbo.udf_MonthYear_Int(CAST(RowStartDate as date)) as RowPeriod,
TerminationDate,
rrd.dbo.udf_MonthYear_Int(TerminationDate) as TermPeriod,
HireDate,
rrd.dbo.udf_MonthYear_Int(HireDate)as HirePeriod,
HireDate AS HireDate_Original,
JobCode,
case
	when EmploymentStatus = 'LOA' then EmploymentStatusLastModifedDate
	else Null
end as LOADate,

case
	when EmploymentStatus = 'LOA' then rrd.dbo.udf_MonthYear_Int(EmploymentStatusLastModifedDate)
	else Null
end as LOAPeriod,
NULL as LO_Location,
ISNULL(case
			when PreferredName = 'Jose Rodriguez Flores' and @period >= 201405 then 'CA - Pasadena'
			else OfficeLocation
		end,'City Unavailable') as City,

ISNULL(OfficeLocation,'City Unavailable') AS City_OfficeLocation,
case
	when PreferredName = 'Heather Barrow' and @period >= 201407 then 'Moorpark, CA CC Sales #1'
	else DeptName
end as DeptName,


case
	when DeptName in ('Retail Production Support', 'MFD Loan Opening') then 'Fulfillment'
	when Title in ('Junior Loan Officer') then 'Sales'
	when PreferredName = 'Anna Barrera' then 'Shared Services'
	--when Title in('Intern') then 'Fulfillment'
	when Title in('Specialist I, Mtge Fulfl Qual', 'Specialist II, Mtge Fulfl Qual') then 'Shared Services'
	when Title in ('Admin, Policies & Procedures','Specialist I, Business Control','Specialist I, Bus Controls', 'Assistant II, Admin Support') then 'Enterprise Support'
	when Title in ('Specialist I, Mtge Fulfl Qual') then 'Shared Services'
	when DeptName in ('MFD Closing & Funding', 'MFD Loan Opening','MFD Support - Retail') then 'Fulfillment'
	when DeptName in ('Retail Training') then 'Retail Enterprise Support'
	when PreferredName in ('Indy Hing', 'Etidal Almaoui')  then 'Sales Support'
	when Title in ('Specialist, Leads Support', 'Specialist II, Purchase Loan', 'Coordinator, Transaction','Sr Analyst, Call Monitoring', 'AVP, Control Tower', 'AVP, Business Ops') then 'Sales Support'
	when Title = 'Processor, Retail Loan' and OfficeLocation = 'CA - Moorpark' then 'Moorpark, CA Fulfillment'
	when Title like '%EVP%' or Title like '%SVP%' then 'Retail Executive Management'
	when Title in ('Chief, Consumer Direct Lending', 'MD, Consumer Direct Lending') then 'Retail Executive Management'
	when Title in ('VP, Retail Sales & Channel', 'FVP, Retail Call Ctr Ops','VP, Retail Sales & Chnnl Mgmt') and OfficeLocation in ('CA - Pasadena') then 'Pasadena Sales'
	when Title in ('FVP, Bus Development Officer') and OfficeLocation in ('WA - Issaquah') then 'Seattle Sales'
	when Title in('FVP, Retail Operations') and OfficeLocation = 'TX - Ft. Worth' then 'Dallas, TX Fulfillment'
	when Title in ('VP, PCG Fulfillment', 'First VP, Retail Operations','Sup, Purchase Rev Audit') then  'Moorpark, CA Fulfillment'
	when Title in ('Adm I, Ctrl Tower','Administrator I, Control Tower','Sr Manager, Bus Ops & Strategy', 'Specialist, Process Support','Admin I, Ctrl Tower', 'Sr. Analyst, Mtge Bus Sys', 'FVP, Retail Business Ops',
					'Business Analyst', 'Sr. Analyst, Mtge Bus System','Aministrator I, Ctrl Tower',
					'Manager, Control Tower', 'Project Manager, Retail Sales', 'Sr Analyst, Mtge Business Sys',
					'Manager, Call Monitoring', 'Sr Analyst, Mtge Bus Systems', 'Mgr, Data Mgmt & Analytics',
					 'Mgr, Retail Pricing & Products', 'Mgr, Control Tower', 'Admin I, Control Tower',
					  'Admin, Policies & Procedures', 'Mgr, Call Monitoring', 'Mgr, Business Systems', 'AVP, Pricing Operations','VP, Business Ops & Strategy',
					  'Analyst II, Pricing') then 'Sales Support'
	when Title in ('Team Manager','Mgr, Project Management','Manager, Bus Ops & Strategy',
		           'Mgr, Bus Ops & Strat','Sr Mgr, Bus Ops & Strat', 'Manager, Business Systems') then 'Sales Support'
	when Title in ('Specialist, Retail Dis','Mgr, Shared Services','Specialist, Retail Disclosure','Spec, Retail Dis') then 'Shared Services'
	when Title in ('VP, Org Infrastructure','Auditor, Compliance Rev','Manager, Retail Compliance','Mgr, Compliance') then 'Retail Enterprise Support'

	when Title in ('FVP, Retail Lending Bus Op','Lead Manager, Retail Lending','Lead Manager, Retail Lend','Specialist, Process Supp',
				   'Mgr, Project Management','Manager, pricing/product','Mgr, Rtl Pric/Prod','Analyst, Pric/Prod','Analyst, Pricing/Product','Analyst, Product/Pricing','Analyst, Call Monitor',
				   'Analyst, Bus Retail Prod','Dispatch Agent, Call Center','Dispatch Agent','Dispatch Agent, Call Cent',
				   'Team Manager','Mgr, Bus Ops & Strat','Manager, Bus Ops & Strategy','Sr Mgr, Bus Ops & Strat','Sr Analyst, Business',
				   'Analyst, Pricing & Products', 'Analyst, Pricing & Product','Analyst, Call Monitoring','Analyst, Product & Pricing',
				   'Team Leader, Call Monitoring', 'Analyst II, Pricing & Products', 'Mgr, Campaign') then 'Sales Support'
	when DeptName like '%Moorpark%CA%CC%Sales%' then 'Moorpark Sales'
	when DeptName like '%Pasadena%CA%CC%Sales%' then 'Pasadena Sales'
	when Title = 'Account Executive, Retail' and Deptname = 'Retail BDO' then 'Pasadena Sales'
	when Title in ('FVP, Regional Call Center','Manager, E-Commerce Purchase') then 'Pasadena Sales'
	when DeptName like '%Dallas%TX%CC%Sales%' then 'Dallas Sales'
	when DeptName like '%Sacramento%CA%CC%Sale%' then 'Sacramento Sales'
	when Title in ('FVP, Reg Call Ctr','FVP, Reg Call Center' ) then 'Sacramento Sales'
	when DeptName = 'Eagan, MN Local Branch' then 'Eagan Sales'
	when DeptName like 'Henderson%NV%' then 'Henderson Sales'
	when DeptName like 'Honolulu%HI%' then 'Honolulu Sales'
	when Title in ('Closer, Retail Loan QC','Closer, Retail Loan DD') then 'Fulfillment'
	when DeptName in ('Moorpark, CA Fulfillment','Pasadena, CA Fulfillment','Retail BDO','Retail Dispatch',
					  'Retail Enterprise Support','Dallas, TX Fulfillment') then DeptName
	when DeptName like '%Shared%Services%' then 'Shared Services'
	when DeptName like '%Kansas%City%MO%' then 'Kansas City Sales'
	when DeptName like '%Sacramento%CA%Fulfill%' then 'Sacramento, CA Fulfillment'
	when DeptName in ('Retail Production:Admin') then 'Retail Enterprise Support'
	when DeptName in ('Retail Compliance Review','Admin, Policies & Procedures') then 'Retail Enterprise Support'
	when Title in ('Processor, Retail Loan') then 'Fulfillment'
	else DeptName
end as DepartmentGrouping,
DivName as DivisionName, --REMOVED BY CHARLIE ON 07/08/2020 DUE TO ACCOUNTING/HR JULY 2020 CHANGE
--CASE WHEN @period <= 202007 THEN OldDivisionName ELSE NewDivisionName END AS DivisionName, --ADDED BY CHARLIE ON 07/08/2020
CAST(Null as varchar(100)) as DivisionGroup,
CostCenter,
Null as NegEqFlag,
'N' as PurchaseFlag,
'N' as HelocFlag,
Null as SLPTeamFlag,
@period as Period,
DepartmentId ,
NULL AS TrainingStartDate,
NULL AS TrainingEndDate,
NULL AS LOAEndDate,
NULL AS LOAEndPeriod,
NULL AS TransferDate,
'N' AS NCAFlag,
NULL AS OriginalTenuredDate,
NULL AS OriginalTenuredFlag,
NULL AS OriginalTenuredNextMoFlag,
1 AS EmployeeRanking,--ROW_NUMBER() OVER(PARTITION BY Main.Email, @period ORDER BY EmployeeId DESC) AS EmployeeRanking, --ADDDED 05/23/2020 FOR DUPLICATE RECORDS FROM HR
NULL AS ChannelManager,
NULL AS SiteLead,
NULL AS ManagerName_ThreeUp,
'N' AS SpecialProjectsFlag,
'N' AS CDLSales,
'N' AS CSRFlag,
WorkStateName, --added on 1/20/21
'N' AS CDLSales_CollegeLOProgram,
NULL AS TrainingClass,
CASE
	WHEN (Main.Title = 'Contractor, Dispatch' and Main.EmployeeId like 'LQ%') or (Main.Title = 'Contractor, Dispatch' and Main.EmployeeId like 'OW%' and
		Main.Email in ('don.laroche@pnmac.com', 'kimaada.jackson@pnmac.com', 'maureen.stemmle@pnmac.com', 'rolando.tanedo@pnmac.com')) THEN 'LQ Agent'
	WHEN (Title = 'Contractor, Dispatch' and Main.EmployeeId like 'OW%') or
		(Title = 'Contractor' and Main.Email = 'norman.aves@pnmac.com') THEN 'WNS Agent'
	WHEN Main.Title = 'Contractor, Dispatch' and (Main.EmployeeId like 'OT%' or Main.EmployeeId like 'OQ%') THEN 'Squeeze Media Agent'
	WHEN Main.Title = 'Contractor, Dispatch' THEN 'Agent'
	ELSE 'Not Applicable'
END AS CDLAgentType,
'N' AS NCAFlag_Agent,
'N' AS BlendFlag,
'N' AS MFDBenchFlag,
NULL AS BlendTrainingDate,
OrgTierDescription,
--INSERT NEW FIELD NAME HERE WITH VALUES IF NOT NULL (Second of 3 sections to include)
GETDATE() as RunDt

FROM (
	SELECT
	EmployeeKey,
	EmployeeId,
	FirstName,
	LastName,
	MiddleName,
	Nickname,
	PreferredName,
	HomeCityName,
	HomeStateName,
	HomeZipCode,
	MailStopCode,
	WorkStateName,
	Title,
	JobCode,
	Email,
	OfficePhoneNumber,
	OfficePhoneExtension,
	CellPhoneNumber,
	EmploymentType,
	EmploymentStatus,
	EEStatusCode,
	EmploymentStatusCode,
	EmploymentStatusLastModifedDate,
	ManagerEmployeeID,
	OfficeLocation,
	NetworkLogin,
	HireSourceName,
	HireDate,
	TerminationDate,
	TerminationReasonDescription,
	DepartmentId,
	OrgTierDescription,
	RowStartDate,
	RowEndDate,
	RowCurrentFlag,
	CreatedDateTime,
	UpdatedDateTime,
	OrgLevel4,
	OfficeLocation2,
	DeptName,
	DivName,
	DivisionId,
	ManagerId,
	ManagerName,
	ManagerEmail,
	ManagerCity,
	ManagerOfficePhoneNumber,
	LastMonthStatus,
	LastMonthDept,
	CostCenter,
	ManagerTitle,
	GroupRank

	FROM (
		SELECT
		Emp.EmployeeKey,
		Emp.EmployeeId,
		Emp.FirstName,
		Emp.LastName,
		Emp.MiddleName,
		Emp.Nickname,
		Emp.PreferredName,
		Emp.HomeCityName,
		Emp.HomeStateName,
		Emp.HomeZipCode,
		Emp.MailStopCode,
		Emp.WorkStateName,
		Emp.Title,
		Emp.JobCode,
		Emp.Email,
		Emp.OfficePhoneNumber,
		Emp.OfficePhoneExtension,
		Emp.CellPhoneNumber,
		Emp.EmploymentType,
		Emp.EmploymentStatus,
		Emp.EEStatusCode,
		Emp.EmploymentStatusCode,
		Emp.EmploymentStatusLastModifedDate,
		Emp.ManagerEmployeeID,
		Emp.OfficeLocation,
		Emp.NetworkLogin,
		Emp.HireSourceName,
		Emp.HireDate,
		Emp.TerminationDate,
		Emp.TerminationReasonDescription,
		Emp.DepartmentId,
		Emp.OrgTierDescription,
		Emp.RowStartDate,
		Emp.RowEndDate,
		Emp.RowCurrentFlag,
		Emp.CreatedDateTime,
		Emp.UpdatedDateTime,
		Emp.OrgLevel4,
		CASE
			WHEN Emp.Email in ('shavone.moore@pnmac.com', 'sharon.haggins@pnmac.com', 'lawerence.pickens@pnmac.com', 'porche.riley@pnmac.com', 'tia.tutt@pnmac.com', 'amanda.avin@pnmac.com', 'aleeta.vinson@pnmac.com') THEN 'Atlanta' -- 04/02 Charlie (to make these individuals Infosys agents)
			WHEN Emp.Email in ('ramesha.mcdonald@pnmac.com', 'tracye.davis@pnmac.com') THEN 'Atlanta' -- 04/16 Charlie (to make these individuals Infosys agents)
			ELSE Emp.OfficeLocation
		END AS OfficeLocation2,
		Dept.Name as DeptName,
		Div.Name as DivName, --REMOVED BY CHARLIE ON 07/08/2020 BECAUSE PREVIOUSLY DIVISION NAME WAS ONE SOURCE
		--OldDiv.Name AS OldDivisionName,
		--NewDiv.Name AS NewDivisionName,
		Dept.DivisionId, --ADDED BY CHARLIE ON 07/07/20 FOR WHERE CLAUSE TO CAPTURE DIVISIONID
		Man.EmployeeId as ManagerId,
		Man.PreferredName as ManagerName,
		Man.Email as ManagerEmail,
		Man.OfficeLocation as ManagerCity,
		Man.OfficePhoneNumber as ManagerOfficePhoneNumber,
		ET.EmploymentStatus as LastMonthStatus,
		ET.Department as LastMonthDept,
		Dept.CostCenterId as CostCenter,
		Man.Title as ManagerTitle,
		ROW_NUMBER() Over(Partition by Emp.EmployeeId Order by Emp.RowStartDate desc, Man.RowStartDate desc) as GroupRank

		From dw_org.dbo.employee Emp (nolock)

		left join dw_org.dbo.department Dept (nolock)
		on Emp.DepartmentId = Dept.DepartmentId

		/* OLD DIVISION NAME SOURCE*/
		left join dw_org.dbo.division Div (nolock)
		on Dept.DivisionId = Div.DivisionId
		and LEFT(Dept.CostCenterId,4) = Div.CompanyId


		--left join DWMSSQLSTAGING1.dw_org.dbo.division OldDiv --(NOLOCK) --ADDED BY CHARLIE ON 07/08/2020 TO ACCOUNT FOR JULY 2020 ACCOUNTING/HR CHANGE
		--on Dept.DivisionId = OldDiv.DivisionId
		--and OldDiv.ActiveYN = 'N'

		--left join DWMSSQLSTAGING1.dw_org.dbo.division NewDiv --(NOLOCK) --ADDED BY CHARLIE ON 07/08/2020 TO ACCOUNT FOR JULY 2020 ACCOUNTING/HR CHANGE
		--on Dept.DivisionId = NewDiv.DivisionId
		--and NewDiv.ActiveYN = 'Y'

		--left join
		--(Select
		--Distinct
		--EmployeeId,
		--PreferredName,
		--Title,
		--Email,
		--case
		--	when PreferredName = 'Jose Rodriguez Flores' and @period >= 201405 then 'CA - Pasadena'
		--	else OfficeLocation
		--end as OfficeLocation,
		--OfficePhoneNumber,
		--OfficePhoneExtension,
		--ManagerEmployeeID

		--From dw_org.dbo.employee (nolock)) Man
		--on Emp.ManagerEmployeeID = Man.EmployeeId

		left join
		(Select
		EmployeeId,
		PreferredName,
		Title,
		Email,
		case
			when PreferredName = 'Jose Rodriguez Flores' and @period >= 201405 then 'CA - Pasadena'
			else OfficeLocation
		end as OfficeLocation,
		OfficePhoneNumber,
		OfficePhoneExtension,
		ManagerEmployeeID,
		RowStartDate,
		UpdatedDateTime

		From dw_org.dbo.employee (nolock)) Man
		on Emp.ManagerEmployeeID = Man.EmployeeId and convert(varchar(6),DATEADD(d,-1,Man.UpdatedDateTime),112) <= @period




		--left join
		--(Select *,
		--Row_Number() Over(Partition by EmployeeId Order by RowStartDate desc) as GroupRank
		--From dw_org.dbo.employee (nolock)
		--Where rrd.dbo.udf_MonthYear_Int(UpdatedDateTime) <= @period) ManTwo
		--on Man.ManagerEmployeeID = ManTwo.EmployeeId and ManTwo.GroupRank = 1

		left join #EmpTemp ET
		on Emp.EmployeeId = ET.EmployeeId and ET.Period + case
															when left(ET.Period,2) = '12' then 89
															else 01
														  end = @period

		Where
		convert(varchar(6),DATEADD(d,-1,Emp.UpdatedDateTime),112) <= @period --and LEFT(Emp.EmployeeId,1) <> 'C'
		and Emp.Email <> 'jeremy.white@pnmac.com'--HR Errors with Records Impacting LO jeremy.white1@pnmac.com
		and Emp.EmployeeId <> 'OT0595'--Squeeze Media Agent has this duplicate EmployeeId we are raisi
	) Mstr

	--Where GroupRank = 1 and Name = 'Retail Production' --NOT USED SINCE BEFORE 2019
	--Where GroupRank = 1 and ((DivName = 'Retail Production' or (DivName <> 'Retail Production' --REPLACED BY CHARLIE ON 07/07/20
	Where GroupRank = 1 and (((DivisionId in (300, 357) or DeptName in ('Retail Dispatch', 'Retail Enterprise Support', 'Marketing')) or (DivisionId not in (300,357) --357 is only present after the July 2020 update unlike 300, so this will run even if we revert - Charlie 07/09/2020
															and Mstr.EmployeeId in (Select EmployeeId
																				   From #EmpTemp
																				   Where EmployeeId = Mstr.EmployeeId
																				   --and DivisionName = 'Retail Production' --REPLACED BY CHARLIE ON 07/07/20
																				   and (DivisionId in (300, 357) or DeptName = 'Retail Dispatch')
																				   and Period = @period - case
																											when right(@period,2) = '01'
																											then 89
																											else 1
																										  end))
																										  or
																										  (DepartmentId = '7841' and Title like '%Unde%')
																										  )
	OR Email in ('cherise.mejia@pnmac.com', 'francisco.duran@pnmac.com', 'david.hernandez@pnmac.com', 'norman.aves@pnmac.com', 'jazmyne.rogers@pnmac.com','jonathan.wilson@pnmac.com'/*SERVICNIG*/,
	'stacie.jenkins@pnmac.com'/*SERVICNIG*/,
	/*ADDED DUE TO NCA HEADCOUNTS NOT MATCHING*/
	'adejumoke.dosunmu@pnmac.com',
	'beverly.lynch@pnmac.com',
	'brock.walker@pnmac.com',
	'christopher.bowman@pnmac.com',
	'christopher.bozel@pnmac.com',
	'curt.coleman@pnmac.com',
	'daniel.kier@pnmac.com',
	'daniel.turner@pnmac.com',
	'dejan.lolic@pnmac.com',
	'donald.carlson@pnmac.com',
	'eric.aron@pnmac.com',
	'exavier.hamilton@pnmac.com',
	'fahali.campbell@pnmac.com',
	'francisco.duran@pnmac.com',
	'gabriel.vallarta@pnmac.com',
	'gary.sahakian@pnmac.com',
	'ihsan.moosapanah@pnmac.com',
	'jeremiah.kneeland@pnmac.com',
	'johann.bonar@pnmac.com',
	'john.ingersoll@pnmac.com',
	'john.wilbanks@pnmac.com',
	'joshua.nelson@pnmac.com',
	'justin.syracuse@pnmac.com',
	'krystan.keyes@pnmac.com',
	'kuno.kaulbars@pnmac.com',
	'maria.espana@pnmac.com',
	'michael.dubrow@pnmac.com',
	'michael.powers@pnmac.com',
	'michael.steel@pnmac.com',
	'monica.ochoa@pnmac.com',
	'nina.moshiri@pnmac.com',
	'robin.hallford@pnmac.com',
	'tim.snow@pnmac.com',
	'sergio.murillo@pnmac.com',
	'melissa.raymundo@pnmac.com',
	'marina.rodriguez@pnmac.com',
	'corin.aurelio@pnmac.com',
	'alizabeth.kanberian@pnmac.com',
	'breanna.mendoza@pnmac.com'
	)
	OR Title = 'Contractor, Dispatch'
	OR Title in ('Rep I, Customer Service','Rep II, Customer Service','Sr Rep, Customer Service','Senior Representative, Customer Service','Rep, Customer Service Sales')
	)


) Main


Left Join #AELicense AE
on replace(replace(replace(replace(replace(
AE.OfficerName,
'Arutyun Vanyan','Aroutyun Vanyan'),'William Manapat','Billy Manapat'),'Nicamedes Bonifacio','Nick Bonifacio')
,'Christopher Jantz','Chris Jantz'),'Feraba Aowrang','Fereba Aowrang')
=
Main.FirstName + ' ' + Main.LastName
-------------------------------------------------------------------------------------------------------------------------------
Set @date = DATEADD(m,1,@date)
-------------------------------------------------------------------------------------------------------------------------------
Set @period = rrd.dbo.udf_MonthYear_Int(@date)
-------------------------------------------------------------------------------------------------------------------------------
END

--=============================================================================================================================
--========================UPDATES TO #EMPTEMP==================================================================================
--=============================================================================================================================
Update ET

Set ET.HireDate = Emp.HireDate

From #EmpTemp ET

inner join dw_org.dbo.employee Emp (nolock)
on ET.EmployeeEmail = Emp.Email and LEFT(Emp.EmployeeId,1) = 'C' and Emp.RowCurrentFlag = 'Y'
----------------------------------------------------------------------------
-----Internal Transfer MFD to CDL  or Rehired resetting hire date for tenure purposes
----------------------------------------------------------------------------
Update #EmpTemp
Set TransferDate = '9/16/19' --removed Hire Date update
where EmployeeName = 'Daniel Kirby'

Update #EmpTemp
Set HireDate = '9/16/19', TransferDate = '9/16/19'
where EmployeeName = 'Carl Wren'

Update #EmpTemp
Set TransferDate = '9/16/19' --removed Hire Date update
where EmployeeName = 'Arthur Hachikian' and HireDate = '6/24/19'

Update #EmpTemp
Set HireDate = '9/16/19', TransferDate = '9/16/19'
where EmployeeName = 'Anthony Gafafyan'

Update #EmpTemp
Set HireDate = '9/16/19', TransferDate = '9/16/19'
where EmployeeName = 'Benjamin Williams'

Update #EmpTemp
Set TransferDate = '9/16/19' --removed Hire Date update
where EmployeeName = 'Michael Angelo'

Update #EmpTemp
Set HireDate = '8/16/19', TransferDate = '8/16/19'
where EmployeeName = 'Steven Vargas'

Update #EmpTemp
Set HireDate = '5/16/19'
where EmployeeName = 'Rob Arias'

Update #EmpTemp
Set HireDate = '9/7/17'
where EmployeeName = 'Brian Schooler'

Update #EmpTemp
Set HireDate = '9/18/17'
where EmployeeName = 'Ranjnesh Prasad'

Update #EmpTemp
Set HireDate = '8/21/17'
where EmployeeName = 'Jason Watson'

Update #EmpTemp
Set HireDate = '7/17/17'
where EmployeeName = 'Aaron Green'

Update #EmpTemp
Set HireDate = '7/10/17'
where EmployeeName = 'Russell Litzenberger'

Update #EmpTemp
Set HireDate = '4/3/17'
where EmployeeName = 'David Robertson'

Update #EmpTemp
Set HireDate = '3/13/17'
where EmployeeName = 'Selwam Naidu'

Update #EmpTemp
Set HireDate = '4/11/16'
where EmployeeName = 'Jarett Delbene'

Update #EmpTemp
Set HireDate = '2/8/16'
where EmployeeName = 'Abdul Saleh'

Update #EmpTemp
Set HireDate = '5/11/15'
where EmployeeName = 'Jasen Smith'

Update #EmpTemp
Set HireDate = '2/9/15'
where EmployeeName = 'David Erlich'

---Nathan Adjustments
Update #EmpTemp
Set HireDate = '1/2/18'
where EmployeeName = 'Andre Yerkanyan'

Update #EmpTemp
Set HireDate = '12/13/17'
where EmployeeName = 'Bryan Turnley'

Update #EmpTemp
Set HireDate = '10/13/14'
where EmployeeName = 'Abdul Saleh'

Update #EmpTemp
Set HireDate = '9/25/17'
where EmployeeName = 'Austin Schreibman'

Update #EmpTemp
Set HireDate = '9/1/10'
where EmployeeName = 'Ed Vandervelde'

Update #EmpTemp
Set HireDate = '4/1/13'
where EmployeeName = 'Jasen Smith'

Update #EmpTemp
Set HireDate = '1/2/18'
where EmployeeName = 'Joshua Price'

Update #EmpTemp
Set HireDate = '12/1/17'
where EmployeeName = 'Layal Zoueihed'

Update #EmpTemp
Set HireDate = '6/20/16'
where EmployeeName = 'Nshan Terzyan'

Update #EmpTemp
Set HireDate = '9/8/17'
where EmployeeName = 'Paul Santiago'

Update #EmpTemp
Set HireDate = '5/2/16'
where EmployeeName = 'Paula Paran'

Update #EmpTemp
Set HireDate = '4/3/17'
where EmployeeName = 'Shaun Wilson'

Update #EmpTemp
Set HireDate = '2/12/18'    -- Changed from Refi to Purchase Team
where EmployeeName in (
'Bailey Greene',
'Darius Jackson',
'Lisa Garcia',
'Harry Arzrounian',
'Joshua Baker',
'Sofia Armendariz-Vidal',
'Sylvia Villasenor',
'Tony Tsiligian',
'Viet Ho')

Update #EmpTemp
Set HireDate = '3/1/18'
where EmployeeName = 'David Abelyan'

Update #EmpTemp
Set HireDate = '3/21/18'
where EmployeeName = 'Imelda Sanchez'

Update #EmpTemp
Set HireDate = '4/1/18'
where EmployeeName = 'Terrell Jean'


Update #EmpTemp
Set HireDate = '3/26/18'
where EmployeeName = 'Andre Yerkanyan'

Update #EmpTemp
Set HireDate = '5/15/18'
where EmployeeName = 'Tony Trozera'

/*/REMOVED DUE TO NEW HIRE DATE OF 9/16/19 WHEN CHANGED*/
--Update #EmpTemp
--Set HireDate = '5/15/18'
--where EmployeeName = 'Carl Wren'

Update #EmpTemp
Set HireDate = '5/15/18'
where EmployeeName = 'John Anding'

Update #EmpTemp
Set HireDate = '5/15/18'
where EmployeeName = 'Kevin Lundberg'

Update #EmpTemp
Set HireDate = '8/1/18'
where EmployeeName = 'Rodney Perkins'

Update #EmpTemp
Set HireDate = '6/1/18'
where EmployeeName = 'Tara Kaufman'

Update #EmpTemp
Set HireDate = '7/16/18'
where EmployeeName = 'Michael Ammari'

Update #EmpTemp
Set HireDate = '10/16/18'
where EmployeeName = 'Chris Cruz'

Update #EmpTemp
Set HireDate = '11/16/18'
where EmployeeName = 'Ignacio Barrientos'

Update #EmpTemp
Set HireDate = '1/16/19'
where EmployeeName = 'Araceli Jimenez'

Update #EmpTemp
Set HireDate = '2/18/19'
where EmployeeName = 'Albert Tigranyan'

Update #EmpTemp
Set HireDate = '3/1/19'
where EmployeeName = 'Elizabet Ovakimyan'

Update #EmpTemp
Set HireDate = '6/16/19'
where EmployeeName = 'Abigail Wilson'

Update #EmpTemp
Set HireDate = '6/24/19'
where EmployeeName = 'Angel Potts'


Update #EmpTemp
Set HirePeriod = rrd.dbo.udf_MonthYear_Int(HireDate)

--ADDDED 05/23/2020 FOR DUPLICATE RECORDS FROM HR
DELETE FROM #EmpTemp
WHERE EmployeeEmail = 'dian.corsiga@pnmac.com'

Delete ET

From #EmpTemp ET

left join #EmpTemp ET2
on ET.EmployeeEmail = ET2.EmployeeEmail

Where LEFT(ET.EmployeeId,1) = 'C' and LEFT(ET2.EmployeeId,1) <> 'C' and ET.Period = ET2.Period
	and ET.EmployeeId not in (--Employees whose Contractor records is needed to be brought in manually.
	'C01637'
	)

DELETE FROM #EmpTemp WHERE EmployeeId = '004390'

Delete ET

From #EmpTemp ET

left join #EmpTemp ET2
on ET.EmployeeEmail = ET2.EmployeeEmail and ET.Period = ET2.Period

Where LEFT(ET.EmployeeId,2) = 'OW' and LEFT(ET2.EmployeeId,2) <> 'OW' and LEFT(ET2.EmployeeId,2) = 'LQ'

Delete ET

From #EmpTemp ET

left join #EmpTemp ET2
on ET.EmployeeEmail = ET2.EmployeeEmail and ET.Period = ET2.Period

Where LEFT(ET.EmployeeId,2) = 'OT' and LEFT(ET2.EmployeeId,2) <> 'OT'



Update ET

Set ManagerName_TwoUp =
ET2.ManagerName

From #EmpTemp ET

left join #EmpTemp ET2
on case
	when ET.ManagerName like '%Grant%Mills%' then 'Grant Mills'
	else ET.ManagerName
   end = ET2.EmployeeName and ET.Period = ET2.Period


Update ET
Set ET.ManagerName_ThreeUp =
ET2.ManagerName_TwoUp

From #EmpTemp ET

left join #EmpTemp ET2
on case
	when ET.ManagerName like '%Grant%Mills%' then 'Grant Mills'
	else ET.ManagerName
   end = ET2.EmployeeName and ET.Period = ET2.Period
--=============================================================================================================================
--========================FINAL TEMP TABLE=====================================================================================
--=============================================================================================================================
If OBJECT_ID('tempdb..#Final') Is Not Null
drop table #Final

--INSERT NEW FIELD NAME IN QUERY BELOW NEXT TO THE APPROPRIATE FIELD OR NEXT ALPHABETICALLY (Third of 3 sections to include)
select
EmployeeId,
AE_NMLS_ID,
CDLAgentType,
CDLSales,
CDLSales_CollegeLOProgram,
CSRFlag,
City,
City_OfficeLocation,
CostCenter,
Department,
DepartmentId,
DepartmentGrouping,
case
	when DepartmentGrouping in ('Retail Executive Management') then 'Retail Executive Management'
	when DepartmentGrouping in ('Sales Support') then 'Sales Support'
	when DepartmentGrouping like '%Sales%' then 'Sales'
	when DepartmentGrouping like '%Fulfillment%' then 'Fulfillment'
	when DepartmentGrouping in ('Retail BDO','Retail Dispatch') then 'Sales Support'
	when DepartmentGrouping in ('Shared Services') then 'Shared Services'
	when DepartmentGrouping in ('Retail Enterprise Support', 'Enterprise Support') then 'Enterprise Support'
end as DepartmentGroupingII,
DivisionGroup,
DivisionName,
EmployeeEmail,
EmployeeFirstName,
EmployeeLastName,
EmployeeName,
EmploymentStatus,
EmploymentStatus AS EmploymentStatusDetail,
HireDate,
HirePeriod,
HireDate_Original,
JobCode,
LOADate,
LOALastMonth,
LOAPeriod,
LOAEndDate,
LOAEndPeriod,
LO_Location,
ManagerCity,
ManagerEmail,
ManagerId,
ManagerName,
ManagerName_TwoUp,
ManagerName AS ManagerName_Unchanged,
MFDBenchFlag,
ChannelManager,
SiteLead,
ManagerOfficeExtension,
ManagerOfficePhoneNumber,
ManagerTitle,
NegEqFlag,
NetworkLogin,
NewDepartmentFlag,
NewDivisionFlag,
OfficeExtension,
OfficePhoneNumber,
OriginalTenuredDate,
OriginalTenuredFlag,
OriginalTenuredNextMoFlag,
OrgTierDescription,
Period,
PurchaseFlag,
HelocFlag,
NCAFlag,
SpecialProjectsFlag,
NCAFlag_Agent,
BlendFlag,
BlendTrainingDate,
RowDate,
RowPeriod,
SLPTeamFlag,
TenuredDate,
TenuredFlag,
TenuredNextMoFlag,
TerminationDate,
TermPeriod,
Title,
TitleGrouping,
TrainingClass,
TrainingEndDate,
TrainingStartDate,
TransferDate,
WorkStateName,--added on 1/20/21
RunDateTime


Into #Final

from #EmpTemp

WHERE EmployeeRanking = 1 --ADDDED 05/23/2020 FOR DUPLICATE RECORDS FROM HR

CREATE INDEX IDX_EmployeeName ON #Final(EmployeeName)


UPDATE #Final
SET TitleGrouping = 'Dispatch Agent'
WHERE Title in
('Spec I, Sales Contact Center'
,'Spec II, Sales Contact Center'
,'Sales Contact Center Specialist II'
,'Sales Specialist III'
,'Spec II, Sales Contact Center  '
,'Spec III, Sales Contact Center'
) OR Title like 'Spec II, Sales Cnt%'
OR TItle like '%Spec II, Sales Contact%'


UPDATE #Final
SET Title = 'Specialist I, Home Loan'
WHERE EmployeeName = 'Matthew Lawler' and Title is null

UPDATE #Final
SET TitleGrouping = 'Specialist I, Home Loan'
WHERE EmployeeName = 'Matthew Lawler' and TitleGrouping is null

--=====Added 9/2/2015 to identify AEs working neg eq loans, for reporting purposes
Update #Final
Set NegEqFlag = 'Y'
Where
EmployeeName in ('Raffi Tomassian')
and Period >= 201506


Update #Final
Set NegEqFlag = 'Y'
Where
EmployeeName in ('Kyle Pontello')
and Period between 201506 and 201606

Update #Final
Set NegEqFlag = 'Y'
Where
EmployeeName in ('Ozzie Prado')
and Period between 201506 and 201606

Update #Final
Set NegEqFlag = 'Y'
Where
EmployeeName in ('David Hernandez')
and Period between 201506 and 201512



Update #Final
Set NegEqFlag = 'N'
Where NegEqFlag Is Null




/*NCA UPDATE*/
UPDATE #Final
SET TitleGrouping = 'Account Executive', NCAFlag = 'Y'
WHERE Title = 'LO, New Customer Acq' or Title = 'LO, New Customer Acquisition'

UPDATE #Final
SET NCAFlag_Agent = 'Y'
WHERE EmployeeEmail in (
'alecxander.cano@pnmac.com',
'courtney.powell@pnmac.com',
'marvin.stone@pnmac.com',
'melissa.hunter@pnmac.com',
'mosi.moore@pnmac.com',
'stephanie.thornton@pnmac.com',
'sylvia.laija@pnmac.com',
'tina.marshall@pnmac.com',
'yvonda.ganious@pnmac.com',
'amy.hubbard@pnmac.com',
'andrea.coleman@pnmac.com',
'armando.jasso@pnmac.com',
'brandy.lawson@pnmac.com',
'chad.eckols@pnmac.com',
'chad.major@pnmac.com',
'cynthia.mccall@pnmac.com',
'courtney.caldwell@pnmac.com',
'evelyn.smoot@pnmac.com',
'jaerica.chambers@pnmac.com',
'laquita.echols@pnmac.com',
'debbie.graggs@pnmac.com',
'derek.gary@pnmac.com',
'desmond.royal@pnmac.com',
'israel.romero@pnmac.com',
'jarrell.randle@pnmac.com',
'kathryn.ligon@pnmac.com',
'mark.johnson@pnmac.com',
'porchea.mccurdy@pnmac.com',
'ruth.salazar@pnmac.com',
'tamika.toomer@pnmac.com',
'todd.oliver@pnmac.com',
'jennifer.e.brown@pnmac.com',
'jon.kelly@pnmac.com',
'lane.hollis@pnmac.com',
'lorena.garcia@pnmac.com',
'luke.valdemoro@pnmac.com',
'myles.jones@pnmac.com',
'rajon.williams@pnmac.com',
'salonda.mack@pnmac.com',
'shuvonne.allen@pnmac.com',
'xavier.long@pnmac.com',
'yakira.sealey@pnmac.com',
'beonca.washington@pnmac.com',
'elizabeth.reed@pnmac.com',
'jasmine.arolkar@pnmac.com',
'jason.arceneaux@pnmac.com',
'jocelyn.long@pnmac.com',
'christopher.gamez@pnmac.com',
'sabrina.floyd@pnmac.com',
'samantha.eskridge@pnmac.com',
'shamica.mason@pnmac.com'
)

UPDATE #Final
SET
	MFDBenchFlag = 'Y'
WHERE
	Title LIKE '%Bench%'
AND
	Department LIKE '%MFD%'

UPDATE #Final
SET MFDBenchFlag = 'N'
WHERE (Title like '%Manager%' or Title like '%Mgr%' or Title like '%Buffer%')
and OrgTierDescription = 'Offshore'
and MFDBenchFlag = 'Y'

UPDATE #Final
SET BlendFlag = 'Y'
WHERE EmployeeEmail in (
'bryan.devore@pnmac.com',
'darrin.woll@pnmac.com',
'derrick.christensen@pnmac.com',
'dominic.iglesias@pnmac.com',
'earl.nagaran@pnmac.com',
'eric.jones@pnmac.com',
'eric.leonard@pnmac.com',
'eric.leverton@pnmac.com',
'frank.frayer@pnmac.com',
'jacob.powell@pnmac.com',
'jared.fisher@pnmac.com',
'jason.johnson1@pnmac.com',
'jason.johnson@pnmac.com',
'jeremy.rohrer@pnmac.com',
'joe.mckinley@pnmac.com',
'kevin.lovely@pnmac.com',
'marquise.reed@pnmac.com',
'martin.peychev@pnmac.com',
'ross.ahkiong@pnmac.com',
'ryan.finkas@pnmac.com',
'sharon.benites@pnmac.com',
'tracy.corsey@pnmac.com'
) and Period >= 202107


UPDATE #Final
SET BlendFlag = 'Y'
WHERE EmployeeEmail in (
'aaron.arce@pnmac.com',
'adam.adoree@pnmac.com',
'anahit.mkrtchyan@pnmac.com',
'andree.pinson@pnmac.com',
'andrew.nguyen@pnmac.com',
'anthony.mcdevitt@pnmac.com',
'araceli.jimenez@pnmac.com',
'benjamin.wharton@pnmac.com',
'correna.watson@pnmac.com',
'damon.johnson@pnmac.com',
'daniel.kier@pnmac.com',
'derrick.stanley@pnmac.com',
'erind.bisha@pnmac.com',
'sarojni.brij@pnmac.com',
'grae.carson@pnmac.com',
'irik.khoodaverdian@pnmac.com',
'jacob.castro@pnmac.com',
'joel.lamm@pnmac.com',
'john.lantz@pnmac.com',
'jonathan.love@pnmac.com',
'jordan.zilbar@pnmac.com',
'joshua.leatherman@pnmac.com',
'juan.soto@pnmac.com',
'kaylyn.seleman@pnmac.com',
'kim.hong@pnmac.com',
'kyle.vane@pnmac.com',
'mary.karapetyan@pnmac.com',
'max.gavin@pnmac.com',
'meredith.denson@pnmac.com',
'michael.herbst@pnmac.com',
'michael.klein@pnmac.com',
'michael.zajac@pnmac.com',
'morgan.duprey@pnmac.com',
'paul.schweizer@pnmac.com',
'quane.fashaw@pnmac.com',
'randall.alford@pnmac.com',
'ricardo.arreola@pnmac.com',
'rick.busalacchi@pnmac.com',
'roberto.perez@pnmac.com',
'ryan.parr@pnmac.com',
'sonia.lozano@pnmac.com',
'ted.scheidell@pnmac.com',
'tiffany.lewis@pnmac.com',
'youn.lee@pnmac.com',
'zaria.davis@pnmac.com'
) and Period >= 202108

UPDATE #Final
SET BlendFlag = 'Y'
WHERE EmployeeEmail in (
'alec.irwin@pnmac.com',
'ben.erickson@pnmac.com',
'carrie.biondo@pnmac.com',
'daniel.mendoza1@pnmac.com',
'eric.leverton@pnmac.com',
'erica.navarro@pnmac.com',
'gavin.mcpoil@pnmac.com',
'harutyun.atoyan@pnmac.com',
'jason.stevens@pnmac.com',
'joseph.robinson@pnmac.com',
'joshua.benavidez@pnmac.com',
'julia.shupe@pnmac.com',
'karen.montgomery@pnmac.com',
'laurie.baker@pnmac.com',
'madison.salter@pnmac.com',
'matthew.moebius@pnmac.com',
'michael.murray@pnmac.com',
'nicolene.essers@pnmac.com',
'paul.rosadoii@pnmac.com',
'angel.prasad@pnmac.com',
'robert.haviland@pnmac.com',
'tyiona.collins@pnmac.com',
'warren.wilkins@pnmac.com',
'whitney.calta@pnmac.com',
'zachary.knudsen@pnmac.com'
) and Period = 202109
--------------------------------------------
UPDATE F

SET F.BlendTrainingDate = B.BlendTrainingDate

FROM #Final F
left join rrd.dbo.BlendTrainingDates2021 B
ON F.EmployeeEmail = B.EmployeeEmail
--------------------------------------------
UPDATE F

SET F.BlendFlag = 'Y'

FROM #Final F

left join rrd.dbo.BlendTrainingDates2021 B
ON F.EmployeeEmail = B.EmployeeEmail
WHERE F.Period = B.BlendTrainingPeriod
/*========================= BLEND END=====================================*/

/*DISPATCH UPDATE*/
UPDATE #Final
SET TitleGrouping = 'Sup, Dispatch'
WHERE Title like 'Sup, Dispatch%'

/*TITLE UPDATE - INCORRECT HR CHANGES BEGINNING 09/15/2020*/
UPDATE #Final
SET TitleGrouping = 'Account Executive',
	Title = 'Sr Loan Officer'
WHERE Title = 'Sr' and Period >= 202009 and EmployeeName in (
'Aubray Breaux',
'Nathan Riedel',
'Layal Zoueihed',
'Araceli Jimenez',
'Dalia Rodriguez',
'Tyler Smedley',
'Scott Coughlin',
'Jane Riley',
'Jeffrey Smith',
'Edward Taylor',
'Nick Bergh',
'Matthew Hinckley',
'Gary Sahakian',
'Taylor Fiorelli',
'Reid Wright',
'Chris Franklin',
'James Muller',
'Roberto Arias')


/*NAME CHANGES*/
--------------------------------------------------------------------------------------------------------
UPDATE #Final
SET EmployeeName = 'Brandon Ternes'
WHERE EmployeeName = 'R Brandon Ternes' AND EmployeeEmail = 'brandon.ternes@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Jacob Snyder'
where Employeename = 'Jake Snyder' and EmployeeEmail = 'jacob.snyder@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Henry Sorensen'
where Employeename = 'Tyler Sorensen' and EmployeeEmail = 'henry.sorensen@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Matthew Gregson'
where Employeename = 'Matt Gregson' and EmployeeEmail = 'matthew.gregson@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Dominique Benton'
where Employeename = 'Dominique Harge' and EmployeeEmail = 'dominique.benton@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Tshombe Akins'
where Employeename = 'DeeDee Akins' and EmployeeEmail = 'tshombe.akins@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Michael Sannuto'
where Employeename = 'Mike Sannuto' and EmployeeEmail = 'michael.sannuto@pnmac.com'

UPDATE #Final
Set EmployeeName = 'George Ordonez'
where Employeename = 'George Ordonez Sanchez' and EmployeeEmail = 'george.ordonez@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Dale Pancho'
where Employeename = 'DJ Pancho' and EmployeeEmail = 'dale.pancho@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Greg Sarine'
where Employeename = 'Gregory Sarine' and EmployeeEmail = 'gregory.sarine@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Ronald Wright'
where Employeename = 'Ronnie Wright' and EmployeeEmail = 'ronald.wright@pnmac.com'

UPDATE #Final
Set EmployeeName = 'Juan Alvarez'
where Employeename = 'Juan Daniel Alvarez' and EmployeeEmail = 'juan.alvarez@pnmac.com'

Update #Final
Set EmployeeEmail = 'janet.khanibikunle@pnmac.com'
where Employeename = 'Janet Khan-Ibikunle'

Update #Final
Set EmployeeName = 'Joshua T Baker'
where EmployeeEmail = 'joshua.baker2@pnmac.com'

Update #Final
Set EmployeeName = 'Jonathan Pitkevitsch'
where Employeename = 'Jon Pitkevitsch' and EmployeeEmail = 'jonathan.pitkevitsch@pnmac.com'

Update #Final
Set EmployeeName = 'Quteiba Al-Timeemy'
where Employeename = 'Quteiba Al- Timeemy' and EmployeeEmail = 'quteiba.timeemy@pnmac.com'

Update #Final
Set EmployeeName = 'Michael Peluso'
where Employeename = 'Mike Peluso' and EmployeeEmail = 'michael.peluso@pnmac.com'

Update #Final
Set EmployeeName = 'Ernest Howard'
where Employeename = 'Ej Howard' and EmployeeEmail = 'ernest.howard@pnmac.com'

Update #Final
Set EmployeeName = 'William Jameson'
where Employeename = 'Blake Jameson' and EmployeeEmail = 'william.jameson@pnmac.com'

Update #Final
Set EmployeeName = 'Dakota Ballard'
where Employeename = 'Cody Ballard' and EmployeeEmail = 'dakota.ballard@pnmac.com'

Update #Final
Set EmployeeName = 'Michael Tashchyan'
where Employeename = 'Mike Tashchyan' and EmployeeEmail = 'michael.tashchyan@pnmac.com'

Update #Final
Set EmployeeName = 'Terry Brown'
where Employeename = 'TL Brown' and EmployeeEmail = 'terry.brown@pnmac.com'

Update #Final
Set EmployeeName = 'Manuel Guido'
where Employeename = 'Manuel Guido Morales' and EmployeeEmail = 'manuel.guido@pnmac.com'

Update #Final
Set EmployeeName = 'Jeremy Friend'
where Employeename = 'J.J. Friend' and EmployeeEmail = 'jeremy.friend@pnmac.com'

Update #Final
Set EmployeeName = 'James Crowley IV'
where Employeename = 'James Crowley' and EmployeeEmail = 'james.crowleyiv@pnmac.com'

Update #Final
Set EmployeeName = 'Arda Bezjian'
where Employeename = 'Amy Bezjian' and EmployeeEmail = 'arda.bezjian@pnmac.com'

Update #Final
Set EmployeeName = 'Roudvik Abdalian'
where Employeename = 'Roudvik Abdalian Chigani' and EmployeeEmail = 'roudvik.abdalian@pnmac.com'

--Update #Final
--Set EmployeeName = 'Samantha Eskridge', EmployeeEmail = 'samantha.eskridge@pnmac.com'
--where Employeename = 'Samantha Floyd' and EmployeeEmail IN ('samantha.floyd@pnmac.com', 'samantha.eskridge@pnmac.com')

Update #Final
Set EmployeeName = 'Samantha Floyd', EmployeeEmail = 'samantha.floyd@pnmac.com'
where Employeename = 'Samantha Eskridge' and EmployeeEmail IN ('samantha.eskridge@pnmac.com','samantha.floyd@pnmac.com')

Update #Final
Set EmployeeName = 'Kimberly Valdez'
where Employeename = 'Kim Valdez' and EmployeeEmail = 'kimberly.valdez@pnmac.com'

Update #Final
Set EmployeeName = 'Tyler Wynn'
where Employeename = 'Ty WYNN' and EmployeeEmail = 'tyler.wynn@pnmac.com'

UPDATE #Final
SET ManagerName = 'Eddie Machuca'
WHERE ManagerName = 'Eddie Mach' and ManagerEmail = 'eddie.machuca@pnmac.com'

Update #Final
Set EmployeeName = 'Courtney Romanet'
where Employeename = 'Courtney Bettcher' and EmployeeEmail = 'courtney.bettcher@pnmac.com'

Update #Final
Set EmployeeName = 'Bradley Thompson'
where Employeename = 'Brad Thompson' and EmployeeEmail = 'bradley.thompson@pnmac.com'

Update #Final
Set EmployeeName = 'William Chinn'
where Employeename = 'Marcus Chinn' and EmployeeEmail = 'william.chinn@pnmac.com'

Update #Final
Set EmployeeName = 'Robert Woodie'
where Employeename = 'Rob Woodie' and EmployeeEmail = 'robert.woodie@pnmac.com'

Update #Final
Set EmployeeName = 'Truc Le'
where Employeename = 'Amy Le' and EmployeeEmail = 'truc.le@pnmac.com'

Update #Final
Set EmployeeName = 'Jonathan Schulte'
where Employeename = 'Jon Schulte' and EmployeeEmail = 'jonathan.schulte@pnmac.com'

Update #Final
Set EmployeeName = 'Roberto Annoni'
where Employeename = 'Roberto Annoni Fuertes' and EmployeeEmail = 'roberto.annoni@pnmac.com'

Update #Final
Set EmployeeName = 'Yoonji Yeom'
where Employeename = 'Jane Yeom' and EmployeeEmail = 'yoonji.yeom@pnmac.com'


Update #Final
Set EmployeeName = 'Ronald Braxton'
where Employeename = 'Ronnie Braxton' and EmployeeEmail = 'ronald.braxton@pnmac.com'

Update #Final
Set EmployeeName = 'Christopher Muncal'
where Employeename = 'Chris Muncal' and EmployeeEmail = 'christopher.muncal@pnmac.com'

Update #Final
Set EmployeeName = 'William Caldwell'
where Employeename = 'Will Caldwell' and EmployeeEmail = 'william.caldwell@pnmac.com'

Update #Final
Set EmployeeName = 'Alexa Michael'
where Employeename = 'Alexa Mocanu' and EmployeeEmail = 'alexa.michael@pnmac.com'

Update #Final
Set EmployeeName = 'Tedrig Khachadore'
where Employeename = 'Ted Khachadore' and EmployeeEmail = 'tedrig.khachadore@pnmac.com'

Update #Final
Set EmployeeName = 'Varuzhan Hakobyan'
where Employeename = 'Varuzh Hakobyan' and EmployeeEmail = 'varuzhan.hakobyan@pnmac.com'

Update #Final
Set EmployeeName = 'Harold Miller'
where Employeename = 'David Miller' and EmployeeEmail = 'david.miller@pnmac.com'

Update #Final
Set EmployeeName = 'Zohaib Malik'
where Employeename = 'Zach Malik' and EmployeeEmail = 'zohaib.malik@pnmac.com'

Update #Final
Set EmployeeName = 'Jasmine Westmoreland'
where Employeename = 'Phoenix Westmoreland' and EmployeeEmail = 'jasmine.westmoreland@pnmac.com'

Update #Final
Set EmployeeName = 'Tommy Jackson'
where Employeename = 'Ace Jackson' and EmployeeEmail = 'tommy.jackson@pnmac.com'

Update #Final
Set EmployeeName = 'Gregory Lee'
where Employeename = 'Greg Lee' and EmployeeEmail = 'gregory.lee1@pnmac.com'

Update #Final
Set EmployeeName = 'Joseph Hoffie'
where Employeename = 'Joe Hoffie' and EmployeeEmail = 'joseph.hoffie@pnmac.com'

Update #Final
Set EmployeeName = 'Michael Haidar'
where Employeename = 'Michael Haider' and EmployeeEmail = 'michael.haider@pnmac.com'

Update #Final
Set EmployeeName = 'Andrew Starley'
where Employeename = 'Andy Starley' and EmployeeEmail = 'andrew.starley@pnmac.com'

Update #Final
Set EmployeeName = 'Jesus Renteria'
where Employeename = 'Jessie Renteria' and EmployeeEmail = 'jesus.renteria@pnmac.com'

Update #Final
Set EmployeeName = 'Phillip Brown'
where Employeename = 'Phil Brown' and EmployeeEmail = 'phillip.brown1@pnmac.com'

Update #Final
Set EmployeeName = 'Maged Nashid'
where Employeename = 'Mike Nashid' and EmployeeEmail = 'maged.nashid@pnmac.com'

Update #Final
Set EmployeeName = 'Clinton Northcutt'
where Employeename = 'Clint Northcutt' and EmployeeEmail = 'clinton.northcutt@pnmac.com'

Update #Final
Set EmployeeName = 'Jacqueline Sgro'
where Employeename = 'Jackie Sgro' and EmployeeEmail = 'jacqueline.sgro@pnmac.com'

Update #Final
Set EmployeeName = 'Jimmie Limon Jr'
where Employeename = 'Jimmie Limon' and EmployeeEmail = 'jimmie.limon@pnmac.com'

Update #Final
Set EmployeeName = 'DeLoria Robinson'
where Employeename = 'De’Loria Robinson' and EmployeeEmail = 'deloria.robinson@pnmac.com'

Update #Final
Set EmployeeName = 'Truong Le'
where Employeename = 'Paul Le' and EmployeeEmail = 'truong.le@pnmac.com'

Update #Final
Set EmployeeName = 'Darcell Hagins'
where Employeename = 'Darcell Thomas Thomas' and EmployeeEmail = 'darcell.hagins@pnmac.com'

Update #Final
Set EmployeeName = 'Tashia Hoekstra'
where Employeename = 'Tashia Hoektra' and EmployeeEmail = 'tashia.hoekstra@pnmac.com'

Update #Final
Set EmployeeName = 'Russ Martin'
where Employeename= 'Russell Martin' and EmployeeEmail = 'russell.martin@pnmac.com'

Update #Final
Set EmployeeName = 'Susan Flores'
where Employeename= 'Sammy Flores' and EmployeeEmail = 'susan.flores@pnmac.com'

Update #Final
Set EmployeeName = 'Lisa Woltz'
where Employeename= 'Lisa Hauke' and EmployeeEmail = 'lisa.woltz@pnmac.com'

Update #Final
Set EmployeeName = 'Madison Salter'
where Employeename= 'Madison Grogg' and EmployeeEmail = 'madison.salter@pnmac.com'

Update #Final
Set EmployeeName = 'De’Loria Robinson'
where Employeename= 'De?Loria Robinson' and EmployeeEmail = 'deloria.robinson@pnmac.com'

Update #Final
Set EmployeeName = 'Pamela Wilcox'
where EmployeeName='Pam Wilcox' and EmployeeEmail = 'pamela.wilcox@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Christopher Coleman'
WHERE EmployeeName = 'Chris Coleman' and EmployeeEmail = 'christopher.coleman@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Juan Alvarez'
WHERE EmployeeName = 'Daniel Alvarez' and EmployeeEmail = 'juan.alvarez@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Michael Mikulich'
WHERE EmployeeName = 'Michael L Mikulich' and EmployeeEmail = 'michael.mikulich@pnmac.com'

UPDATE #Final
SET EmployeeName = 'David Clark'
WHERE EmployeeName = 'Dave Clark' and EmployeeEmail = 'david.clark@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Joshua Hylan'
WHERE EmployeeName = 'Josh Hylan' and EmployeeEmail = 'joshua.hylan@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Wesley Marsh'
WHERE EmployeeName = 'Wes Marsh' and EmployeeEmail = 'wesley.marsh@pnmac.com'

UPDATE #Final
SET EmployeeName = 'James Randall'
WHERE EmployeeName = 'Dave Randall' and EmployeeEmail = 'james.randall@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Matthew Mcglinn'
WHERE EmployeeName = 'Matt Mcglinn' and EmployeeEmail = 'matthew.mcglinn@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Anthony Gonzales'
WHERE EmployeeName = 'Tony Gonzales' and EmployeeEmail = 'anthony.gonzales@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Samuel Uzzan'
WHERE EmployeeName = 'Sam Uzzan' and EmployeeEmail = 'samuel.uzzan@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Siena Lee' , EmployeeEmail = 'siena.lee@pnmac.com'
WHERE EmployeeName = 'Kyungmi Lee' and EmployeeEmail = 'kyungmi.lee@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Joseph Ferrante'
WHERE EmployeeName = 'Joe Ferrante' and EmployeeEmail = 'joseph.ferrante@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Joseph Gallo'
WHERE EmployeeName = 'Joe Gallo' and EmployeeEmail = 'joseph.gallo@pnmac.com'

UPDATE #Final
SET EmployeeName = 'William Caylor'
WHERE EmployeeName = 'Austin Caylor' and EmployeeEmail = 'william.caylor@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Sharon Luckett'
WHERE EmployeeName = 'Shay Luckett' and EmployeeEmail = 'sharon.luckett@pnmac.com'

UPDATE #Final
SET EmployeeName = 'John McCafferty'
WHERE EmployeeName = 'Drew McCafferty' and EmployeeEmail = 'john.mccafferty@pnmac.com'

UPDATE #Final
SET ManagerName = 'Anthony Trozera'
WHERE ManagerName = 'Tony Trozera' and ManagerEmail = 'anthony.trozera@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Candace Daramola'
WHERE EmployeeName = 'Delori Daramola' and EmployeeEmail = 'candace.daramola@pnmac.com'

UPDATE #Final
SET EmployeeName = 'James Young'
WHERE EmployeeName = 'Rick Young' and EmployeeEmail = 'james.young@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Andrew Pena'
WHERE EmployeeEmail = 'andrew.pena@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Nicholas Massari'
WHERE EmployeeName = 'Nick Massari' and EmployeeEmail = 'nicholas.massari@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Nicholas Hunter'
WHERE EmployeeName = 'Nick Hunter' and EmployeeEmail = 'nicholas.hunter@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Peter Perez'
WHERE EmployeeName = 'Pete Perez' and EmployeeEmail = 'peter.perez@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Artuz Manning Jr'
WHERE EmployeeName = 'Artuz Manning' and EmployeeEmail = 'artuz.manning@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Chris Nicholson'
WHERE EmployeeName = 'Christopher Nicholson' and EmployeeEmail = 'chris.nicholson@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Abayomi Famuyiwa'
WHERE EmployeeName = 'Yomi Famuyiwa' and EmployeeEmail = 'abayomi.famuyiwa@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jon Rosenthal'
WHERE EmployeeName = 'JT Rosenthal' and EmployeeEmail = 'jon.rosenthal@pnmac.com'

UPDATE #Final
SET EmployeeName = 'David Westfall'
WHERE EmployeeName = 'Dave Westfall' and EmployeeEmail = 'david.westfall@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Elizabeth Cahill'
WHERE EmployeeName = 'Liz Cahill' and EmployeeEmail = 'elizabeth.cahill@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Pavandeep Mann'
WHERE EmployeeName = 'Pavan Mann' and EmployeeEmail = 'pavandeep.mann@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Alberto De Leon'
WHERE EmployeeName = 'Alberto Leon' and EmployeeEmail = 'alberto.leon@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Cynthia Crouse'
WHERE EmployeeName = 'Cindy Crouse' and EmployeeEmail = 'cynthia.crouse@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Tynisha Robinson'
WHERE EmployeeName = 'Ty Robinson' and EmployeeEmail = 'tynisha.robinson@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Matthew Rittenhouse'
WHERE EmployeeName = 'Matt Rittenhouse' and EmployeeEmail = 'matthew.rittenhouse@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Michael Zajac'
WHERE EmployeeName = 'Mike Zajac' and EmployeeEmail = 'michael.zajac@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Al Nasser'
WHERE EmployeeName = 'Al Al Nasser' and EmployeeEmail = 'al.nasser@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Al Nasser'
WHERE EmployeeName = 'Al Al Nasser' and EmployeeEmail = 'al.nasser@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Maziar Alagheband'
WHERE EmployeeName = 'Mazi Alagheband' and EmployeeEmail = 'maziar.alagheband@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Ali Shams'
WHERE EmployeeName = 'Eli Shams' and EmployeeEmail = 'ali.shams@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'JohnCarlo Menjivar'
WHERE EmployeeName = 'John Menjivar' and EmployeeEmail = 'johncarlo.menjivar@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Yvonne Holloway'
WHERE EmployeeName = 'Bonnie Holloway' and EmployeeEmail = 'yvonne.holloway@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Gabriel Phelps'
WHERE EmployeeName = 'Gabe Phelps' and EmployeeEmail = 'gabriel.phelps@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Christopher Sapienza'
WHERE EmployeeName = 'Chris Sapienza' and EmployeeEmail = 'christopher.sapienza@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Daniel Poling'
WHERE EmployeeName = 'Dan Poling' and EmployeeEmail = 'daniel.poling@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'William Fitch'
WHERE EmployeeName = 'Brad Fitch' and EmployeeEmail = 'william.fitch@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Christopher Toler'
WHERE EmployeeName = 'Chris Toler' and EmployeeEmail = 'christopher.toler@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Josh Siguenza'
WHERE EmployeeName = 'Joshua Siguenza' and EmployeeEmail = 'josh.siguenza@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Anastasios Marcopulos'
WHERE EmployeeName = 'Taso Marcopulos' and EmployeeEmail = 'anastasios.marcopulos@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'James Bushong'
WHERE EmployeeName = 'Travis Bushong' and EmployeeEmail = 'james.bushong@pnmac.com' and Period >= 202106

UPDATE #Final
SET EmployeeName = 'Josh Baker'
WHERE EmployeeName = 'Joshua Baker' and EmployeeEmail = 'josh.baker@pnmac.com' and Period >= 202105

UPDATE #Final
SET EmployeeName = 'Yaladhit Chavez'
WHERE EmployeeName = 'Yaladait Chavez' and EmployeeEmail = 'yaladhit.chavez@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jaime Palacios'
WHERE EmployeeName = 'JP Palacios' and EmployeeEmail = 'jaime.palacios@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Raymond Hays'
WHERE EmployeeName = 'Ray Hays' and EmployeeEmail = 'raymond.hays@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Ronald Gilmore'
WHERE EmployeeName = 'Ron Gilmore' and EmployeeEmail = 'ronald.gilmore@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Rafael Cortez Jr'
WHERE EmployeeName = 'Ralph Cortez' and EmployeeEmail = 'rafael.cortez@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Babak Javaherpour'
WHERE EmployeeName = 'Bobby Javaherpour' and EmployeeEmail = 'babak.javaherpour@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Christopher Aziz'
WHERE EmployeeName = 'Chris Aziz' and EmployeeEmail = 'christopher.aziz@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Deisy Alvarez'
WHERE EmployeeName = 'Daisy Alvarez Hernandez' and EmployeeEmail = 'deisy.alvarez@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Huong Tran'
WHERE EmployeeName = 'Lynn Tran' and EmployeeEmail = 'huong.tran@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Andrew Miller'
WHERE EmployeeName = 'Drew Miller' and EmployeeEmail = 'andrew.miller@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Madison Brown'
WHERE EmployeeName = 'Madi Brown' and EmployeeEmail = 'madison.brown@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Daniel Graziosi'
WHERE EmployeeName = 'Danny Graziosi' and EmployeeEmail = 'daniel.graziosi@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Latoya Johnson'
WHERE EmployeeName = 'LaToya Johnson Anderson' and EmployeeEmail = 'latoya.johnson@pnmac.com'

UPDATE #Final
SET EmployeeName = 'LaQuasha Smith'
WHERE EmployeeName = 'Asia Smith' and EmployeeEmail = 'laquasha.smith@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jeffery Dorothy'
WHERE EmployeeName = 'Jeff Dorothy' and EmployeeEmail = 'jeffery.dorothy@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Yahnee Russell'
WHERE EmployeeName = 'Luci Russell' and EmployeeEmail = 'yahnee.russell@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Yvonne Stancil'
WHERE EmployeeName = 'Renee Geikler' and EmployeeEmail = 'yvonne.stancil@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jonghyun Lee'
WHERE EmployeeName = 'John Lee' and EmployeeEmail = 'jonghyun.lee@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Leina Seneres'
WHERE EmployeeName = 'Eysvetleina Seneres' and EmployeeEmail = 'eysvetleina.seneres@pnmac.com'

UPDATE #Final
SET EmployeeName = 'RayLeisha Lane'
WHERE EmployeeName = 'Ray Lane' and EmployeeEmail = 'rayleisha.lane@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Andres Lopez'
WHERE EmployeeName = 'Andrew Lopez' and EmployeeEmail = 'andres.lopez1@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Shacoriya Easterly'
WHERE EmployeeName = 'Shacee Easterly' and EmployeeEmail = 'shacoriya.easterly@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Michael Ellerbeck'
WHERE EmployeeName = 'Mike Ellerbeck' and EmployeeEmail = 'michael.ellerbeck@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Ted Scheidell'
WHERE EmployeeName = 'Ted Scheidell-Paholski' and EmployeeEmail = 'ted.scheidell@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Nicole Stober'
WHERE EmployeeName = 'Nikki Stober' and  EmployeeEmail = 'nicole.stober@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Angelica Posada',
    EmployeeEmail = 'angelica.posada@pnmac.com'
WHERE EmployeeName = 'Angie Posada'

UPDATE #Final
SET EmployeeName = 'Christopher Johnson',
    EmployeeEmail = 'christopher.johnson@pnmac.com'
WHERE EmployeeName = 'Chris Johnson'

UPDATE #Final
SET EmployeeName = 'Kathryn Lesseur',
    EmployeeEmail = 'kathryn.lesseur@pnmac.com'
WHERE EmployeeName = 'Kathyrn Lesseur'

UPDATE #Final
SET EmployeeName = 'Benjamin Mygatt'
WHERE EmployeeName = 'Ben Mygatt' and EmployeeEmail = 'benjamin.mygatt@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Andrea Hopkins'
WHERE EmployeeName = 'Drea Hopkins' and EmployeeEmail = 'andrea.hopkins@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Brandon Avila_RLS'
WHERE TitleGrouping = 'Specialist, Loan Refinance'
and EmployeeName = 'Brandon Avila'
and EmployeeEmail = 'brandon.avila1@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Ricardo Campos'
WHERE EmployeeName = 'Rick Campos' and EmployeeEmail = 'ricardo.campos1@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Mike Mekler'
WHERE EmployeeName = 'Michael Mekler' and EmployeeEmail = 'mike.mekler@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Paul Rosado II'
WHERE EmployeeName = 'Paul Rosado' and EmployeeEmail = 'paul.rosadoii@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Mike Agne'
WHERE EmployeeName = 'Michael Agne' and EmployeeEmail = 'mike.agne@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Samantha Agle'
WHERE EmployeeName = 'Sam Agle' and EmployeeEmail = 'samantha.agle@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Robert Nielsen'
WHERE EmployeeName = 'Bob Nielsen' and EmployeeEmail = 'robert.nielsen@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Joshua Dutton'
WHERE EmployeeName = 'Josh Dutton' and EmployeeEmail = 'joshua.dutton@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jonathan Love'
WHERE EmployeeName = 'Jay Love' and EmployeeEmail = 'jonathan.love@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Rudolph Galas'
WHERE EmployeeName = 'Brock Galas' and EmployeeEmail = 'rudolph.galas@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Berenice Orozco'
WHERE EmployeeName = 'B Orozco' and EmployeeEmail = 'berenice.orozco@pnmac.com'

UPDATE #Final
SET EmployeeName = 'John-Paul Pettus'
WHERE EmployeeName = 'JP Pettus' and EmployeeEmail = 'john.pettus@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Juliette Lee'
WHERE EmployeeName in ('Julie Tan','Juliette Lee Tan') and EmployeeEmail = 'juliette.lee@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Richard Previdi'
WHERE EmployeeName = 'Rick Previdi' and EmployeeEmail = 'richard.previdi@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Maria Fortin'
WHERE EmployeeName = 'Angelica Fortin' and EmployeeEmail = 'maria.fortin@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Lamanda Heil'
WHERE EmployeeName = 'Mandy Heil' and EmployeeEmail = 'lamanda.heil@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Lawanda Ivy'
WHERE EmployeeName = 'Wanda Ivy' and EmployeeEmail = 'lawanda.ivy@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Raúl Macias'
WHERE EmployeeName in ('Ra?l Macias', 'Raul Macias') and EmployeeEmail = 'raul.macias@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Gregory Stage Jr'
WHERE EmployeeName = 'Greg Stage' and EmployeeEmail = 'gregory.stage@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Sokhom Sim'
WHERE EmployeeName = 'Kenny Sim' and EmployeeEmail = 'sokhom.sim@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jonathan Espinoza'
WHERE EmployeeName = 'Jon Espinoza' and EmployeeEmail = 'jonathan.espinoza@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Donald Williams'
WHERE EmployeeName = 'Don Williams' and EmployeeEmail = 'donald.williams@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Sejong Killian'
WHERE EmployeeName = 'SJ Killian' and EmployeeEmail = 'sj.killian@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Thomas Wahl'
WHERE EmployeeName = 'Tommy Wahl' and EmployeeEmail = 'thomas.wahl@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jeffrey Johnson'
WHERE EmployeeName = 'Jeff Johnson' and EmployeeEmail = 'jeffrey.johnson@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Valeria Saravia'
WHERE EmployeeName = 'Valerie Saravia' and EmployeeEmail = 'valeria.saravia@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Gabrielle Simo'
WHERE EmployeeName = 'Numbiah Simo' and EmployeeEmail = 'gabrielle.simo@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Andrew Abrams'
WHERE EmployeeName = 'Drew Abrams' and EmployeeEmail = 'andrew.abrams@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Zachary Knudsen'
WHERE EmployeeName = 'Zach Knudsen' and EmployeeEmail = 'zachary.knudsen@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Josie Andrade'
WHERE EmployeeName = 'Josefina Andrade' and EmployeeEmail = 'josefina.andrade@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Christina Romero'
WHERE EmployeeName = 'Christina A. Romero' and EmployeeEmail = 'christina.romero1@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jah''eesh Brown'
WHERE EmployeeName = 'Shilay Brown' and EmployeeEmail = 'shilay.brown@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Katelyn Shea'
WHERE EmployeeName = 'Katie Shea' and EmployeeEmail = 'katelyn.shea@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Nicholas Guerrero'
WHERE EmployeeName = 'Nick Guerrero' and EmployeeEmail = 'nicholas.guerrero@pnmac.com'

UPDATE #Final
SET EmployeeEmail = 'tashae.davis@pnmac.com'
WHERE EmployeeName = 'Tashae Davis' and EmployeeEmail = 'old.tashae.davis@pnmac.com'

Update #Final
Set EmployeeName = 'Tashia Hoekstra'
Where EmployeeName = 'Tashia Hoesktra' and EmployeeEmail = 'tashia.hoektra@pnmac.com'

Update #Final
Set EmployeeName = 'Charles Norice III'
Where EmployeeName = 'Charles Norice' and EmployeeEmail = 'charles.norice@pnmac.com'

Update #Final
Set EmployeeName = 'Barbara Smith'
Where EmployeeName = 'Becky Smith' and EmployeeEmail = 'barbara.smith@pnmac.com'

Update #Final
Set EmployeeName = 'Theaurty Howard Jr'
Where EmployeeName = 'Theaurty Howard' and EmployeeEmail = 'theaurty.howard@pnmac.com'

Update #Final
Set EmployeeName = 'Michael Pemberton'
Where EmployeeName = 'Mike Pemberton' and EmployeeEmail = 'michael.pemberton@pnmac.com'

Update #Final
Set EmployeeName = 'Manuel Cobos'
Where EmployeeName = 'Manny Cobos' and EmployeeEmail = 'manuel.cobos@pnmac.com'

Update #Final
Set EmployeeName = 'Margaret Erickson'
Where EmployeeName = 'Maggie Erickson' and EmployeeEmail = 'margaret.erickson@pnmac.com'

Update #Final
Set EmployeeFirstName = 'Alexander',
	EmployeeLastName = 'Soria',
	EmployeeName = 'Alexander Soria'
Where EmployeeName = 'Alex Soria' and EmployeeEmail = 'alexander.soria@pnmac.com'

Update #Final
Set EmployeeName = 'Anna Chao Bond'
Where EmployeeName = 'Anna Chao' and EmployeeEmail = 'anna.bond@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Barbara Dudzienski'
WHERE EmployeeName = 'Barb Dudzienski' and EmployeeEmail = 'barbara.dudzienski@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Abbas Suliman'
WHERE EmployeeName = 'Abby Suliman' and EmployeeEmail = 'abbas.suliman@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Melissa Franklin'
WHERE EmployeeName = 'Missy Franklin' and EmployeeEmail = 'melissa.franklin1@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Eleonor Del Rosario Navarro'
WHERE EmployeeName = 'Eleonor Del Rosario,Navarro'

UPDATE #Final
SET EmployeeName = 'Abigail Rogers'
WHERE EmployeeName = 'Abby Rogers' and EmployeeEmail = 'abigail.rogers@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Jerold Dienes'
WHERE EmployeeName = 'Jerry Dienes' and EmployeeEmail = 'jerold.dienes@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Russ Martin'
WHERE EmployeeName = 'Horacio Martin' and EmployeeEmail = 'russell.martin@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Michael Herbst'
WHERE EmployeeName = 'Mike Herbst'

UPDATE #Final
SET EmployeeName = 'Lori Ann Gibson'
WHERE EmployeeName = 'Lori Gibson'

UPDATE #Final
SET EmployeeName = 'Gerald Beaudette'
WHERE EmployeeName = 'Gerry Beaudette'

UPDATE #Final
SET EmployeeName = 'Matthew Thorpe'
WHERE EmployeeName = 'Matt Thorpe'

UPDATE #Final
SET EmployeeName = 'Rabon Patterson'
WHERE EmployeeName = 'Michael Patterson'

UPDATE #Final
SET EmployeeName = 'Rabon Patterson'
WHERE EmployeeName = 'Michael Patterson Patterson'

UPDATE #Final
SET EmployeeName = 'Daniel Postak'
WHERE EmployeeName = 'Dan Postak'

UPDATE #Final
SET ManagerName = 'Daniel Postak'
WHERE ManagerName = 'Dan Postak'

UPDATE #Final
SET EmployeeName = 'Eliud Rodriguez'
WHERE EmployeeName = 'Danny Rodriguez'

UPDATE #Final
SET EmployeeName = 'Shaun Riley'
WHERE EmployeeName = 'Ashaundy Riley'

UPDATE #Final
SET EmployeeName = 'Dennis Giardina'
WHERE EmployeeName = 'Denny Giardina'

UPDATE #Final
SET EmployeeName = 'Brittany Fischer'
WHERE EmployeeName = 'Britt Fischer'

UPDATE #Final
SET EmployeeName = 'Alexandra Omalley'
WHERE EmployeeName = 'Alexandra O''Malley'

UPDATE #Final
SET EmployeeName = 'Christopher Markes'
WHERE EmployeeName = 'Chris Markes'

UPDATE #Final
SET EmployeeName = 'James Wetsel'
WHERE EmployeeName = 'Reagan Wetsel'

UPDATE #Final
SET EmployeeName = 'Rebecca Holland'
WHERE EmployeeName = 'Becca Holland'

UPDATE #Final
SET EmployeeName = 'Nathaniel Clark'
WHERE EmployeeName = 'Nate Clark'

UPDATE #Final
SET EmployeeName = 'Samuel Velick'
WHERE EmployeeName = 'Sammy Velick'

UPDATE #Final
SET EmployeeName = 'Ronsha Lawson'
WHERE EmployeeName = 'Shay Lawson Lawson'

UPDATE #Final
SET EmployeeEmail = 'eddie.bailey@pnmac.com'
WHERE EmployeeEmail = 'william.bailey@pnmac.com'

UPDATE #Final
SET ManagerEmail = 'eddie.bailey@pnmac.com'
WHERE ManagerEmail = 'william.bailey@pnmac.com'

--REMOVED ON 09/24/2020 TO MATCH NEW ENCOMPASS PROFILE THAT WAS UPDATED/CONSOLIDATED ON THE CDL REPORTING HUB
--UPDATE #Final
--SET EmployeeName = 'Ivonne Cordero'
--WHERE EmployeeName = 'Ivonne Cordero-Calderon'

UPDATE #Final --UPDATED ON 09/24/2020 TO MATCH NEW ENCOMPASS PROFILE THAT WAS UPDATED/CONSOLIDATED ON THE CDL REPORTING HUB
SET EmployeeName = 'Ivonne Cordero-Calderon'
WHERE EmployeeName = 'Ivonne Cordero'

UPDATE #Final
SET EmployeeName = 'Timothy King'
WHERE EmployeeName = 'Tim King'

UPDATE #Final
SET EmployeeName = 'Abed Almaoui'
WHERE EmployeeName = 'Alex Almaoui'

UPDATE #Final
SET EmployeeName = 'Adejumoke Dosunmu'
WHERE EmployeeName = 'Addy Dosunmu'

UPDATE #Final
SET EmployeeName = 'Kim Hong'
WHERE EmployeeName = 'KIM HONG'

UPDATE #Final
SET EmployeeName = 'Brian Butler'
WHERE EmployeeName = 'BRIAN Butler'

UPDATE #Final
SET EmployeeName = 'Maria Espana'
WHERE EmployeeName = 'Maria Espa?a'

UPDATE #Final
SET EmployeeName = 'Timothy Woods'
WHERE EmployeeName = 'Tim Woods'

UPDATE #Final
SET EmployeeName = 'Michael Payne'
WHERE EmployeeName = 'Mike Payne'

UPDATE #Final
SET EmployeeName = 'Juan Soto'
WHERE EmployeeName = 'Juan Carlos Soto'

Update #Final
Set EmployeeName = 'Moiralanna Nolan'
Where EmployeeName = 'Mo Nolan' and EmployeeEmail = 'moiralana.nolan@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Moiralanna Nolan' --MISPELLED WITH ONE N
WHERE EmployeeName = 'Moiralana Nolan' and EmployeeEmail = 'moiralana.nolan@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Norman Jr Dominado Aves'
WHERE EmployeeName = 'Norman Dominado Aves'

UPDATE #Final
SET EmployeeName = 'Cristobal Garcia'
WHERE EmployeeName = 'Chris Garcia' and EmployeeEmail = 'cristobal.garcia@pnmac.com'

UPDATE #Final
SET EmployeeName = 'Donald Carlson'
WHERE EmployeeName = 'Don Carlson'

UPDATE #Final
SET EmployeeName = 'Travis John Lemley'
WHERE EmployeeName = 'Travis Lemley'

UPDATE #Final
SET ManagerName = 'Travis John Lemley'
WHERE ManagerName = 'Travis Lemley'

UPDATE #Final
SET EmployeeName = 'Barry Clay II'
WHERE EmployeeName = 'Michael Clay'

UPDATE #Final
SET EmployeeName = 'Jeremiah Kneeland'
WHERE EmployeeName = 'Jay Kneeland'

UPDATE #Final
SET EmployeeName = 'Thomas Zinschlag'
WHERE EmployeeName = 'Tom Zinschlag'

UPDATE #Final
SET ManagerName = 'Thomas Zinschlag'
WHERE ManagerName = 'Tom Zinschlag'

UPDATE #Final
SET EmployeeName = 'Michael Powers'
WHERE EmployeeName = 'Mike Powers'

UPDATE #Final
SET EmployeeName = 'Gwendolyn Drury'
WHERE EmployeeName = 'Gwen Drury'

UPDATE #Final
SET EmployeeName = 'Alexis Borilla'
WHERE EmployeeName = 'Alexis Marc Borilla'

UPDATE #Final
SET EmployeeName = 'Catabona Victoria'
WHERE EmployeeName = 'Catabona Maria Victoria'

UPDATE #Final
SET EmployeeName = 'Emma Ruth Robles'
WHERE EmployeeName = 'Emma Robles'

UPDATE #Final
SET EmployeeName = 'Ligaya Rotol'
WHERE EmployeeName = 'Ligaya Joy Rotol'

UPDATE #Final
SET EmployeeName = 'Mary Grace Cruz'
WHERE EmployeeName = 'Mary Cruz'

UPDATE #Final
SET EmployeeName = 'Rem Villanueva'
WHERE EmployeeName = 'Rem Renz Villanueva'

UPDATE #Final
SET EmployeeName = 'Sheryl Macairan'
WHERE EmployeeName = 'Sheryl Cargando Macairan'





UPDATE #Final
SET EmployeeName = 'Joi Holliday'
WHERE EmployeeName = 'Joi Blakemore'

UPDATE #Final
SET EmployeeName = 'Kristen Sprang'
WHERE EmployeeName = 'Kristen Griffin'

UPDATE #Final
SET EmployeeName = 'Royal Cameron'
WHERE EmployeeName = 'Royal Ihrig-Cameron'

UPDATE #Final
SET EmployeeName = 'Sevak Abkarian'
WHERE EmployeeName = 'Sev Abkarian'

UPDATE #Final
SET EmployeeName = 'Antonio Torres'
WHERE EmployeeName = 'Tony Torres'

--REMOVED DUE TO FALSE CHANGE
--UPDATE #Final
--SET EmployeeName = 'Kenny Barrientos'
--WHERE EmployeeName = 'Kenney Barrientos'

--REMOVED DUE TO FALSE CHANGE
--UPDATE #Final
--SET EmployeeName = 'Jeremey Hain'
--WHERE EmployeeName = 'Jeremy Hain'

UPDATE #Final
SET EmployeeName = 'Nina Moshiri'
WHERE EmployeeName = 'Nina Moshirisfahini'

UPDATE #Final
SET EmployeeName = 'Douglas Vorbeck'
WHERE EmployeeName = 'Doug VORBECK'

UPDATE #Final
SET EmployeeName = 'Nicole Payne'
WHERE EmployeeName = 'Nic Payne'

UPDATE #Final
SET EmployeeName = 'Lisa-Danielle Lane'
WHERE EmployeeName = 'Danielle Lane'

UPDATE #Final
SET EmployeeName = 'Joshua Nelson'
WHERE EmployeeName = 'Josh Nelson'

UPDATE #Final
SET EmployeeName = 'John Kimble Jr'
WHERE EmployeeName = 'John Kimble'

UPDATE #Final
SET EmployeeName = 'Linda Frazier'
WHERE EmployeeName = 'Linda Mayfield Frazier'

/*REMOVED ON 7/21 DUE TO MISMATCH TO ENCOMPASS
UPDATE #Final
SET EmployeeName = 'David Morales'
WHERE EmployeeName = 'Franky Morales' and EmployeeEmail = 'david.morales@pnmac.com'
*/

UPDATE #Final
SET EmployeeName = 'Nicholas Spencer'
WHERE EmployeeName = 'Nick Spencer'

UPDATE #Final
SET EmployeeName = 'Patricia Nicholas'
WHERE EmployeeName = 'Tricia Nicholas'

--UPDATE #Final --REMOVED BY CHARLIE ON 07/10/2020
--SET EmployeeName = 'Jose Chanaba'
--WHERE EmployeeName = 'Jose Chanaba Guerrero'

--UPDATE #Final --REMOVED BY CHARLIE ON 07/10/2020
--SET EmployeeName = 'Matthew Baronich'
--WHERE EmployeeName = 'Matt Baronich'

--UPDATE #Final --REMOVED BY CHARLIE ON 07/10/2020
--SET EmployeeName = 'Diego Castellanos'
--WHERE EmployeeName = 'Diego Castellanos Sahagun'

--UPDATE #Final --REMOVED BY CHARLIE ON 07/10/2020
--SET EmployeeName = 'Cynthia McCall'
--WHERE EmployeeName = 'Cindy McCall'

UPDATE #Final
SET EmployeeName = 'Christopher Butner'
WHERE EmployeeName = 'Chris Butner'

UPDATE #Final
SET EmployeeName = 'Beverly Lynch'
WHERE EmployeeName = 'Anita Lynch'

UPDATE #Final
SET EmployeeName = 'Matthew Gillespie'
WHERE EmployeeName = 'Matt Gillespie'

UPDATE #Final
SET EmployeeName = 'Clinton Harris'
WHERE EmployeeName = 'Clint Harris'

	UPDATE #Final
	SET ManagerName = 'Clinton Harris'
	WHERE ManagerName = 'Clint Harris'

UPDATE #Final
SET EmployeeName = 'Nicholas Gilliam'
WHERE EmployeeName = 'Cole Gilliam'

UPDATE #Final
SET EmployeeName = 'Jacob Grubb'
WHERE EmployeeName = 'Jake Grubb'

UPDATE #Final
SET EmployeeName = 'Mark Guillermo'
WHERE EmployeeName = 'Mark-Daniel Guillermo'

UPDATE #Final
SET EmployeeName = 'Alvaro Vaca'
WHERE EmployeeName = 'AJ Vaca'

UPDATE #Final
SET EmployeeName = 'Maxwell Mitchell'
WHERE EmployeeName = 'Max Mitchell'

UPDATE #Final
SET EmployeeName = 'Angelique Muccio'
WHERE EmployeeName = 'Tina Muccio'

UPDATE #Final
SET EmployeeName = 'Guillom Hines'
WHERE EmployeeName = 'G Hines'

UPDATE #Final
SET EmployeeName = 'Shauntelle Walker'
WHERE EmployeeName = 'Shauntel Walker'

UPDATE #Final
SET EmployeeName = 'Charles Shepherd'
WHERE EmployeeName = 'Van Shepherd'

UPDATE #Final
SET EmployeeName = 'Quintrell Hillard'
WHERE EmployeeName = 'Que Hillard'

UPDATE #Final
SET EmployeeName = 'Judith Navarro Perez'
WHERE EmployeeName = 'Judy Navarro Perez'

UPDATE #Final
SET EmployeeName = 'Michael Peterson'
WHERE EmployeeName = 'Mike Peterson'

UPDATE #Final
SET EmployeeName = 'Greg Johnston'
WHERE EmployeeName = 'Gregory Johnston'

UPDATE #Final
SET EmployeeName = 'Michael Henry'
WHERE EmployeeName = 'Mike Henry'

Update #Final
Set Employeename = 'Isabella Mislinay'
Where Employeename = 'Bella Mislinay'

Update #Final
Set Employeename = 'Loni Dellamalva'
Where Employeename = 'Loni Dellamalva Dellamalva'

Update #Final
Set Employeename = 'Elizabeth Bewen'
Where Employeename = 'Beth Bewen'

Update #Final
Set Employeename = 'Gevork Dzhabroyan'
Where Employeename = 'George Dzhabroyan'

Update #Final
Set Employeename = 'Mauro Serrano'
Where Employeename = 'Rick Serrano'

Update #Final
Set Employeename = 'Ted Coburn'
Where Employeename = 'Ted Coburn IV'

Update #Final
Set Employeename = 'Rutendo Chiradza'
Where Employeename = 'Rue Chiradza'

Update #Final
Set EmployeeName = 'Darrin Woll'
Where EmployeeName = 'DJ Woll'

Update #Final
Set Employeename = 'Christopher Folz'
Where Employeename = 'Chris Folz'

Update #Final
Set EmployeeName = 'Erandeny Hernandez'
Where EmployeeName = 'Erandeny Lopez Hernandez'

Update #Final
Set EmployeeName = 'Robert Winkler'
Where EmployeeName = 'Robbie Winkler'

Update #Final
Set EmployeeName = 'Kathleen Hatke'
Where EmployeeName = 'Kathy Hatke'

Update #Final
Set EmployeeName = 'Frank Frayer'
Where EmployeeName = 'Frank Frayer Frayer'

Update #Final
Set ManagerName = 'Frank Frayer'
Where ManagerName = 'Frank Frayer Frayer'

Update #Final
Set EmployeeName = 'Andrew Schmelig'
Where EmployeeName = 'Drew Schmelig'

Update #Final
Set EmployeeName = 'Robert McGaughy'
Where EmployeeName = 'Scott McGaughy'

Update #Final
Set EmployeeName = 'Nekita Morris'
Where EmployeeName = 'Kita Morris'

Update #Final
Set EmployeeName = 'Ruben Luna Jr'
Where EmployeeName = 'Ruben Luna'

Update #Final
Set EmployeeName = 'Walter Zimmermann'
Where EmployeeName = 'Walt Zimmermann'

Update #Final
Set EmployeeName = 'Wesley Black'
Where EmployeeName = 'Wes Black'

Update #Final
Set EmployeeName = 'Jennifer Ovando'
Where EmployeeName = 'Jen Ovando'

Update #Final
Set EmployeeName = 'Joshua Baker'
Where EmployeeName = 'Josh Baker' and EmployeeEmail = 'joshua.baker1@pnmac.com'

Update #Final
Set EmployeeName = 'Kelsye McCausland',
	EmployeeLastName = 'McCausland'
Where EmployeeName = 'Kelsye Dean'

Update #Final
Set EmployeeName = 'Mari Sallaberry-Mallicote'
Where EmployeeName = 'Mari Sallaberry Sallaberry-Mallicote'

Update #Final
Set EmployeeName = 'Severiano Rico'
Where EmployeeName = 'Seven Rico'

Update #Final
Set EmployeeName = 'Alex Khosravi'
Where EmployeeName = 'Alex Khosravighasemabadi'

Update #Final
Set EmployeeName = 'Joseph Kirleis'
Where EmployeeName = 'Joe Kirleis'

Update #Final
Set EmployeeName = 'Arshage Aroush'
Where EmployeeName = 'Daniel Aroush'

Update #Final
Set EmployeeName = 'Sarahi Guevara'
Where EmployeeName = 'Sarah Guevara'

Update #Final
Set EmployeeName = 'Jelani Keller'
Where EmployeeName = 'Jay Keller'

Update #Final
Set EmployeeName = 'Robert Gillespie'
Where EmployeeName = 'Rob Gillespie'

Update #Final
Set EmployeeName = 'Gilbert Herrera'
Where EmployeeName = 'Gil Herrera'

Update #Final
Set EmployeeName = 'Stephen Ward'
Where EmployeeName = 'STEPHEN WARD'


Update #Final
Set EmployeeName = 'Roberto Arias'
Where EmployeeName = 'Rob Arias'

Update #Final
Set EmployeeName = 'Thomas Papageorge'
Where EmployeeName = 'Tom Papageorge'

Update #Final
Set EmployeeName = 'Christina Sullivan'
Where EmployeeName = 'Nikki Sullivan'

Update #Final
Set EmployeeName = 'Winston Cutter'
Where EmployeeName = 'John Cutter'

Update #Final
Set EmployeeName = 'Jeffrey Harp'
Where EmployeeName = 'Jeff Harp'

Update #Final
Set EmployeeFirstName = 'Jeffrey'
Where EmployeeEmail = 'jeffrey.harp@pnmac.com'

Update #Final
Set EmployeeName = 'Ledung Kieu'
Where EmployeeName = 'Lee Kieu'

Update #Final
Set EmployeeName = 'Selwam Naidu'
Where EmployeeName = 'Sal Naidu'

Update #Final
Set EmployeeName = 'Ben Shaevitz'
Where EmployeeName = 'Benjamin Shaevitz'

Update #Final
Set EmployeeName = 'Deborah Lisa Loopesko'
Where EmployeeName = 'Deborah Loopesko'

Update #Final
Set EmployeeName = 'Ben Erickson'
Where EmployeeName = 'Benjamin Erickson'

Update #Final
Set EmployeeName = 'Tippong Prudhipornvirakul'
Where EmployeeName = 'Art Prudhipornvirakul'

Update #Final
Set EmployeeName = 'Richard Gerlach'
Where EmployeeName = 'Rich Gerlach'

Update #Final
Set EmployeeName = 'Haroutioun Matossian'
Where EmployeeName = 'Harry Matossian'

Update #Final
Set EmployeeName = 'Ranjnesh Prasad'
Where EmployeeName = 'Angel Prasad'

Update #Final
Set EmployeeName = 'Gregory Paterno'
Where EmployeeName = 'Greg Paterno'

Update #Final
Set EmployeeEmail = 'henry.vanyan@pnmac.com'
Where EmployeeEmail = 'aroutyun.vanyan@pnmac.com'


Update #Final
Set EmployeeName = 'Timothy Williams'
Where EmployeeName = 'Tim Williams'

Update #Final
Set EmployeeName = 'Anitha Frazier'
Where EmployeeName = 'Anitha Frazier Rhem'


Update #Final
Set EmployeeName = 'Cheryl Lazaldijohnson'
Where EmployeeName = 'Cheryl Lazaldi-Johnson'

Update #Final
Set EmployeeName = 'Michelle Powell'
Where EmployeeName = 'Michelle Burgos-Powell'

Update #Final
Set EmployeeName = 'George De Guzman'
Where EmployeeName = 'George David De Guzman III'

Update #Final
Set EmployeeName = 'Gail Manginelli'
Where EmployeeName = 'Gail Anderson'

Update #Final
Set EmployeeName = 'Katharine Magsaysay'
Where EmployeeName = 'Katharine Nicole Magsaysay'

Update #Final
Set EmployeeName = 'Michiko Solon'
Where EmployeeName = 'Miko Solon'

/* CREATED TO MATCH ENCOMPASS NAME*/
Update #Final
Set ManagerName = 'Michiko Solon'
Where ManagerName = 'Miko Solon'

Update #Final
Set EmployeeName = 'Frank Garcia'
Where EmployeeName = 'Francis Garcia'

Update #Final
Set EmployeeEmail = 'Frank.Garcia@pnmac.com'
Where EmployeeEmail = 'Francis.Garcia@pnmac.com'

Update #Final
Set EmployeeName = 'Russell Litzenberger'
Where EmployeeName = 'Russ Litzenberger'

Update #Final
Set EmployeeName = 'Veralis Mendoza'
Where EmployeeName = 'Vera Mendoza'

Update #Final
Set EmployeeName = 'Tim Hardaway'
Where EmployeeName = 'Timothy Hardaway'

Update #Final
Set EmployeeName = 'Nandani Perera'
Where EmployeeName = 'Indra Perera'

Update #Final
Set EmployeeName = 'Marine Zakaryan'
Where EmployeeName = 'Marina Zakaryan'

Update #Final
Set EmployeeName = 'Elizabeth Lopez'
Where EmployeeName = 'Liz Lopez'

Update #Final
Set EmployeeName = 'Christopher Brooks'
Where EmployeeName = 'Chris Brooks'

Update #Final
Set EmployeeName = 'Harjoyte Bisla'
Where EmployeeName = 'Jay Bisla'

Update #Final
Set EmployeeName = 'Nicole De La Cruz'
Where EmployeeName = 'Nikki De La Cruz'

Update #Final
Set EmployeeName = 'Becky Bond'
Where EmployeeName = 'Rebecca Bond'

Update #Final
Set EmployeeName = 'Shukemya Robinson'
Where EmployeeName = 'Keme Robinson'

Update #Final
Set EmployeeName = 'Angelica Ortiz'
Where EmployeeName = 'Angie Ortiz'

Update #Final
Set EmployeeName = 'Brandlyn Haynes'
Where EmployeeName = 'Brand Haynes'

Update #Final
Set EmployeeName = 'Patricia Sargent'
Where EmployeeName = 'Pat Sargent'

Update #Final
Set EmployeeName = 'Kimberly Coleman'
Where EmployeeName = 'Kim Coleman'

Update #Final
Set EmployeeName = 'Hai Nguyen'
Where EmployeeName = 'Van Nguyen'

Update #Final
Set EmployeeName = 'Jessie Corral'
Where EmployeeName = 'Jesse Corral'

Update #Final
Set EmployeeName = 'Anna Ibe'
Where EmployeeName = 'Anna Lorelei Ibe'

Update #Final
Set EmployeeName = 'Marlene Spencer'
Where EmployeeName = 'Marleen Spencer'

Update #Final
Set EmployeeName = 'Terrence Jackson - Smith'
Where EmployeeName = 'Terrence Jackson-Smith'

Update #Final
Set EmployeeName = 'Denisha Leonard'
Where EmployeeName = 'Denise Leonard'

Update #Final
Set EmployeeName = 'Dianah Miller'
Where EmployeeName = 'Diana Miller'

Update #Final
Set EmployeeName = 'Cecilia Sunga'
Where EmployeeName = 'Cecille Sunga'

Update #Final
Set EmployeeName = 'Juanita Cruz'
Where EmployeeName = 'Juanita Cruz Cuevas'

Update #Final
Set EmployeeName = 'Lashanda Benton'
Where EmployeeName = 'Lashanda Anderson Benton'

Update #Final
Set EmployeeName = 'Nyesha Harris'
Where EmployeeName = 'Nye Harris'

Update #Final
Set EmployeeName = 'Gabriel Mann'
Where EmployeeName = 'Gabe Mann'

Update #Final
Set EmployeeName = 'Karen Puente'
Where EmployeeName = 'Karen Puente Diaz De Leon'

Update #Final
Set EmployeeName = 'Jorge Vazquez'
Where EmployeeName = 'George Vazquez-Castaneda'

Update #Final
Set EmployeeName = 'Marleen Spencer'
Where EmployeeName = 'Marlene Spencer'

Update #Final
Set EmployeeName = 'Elizabeth Ravelo'
Where EmployeeName = 'Liz Ravelo'


Update #Final
Set EmployeeName = 'Timothy Cameron'
Where EmployeeName = 'Tim Cameron'

Update #Final
Set EmployeeEmail = 'tony.tsiligian@pnmac.com'
Where EmployeeEmail = 'tigran.tsiligian@pnmac.com'

Update #Final
Set EmployeeName = 'Tony Tsiligian'
Where EmployeeName = 'Tony Tsiligian Tsiligian'

Update #Final
Set EmployeeName = 'Mary Grace de Guzman'
Where EmployeeName = 'Grace De Guzman'

Update #Final
Set EmployeeName = 'Salvacion Tyson'
Where EmployeeName = 'Sallie Tyson'

Update #Final
Set EmployeeName = 'Ruth Yarnell'
Where EmployeeName = 'Ruthie Yarnell'

Update #Final
Set EmployeeName = 'Katrina Hawkins'
Where EmployeeName = 'Trina Hawkins'

Update #Final
Set EmployeeName = 'Rupinder Kaur'
Where EmployeeName = 'Rupinder Manley'

Update #Final
Set EmployeeName = 'Sharon Wingate-Stanfield'
Where EmployeeName = 'Shoney Wingate-Stanfield'

Update #Final
Set EmployeeName = 'Michele Adams'
Where EmployeeName = 'Michele Adams Thompson-Ford'

Update #Final
Set EmployeeName = 'Roxanna Ruiz'
Where EmployeeName = 'Roxy Ruiz'

Update #Final
Set EmployeeName = 'Elizabeth Tripp'
Where EmployeeName = 'Paloma Tripp'

Update #Final
Set EmployeeName = 'Theresa Marquez-Blas'
Where EmployeeName = 'Theresa A Marquez Marquez-Blas'

Update #Final
Set EmployeeName = 'Nshan Terzyan'
where EmployeeName = 'Nick Terzyan'

Update #Final
Set EmployeeName = 'Angelica Bolanos'
where EmployeeName = 'Angie Bolanos'

--Update #Final
--Set EmployeeName = 'Hakop Garlanian'
--where EmployeeName = 'Jack Garlanian'

Update #Final
Set EmployeeName = 'Elodia Vargas'
where EmployeeName = 'Ellie Vargas'

Update #Final
Set EmployeeName = 'Edward Gallegos'
where EmployeeName = 'Eddie Gallegos'

Update #Final
Set EmployeeName = 'Jeffries Johnson'
where EmployeeName = 'Ramon Johnson'

Update #Final
Set ManagerName = 'Jeffries Johnson'
where ManagerName = 'Ramon Johnson'

Update #Final
Set EmployeeName = 'Haroutun Arzrounian'
where EmployeeName = 'Harry Arzrounian'

Update #Final
Set EmployeeName = 'Anthony Trozera'
where EmployeeName = 'Tony Trozera'

Update #Final
Set EmployeeName = 'David Risse'
where EmployeeName = 'Dave Risse'

Update #Final
Set ManagerName = 'David Risse'
where ManagerName = 'Dave Risse'

Update #Final
Set EmployeeName = 'Jo-Nathan Green'
where EmployeeName = 'Jo Green'

Update #Final
Set EmployeeName = 'Stephanie McPherson'
where EmployeeName = 'Stephanie Spencer McPherson'

Update #Final
Set EmployeeName = 'Deborah Patenaude'
where EmployeeName = 'Debbie Patenaude'

Update #Final
Set EmployeeName = 'Anthony Kim'
where EmployeeName = 'Tony Kim'

Update #Final
Set EmployeeName = 'Joseph Purcell'
where EmployeeName = 'Joe Purcell'

Update #Final
Set EmployeeName = 'Brad Thompson'
where EmployeeName = 'Bradley Thompson'

Update #Final
Set ManagerName = 'Brad Thompson'
where ManagerName = 'Bradley Thompson'

Update #Final
Set EmployeeName = 'Dakila Cabrera'
where EmployeeName = 'Dak Cabrera'

Update #Final
Set EmployeeName = 'Thomas Palacios'
where EmployeeName = 'Tommy Palacios'

Update #Final
Set EmployeeName = 'Kathryn Ruiz'
where EmployeeName = 'Kathy Ruiz'

Update #Final
Set EmployeeName = 'Jo Ann Wiseman'
where EmployeeName = 'JoAnn Wiseman'


Update #Final
Set EmployeeName = 'Pauline De La Salle'
where EmployeeName = 'Pauline DeLaSalle'


Update #Final
Set EmployeeName = 'Shount Davoodian'
where EmployeeName = 'Sean Davoodian'

Update #Final
Set EmployeeName = 'Jennifer Spishak'
where EmployeeName = 'Jen Spishak'

Update #Final
Set EmployeeName = 'Maria Gembler'
where EmployeeName = 'Maria Gembler Gembler'

Update #Final
Set EmployeeName = 'Shynillia Davis'
where EmployeeName = 'Shy Davis'

Update #Final
Set EmployeeName = 'Charles Littlejohn Jr'
where EmployeeName = 'Chuck Littlejohn'



Update #Final
Set EmployeeName = 'Katrina Williams'
where EmployeeName = 'TRINA Williams'

Update #Final
Set EmployeeName = 'Jonathan Jeffrey'
where EmployeeName = 'JJ Jeffrey'

Update #Final
Set EmployeeName = 'Matthew Hernandez'
where EmployeeName = 'Matt Hernandez'

Update #Final
Set EmployeeName = 'Regina Lal'
where EmployeeName = 'Regi Lal'

Update #Final
Set EmployeeName = 'Ronald O''Neal'
where EmployeeName = 'Ron O''Neal'


Update #Final
Set EmployeeName = 'Aaron Hatfield'
where EmployeeName = 'AJ Hatfield'

Update #Final --ADDED BY CHARLIE 08/09/2019 FOR MATCHING
Set ManagerName = 'Aaron Hatfield'
where ManagerName = 'AJ Hatfield'

Update #Final
Set EmployeeName = 'Sarah York'
where EmployeeName = 'Sarah Beth York'

Update #Final
Set EmployeeName = 'Teodora Pfister'
where EmployeeName = 'Teo Pfister'

Update #Final
Set EmployeeName = 'Pheominity Hayes'
where EmployeeName = 'Tim Hayes'


Update #Final
Set EmployeeName = 'Joshua Wofford'
where EmployeeName = 'Josh Wofford'


Update #Final
Set EmployeeName = 'Dwight Dickey'
where EmployeeName = 'Robert Dickey'

Update #Final
Set ManagerName = 'Dwight Dickey'
where ManagerName = 'Robert Dickey'

Update #Final
Set EmployeeEmail = 'dwight.dickey@pnmac.com'
where EmployeeEmail = 'robert.dickey@pnmac.com'

Update #Final
Set EmployeeName = 'Gregory Littleton'
where EmployeeName = 'Gregory Littleton Littleton'

Update #Final
Set EmployeeName = 'Walter Macauley'
where EmployeeName = 'Craig Macauley'

Update #Final
Set EmployeeName = 'Derwin Rogers'
where EmployeeName = 'Sean Rogers'

Update #Final
Set EmployeeName = 'Everardo Zaragoza'
where EmployeeName = 'Everardo Zaragoza Hernandez'

Update #Final
Set EmployeeName = 'Christinia Kanlise'
where EmployeeName = 'Chrissy Kanlise'

Update #Final
Set EmployeeName = 'Stephen Elliston'
where EmployeeName = 'Steve Elliston'

Update #Final
Set EmployeeName = 'Timothy Gerrity'
where EmployeeName = 'Tim Gerrity'


Update #Final
Set EmployeeName = 'Benedick Magcalas'
where EmployeeName = 'Ben Magcalas'

Update #Final
Set EmployeeName = 'Eulronda Adams'
where EmployeeName = 'Ronda Adams'

Update #Final
Set EmployeeName = 'Joshua Rubio'
where EmployeeName = 'Josh Rubio'

Update #Final
Set EmployeeName = 'Ashot Gafafyan'
where EmployeeName = 'Anthony Gafafyan'


Update #Final
Set EmployeeName = 'Zachary Vorhof'
where EmployeeName = 'Zac Vorhof'

Update #Final
Set EmployeeName = 'Azeem Ahmad'
where EmployeeName = 'AJ Ahmad'

Update #Final
Set EmployeeName = 'Nikolaus Coromelas'
where EmployeeName = 'Niko Coromelas'

Update #Final
Set EmployeeName = 'Marine Chakmakchya'
where EmployeeName = 'Marina Chakmakchyan'

Update #Final
Set EmployeeName = 'Robert Long'
where EmployeeName = 'Chris R Long'

Update #Final
Set EmployeeName = 'Alvoid Scott'
where EmployeeName = 'Al Scott'


Update #Final
Set EmployeeName = 'Horacio Martin'
where EmployeeName = 'Russell Martin'

Update #Final
Set EmployeeName = 'Leonidas Ostorga'
where EmployeeName = 'Leo Ostorga'

Update #Final
Set EmployeeName = 'Terri Jaksa'
where EmployeeName = 'Terri Boardman Jaksa'

Update #Final
Set EmployeeName = 'Merrill Von Bargen'
where EmployeeName = 'Merrill Tapia'

Update #Final
Set EmployeeName = 'Osvaldo Martinez'
where EmployeeName = 'Ozzy Martinez'

Update #Final
Set EmployeeName = 'Jessica Espino'
where EmployeeName = 'Jess Espino'


Update #Final
Set EmployeeName = 'Lorena Martinez'
where EmployeeName = 'Lorena Martinez Gutierrez'


Update #Final
Set EmployeeLastName = 'Littlejohn Jr'
where EmployeeName = 'Charles Littlejohn Jr'

Update #Final
Set EmployeeLastName = 'Grace Kapaun'
where EmployeeName = 'Gracie Kapaun'

Update #Final
Set EmployeeName = 'Shaun Wilson'
where EmployeeName = 'Shaun Eric Wilson'

Update #Final
Set EmployeeName = 'Jennifer Boker'
where EmployeeName = 'Jenny Boker'

Update #Final
Set EmployeeName = 'Ziyad Fayad',
    EmployeeEmail ='ziyad.fayad@pnmac.com'
where EmployeeName = 'ZEE Fayad'

Update #Final
Set EmployeeName = 'Shyhede Kendrick'
where EmployeeName = 'Shy Kendrick'


Update #Final
Set EmployeeName = 'Thomas Cook'
where EmployeeName = 'Tom Cook'


Update #Final
Set EmployeeName = 'Eugenia LoPiccolo'
where EmployeeName = 'Gina LoPiccolo'

Update #Final
Set EmployeeName = 'Kimberly Ulloa'
where EmployeeName = 'Kim Ulloa'

Update #Final
Set EmployeeName = 'Monisha Gleghorn'
where EmployeeName = 'Mona Gleghorn'

Update #Final
Set EmployeeName = 'Tamika Debow'
where EmployeeName = 'Tamika DeBow-Williams'

Update #Final
Set EmployeeName = 'Marisol Lopez'
where EmployeeName = 'Marisol Ramos'

Update #Final
Set EmployeeName = 'Greg Scott Littleton'
where EmployeeName = 'Gregory Littleton'

Update #Final
Set EmployeeName = 'Gilbert Ledezma'
where EmployeeName = 'Gilberto Ledezma'

Update #Final
Set EmployeeName = 'Oribel Ortiz'
where EmployeeName = 'Bel Ortiz'


Update #Final
Set EmployeeName = 'Clyde Anderson'
where EmployeeName = 'CJ Anderson'

Update #Final
Set EmployeeName = 'Timothy Esterly'
where EmployeeName = 'Tim Esterly'

Update #Final
Set ManagerName = 'Timothy Esterly'
where ManagerName = 'Tim Esterly'

Update #Final
Set City = 'Honolulu'
where EmployeeName = 'Paul Santiago'

UPDATE #Final
SET City = 'Manila',
	City_OfficeLocation = 'PH - Manila'
WHERE City in ('Manilla','Philippines')
or City_OfficeLocation in ('PH - Manilla', 'Manila- Philippines')

Update #Final
Set EmployeeName = 'Elizabeth Garcia'
where EmployeeName = 'Lisa Garcia'

Update #Final
Set EmployeeName = 'Christopher Lyman'
where EmployeeName = 'Chris Lyman'

Update #Final
Set EmployeeEmail = 'christopher.lyman@pnmac.com'
where EmployeeEmail = 'chris.lyman@pnmac.com'

Update #Final
Set EmployeeName = 'Joshua Aaron Benavidez'
where EmployeeName = 'Joshua Benavidez'


Update #Final
Set EmployeeName = 'Ricardo Byers'
where EmployeeName = 'Ric Byers'

--Update #Final
--Set EmployeeName = 'Ric Byers'
--where EmployeeName = 'Ricardo Byers'


Update #Final
Set EmployeeName = 'Jonathan Wahrman'
where EmployeeName = 'JD Wahrman'


Update #Final
Set EmployeeName = 'Jenny Boker'
where EmployeeName = 'Jennifer Boker'

Update #Final
Set EmployeeName = 'Eraina Holmes'
where EmployeeName = 'Raina Holmes'

Update #Final
Set EmployeeName = 'Rebecca Dowling'
where EmployeeName = 'Becky Dowling'

Update #Final
Set EmployeeName = 'Jonnie Maretti'
where EmployeeName = 'Jon Maretti'

Update #Final
Set EmployeeName = 'Calister Sundire'
where EmployeeName = 'Caly Sundire'


Update #Final
Set EmployeeName = 'Grace Kapaun'
where EmployeeName = 'Gracie Kapaun'


Update #Final
Set EmployeeName = 'Catherine Randle'
where EmployeeName = 'Cathy Randle'


Update #Final
Set EmployeeName = 'David DeVore'
where EmployeeName = 'Jay DeVore'

Update #Final
Set EmployeeName = 'Jeffrey Anderson'
where EmployeeName = 'Jeff Anderson'

Update #Final
Set EmployeeName = 'Dale McMahen'
where EmployeeName = 'Keith McMahen'

Update #Final
Set EmployeeName = 'Kristopher McGrail'
where EmployeeName = 'Kris McGrail'

Update #Final
Set EmployeeName = 'Hessam Kiani'
where EmployeeName = 'Sam Kiani'

Update #Final
Set EmployeeName = 'Randall Alford'
where EmployeeName = 'Randy Alford'

Update #Final
Set EmployeeName = 'Antoinette Young'
where EmployeeName = 'Toni Young'

Update #Final
Set EmployeeName = 'Katherine House'
where EmployeeName = 'Kathy House'

--Update #Final
--Set EmployeeName = 'Brian N Mitchell'
--where EmployeeName = 'Nick Mitchell'

Update #Final
Set EmployeeName = 'Brian N Mitchell'
where EmployeeName = 'Nick Mitchell'

Update #Final
Set EmployeeName = 'Andrew Dunham'
where EmployeeName = 'Andy Dunham'

/* DELETED ON 07/24/2019 TO MAKE A MATCH ON ENCOMPASS */
/* REVERTED ON 08/12/2019 BECAUSE OF DW_ORG CHANGE*/
Update #Final
Set EmployeeName = 'James Wright'
where EmployeeName = 'Jamie Wright'

Update #Final
Set EmployeeName = 'Felicia Mulkey'
where EmployeeName = 'Nicole Mulkey'

Update #Final
Set Employeename = 'Matthew Hinckley'
Where Employeename = 'Matt Hinckley'

Update #Final
Set ManagerName = 'Matthew Hinckley'
Where ManagerName = 'Matt Hinckley'

Update #Final
Set Employeename = 'Samone Howard'
Where Employeename = 'Ashley Howard'

Update #Final
Set Employeename = 'Anthony Sells'
Where Employeename = 'Ace Sells'


Update #Final
Set Employeename = 'Katherine Smith'
Where Employeename = 'Kathy Smith'

Update #Final
Set ManagerName = 'Katherine Smith'
Where ManagerName = 'Kathy Smith'

Update #Final
Set Employeename = 'Venus Ferate'
Where Employeename = 'Venus Castillo'

Update #Final
Set Employeename = 'Venus Ferate'
Where Employeename = 'Venus Castillo'

Update #Final
Set Employeename = 'Dennis Mueller'
Where Employeename = 'Denny Mueller'





Update #Final
Set ManagerName_TwoUp = 'Rich Ferre'
where ManagerName like '%Ben%Erickson%' and ManagerName_TwoUp is Null




Update #Final
Set Employeename = 'Ayeni Desmond'
Where Employeename = 'Desmond Ayeni'

Update #Final
Set Employeename = 'Evgeny Goldberg'
Where Employeename = 'Jim Goldberg'

Update #Final
Set Employeename = 'LoPiccolo Eugenia'
Where Employeename = 'Eugenia LoPiccolo'

Update #Final
Set Employeename = 'Wanada Patton'
Where Employeename = 'Wanda Patton'

Update #Final
Set Employeename = 'Wanda French'
Where Employeename = 'Wanda French-Wallace'

Update #Final
Set Employeename = 'Monique Everett'
Where Employeename = 'MONQIUE Everett'

Update #Final
Set Employeename = 'Nikki Shenickqua Carter'
Where Employeename = 'Nikki Carter'

Update #Final
Set Employeename = 'Galvez Carolina'
Where Employeename = 'Carolina Galvez'

Update #Final
Set Employeename = 'Kyle Hagadorn'
Where Employeename = 'Kyle Hagadorn-Aranzazu'

Update #Final
Set Employeename = 'Laura De Stefano'
Where Employeename = 'Laura Lundberg'

Update #Final
Set Employeename = 'Jessica Jones'
Where Employeename = 'Jessica Battle'

Update #Final
Set Employeename = 'Kaila Campbell'
Where Employeename = 'Kaila Mier'

Update #Final
Set Employeename = 'Mike Sample'
Where Employeename = 'Michael Sample'

Update #Final
Set Employeename = 'Kimberly Elliott'
Where Employeename = 'Kimberly Terrazas'

Update #Final
Set Employeename = 'Vazrik Masihi'
Where Employeename = 'Vazrik Yaghoubi Masihi'

Update #Final
Set Employeename = 'Soheila Noroozi'
Where Employeename = 'Soheila Norooziidlou'

Update #Final
Set Employeename = 'Arturo Banda'
Where Employeename = 'Art Banda'

Update #Final
Set Employeename = 'Carol Parrish'
Where Employeename = 'CJ Parrish'

Update #Final
Set Employeename = 'Christopher Ellsworth'
Where Employeename = 'Chris Ellsworth'

Update #Final
Set Employeename = 'Elizabeth Gebbie'
Where Employeename = 'Beth Gebbie'

Update #Final
Set Employeename = 'Hui-Hsin Tsai'
Where Employeename = 'Abby Tsai'

Update #Final
Set Employeename = 'Lori-Ann Walsh-Soucy'
Where Employeename = 'Lori Walsh-Soucy'

Update #Final
Set Employeename = 'Margaret Donohoo'
Where Employeename = 'Garet Donohoo'

Update #Final
Set Employeename = 'Nikhil Patel'
Where Employeename = 'Nick Patel'

Update #Final
Set Employeename = 'Pricinda Meehan'
Where Employeename = 'Cindi Meehan'

Update #Final
Set Employeename = 'Virginia Furman'
Where Employeename = 'Gina Furman Furman'

Update #Final
Set Employeename = 'Crickett Youngman'
Where Employeename = 'Christine Youngman'

Update #Final
Set Employeename = 'Donald Maday'
Where Employeename = 'Don Maday'

/* DELETED ON 07/24/2019 TO MAKE A MATCH ON ENCOMPASS */
--Update #Final
--Set Employeename = 'James Wright'
--Where Employeename = 'James R Wright'

Update #Final
Set Employeename = 'Kim Coleman'
Where Employeename = 'Kimberly Coleman'

Update #Final
Set Employeename = 'Mona Gleghorn'
Where Employeename = 'Monisha Gleghorn'

Update #Final
Set Employeename = 'Katherine Engels'
Where Employeename = 'Katie Engels'


Update #Final
set EmployeeName ='Kimberly Coleman'
where EmployeeName='Kim Coleman'


Update #Final
set EmployeeName ='Monisha Gleghorn'
where EmployeeName='Mona Gleghorn'

Update #Final
set EmployeeName ='Robert G Taylor'
where EmployeeName='Robert Taylor'

Update #Final
set EmployeeName ='Nicholas Batten'
where EmployeeName='Nick Batten'

Update #Final
set EmployeeName ='Jeffrey Smith'
where EmployeeName='Jeff Smith'

Update #Final
set EmployeeName = 'Mary DiPalo'
where EmployeeName = 'Mary Lou DiPalo'

Update #Final
set EmployeeName = 'Kelsye Dean'
where EmployeeName = 'Kelsye McCausland'

Update #Final
set EmployeeName = 'Edward Overkleeft'
where EmployeeName = 'Ed Overkleeft'


Update #Final
set EmployeeName = 'Shante Viamontes'
where EmployeeName = 'Sherri Viamontes'


Update #Final
set EmployeeName = 'Gregory Ligon'
where EmployeeName = 'Greg Ligon'

Update #Final
set EmployeeName = 'Nicholas Groetken'
where EmployeeName = 'Nick Groetken'

Update #Final
set EmployeeName = 'Christopher Cruz'
where EmployeeName = 'Chris Cruz'


Update #Final
set EmployeeName = 'Daniel Tepel'
where EmployeeName = 'Danny Tepel'

Update #Final
set EmployeeName = 'Fergielyn Aranzazu'
where EmployeeName = 'Fergielyn Hagadorn-Aranzazu'


Update #Final
set EmployeeName = 'Aizen Malki'
where EmployeeName = 'David Malki'

Update #Final
set EmployeeName = 'Jarett Delbene'
where EmployeeName = 'Jarett Del Bene'


Update #Final
Set HireDate = '6/22/2015'
where EmployeeName = 'Maria Solorzano'

Update #Final
Set
Title = 'Client Coordinator',
TitleGrouping = 'Client Coordinator'
Where
EmployeeName = 'Lea Santoyo'
and Period between 201404 and 201502


Update #Final
Set
Title = 'Account Executive',
TitleGrouping = 'Account Executive'
Where
EmployeeName = 'Lea Santoyo'
and Period = 201503


Update #Final
Set
City = 'Sacramento'
Where
EmployeeName = 'Melissa Heffelfinger'
and Period >= 201408

Update #Final
Set
ManagerId = '001510',
ManagerName = 'Jason Pliska',
ManagerEmail = 'jason.pliska@pnmac.com',
ManagerTitle = 'AE, Retail',
ManagerCity = 'Sacramento',
ManagerName_TwoUp = 'Rich Ferre',
Title = 'Loan Officer',
TitleGrouping = 'Account Executive'
Where EmployeeName = 'Everardo Zaragoza Hernandez'
and Period = 201608


Update #Final
Set
ManagerId = '003800',
ManagerName = 'Allen Brunner',
ManagerEmail = 'allen.brunner@pnmac.com',
ManagerCity = 'Pasadena',
ManagerName_TwoUp = 'Nathan Dyce'
Where EmployeeName = 'Ruben Sanchez'
and Period = 201809

/*
OFFICE PHONE NUMBER CHANGES - CHARLIE 07/10/2019
Phone numbers were changed due to the PennyMac hotlin number being associated with these terminated employees.
*/

UPDATE #Final
SET OfficePhoneNumber = null
WHERE EmployeeName in (
'Anthony Douk',
'Christopher Huynh',
'Courtney Harper',
'Denisha Leonard',
'Dil Perera',
'Jack Palmer',
'Janet Haritouni-Gozalian',
'Jo Scheerer',
'Jose Salas',
'Julie Du Bois',
'Kathy Padilla',
'Mina Mettry',
'Nikki Nguyen',
'Patrick Stinson',
'Robert Griese',
'Ryan Yam',
'Shakeb Mohammad',
'Stephanie DiGiovine',
'Suzanne Feinberg',
'Yaladait Chavez')


--=======Update Jr. LoanOfficer Title Grouping to Dispatch Agent while they perform Dispatch activities

Update #Final
Set TitleGrouping = 'Dispatch Agent'
where EmployeeName in ('Justin Beatty', 'Myles Hunter')

---==================================================================================

Delete
From #Final
where
EmployeeName = 'Sandra Rosales'
and EmployeeId = '005435'






Update #Final
Set EmployeeFirstName = LEFT(EmployeeName,charindex(' ',EmployeeName))

Update #Final
Set EmployeeFirstName = 'Sheetal'
Where EmployeeName = 'SheetalSingh'

Update #Final
Set EmployeeLastName = LTRIM(RIGHT(EmployeeName,(charindex(' ',reverse(EmployeeName)))))

Update #Final
Set EmployeeLastName = 'Singh'
Where EmployeeName = 'SheetalSingh'


Update #Final
Set City = case
				when City like '%Worth%' then 'Ft Worth'
				when CHARINDEX('-',City) <> 0 then rrd.dbo.udf_RemoveNonAlpha(RIGHT(City,LEN(City)-charindex('-',City)-1))
				else rrd.dbo.udf_RemoveNonAlpha(City)
		  end


Update #Final
Set ManagerCity = case
					when ManagerCity like '%Worth%' then 'Ft Worth'
					when CHARINDEX('-',ManagerCity) <> 0
							then rrd.dbo.udf_RemoveNonAlpha(RIGHT(ManagerCity,LEN(ManagerCity)-charindex('-',ManagerCity)-1))
					else rrd.dbo.udf_RemoveNonAlpha(ManagerCity)
				  end



Update SM
Set NewDepartmentFlag = case
						when SM2.DepartmentGroupingII <> SM.DepartmentGroupingII then 'Y'
						else 'N'
					end

From #Final SM (nolock)

left join #Final SM2 (nolock)
on SM.EmployeeId = SM2.EmployeeId
and SM.Period = SM2.Period + case
								when left(SM2.Period,2) = '12' then 89
								else 01
							  end




Update #Final
Set NewDivisionFlag = 'Y'
Where DivisionName <> 'Retail Production'

Update #Final
Set NewDivisionFlag = 'N'
Where NewDivisionFlag Is Null

Update #Final
set EmployeeName ='Jennifer White'
where EmployeeName='Jenn White'


--Update #Final --removed by Charlie to make name match Encompass
--set EmployeeName ='AJ Hatfield'
--where EmployeeName='aaron hatfield'


Update #Final
set EmployeeName ='Andre''sha N Baker'
where EmployeeName='AndreSha Baker'

/*DELETED 08/12/2019 BY CHARLIE DUE TO NAME CHANGE IN DW_ORG*/
--Update #Final
--set EmployeeName =  'James R Wright'
--where EmployeeName =  'James Wright'


Update #Final
set EmployeeName ='Joyce Renee Williams'
where EmployeeName='Joyce Williams'

Update #Final
set EmployeeName =  'Monti jamila Willis'
where EmployeeName =  'Monti Willis'

/*DELETED 08/12/2019 BY CHARLIE DUE TO NAME CHANGE IN DW_ORG*/
--Update #Final
--set EmployeeName =  'James Wright'
--where EmployeeName =  'James R Wright'


Update #Final
set EmployeeName =  'Edward Taylor'
where EmployeeName =  'Will Taylor'

Update #Final
set ManagerName =  'Edward Taylor'
where ManagerName =  'Will Taylor'

Update #Final
set ManagerName =  'Madison Salter'
where ManagerName =  'Madison Grogg'

--Update #Final
--set EmployeeName =  'Katherine Olmos'
--where EmployeeName =  'Katie Olmos'



Delete from #Final
where City = 'Atlanta' and EmployeeName like 'Adriana Smith'



--- Updated Email Address of Term Employee,  due to new employee having the same address

Update #Final
Set EmployeeEmail = 'jas.singh@pnmac.com_term',
    EmployeeName = 'Jas Singh_Term'
Where EmployeeId = '000748'



--Delete
--From #Final
--where
--TitleGrouping = 'Dispatch Agent - Infosys'
--and ManagerName in ('Lori Schofield')



----====MANUALLY INCLUDING HIRE DATES AS THE FIRST BATCH OF INFOSYS DISPATCHERS DID NOT RECEIVE ONE
Update #Final
Set HireDate = '6/11/2018', HirePeriod = 201806
where
TitleGrouping = 'Dispatch Agent - Infosys'
and EmployeeName in (
'Deepak Sadanandan',
'Gracia Asoh',
'Junaye Freeman',
'Kindra Morton',
'Audrey Williams',
'Henry Dillard',
'Duane Kucharczyk',
'Cedric Griffith',
'Donell Spencer',
'Phyllis Black') and Period < 201904



update #Final
Set HireDate = '7/18/2018', HirePeriod = 201807
where
EmployeeName
in (
'Beverly McLean',
'Dominique Johnston',
'Duane Kucharczyk',
'Fallon Reed',
'Janaca Lesure',
'Stacia Moseley',
'Stephania Belfond',
'Wandell Thomas')




update #Final
Set HireDate = '8/1/2018', HirePeriod = 201808
where
EmployeeName
in (
'Cynthia Thomas',
'Danielle Williams',
'Rodney President',
'Hardy Dorsey',
'Jasmine Franklin',
'Jerri Christopher',
'Dezzie Rodriguez',
'Juaquin Brown',
'Julisa Cruz')


--update #Final
--Set HireDate = '8/22/2018', HirePeriod = 201808
--where
--EmployeeName
--in (
--'Altricia Echols',
--'Andre''sha N Baker',
--'Barry Blackson',
--'Brandon Foster',
--'Cherridy Thornton',
--'Kimberly Sloan',
--'Lametria Ford',
--'Nigera Fulton',
--'Raven Hibbert',
--'Teresa Scales',
--'Treajure Silver',
--'Valentina Valantine'
--)



--update #Final
--Set HireDate = '9/25/2018', HirePeriod = 201809
--where
--EmployeeName
--in (
--'Adriana Smith',
--'Cheyenne Ross',
--'Joyce Renee Williams',
--'Monti jamila Willis',
--'Nova Blackman',
--'Rachelle Darden',
--'Tyunna Hodo'
--)







----removes Rachelle Andrade's contractor record
delete
from #Final
where Period in (201508, 201509, 201510, 201511, 201512, 201601, 201602, 201603, 201604, 201605, 201606, 201607,201608,201609, 201610, 201611, 201612
				,201701, 201702, 201703, 201704,201705,201706,201707,201708,201709,201710,201711,201712, 201801, 201802, 201803) and EmployeeId = 'C00566'



----update to write the LOA period and date to all subsequent month snapshots - 9/15/2015 - LC
Update #Final
Set LOAPeriod = (Select MAX(LOAPeriod)
				 From #Final
				 Where EmployeeName = SM.EmployeeName
				 and Period <= SM.Period)
				 from #Final SM


Update #Final
Set LOADate = (Select MAX(LOADate)
				 From #Final
				 Where EmployeeName = SM.EmployeeName
				 and Period <= SM.Period)
				 from #Final SM

/*COMMENTED OUT BY CHARLIE 03/02/2020*/
--update #Final
--Set TenuredDate=
--case

--	when
--	--TitleGrouping = 'Account Executive'
--    TitleGrouping in ('Account Executive','Loan Officer') and Purchaseflag='Y' -- eff 7/19/16 ae
--	then
--		case
--			when DATEPART(d,HireDate) <= 15 then rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,HireDate))
--			else rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,5,HireDate))
--		end
--	 else TenuredDate
--end--by PK for ManagerProductivity


--Update #Final

--Set TenuredFlag = case
--					when rrd.dbo.udf_MonthYear_Int(TenuredDate) <= Period then 'Y'
--					else 'N'
--				  end--by PK for ManagerProductivity

--Update #Final

--Set TenuredNextMoFlag = case
--							when rrd.dbo.udf_MonthYear_Int(Dateadd(m,-1,TenuredDate)) = Period
--							then 'Y'
--							else 'N'
--						end--by PK for ManagerProductivity




--======================================================================================================
---starting with historical records, employees here before MFD------------------------------------------
--======================================================================================================
Update #Final
Set DivisionGroup = 'CDL'
Where
Period <= 201502

--or (Period > 201502 and EmploymentStatus Not In ('Active') and EmployeeId in (
--																(Select EmployeeId
--																From #Final
--																Where Period <= 201502)))


--======================================================================================================
---starting point for MFD, C-Level Employee------------------------------------------------------------
--======================================================================================================
Update #Final
Set DivisionGroup = 'MFD'
where
DivisionName = 'Mortgage Ops Support'

Update #Final
Set DivisionGroup = 'MFD'
where
Department like '%Fulfillment%'


Update #Final
Set DivisionGroup = 'MFD'
where
Department like '%MFD%'

--Update #Final
--Set DivisionGroup = 'MFD'
--Where ManagerTitle like 'Chief%Mtg%Fulfill%Of%'
--or ManagerTitle = 'MD, Mortgage Fulfillment'


--=====================================================================================================
--Updated to Roll Back Purchase LOs that have transferred to TX to old managers for 201808 and keep as purchase lo
--=====================================================================================================

Update #Final
Set ManagerName = 'Kevin Price',
    ManagerName_TwoUp = 'Nathan Dyce',
    PurchaseFlag = 'Y'
    ,ManagerEmail ='kevin.price@pnmac.com'
where EmployeeName in ('Rovic Clemente', 'Dominic Cifarelli')
and Period = 201808

Update #Final
Set ManagerName = 'Evan Tuchman',
    ManagerName_TwoUp = 'Nathan Dyce',
    PurchaseFlag = 'Y'
    ,ManagerEmail ='evan.tuchman@pnmac.com'
where EmployeeName in ('Joshua Baker')
and Period = 201808

--Changed by pk
Update #Final
Set HelocFlag = 'Y'
where EmployeeName in ('Araceli Jimenez',
'Braden DaBell',
'Leonard Bernal',
'Nick Groetken',
'Omar Bretado',
'Penny Mrva',
'Rodney Perkins',
'Sonia Lozano',
'Stephanie McCanlas',
'Timothy Esterly',
'Timothy Esterly',  --- ae 1/14/19 hangout carl i
'Nicholas Groetken'  --- ae 1/14/19 hangout carl i
)
and Period >= 201901 and Period < 202003

Update #Final
Set HelocFlag = 'Y'
where EmployeeName in (
'Tramell Nash'			--Scott Request 06/04
)
and Period >= 201905 and Period < 202003

Update #Final
Set HelocFlag = 'Y'
where EmployeeName in (
'Ignacio Barrientos'			--Scott Request 09/20
)
and Period >= 201908 and Period < 202003


--Update for LOs under Purchase SM but are Refi LOs
Update #Final
Set PurchaseFlag = 'N'
where EmployeeName in (
'Abdul Saleh',
'Joshua Baker',
'haroutun Arzrounian',
'Kevin Lundberg'
)
and Period >= 201810

Update #Final
Set PurchaseFlag = 'N'
where EmployeeName in (
'Aaron Dounel'
)
and Period >= 201812




Delete
From #Final
where
EmployeeName = 'Trice Moffett'
and EmployeeId = 'OI0260' --PK  08-31


Delete
From #Final
where
EmployeeName = 'Christina Martensen'
and EmployeeId = 'OI0261'--PK 08-31


Update #Final
Set EmployeeName = 'Julian Pickie'
where
EmployeeName like '%Julie Maramba Pickie%'


Update #Final
Set TitleGrouping = 'Dispatch Agent - Infosys'
where
EmployeeEmail like 'gracia.asoh@pnmac.com'
and Period < 201904


Update #Final
Set TitleGrouping = 'Dispatch Agent - Infosys'
where
EmployeeEmail like 'Audrey.Williams@pnmac.com'
and Period < 201904



Update #Final
Set EmployeeEmail = 'debbie.ruiz@pnmac.com'
where
EmployeeEmail like 'debbie.silva@pnmac.com'




Update #Final
Set EmployeeName = 'Dominque Barber'
where
EmployeeName like 'Domonique Barber'


Update #Final
Set EmployeeName = 'Barry Blackson'
where
EmployeeName like 'Barry L Blackson'


/* Added by Jleyba 20181228*/

Update #Final
Set EmployeeName = 'Ronald Braudaway'
where
EmployeeName = 'Mark Braudaway'


Update #Final
Set EmployeeName = 'Wanda French-Wallace'
where
EmployeeName = 'Wanda French'

Update #Final
Set EmployeeName = 'Jennifer Clem'
where
EmployeeName = 'Jenny Clem'

Update #Final
Set EmployeeName = 'Pamela Turner'
where
EmployeeName = 'Pam Turner'

/* Added by Jleyba 20190109*/

Update #Final
Set EmployeeName = 'Raymond Nowell'
where
EmployeeName = 'Ray Nowell'


/* Added by Jleyba 20190211*/

Update #Final
Set EmployeeName = 'William Hang'
where
EmployeeName = 'Will Hang'


/* Added by Jleyba 20190315*/

Update #Final
Set EmployeeName = 'Michael Tarzian'
where
EmployeeName = 'Mike Tarzian'


Update #Final
Set EmployeeName = 'Gene Ackerman III'
where
EmployeeName = 'Geno Ackerman'



Update #Final
Set EmployeeName = 'Margaret Isuo'
where
EmployeeEmail = 'margaret.isuo@pnmac.com'


Update #Final
Set EmployeeName = 'Gaitree Shanahan'
where
EmployeeName = 'Gai Shanahan'

Update #Final
Set EmployeeEmail = 'gai.shanahan@pnmac.com'
where
EmployeeEmail = 'gaitree.shanahan@pnmac.com'



Update #Final
Set EmployeeName = 'Debbie Igarashi'
where
EmployeeName = 'Deborah Igarashi'


/* Added by Jleyba 20190403*/


Update #Final
set EmployeeName = 'Mary Lou DiPalo'
where EmployeeName = 'Mary DiPalo'


Update #Final
Set Employeename = 'Joyer Chase'
Where Employeename = 'Joyer Ivey'

/* Added by Jleyba 20190612*/


Update #Final
Set Employeename = 'Timothy Thompson'
Where Employeename = 'Tim Thompson'


/* Added by Jleyba 20190903 For Email process*/

  update #Final
  set Title = 'No Title Provided'
  where EmployeeName like '%Ashley Tolliver%'
  and title is null



/*LOGIC NEEDED TO CALIBRATE CORRECTLY - DO NOT DELETE*/
Update #Final
Set ManagerName_TwoUp = 'Carl Illum',
	ManagerName = 'Aaron Hatfield'
Where EmployeeName = 'Hessam Kiani'
and EmploymentStatus = 'Terminated'
and Period >= 201908

--======================================================================================
--======================================================================================
-----Staffing Changes Pending HR
-----Employment status LOA or Terminated
--======================================================================================
--======================================================================================
UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/27/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'jamilynn.merolle@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/13/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'hailee.allen@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/09/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
    'angel.potts@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/02/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'akop.yerkanyan@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/09/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
    'travis.vorbeck@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/08/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
    'Edith.Torosyan@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/08/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'connor.loftis@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/07/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'cesar.flores@pnmac.com',
    'jamie.adcock@pnmac.com',
    'rachel.connolly@pnmac.com',
    'elena.akopyan@pnmac.com',
    'jason.martinez@pnmac.com',
    'roudvik.abdalian@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/07/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
    'austin.schreibman@pnmac.com'
    )
UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/04/2022',
LOAPeriod = 202205
WHERE Period >= 202205
and EmployeeEmail in (
    'kaitey.gates@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'Terminated',
    TerminationDate = '06/07/2022',
    TermPeriod = 202206
WHERE Period = 202206
    and EmployeeEmail in (
    'martin.ramirez@pnmac.com'--,
    --'leo.shahnazari@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/01/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
    'reid.wright@pnmac.com'
    ,'michael.payne@pnmac.com'
    )


UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/25/2022',
LOAPeriod = 202205
WHERE Period = 202205 and LOADate is null
and EmployeeEmail in (
    'jamilynn.merolle@pnmac.com'
    )

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '06/03/2022',
LOAPeriod = 202206
WHERE Period = 202206
and EmployeeEmail in (
	'alfred.reams@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/25/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'clyde.anderson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/24/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'moses.hernandez@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/23/2022',
LOAPeriod = 202205
WHERE Period = 202205
and EmployeeEmail in (
	'paul.lechich@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/16/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'everardo.zaragoza@pnmac.com'
	,'emily.morris@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '2020-07-17',
	TermPeriod = 202007
WHERE Period >= 202007
	and EmployeeId IN (
	 'V12724'
	,'006101'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '2022-03-16',
LOAPeriod = 202203
WHERE Period >= 202203
and EmployeeId in (
	'V10183'
	,'012224'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '2022-03-01',
LOAPeriod = 202203
WHERE Period >= 202203
and EmployeeId in (
	'V07735'
	,'V08035'
	,'005779'
	,'007328'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeId IN (
	'V01337'
	,'V01560'
	,'V05427'
	,'V06507'
	,'V06577'
	,'V07276'
	,'V09201'
	,'V11001'
	,'V11551'
	,'012080'
	,'010207'
	,'006318'
	,'011127'
	,'011987'
	,'006411'
	,'011613'
	,'011953'
	,'011689'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/11/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'courtney.bettcher@pnmac.com'
	,'joshua.quebada@pnmac.com'
	,'dale.pancho@pnmac.com'
	,'justin.hansen@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/06/2022',
LOAPeriod = 202205
WHERE Period = 202205
and EmployeeEmail in (
	'tauny.durruthy@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/10/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'heather.blowers@pnmac.com'
	)


UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/09/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'hassan.raza@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/06/2022',
LOAPeriod = 202205
WHERE Period = 202205
and EmployeeEmail in (
	'felix.kim@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/06/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'sipan.beglaryan@pnmac.com'
	,'jamiya.prewitt@pnmac.com'
	,'daniel.silvey@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/28/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'brock.likens@pnmac.com'
	,'christian.smith@pnmac.com'
	,'isaac.solorio@pnmac.com'
	,'joshua.alvarez@pnmac.com'
	,'richard.guice@pnmac.com'
	,'scott.nash@pnmac.com'
	,'mark.carter@pnmac.com'
	,'frank.saputo@pnmac.com'
	,'martha.austin@pnmac.com'
	,'elsa.ramirez@pnmac.com'
	,'tamara.henderson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/20/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'ian.burkhardt@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/04/2022',
LOAPeriod = 202205
WHERE Period = 202205
and EmployeeEmail in (
	'rod.walker@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '05/09/2022',
LOAPeriod = 202205
WHERE Period = 202205
and EmployeeEmail in (
	'anthony.tabor@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/26/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'cameron.hall@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/02/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'justin.frerichs@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/02/2022',
	TermPeriod = 202205
WHERE Period = 202205
	and EmployeeEmail in (
	'brian.green@pnmac.com',
	'Matthew.Flores@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/28/2022',
	TermPeriod = 202204
WHERE Period >= 202204
	and EmployeeEmail in (
	'christina.sullivan@pnmac.com'
	,'damian.olmedo@pnmac.com'
	,'daniel.craun@pnmac.com'
	,'johnathan.warren@pnmac.com'
	,'kenny.fatino@pnmac.com'
	,'nidia.valencia@pnmac.com'
	,'ottokar.pek@pnmac.com'
	,'ryan.ward@pnmac.com'
	,'sarfraz.khan@pnmac.com'
	,'saviz.hatam@pnmac.com'
	,'tobias.blanchard@pnmac.com'
	,'cody.taylor@pnmac.com'
	,'daniel.ngo@pnmac.com'
	,'david.arsenyan@pnmac.com'
	,'deaon.sanders@pnmac.com'
	,'dominique.sinsay@pnmac.com'
	,'donald.cook@pnmac.com'
	,'ed.varon@pnmac.com'
	,'erik.karibas@pnmac.com'
	,'jermaine.stevenson@pnmac.com'
	,'kristopher.kast@pnmac.com'
	,'kyle.vane@pnmac.com'
	,'manuk.manukyan@pnmac.com'
	,'mark.fitzpatrick@pnmac.com'
	,'mark.guillermo@pnmac.com'
	,'michael.peluso@pnmac.com'
	,'mireya.gutierrez@pnmac.com'
	,'caleb.richard@pnmac.com'
	,'dustin.fletcher@pnmac.com'
	,'jonathan.schulte@pnmac.com'
	,'mark.cobb@pnmac.com'
	,'nathan.schirmer@pnmac.com'
	,'rick.busalacchi@pnmac.com'
	,'roberto.annoni@pnmac.com'
	,'samantha.piccirillo@pnmac.com'
	,'tommy.jackson@pnmac.com'
	,'tracie.jones@pnmac.com'
	,'andre.pettas@pnmac.com'
	,'art.soto@pnmac.com'
	,'jc.gray@pnmac.com'
	,'john.anderson@pnmac.com'
	,'jordan.skousen@pnmac.com'
	,'justino.villamil@pnmac.com'
	,'kimberly.valdez@pnmac.com'
	,'krystal.wedlow@pnmac.com'
	,'margaret.erickson@pnmac.com'
	,'patrick.nielsen@pnmac.com'
	,'peter.carter@pnmac.com'
	,'mark.carter@pnmac.com'
	,'caroline.sessa@pnmac.com'
	,'patrick.fleckenstein@pnmac.com'
	)

UPDATE #Final --1.1
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/28/2022',
	TermPeriod = 202204
WHERE Period in (202204, 202205)
	and EmployeeEmail in (
	'cody.taylor@pnmac.com',
	'daniel.ngo@pnmac.com',
	'david.arsenyan@pnmac.com',
	'deaon.sanders@pnmac.com',
	'dominique.sinsay@pnmac.com',
	'donald.cook@pnmac.com',
	'ed.varon@pnmac.com',
	'erik.karibas@pnmac.com',
	'jermaine.stevenson@pnmac.com',
	'kristopher.kast@pnmac.com',
	'kyle.vane@pnmac.com',
	'manuk.manukyan@pnmac.com',
	'mark.fitzpatrick@pnmac.com',
	'mark.guillermo@pnmac.com',
	'michael.peluso@pnmac.com',
	'mireya.gutierrez@pnmac.com',
	'anthony.burns@pnmac.com',
	'dustin.fletcher@pnmac.com',
	'jonathan.schulte@pnmac.com',
	'mark.cobb@pnmac.com',
	'nathan.schirmer@pnmac.com',
	'nija.ross@pnmac.com',
	'oswald.browne@pnmac.com',
	'ravi.malhotra@pnmac.com',
	'rick.busalacchi@pnmac.com',
	'roberto.annoni@pnmac.com',
	'samantha.piccirillo@pnmac.com',
	'tommy.jackson@pnmac.com',
	'tracie.jones@pnmac.com',
	'abbas.suliman@pnmac.com',
	'andrew.yasno@pnmac.com',
	'brett.fraser@pnmac.com',
	'christopher.bozel@pnmac.com',
	'cody.anderson@pnmac.com',
	'dylan.maio@pnmac.com',
	'eddy.pineda@pnmac.com',
	'eric.farnell@pnmac.com',
	'erind.bisha@pnmac.com',
	'francisco.duran@pnmac.com',
	'jairo.rodriguez@pnmac.com',
	'jean.lambertson@pnmac.com',
	'jeffrey.johnson@pnmac.com',
	'jeremiah.kneeland@pnmac.com',
	'joshua.guest@pnmac.com',
	'kelly.mason@pnmac.com',
	'kuno.kaulbars@pnmac.com',
	'manushak.marsoubian@pnmac.com',
	'maria.espana@pnmac.com',
	'michael.klein@pnmac.com',
	'michael.miller@pnmac.com',
	'michael.powers@pnmac.com',
	'michael.zajac@pnmac.com',
	'nicholas.grandchamp@pnmac.com',
	'phillip.brown1@pnmac.com',
	'terry.taylor@pnmac.com',
	'tonya.watkins@pnmac.com',
	'zohaib.malik@pnmac.com',
	'alan.croasdale@pnmac.com',
	'andre.pettas@pnmac.com',
	'art.soto@pnmac.com',
	'bree.bailey@pnmac.com',
	'carina.ramos@pnmac.com',
	'christa.keran@pnmac.com',
	'colton.anner@pnmac.com',
	'daniel.sipp@pnmac.com',
	'deirdre.rose@pnmac.com',
	'devin.sundheim@pnmac.com',
	'diana.tulia@pnmac.com',
	'ernest.howard@pnmac.com',
	'gerardo.carranza@pnmac.com',
	'jc.gray@pnmac.com',
	'john.anderson@pnmac.com',
	'jordan.skousen@pnmac.com',
	'juan.alvarez@pnmac.com',
	'kimberly.valdez@pnmac.com',
	'krystal.wedlow@pnmac.com',
	'marcia.rodriguez@pnmac.com',
	'margaret.erickson@pnmac.com',
	'patrick.nielsen@pnmac.com',
	'paul.t.szymanski@pnmac.com',
	'peter.carter@pnmac.com',
	'william.smith@pnmac.com',
	'amy.wilder@pnmac.com',
	'brad.harley@pnmac.com',
	'brock.likens@pnmac.com',
	'christian.smith@pnmac.com',
	'christopher.toler@pnmac.com',
	'elsa.ramirez@pnmac.com',
	'eric.almazan@pnmac.com',
	'ezio.cecchet@pnmac.com',
	'frank.saputo@pnmac.com',
	'david.miller@pnmac.com',
	'isaac.solorio@pnmac.com',
	'jackie.sager@pnmac.com',
	'jordan.mcdonald@pnmac.com',
	'joshua.alvarez@pnmac.com',
	'mark.carter@pnmac.com',
	'martha.austin@pnmac.com',
	'matthew.stephens@pnmac.com',
	'patrick.williams@pnmac.com',
	'richard.guice@pnmac.com',
	'scott.nash@pnmac.com',
	'tamara.henderson@pnmac.com',
	'todd.maier@pnmac.com',
	'christina.sullivan@pnmac.com',
	'damian.olmedo@pnmac.com',
	'daniel.craun@pnmac.com',
	'johnathan.warren@pnmac.com',
	'kenny.fatino@pnmac.com',
	'nidia.valencia@pnmac.com',
	'ottokar.pek@pnmac.com',
	'ryan.ward@pnmac.com',
	'sarfraz.khan@pnmac.com',
	'saviz.hatam@pnmac.com',
	'tobias.blanchard@pnmac.com',
	'jasmine.foy@pnmac.com',
	'john.garrett@pnmac.com',
	'madison.booth@pnmac.com',
	'nathan.behrens@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/27/2022',
	TermPeriod = 202204
WHERE Period >= 202204
	and EmployeeEmail in (
	'olive.njombua@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/13/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'christopher.muncal@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/12/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'courtney.sandison@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/08/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'michael.fascetti@pnmac.com'
	,'daniel.torres@pnmac.com'
	,'angela.walters@pnmac.com'
	,'brian.stoddard@pnmac.com'
	,'julia.shupe@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/07/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'brittney.hinson@pnmac.com'
	,'amber.prasopoulos@pnmac.com'
	,'jeffery.dorothy@pnmac.com'
	,'nick.bonifacio@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/06/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'stephen.castaneda@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/05/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'clay.hagler@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/11/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'janice.randall@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/18/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'michael.bojaj@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/28/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'joseph.marek@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/04/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'leo.jordan@pnmac.com'
	)

UPDATE #Final
SET LOADate = '04/04/2022',
LOAPeriod = 202204
WHERE Period = 202205
and EmployeeEmail in (
	'leo.jordan@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '04/01/2022',
LOAPeriod = 202204
WHERE Period = 202204
and EmployeeEmail in (
	'abdul.saleh@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/01/2022',
	TermPeriod = 202204
WHERE Period = 202204
	and EmployeeEmail in (
	'brandon.washington@pnmac.com',
	'gabriel.vallarta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/31/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'ernesto.godoy@pnmac.com',
	'angie.dudley@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '03/18/2022',
LOAPeriod = 202203
WHERE Period = 202203
and EmployeeEmail in (
	'gerardo.carranza@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '03/18/2022',
LOAPeriod = 202203
WHERE Period = 202203
and EmployeeEmail in (
	'janice.randall@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/30/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'sam.smith@pnmac.com',
	'anita.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/29/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'arthur.hachikian@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '03/28/2022',
LOAPeriod = 202203
WHERE Period = 202203
and EmployeeEmail in (
	'ross.ahkiong@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/28/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'peter.perez@pnmac.com',
	'eric.leonard@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/09/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'yazan.albalouli@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/08/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'justin.nesbitt@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/04/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'jeff.borgognoni@pnmac.com'
	,'nathan.robinson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/07/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'george.ballard@pnmac.com'
	,'tanya.queen@pnmac.com'
	,'quane.fashaw@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/07/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'ryan.cohen@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/07/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'tatum.thompson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '03/07/2022',
LOAPeriod = 202203
WHERE Period = 202203
and EmployeeEmail in (
	'giovanni.fernandez@pnmac.com',
	'nathaniel.husser@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/28/2022',
LOAPeriod = 202202
WHERE Period = 202202
and EmployeeEmail in (
	'paul.t.szymanski@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '03/01/2022',
LOAPeriod = 202203
WHERE Period = 202203
and EmployeeEmail in (
	'samuel.ngu@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/23/2022',
LOAPeriod = 202202
WHERE Period between 202202 and 202204
and EmployeeEmail in (
	'kevin.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/03/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'jose.ramirez@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/01/2022',
	TermPeriod = 202203
WHERE Period = 202203
	and EmployeeEmail in (
	'laurie.baker@pnmac.com',
	'cesar.peralta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/25/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'alejandro.rojas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/24/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'kyle.atteberry@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/16/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'alessandra.malta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/15/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'john.curran@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/10/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'shelbi.janssen@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/23/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'jordan.correa@pnmac.com',
	'areg.nazarian@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/22/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'melissa.key@pnmac.com',
	'will.rowe@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/22/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'mitchell.peralta@pnmac.com',
	'alexa.michael@pnmac.com',
	'justin.beck@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/22/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'mitchell.peralta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/22/2022',
LOAPeriod = 202202
WHERE Period = 202202
and EmployeeEmail in (
	'kyle.yu@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/09/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'jason.tomiello@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/10/2022',
LOAPeriod = 202202
WHERE Period = 202202
and EmployeeEmail in (
	'khadeeja.ali@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/10/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'ashley.ayala@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/08/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'david.brown@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/08/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'garrett.greene@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/01/2022',
LOAPeriod = 202202
WHERE Period = 202202
and EmployeeEmail in (
	'anita.jones@pnmac.com'
	)

UPDATE #Final
SET LOADate = '02/01/2022',
	LOAPeriod = 202202
WHERE Period = 202203
AND EmployeeEmail in (
	'anita.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '02/04/2022',
LOAPeriod = 202202
WHERE Period = 202202
and EmployeeEmail in (
	'kyle.yu@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/07/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'peter.blancarte@pnmac.com'
	,'roberto.perez@pnmac.com'
	,'preston.orellana@pnmac.com'
	,'eric.leverton@pnmac.com'
	,'vanessa.hansard@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/04/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'sue.nebbio@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/02/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	'cynthia.williamson@pnmac.com',
	'michael.willis@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/08/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
    'benedick.magcalas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/04/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
    'alex.bozymowski@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '02/01/2022',
	TermPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
    'asiah.dorsey@pnmac.com',
	'nathaniel.clark@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/31/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'cameron.freeland@pnmac.com'
	)

UPDATE  #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/18/2022',
	LOAPeriod = 202201
WHERE Period between 202201 and 202204
	and EmployeeEmail in (
	 'kc.packer@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/20/2022',
	LOAPeriod = 202201
WHERE Period >= 202201
	and EmployeeEmail in (
	 'alessandra.malta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/27/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'rachel.connolly@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '02/01/2022',
	LOAPeriod = 202202
WHERE Period = 202202
	and EmployeeEmail in (
	 'ian.burkhardt@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/28/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'melissa.franklin1@pnmac.com'
	,'rob.arias@pnmac.com'
	,'victoria.groeger@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/27/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'hesham.samaan@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/24/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'karen.montgomery@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/20/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'alessandra.malta@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '09/06/2021',
LOAPeriod = 202109
WHERE Period between 202109 and 202203
and EmployeeEmail in (
	'ed.vandervelde@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
LOADate = '11/24/2021',
LOAPeriod = 202111
WHERE Period between 202111 and 202202
and EmployeeEmail in (
	'brian.stoddard@pnmac.com'
	)

UPDATE #Final
SET LOADate = '11/24/2021',
LOAPeriod = 202111
WHERE Period >= 202111
and EmployeeEmail in (
	'brian.stoddard@pnmac.com'
	)

UPDATE #Final
SET LOAEndDate = '04/17/2022'
WHERE Period >= 202204
and EmployeeEmail in (
	'ed.vandervelde@pnmac.com'
	)

UPDATE #Final
SET LOAEndDate = '02/02/2022'
WHERE Period >= 202202
and EmployeeEmail in (
	'brian.stoddard@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/11/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'karen.montgomery@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/10/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'truc.le@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/04/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'khadeeja.ali@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/06/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'sasha.drawdy@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/07/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	 'ashley.rico@pnmac.com'
	,'babak.javaherpour@pnmac.com'
	,'eysvetleina.seneres@pnmac.com'
	,'melonique.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/05/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'tracy.corsey@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '12/16/2021',
	LOAPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'kerry.lucas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/03/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'esther.lozano@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/04/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'kenney.barrientos@pnmac.com'
	,'tedrig.khachadore@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/07/2022',
	TermPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'henry.marron@pnmac.com'
	,'sevada.babakhani@pnmac.com'
	,'christopher.reynosa@pnmac.com'
	,'joseph.wagner@pnmac.com'
	,'connie.serrano@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/29/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'abigail.rupin@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '01/06/2022',
	TermPeriod = 202211
WHERE Period = 202211
	and EmployeeEmail in (
	'eysvetleina.seneres@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '01/03/2022',
	LOAPeriod = 202201
WHERE Period = 202201
	and EmployeeEmail in (
	'yazan.albalouli@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/29/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	 'cindy.hudgins@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/27/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	 'joseph.duffy@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/23/2021',
	TermPeriod = 202112
WHERE Period >= 202112
	and EmployeeEmail in (
	 'raymond.hays@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/21/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'justin.braden@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/21/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	 'ashley.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/20/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	 'kaitlin.smith@pnmac.com'
	,'james.byers@pnmac.com'
	,'brittany.garcia@pnmac.com'
	,'michael.reul@pnmac.com'
	,'rich.ferre@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/17/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	 'kevin.breunig@pnmac.com'
	,'jessica.ciero@pnmac.com'
	,'makagan.mitchell@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/27/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'sulayman.ghafarzada@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/14/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'victoria.nick@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/14/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'penny.reed@pnmac.com'
	,'andrea.flores@pnmac.com'
	, 'christopher.johnson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/13/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'jeffrey.lemke@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/08/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'dana.goodmiller@pnmac.com'
	,'elijah.kneeland@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '12/07/2021',
	LOAPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'patty.schultz@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/07/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'lauren.ballard@pnmac.com'
	,'correna.watson@pnmac.com'
	,'evan.green@pnmac.com'
	,'jasson.jimenezjuarez@pnmac.com'
	,'steven.owens@pnmac.com'
	, 'michael.herbst@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/03/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'roger.cuevas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/01/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'ruben.rodriguez@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/01/2021',
	TermPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'jordan.pyle@pnmac.com'
	,'ruben.rodriguez1@pnmac.com'
	,'keith.williams@pnmac.com'
	,'roberto.montero@pnmac.com'
	,'ryan.p.wilson@pnmac.com'
	,'ashley.jones@pnmac.com'
	,'gabrielle.simo@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '12/01/2021',
	LOAPeriod = 202112
WHERE Period = 202112
	and EmployeeEmail in (
	'gabrielle.simo@pnmac.com'
	,'thomas.papageorge@pnmac.com'
	,'alexander.soria@pnmac.com'
	,'maritza.chiaway@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '11/30/2021',
	LOAPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'jany.alvarez@pnmac.com'
	)


UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	 'barry.clay@pnmac.com'
	,'carli.kelley@pnmac.com'
	,'sherena.walters@pnmac.com'
	,'sharon.dennis@pnmac.com'
	,'nicolene.essers@pnmac.com'
	,'emma.hardin@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/19/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'carli.kelley@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/19/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'freddie.garciaflores@pnmac.com'
	,'cody.sorells@pnmac.com'
	,'ashley.smaldino@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/09/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'al.nasser@pnmac.com',
	'jason.minor@pnmac.com',
	'kristen.malave@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/08/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'paul.schweizer@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '11/15/2021',
	LOAPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'brittany.garcia@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '11/08/2021',
	LOAPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'michael.ammari@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '11/08/2021',
	LOAPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'carlo.abarro@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/05/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'mark.stoppa@pnmac.com'
	,'brian.butler@pnmac.com'
	,'ashley.burkes@pnmac.com'
	,'wyatt.coplen@pnmac.com'
	,'brian.butler@pnmac.com'
	,'michael.pemberton@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/03/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'richard.herrin@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/01/2021',
	TermPeriod = 202111
WHERE Period = 202111
	and EmployeeEmail in (
	'abigail.wilson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/29/2021',
	TermPeriod = 202110
WHERE Period = 202110
	and EmployeeEmail in (
	'usman.ali@pnmac.com',
	'kaylyn.seleman@pnmac.com',
	'augusto.cotte@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '10/26/2021',
	LOAPeriod = 202110
WHERE Period in (202110, 202111)
	and EmployeeEmail in (
	'paul.schweizer@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '10/11/2021',
	LOAPeriod = 202110
WHERE Period in (202110, 202111)
	and EmployeeEmail in (
	'stephen.castaneda@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Active',
	TerminationDate = NULL,
	TermPeriod = NULL
WHERE Period = 202109
	and EmployeeEmail in (
	'tanner.barge@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/20/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'andrew.pennywell@pnmac.com',
	'bryan.popp@pnmac.com',
	'kane.wilkin@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '09/13/2021',
	LOAPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'kim.hong@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '09/09/2021',
	LOAPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'suzanne.tonoli@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/10/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'ted.coburn@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/03/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'neal.marchin@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/03/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'craig.jones@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/03/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'hamilton.duong@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/03/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'samson.nargizyan@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/03/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'henry.nguyen@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '09/02/2021',
	TermPeriod = 202109
WHERE Period = 202109
	and EmployeeEmail in (
	'michele.heck@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '08/19/2021',
	TermPeriod = 202108
WHERE Period between 202108 and 202110
	and EmployeeEmail in (
	'v-shaun.thompson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '08/11/2021',
	TermPeriod = 202108
WHERE Period = 202108
	and EmployeeEmail in (
	'austin.holman@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '08/05/2021',
	TermPeriod = 202108
WHERE Period = 202108
	and EmployeeEmail in (
	'andre.oliveira@pnmac.com',
	'dylan.kohl@pnmac.com',
	'lymar.cole@pnmac.com'
	)

--UPDATE #Final
--SET EmploymentStatus = 'LOA',
--	LOADate = '08/04/2021',
--	LOAPeriod = 202108
--WHERE Period = 202108
--	and EmployeeEmail in (
--	'justin.beck@pnmac.com'
--	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '08/01/2021',
	TermPeriod = 202108
WHERE Period = 202108
	and EmployeeEmail in (
	'curtis.brown@pnmac.com',
	'huong.tran@pnmac.com',
	'sean.fitzgeraldmcgill@pnmac.com',
	'shannon.ryle@pnmac.com',
	'tyler.richardson@pnmac.com'
	)

UPDATE #Final
SET LOADate = NULL,
	LOAPeriod = NULL
WHERE Period = 202106
	and EmployeeEmail in (
	'daniel.craun@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '05/13/2021',
	LOAPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'daniel.craun@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '06/08/2021',
	TermPeriod = 202106
WHERE Period = 202106
	and EmployeeEmail in (
	'kirk.blackshear@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '06/01/2021',
	LOAPeriod = 202106
WHERE Period = 202106
	and EmployeeEmail in (
	'connie.serrano@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '06/07/2021',
	TermPeriod = 202106
WHERE Period = 202106
	and EmployeeEmail in (
	'dylan.greene@pnmac.com',
	'jake.jacobs@pnmac.com',
	'jameson.davis@pnmac.com',
	'tim.snow@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '06/01/2021',
	TermPeriod = 202106
WHERE Period = 202106
	and EmployeeEmail in (
	'anibal.zavala@pnmac.com'
	)



UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/19/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'george.kala@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/20/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'gabrialla.gabriel@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/10/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'patrick.quinlan@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/03/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'michael.johnson@pnmac.com',
	'daniel.pollock@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/10/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'emmett.kinsella@pnmac.com',
	'jill.cunningham@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/07/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'allen.brunner@pnmac.com',
	'william.bailey@pnmac.com',
	'jay.suter@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/04/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'sairraj.stephens@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/06/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'david.jayson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '05/05/2021'
WHERE Period = 202105
	and EmployeeEmail in (
	'gabrialla.gabriel@pnmac.com',
	'braxton.bearden@pnmac.com',
	'abigail.wilson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '05/05/2021',
	TermPeriod = 202105
WHERE Period = 202105
	and EmployeeEmail in (
	'haylee.dimeo@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '05/03/2021'
WHERE Period = 202105
	and EmployeeEmail in (
	'taylor.crume@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/23/2021',
	TermPeriod = 202104
WHERE Period = 202104
	and EmployeeEmail in (
	'kaitlynn.kern@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/22/2021',
	TermPeriod = 202104
WHERE Period = 202104
	and EmployeeEmail in (
	'hector.centeno@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '03/25/2021'
WHERE Period in (202103, 202104)
	and EmployeeEmail in (
	'emmett.kinsella@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '04/01/2021',
	TermPeriod = 202104
WHERE Period = 202104
	and EmployeeEmail in (
	'scott.coughlin@pnmac.com',
	'david.hernandez@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/31/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'valeria.saravia@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/30/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'sean.mcmanamon@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/29/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'jared.falk@pnmac.com',
	'ronald.baker@pnmac.com',
	'abed.almaoui@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/26/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'connor.burns@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/25/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'frank.espree@pnmac.com',
	'jason.konopaske@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/23/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'andy.anneville@pnmac.com',
	'brielle.ware@pnmac.com',
	'john.kimble@pnmac.com',
	'connie.duong@pnmac.com',
	'logan.sagely@pnmac.com',
	'brandon.peterson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/22/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'corey.golden@pnmac.com',
	'sj.killlian@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/19/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'michael.weber@pnmac.com',
	'jason.dodds@pnmac.com',
	'barbara.dudzienski@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/16/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'ryan.peppers@pnmac.com',
	'shannon.smallman@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/15/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'janet.franklin@pnmac.com',
	'drew.kozel@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/15/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'david.kater@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/12/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'jennifer.tobar@pnmac.com',
	'lawrence.mike@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/08/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'mirza.jasarevic@pnmac.com',
	'rabon.patterson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/30/2021',
	LOAPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'adam.key@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/25/2021',
	LOAPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'nicole.graham@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/15/2021',
	LOAPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'juan.barron@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/1/2021',
	LOAPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'abed.almaoui@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/1/2021',
	LOAPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'vincent.cooper@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '03/01/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'thomas.johnson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '3/01/2021',
	TermPeriod = 202103
WHERE Period = 202103
	and EmployeeEmail in (
	'tonisha.brown@pnmac.com',
	'jonnie.maretti@pnmac.com',
	'dominic.iglesias@pnmac.com',
	'aimee.long@pnmac.com'
	)
UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '2/18/2021',
	TermPeriod = 202102
WHERE Period = 202102
	and EmployeeName in (
	'Logan Sagely'
	)
	and EmployeeEmail in (
	'logan.sagely@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '2/01/2021',
	TermPeriod = 202102
WHERE Period = 202102
	and EmployeeName in (
	'Luis Larcina'
	)
	and EmployeeEmail in (
	'luis.larcina@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '2/01/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Fred Aghili'
	)
	and EmployeeEmail in (
	'fred.aghili@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/12/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Sokhom Sim'
	)
	and EmployeeEmail in (
	'sokhom.sim@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/7/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Sheryl Contreras'
	)
	and EmployeeEmail in (
	'sheryl.contreras@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/8/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Tyler Stephens'
	)
	and EmployeeEmail in (
	'tyler.stephens@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/8/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Michael Steel'
	)
	and EmployeeEmail in (
	'michael.steel@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/7/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Danny Finlay'
	)
	and EmployeeEmail in (
	'danny.finlay@pnmac.com'
	)

UPDATE #Final
SET 	EmploymentStatus = 'Terminated',
	TerminationDate = '1/7/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Gregory Stage Jr'
	)
	and EmployeeEmail in (
	'gregory.stage@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/7/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Michael Thompson'
	)
	and EmployeeEmail in (
	'michael.thompson@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '1/4/2021',
	LOAPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Deanna Crawford'
	)
	and EmployeeEmail in (
	'deanna.crawford@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/5/2021',
	TermPeriod = 202101
WHERE Period = 202101
	and EmployeeName in (
	'Cristobal Garcia'
	)
	and EmployeeEmail in (
	'cristobal.garcia@pnmac.com'
	)

UPDATE #Final --BACK FROM LOA
SET EmploymentStatus = 'Active'
WHERE Period = 202101
	and EmployeeName in (
	'David Kater'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '12/10/2020',
	LOAPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Sydney Barnes'
	)
	and EmployeeEmail in (
	'sydney.barnes@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/21/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Carl Thomas'
	)
	and EmployeeEmail in (
	'carl.thomas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/18/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Simone Wood'
	)
	and EmployeeEmail in (
	'simone.wood@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/18/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Solo Mesumbe'
	)
	and EmployeeEmail in (
	'solomon.mesumbe@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/16/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Brittany Fischer'
	)
	and EmployeeEmail in (
	'brittany.fischer@pnmac.com'
	)


UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/14/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Michael Gingras'
	)
	and EmployeeEmail in (
	'michael.gingras@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/07/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Phillip Zayas'
	)
	and EmployeeEmail in (
	'phillip.zayas@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/07/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Moe Bannat'
	)
	and EmployeeEmail in (
	'moe.bannat@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/07/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Dino Rousseve'
	)
	and EmployeeEmail in (
	'dino.rousseve@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/03/2020',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Jirir Wosgerijyan'
	)
	and EmployeeEmail in (
	'jirir.wosgerijyan@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/3/20',
	TermPeriod = 202012
WHERE Period = 202012
	and EmployeeName in (
	'Lloyd Smith'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/30/20',
	TermPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Celso Dockhorn'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/24/20',
	TermPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Max Cordy'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/20/20',
	TermPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Clinton Harris'
	)

UPDATE #Final
SET EmploymentStatus = 'LOA',
	LOADate = '11/11/20',
	LOAPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Gwendolyn Munder'
	)
	and EmployeeEmail in (
	'gwendolyn.munder@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/11/20',
	TermPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Chris Porter'
	)
	and EmployeeEmail in (
	'chris.porter@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/09/20',
	TermPeriod = 202011
WHERE Period = 202011
	and EmployeeName in (
	'Daniel Turner'
	)
	and EmployeeEmail in (
	'daniel.turner@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/30/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'William Slater'
	)
	and EmployeeEmail in (
	'william.slater@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/30/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'Christopher Cruz'
	)
	and EmployeeEmail in (
	'christopher.cruz@pnmac.com'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/21/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'Rebecca Starr'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/9/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'Alexandra Omalley'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/6/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'Micah Ramos',
	'Nina Moshiri',
	'Daily Webb',
	'Andrew Arakelian'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/5/20',
	TermPeriod = 202010
WHERE Period = 202010
	and EmployeeName in (
	'Mark Mitchell'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/23/20',
	TermPeriod = 202009
WHERE Period = 202009
	and EmployeeName in (
	'Lauren Swartz'
	)

Update #Final
SET EmploymentStatus = 'LOA',
	LOADate = '9/21/20',
	LOAPeriod = 202009
WHERE Period = 202009
	and EmployeeName in (
	'Kyle Yu'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/8/20',
	TermPeriod = 202009
WHERE Period = 202009
	and EmployeeName in (
	'Steven Bruce'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/1/20',
	TermPeriod = 202009
WHERE Period = 202009
	and EmployeeName in (
	'Carl Wren'
	)

UPDATE #Final
SET LOADate = '8/28/20'
WHERE LOADate = '7/1/20'
	and EmployeeName in (
	'Christina Sullivan'
	)

UPDATE #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '8/24/20',
	TermPeriod = 202008
WHERE Period = 202008
	and EmployeeName in (
	'Jolene Regan'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '8/6/20',
	TermPeriod = 202008
WHERE Period = 202008
	and EmployeeName in (
	'Matt Saladino',
	'John Rodgers',
	'Victor Martinez'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '8/3/20',
	TermPeriod = 202008
WHERE Period = 202008
	and EmployeeName in (
	'Tony Tsiligian',
	'Haroutun Arzrounian',
	'Amir Rizvi',
	'Krystan Keyes'
	)

Update #Final
SET LOADate = '7/21/20'
WHERE LOADate = '7/1/20'
	and EmployeeName in (
	'Elizabet Ovakimyan'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/21/20',
	TermPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Fahali Campbell'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/20/20',
	TermPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Robert McGaughy'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/6/20',
	TermPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Evan Souza',
	'Wesley Black',
	'Kuno Kaulbars',
	'Sarah Brown'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/1/20',
	TermPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Severiano Rico',
	'Marlon Bivens'
	)

Update #Final
SET EmploymentStatus = 'LOA',
	LOADate = '7/1/20',
	LOAPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Brandon Locke'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/13/20',
	TermPeriod = 202007
WHERE Period = 202007
	and EmployeeName in (
	'Brandon Locke'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/16/20',
	TermPeriod = 202006
WHERE Period = 202006
	and EmployeeName in (
	'Justin Huse'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/12/20',
	TermPeriod = 202006
WHERE Period = 202006
	and EmployeeName in (
	'Elsie Tejeda'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/3/20',
	TermPeriod = 202006
WHERE Period = 202006
	and EmployeeName in (
	'Nathan Jackson'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/1/20',
	TermPeriod = 202006
WHERE Period = 202006
	and EmployeeName in (
	'Mohammed Ahmed'
	--,
	--'Hung Nguyen' --commented out to test and see if May term is reflected in next refresh
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/26/20',
	TermPeriod = 202005
WHERE Period = 202005
	and EmployeeName in (
	'Jeremy Brunson'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/8/20',
	TermPeriod = 202005
WHERE Period = 202005
	and EmployeeName in (
	'Robert Macias'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/4/20',
	TermPeriod = 202005
WHERE Period = 202005
	and EmployeeName in (
	'Robert Tovar',
	'Charles Noorzaie'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/1/20',
	TermPeriod = 202005
WHERE Period = 202005
	and EmployeeName in (
	'Shawnta Cody',
	'Benjamin Contreras'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/29/20',
	TermPeriod = 202004
WHERE Period = 202004
	and EmployeeName in (
	'Shauntelle Walker'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/15/20',
	TermPeriod = 202004
WHERE Period = 202004
	and EmployeeName in (
	'Keith Seeley'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/6/20',
	TermPeriod = 202004
WHERE Period = 202004
	and EmployeeName in (
	'Victor Lai'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/2/20',
	TermPeriod = 202004
WHERE Period = 202004
	and EmployeeName in (
	'Brian DiGiovanni'
	)



Update #Final
SET EmploymentStatus = 'LOA',
	LOADate = '6/1/20',
	LOAPeriod = 202006
WHERE Period = 202006
	and EmployeeName in (
	'Christopher Cruz'
	)



Update #Final
SET EmploymentStatus = 'LOA',
	LOADate = '3/30/20',
	LOAPeriod = 202003
WHERE Period = 202003
	and EmployeeName in (
	'Benedick Magcalas'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '3/6/20',
	TermPeriod = 202003
WHERE Period = 202003
	and EmployeeName in (
	'Angelique Muccio'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '2/3/20',
	TermPeriod = 202002
WHERE Period = 202002
	and EmployeeName in (
	'Juanita Giovanni'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/31/20',
	TermPeriod = 202001
WHERE Period in (202001, 202002)
	and EmployeeName in (
	'Jerry Burba'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/14/20',
	TermPeriod = 202001
WHERE Period = 202001
	and EmployeeName in (
	'Jack Cooper',
	'Mark Carpenter'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/7/20',
	TermPeriod = 202001
WHERE Period = 202001
	and EmployeeName in (
	'Mantell Beckham',
	'Selwam Naidu'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/6/20',
	TermPeriod = 202001
WHERE Period = 202001
	and EmployeeName in (
	'Nathan Lehmer'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '1/2/20',
	TermPeriod = 202001
WHERE Period = 202001
	and EmployeeName in (
	'Janelle Okuma'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/20/19',
	TermPeriod = 201912
WHERE Period = 201912
	and EmployeeName in (
	'Ian Bey'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/4/19',
	TermPeriod = 201912
WHERE Period = 201912
	and EmployeeName in (
	'Bruce Ramirez'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '12/4/19',
	TermPeriod = 201912
WHERE Period = 201912
	and EmployeeName in (
	'Marvin Zayas'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/29/19',
	TermPeriod = 201911
WHERE Period in (201911, 201912)
	and EmployeeName in (
	'Joshua Baker'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/22/19',
	TermPeriod = 201911
WHERE Period = 201911
	and EmployeeName in (
	'Nicholas DeVuono'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/8/19',
	TermPeriod = 201911
WHERE Period = 201911
	and EmployeeName in (
	'Jeremy Burnett'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '11/4/19',
	TermPeriod = 201911
WHERE Period = 201911
	and EmployeeName in (
	'Rovic Clemente'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/29/19',
	TermPeriod = 201910
WHERE Period = 201910
	and EmployeeName in (
	'Carl Viviano'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/28/19',
	TermPeriod = 201910
WHERE Period = 201910
	and EmployeeName in (
	'Storm Wilcoxen'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/3/19',
	TermPeriod = 201910
WHERE Period = 201910
	and EmployeeName in (
	'Gene Ackerman III',
	'Levi Vigna'
	)

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '10/1/19',
	TermPeriod = 201910
WHERE Period = 201910
	and EmployeeName in ('Benjamin Williams')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/30/19',
	TermPeriod = 201909
WHERE Period in (201909, 201910)
	and EmployeeName in ('Mike Sher')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/23/19',
	TermPeriod = 201909
WHERE Period = 201909
	and EmployeeName in ('James Kozar')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '9/12/19',
	TermPeriod = 201909
WHERE Period = 201909
	and EmployeeName in ('Steven Vargas')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/16/19',
	TermPeriod = 201907
WHERE Period = 201907
	and EmployeeName in ('Debbie Igarashi')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '7/3/19',
	TermPeriod = 201907
WHERE Period = 201907
	and EmployeeName in ('Edward Overkleeft')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/28/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('Michael Crews')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/24/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('Aaron Baca')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/14/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('Devin Boyle')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/12/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('Jennifer Menchaca')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/11/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('David Baker', 'Jason Cortina')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/7/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('David Robertson')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '6/3/19',
	TermPeriod = 201906
WHERE Period = 201906
	and EmployeeName in ('Adam Ellsworth')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/15/19',
	TermPeriod = 201905
WHERE Period = 201905
	and EmployeeName in ('Leonard Bernal')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/13/19',
	TermPeriod = 201905
WHERE Period = 201905
	and EmployeeName in ('Peter Koch')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/7/19',
	TermPeriod = 201905
WHERE Period = 201905
	and EmployeeName in ('Braden DaBell')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/3/19',
	TermPeriod = 201905
WHERE Period = 201905
	and EmployeeName in ('Gaitree Shanahan', 'Andre Yerkanyan')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '5/1/19',
	TermPeriod = 201905
WHERE Period = 201905
	and EmployeeEmail in ('david.spalding@pnmac.com')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/11/19',
	TermPeriod = 201904
WHERE Period = 201904
	and EmployeeName in ('Debra Major')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/8/19',
	TermPeriod = 201904
WHERE Period = 201904
	and EmployeeName in ('Filza Satti', 'Stephanie McCanlas')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/5/19',
	TermPeriod = 201904
WHERE Period = 201904
	and EmployeeName in ('Sofia Velazquez')

Update #Final
SET EmploymentStatus = 'Terminated',
	TerminationDate = '4/4/19',
	TermPeriod = 201904
WHERE Period = 201904
	and EmployeeName in ('Kevin Lundberg', 'Joshua Price')


Update #Final     --Nathan Request
Set PurchaseFlag = 'N'
where Period >= 201904
and EmployeeName = 'Darius Jackson'


Update #Final     --Nathan Request
Set PurchaseFlag = 'N'
where Period >= 201904
and EmployeeName = 'Terrell Jean'

Update #Final  -- Nathan Request
Set EmploymentStatus = 'LOA',
	LOADate = '4/1/19',
	LOAPeriod = '201904'
Where Period = 201904
and EmployeeName = 'Alex Wong'



Update #Final     --Doug Request
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales'
where Period = 201903
and EmployeeName = 'Harjoyte Bisla'


--Delete from #Final   -- Doug Request
--where Period = 201903
--and EmployeeName in ('Elizabeth Garcia', 'Geoffrey Deitrick')


Update #Final     --Doug Request
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales'
where Period = 201903
and EmployeeName = 'Timothy Esterly'

Update #Final     --Doug Request
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales'
where Period = 201903
and EmployeeName = 'Shaun Wilson'

Update #Final     --Doug Request
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales'
where Period = 201903
and EmployeeName = 'Emma Mullen'



Update #Final     --Stephen Email 3-22-2019 making AJ show active for Feb as HR tables show 3-01-2019 as termination date
Set EmploymentStatus = 'Active'
,terminationdate = null ,TermPeriod=null
where Period = 201902
and EmployeeName = 'Aaron Hatfield'



Update #Final     --Stephen Email 3-22-2019 making AJ's Team not to show manager as Carl Illum
Set ManagerEmail='aaron.hatfield@pnmac.com',ManagerId = '004367',managerNAme = 'AJ Hatfield',ManagerName_TwoUp='Carl Illum',ManagerTitle = 'Mgr, Sales'
where Period = 201902
and EmployeeName in( 'Angey Wu',
'David Baker',
'Debbie Igarashi',
'Eric Lewis',
'Gregory Ligon',
'Matthew Hinckley',
'Michael Crews',
'Moe Bannat',
'Sofia Velazquez',
'Tramell Nash',
'Veronica Tovar')


/*QUICK RESOLUTION BEFORE HR SOLVE*/
DELETE FROM #Final
WHERE EmployeeId = 'OI1204' and Period >= 201908


--=====================================================================================================
-- May 2019 UPDATES
-- Manager updated for Tuchman's LOs that transferred to other purchase managers
-- will remove once HR updates dw_org
--======================================================================================================

/*
--UPDATES COMMENTED OUT ARE NOW AVAILABLE ON DW_ORG - CHARLIE 05/30/2019

Update #Final
Set ManagerName = 'Benjamin Williams',
    PurchaseFlag = 'Y'
where Period = 201905
and EmployeeName in (/*'Jason Cortina',*/ 'Bailey Greene')

Update #Final
Set ManagerName = 'Allen Brunner',
	PurchaseFlag = 'Y'
where Period = 201905
and EmployeeName in ('Randall Alford', 'Yuri Abrego')

Update #Final
Set ManagerName = 'Evan Tuchman',
	PurchaseFlag = 'N'
where Period = 201905
and EmployeeName in ('Michael Ammari', 'Terrell Jean','William Slater', 'Elizabet Ovakimyan', 'William Hang')

Update #Final
Set ManagerName = 'Todd Bugbee',
	PurchaseFlag = 'Y'
where Period = 201905
and EmployeeName in ('Jason Cortina')

Update #Final
Set ManagerName = 'Orlando Cassara',
	HelocFlag = 'Y'
where Period = 201905
and EmployeeName in ('Tramell Nash')

Update #Final
Set ManagerName = 'Steven Vargas'
where Period = 201905
and EmployeeName in ('Aaron Hatfield', 'Rob Arias', 'Jonathan Cummins')
*/

Update #Final
Set ManagerName = 'Todd Bugbee'
where Period = 201905
and EmployeeName in ('Natalia Navarro')

Update #Final
Set ManagerName = 'Adam Adoree'
where Period = 201905
and EmployeeName in ('Amir Rizvi')

Update #Final
Set ManagerName = 'Ryan Finkas'
where Period = 201905
and EmployeeName in ('Cameron Freeland')

--Update #Final
--Set ManagerName = 'Tim Esterly'
--where Period = 201905
--and EmployeeName in ('Jorje Cruz')

Update #Final
Set PurchaseFlag = 'Y'
where Period = 201905
and EmployeeName in ('Michael Angelo', 'Natalia Navarro')

--=====================================================================================================
-- JUNE 2019 UPDATES
-- Manager updated for Tuchman's LOs that transferred to other purchase managers
-- will remove once HR updates dw_org
--======================================================================================================

--Update #Final
--Set ManagerName = 'Ryan Finkas',
--    Title = 'Sr. Loan Officer'
--where Period = 201906
--and EmployeeName in ('Owen Ekimoto')

--Update #Final
--Set ManagerName = 'Ryan Finkas'
--where Period = 201906
--and EmployeeName in ('James Kozar')

Update #Final
Set ManagerName = 'Linda Le',
    ManagerName_TwoUp = 'Rich Ferre'
where Period = 201905
and EmployeeName in ('Owen Ekimoto', 'James Kozar')

Update #Final
Set City = 'Plano'
where Period = 201906
and EmployeeName in ('Craig Wood')

/* NO LONGER OCCURING PER NICOLE'S 6/25 E-MAIL --CHARLIE
Update #Final
Set Title = 'VP, Retail Sales & Chnnl'
where Period = 201906
and EmployeeName in ('Ryan Finkas')
*/

Update #Final
Set Title = 'Loan Officer',
	ManagerName = 'Shaun Wilson'
where Period = 201906
and EmployeeName in ('Abigail Wilson')

Update #Final
Set ManagerName = 'Evan Tuchman' --Previously Jason Massie, Emma Mullen
where Period = 201906
and EmployeeName in ('Jonnie Maretti', 'Scott Coughlin')

Update #Final
Set Title = 'Loan Officer', TitleGrouping = 'Account Executive'
where Period >= 201906
and EmployeeName in ('Angel Potts')

Update #Final
Set ManagerName = 'Benjamin Williams' --Previously Emma Mullen
where Period = 201906
and EmployeeName in ('Michael Angelo')

--=====================================================================================================
-- JULY 2019 UPDATES
-- Manager updated for Tuchman's LOs that transferred to other purchase managers
-- will remove once HR updates dw_org
--======================================================================================================

Update #Final
Set ManagerName = 'Matt Moebius'
where Period = 201907
and EmployeeName in ('Larry Martin')

Update #Final
Set ManagerName = 'Madison Salter'
where Period = 201907
and EmployeeName in ('Karen Flores')

Update #Final
Set ManagerName = 'Diego Cabello Alvarado'
where Period = 201907
and EmployeeName in ('Marcel Montano')

Update #Final
Set ManagerName = 'Timothy Esterly'
where Period = 201907
and EmployeeName in ('Charles Noorzaie', 'Shannon Vaughn')

Update #Final
Set ManagerName = 'Kevin Price',
	PurchaseFlag = 'Y'
where Period = 201907
and EmployeeName in ('James Byers')

Update #Final
Set PurchaseFlag = 'Y'
where Period >= 201907 and Period < 201909
and EmployeeName in ('Severiano Rico', 'Juanita Giovanni', 'Arthur Hachikian')

Update #Final
Set Title = null,
	TitleGrouping = null
where Period = 201907
and EmployeeName in ('Raymond Nowell')

--CHARLIE: THE FOLLOWING ASKED OT BE REMOVED BY STEPHEN BRANDT ON 07/23/2019:
--UPDATE #Final
--SET Title = 'Mgr, Sales'
--	, TitleGrouping = 'Manager - Sales'
--	, ManagerName = 'Nathan Dyce'
--WHERE Period = 201907
--and EmployeeName in ('Darius Jackson', 'Michiko Solon')

UPDATE #Final
SET PurchaseFlag = 'N'
WHERE Period >= 201907
and EmployeeName in ('Juanita Giovanni')

--CHARLIE: THE FOLLOWING ASKED OT BE REMOVED BY STEPHEN BRANDT ON 07/23/2019:
--UPDATE #Final
--SET Title = 'Mgr, Sales'
--	, TitleGrouping = 'Manager - Sales'
--	, ManagerName = 'Carl Illum'
--WHERE Period = 201907
--and EmployeeName in ('Aaron Hatfield')

--CHARLIE: THE FOLLOWING ASKED OT BE REMOVED BY STEPHEN BRANDT ON 07/23/2019:
--UPDATE #Final
--SET Title = 'Mgr, Sales'
--	, TitleGrouping = 'Manager - Sales'
--	, ManagerName = 'Rich Ferre'
--WHERE Period = 201907
--and EmployeeName in ('Marc Henry')

UPDATE #Final
SET TitleGrouping = 'Account Executive'
	, ManagerName = 'Evan Tuchman'
WHERE Period = 201907
and EmployeeName in ('Darius Jackson')

UPDATE #Final
SET TitleGrouping = 'Account Executive'
	, ManagerName = 'Jimmy Yang'
WHERE Period = 201907
and EmployeeName in ('Michiko Solon')


UPDATE #Final
SET TitleGrouping = 'Account Executive'
	, ManagerName = 'Steven Vargas'
WHERE Period = 201907
and EmployeeName in ('Aaron Hatfield')

UPDATE #Final
SET TitleGrouping = 'Account Executive'
	, ManagerName = 'Madison Salter'
WHERE Period = 201907
and EmployeeName in ('Marc Henry')

UPDATE #Final
SET ManagerName = 'DeeDee Akins'
WHERE Period = 201907
and EmployeeName in ('Sarahi Guevara')


--=====================================================================================================
-- AUGUST 2019 UPDATES
-- Manager updated for Tuchman's LOs that transferred to other purchase managers
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET Title = 'Mgr, Sales'
	, TitleGrouping = 'Manager - Sales'
	, ManagerName = 'Carl Illum'
WHERE Period = 201908
and EmployeeName in ('Aaron Hatfield', 'Patrick Quinlan')
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales'
	, TitleGrouping = 'Manager - Sales'
	, ManagerName = 'Rich Ferre'
WHERE Period = 201908
and EmployeeName in ('Marc Henry', 'David Risse', 'Joe McKinley')
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales'
	, TitleGrouping = 'Manager - Sales'
	, ManagerName = 'Nathan Dyce'
WHERE Period = 201908
and EmployeeName in ('Darius Jackson', 'Michiko Solon', 'Anthony Tabor', 'David Erlich')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	HelocFlag = 'Y'
WHERE Period = 201908
and EmployeeName in ('Ignacio Barrientos')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aaron Hatfield'
WHERE Period = 201908
and EmployeeName in ('Chris Porter', 'Clay Hagler', 'Erik Luna',
					'Irwing Enriquez', 'Jonathan Cummins', 'Moe Bannat',
					'Richard Kennimer', 'Roberto Arias', 'Dwight Dickey',
					'Hessam Kiani')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich'
WHERE Period = 201908
and EmployeeName in ('Vartan Davtyan')
-----------------------------------------------------
UPDATE #Final
SET HelocFlag = 'N'
WHERE Period >= 201908
and EmployeeName in ('Araceli Jimenez', 'David Kelly', 'Nicholas Groetken',
					'Penny Mrva', 'Sonia Lozano')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	TitleGrouping = 'Account Executive'
WHERE Period = 201908
and EmployeeName in ('Steven Vargas')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	PurchaseFlag = 'Y'
WHERE Period = 201908
and EmployeeName = 'Abigail Wilson'
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = 'Dispatch Agent'
WHERE --Period = 201908
--and
EmployeeName in ('Lance Crayton', 'Krista Mann')
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Carl Illum'
WHERE ManagerName = 'Patrick Quinlan'
and TitleGrouping in ('Account Executive', 'Loan Officer')
and Period = 201908
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = Department
WHERE EmployeeEmail = 'tyler.amstrong@pnmac.com'
and Period >= 201908
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Rich Ferre',
	ManagerName = 'Ryan Finkas'
WHERE EmployeeName = 'Merrill Von Bargen'
and Period in (201908) --Does it show Rich for August without?
-----------------------------------------------------------



--=====================================================================================================
-- SEPTEMBER 2019 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET HelocFlag = 'Y', PurchaseFlag = 'N'
WHERE Period >= 201909 and Period < 202003
and EmployeeName in ('Sarah Brown')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Todd Bugbee',
	PurchaseFlag = 'Y',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Bailey Greene',
'Arin Baghermian',
'Anthony Trozera')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Allen Brunner',
	PurchaseFlag = 'Y',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'John Anding',
'Juan Cruz')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Darius Jackson',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Carl Wren')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Michael Angelo')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerName_TwoUp = 'Nathan Dyce',
	TitleGrouping = 'Account Executive',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Benjamin Williams')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Arthur Hachikian')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	TitleGrouping = 'Specialist, Loan Refinance',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Nicholas Spencer')
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich',
	PurchaseFlag = 'N',
	HelocFlag = 'N'
WHERE Period = 201909
and EmployeeName in (
'Ashot Gafafyan')
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = 'Account Executive',
	Title = 'Sr Loan Officer',
	ManagerEmail = 'kevin.price@pmac.com',
	ManagerName = 'Kevin Price',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Brad Thompson' and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerEmail = 'carl.illum@pnmac.com',
	ManagerName = 'Carl Illum',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName = 'Orlando Cassara' and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Sales & Chnnl Mgmt',
	ManagerEmail = 'carl.illum@pnmac.com',
	ManagerName = 'Carl Illum',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName = 'DJ Ford' and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Damon Johnson' and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Adriana Gonzalez' and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Adam Key',
'Affan Khwaja',
'Andree Pinson',
'Angey Wu',
'Brandon Glenn',
'James Bruce',
'Joshua Leatherman',
'Mark Mitchell',
'Rami Addicks')
and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Emma Mullen',
	ManagerEmail = 'emma.mullen@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Christian Silva',
'Jessie Corral',
'Michael Derderian',
'Robert Macias',
'Ruben Luna jr',
'Steven Bruce',
'Derek Esterberg',
'Stephen Castaneda',
'Andrew Arakelian',
'Gary Zakaryan',
'Jirir Wosgerijyan',
'Wesley Black')
and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jay Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Andrew Ventura',
'Paul Potthast',
'Jason Carvalho',
'Ross Ahkiong',
'Steven Garcia',
'Claude Claybrook',
'Samuel Grant',
'Tristan Summers')
and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Patrick Kirk',
'Amber Broyles',
'Araceli Jimenez',
'Ignacio Barrientos',
'Nicholas Groetken',
'Rodney Perkins',
'Sarah Brown',
'Sonia Lozano',
'Tramell Nash',
'David Kelly')
and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Dustyn Pierson',
'Robert McGaughy',
'Walter Zimmermann')
and Period = 201909
-----------------------------------------------------
UPDATE #Final
SET ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Penny Mrva' and Period = 201909
-----------------------------------------------------
--UPDATE #Final
--SET ManagerName = 'Orlando Cassara',
--	ManagerEmail = 'orlando.cassara@pnmac.com',
--	City = 'Tampa',
--	ManagerCity = 'Tampa',
--	ManagerName_TwoUp = 'DJ Ford'
--WHERE EmployeeName in (
--'Irwing Enriquez')
--and Period = 201910
--=====================================================================================================
-- OCTOBER 2019 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET ManagerEmail = 'olive.njombua@pnmac.com',
	ManagerName = 'Olive Njombua'
WHERE EmployeeName = 'Penny Mrva' and Period = 201910
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance'
	--City = 'Plano', /*ALREADY ROSEVILLE*/
	--ManagerCity = 'Plano', /*ALREADY ROSEVILLE*/
	--ManagerName_TwoUp = 'Carl Illum' /*ALREADY RICH FERRE*/
WHERE EmployeeName in (
'Michael Henry')
and Period = 201910

--=====================================================================================================
-- NOVEMBER 2019 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Irwing Enriquez')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Diego Cabello Alvarado',
	ManagerEmail = 'diego.alvarado@pnmac.com'
WHERE EmployeeName in (
'Samuel Grant')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Mauro Serrano'
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Leslie Baum',
'Lisa Arroyo',
'Mark Carpenter')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Shawnta Cody'
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Darius Jackson',
	ManagerEmail = 'darius.jackson@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Elsie Tejeda',
'Kevin Carlson',
'Robert Tovar',
'Victor Lai')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich',
	ManagerEmail = 'david.erlich@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Carlos Castro',
'Erik Bates',
'Erik Karibas',
'Fred Aghili',
'Solina Neth')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName = 'Gevork Dzhabroyan'
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	ManagerEmail = 'michiko.solon@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Daily Webb',
'Dino Rousseve',
'Marlon Bivens',
'Marvin Zayas',
'Sarkis Babakhanyan')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Adam Emmert',
'Braxton Bearden',
'Daniel Kirby')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Ben Curcio',
'Ted Coburn')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Amelia Stratton',
'Darrin Woll',
'Hung Nguyen',
'Jack Cooper',
'Keith Seeley',
'Sydney Barnes')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Bruce Ramirez',
'Dalia Rodriguez',
'Janelle Okuma',
'Jeremy Brunson',
'Michael Kramar')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Jolene Regan',
'Tate Fackrell',
'Tyler Smedley')
and Period = 201911
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Scott Coughlin'
)
and Period = 201911
-----------------------------------------------------
--UPDATE #Final
--SET NCAFlag = 'Y'
--WHERE EmployeeName in (
--'Krystan Keyes',
--'Gary Sahakian',
--'Eric Aron'
--) and Period >= 201911

--=====================================================================================================
-- DECEMBER 2019 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	--City = 'Plano', /*ALREADY IN PLANO*/
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum',
	PurchaseFlag = 'N',
	HelocFlag = 'N',
	TransferDate = '12/1/2019'
WHERE EmployeeName in (
'Carl Thomas')
and Period = 201912
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	--City = 'Plano', /*ALREADY IN PLANO*/
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum',
	PurchaseFlag = 'Y',
	HelocFlag = 'N',
	TransferDate = '12/1/2019'
WHERE EmployeeName in (
'Dustyn Pierson')
and Period >= 201912
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Evan Tuchman',
	ManagerEmail = 'evan.tuchman@pnmac.com',
	--City = 'Pasadena', /*ALREADY IN Pasadena*/
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	PurchaseFlag = 'N',
	HelocFlag = 'N',
	TransferDate = '12/1/2019'
WHERE EmployeeName in (
'Severiano Rico')
and Period = 201912
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Harjoyte Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	--City = 'Plano', /*ALREADY ROSEVILLE*/
	--ManagerCity = 'Plano', /*ALREADY ROSEVILLE*/
	ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName in (
'Michael Henry')
and Period = 201912
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = 'Account Executive'
WHERE TitleGrouping <> 'Account Executive'
and Title like '%Loan%Officer%'
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Alfred Reams')
and Period = 201912
--=====================================================================================================
-- JANUARY 2020 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Tyler Richardson',
'Eric Busalacchi',
'Taylor Fiorelli',
'Ricardo Arreola')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Jane Riley'
)
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Aaron Arce',
'Corey Golden',
'Michael Thompson')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'Gwendolyn Munder'
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Jessica McGillewie')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Justin Huse')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Nathan Jackson',
'Adam Emmert'
)
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Rod Walker')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Madison Salter',
	ManagerEmail = 'madison.salter@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Will Langhagen')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Sales & Chnnl Mgmt'
WHERE EmployeeName in (
'Evan Tuchman')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	--City = 'Pasadena',
	--ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Austin Schreibman')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Grant Mills'
WHERE NCAFlag='Y'
and Period < 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Scott Bridges'
WHERE EmployeeName = 'Grant Mills' and Period >= 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	--City = 'WestlakeLakeview', --ALREADY Lakeview
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Krystan Keyes',
'Gary Sahakian',
'Eric Aron',
'Johann Bonar'
)
and Period in (202001, 202002)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Grant Mills',
	ManagerEmail = 'grant.mills@pnmac.com',
	Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	City = 'WestlakeLakeview',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'Frank Frayer')
and Period in (202001, 202002)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Emma Mullen',
	ManagerEmail = 'emma.mullen@pnmac.com',
	--City = 'Pasadena', --ALREADY Pasadena
	--ManagerCity = 'WestlakeLakeview', --ALREADY Pasadena
	ManagerName_TwoUp = 'Stephen Brandt',
	PurchaseFlag = 'Y'
WHERE EmployeeName in (
'Carlos Castro')
and Period = 202001
-----------------------------------------------------
UPDATE #Final
SET Title = 'Sup, Dispatch'
WHERE Title like 'Sup, Dispatch%' and EmployeeEmail = 'amber.brown@pnmac.com'
--=====================================================================================================
-- FEBRUARY 2020 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'Eric Busalacchi')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Stephen Brandt',
	ManagerEmail = 'stephen.brandt@pnmac.com',
	Title = 'Mgr, CDL Recruiting & Training',
    TitleGrouping = 'Mgr, CDL Recruiting & Training',
	--City = 'Tampa',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'Brian Schooler')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET --ManagerName = 'Adriana Gonzalez',
	--ManagerEmail = 'stephen.brandt@pnmac.com',
	Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
	--City = 'Tampa',
	--ManagerCity = 'Tampa',
	--ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Nicholas Gilliam')
and Period in (202002, 202003)
-----------------------------------------------------
--UPDATE #Final
--SET ManagerName = 'DJ Ford',
--	ManagerEmail = 'dj.ford@pnmac.com',
--	Title = 'Mgr, Sales',
--    TitleGrouping = 'Manager - Sales',
--	City = 'Tampa',
--	ManagerCity = 'Tampa',
--	ManagerName_TwoUp = 'Scott Bridges'
--WHERE EmployeeName in (
--'Eric Busalacchi')
--and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com',
	Title = 'Specialist, Loan Refinance',
    TitleGrouping = 'Specialist, Loan Refinance',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Matt Mcglinn')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'John Anding')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	ManagerCity = 'Pasadena'
WHERE EmployeeName in (
'Kevin Price')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Nathan Dyce'
WHERE ManagerName in (
'Kevin Price')
and Period >= 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'John Anding',
	ManagerEmail = 'john.anding@pnmac.com',
	--City = 'Pasadena', --ALREADY Pasadena
	--ManagerCity = 'WestlakeLakeview', --ALREADY Pasadena
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Carlos Castro')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Nathan Dyce'
WHERE ManagerName_TwoUp = 'Evan Tuchman'
and Period >= 202001
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	--City = 'WestlakeLakeview', --ALREADY Lakeview
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Brock Walker',
'Gabriel Vallarta',
'Johann Bonar',
'Kuno Kaulbars')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	--City = 'Plano', --ALREADY Plano
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Charles Shepherd')
and Period in (202002, 202003)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	--City = 'Pasadena', --ALREADY Pasadena
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Sevada Babakhani',
'Shauntelle Walker')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName = 'William Long'
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Bryan Ross',
'Debra Creelman',
'Floyd Taylor',
'Micah Ramos'
)
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Carol Dion',
'Tabatha Atkins')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Diego Cabello Alvarado',
	ManagerEmail = 'diego.alvarado@pnmac.com',
	Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Anthony Soto')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName = 'Guillom Hines'
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Quintrell Hillard',
'Ricardo De Carlo')
and Period in (202002, 202003)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Roberto Montoya')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Angelique Muccio',
'Macy Gunderson',
'Tony Russo',
'Tiffany Lewis')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Afton Lambert')
and Period = 202002
-----------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE EmployeeName in (
'Corin Aurelio',
'Patricia Nicholas',
'Morgan Bui',
'Christopher Butner',
'Benjamin Contreras',
--ADDED ON 04/02/2020
'Martha Orellana',
'Kevin Jones',
'Samuel Johnny',
'Jessica Diamond',
--ADDED ON 04/03/2020
'Kevin Jones',
'Martha Orellana',
--ADDED ON 06/29/2020
'Connie Duong',
'Jonathan Franco',
--ADDED ON 07/22/2020
'Thomas Johnson',
--ADDED ON 08/25/2020
'Anna Marie Francesco',
'Megan Curtis',
'Robel Moreno',
'Jennica Lindqvist',
'Jessie Adams',
'Marvin Zayas',
'Zain Sohrab',
'Connie Duong',
--ADDED ON 09/21/2020
'Hamilton Duong',
--ADDED ON 10/01/2020
'Abigail Rogers',
--ADDED ON 10/09/2020
'Kristin Martini',
--ADDED ON 10/21/2020
'Anna Chao Bond',
--ADDED ON 11/17/2020
'Leslie Walling',
'Michael Peck',
'Monie Frost',
'Brigette Sherman',
--ADDED ON 12/28/2020
'Rick Campos',
'Nestor Velasco',
'Michael Mekler',
'Michael Fascetti',
'Lawrence Mike',
'Dylan Greene',
'Craig Jones',
--ADDED ON 01/04/2021
'Shannon Metcalf',
'Jennifer Brucker'
) and ManagerName = 'Emma Mullen'
-----------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE EmployeeName in (
--ADDED ON 07/22/2020
'Matthew Mercado'
) and ManagerName = 'Afton Lambert'
--=====================================================================================================
-- MARCH 2020 UPDATES
-- will remove once HR updates dw_org
--======================================================================================================
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Mark Guillermo')
and Period = 202003
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	Title = 'Specialist, Purchase Loan',
    TitleGrouping = 'Specialist, Purchase Loan',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Amber Bush')
and Period = 202003
-----------------------------------------------------
UPDATE #Final
SET Title = NULL,
    TitleGrouping = NULL
WHERE EmployeeName in (
'Michael Derderian',
'Michael Angelo')
and Period in (202003, 202004)
--=====================================================================================================
-- APRIL 2020 UPDATES
-- will remove once HR updates dw_org
--=====================================================================================================
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Emma Mullen',
    ManagerEmail = 'emma.mullen@pnmac.com',
    City = 'Pasadena',
    ManagerCity = 'Pasadena',
    ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName in (
'Nicholas Spencer',
'Martha Orellana',
'Arameh Dilanchian',
'Neal Renzi',
'Kevin Jones')
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Shaun Eric Wilson',
    ManagerEmail = 'shaun.wilson@pnmac.com',
    City = 'Plano',
    ManagerCity = 'Plano',
    ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName in (
'Tonisha Brown')
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Grant Mills',
	ManagerEmail = 'grant.mills@pnmac.com',
	Title = 'NCA Sales Manager',
    TitleGrouping = 'NCA Sales Manager',
	--City = 'Moorpark',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'Katherine Smith')
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	--City = 'WestlakeLakeview', --ALREADY Lakeview
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Aryan Fakoor',
'Beverly Lynch',
'John Ingersoll',
'John Wilbanks',
'Monica Ochoa',
'Robin Hallford'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeName in (
'Dwight Dickey')
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'robert.dickey@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Adam Key',
'Rory Shanahan',
'Ted Coburn',
--GRADUATED LOs BELOW
'Donald Lucas',
'Matthew Gillespie'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brian Schooler',
    ManagerEmail = 'brian.schooler@pnmac.com',
    --City = 'Plano',
    ManagerCity = 'WestlakeLakeview',
    ManagerName_TwoUp = 'Stephen Brandt'
WHERE EmployeeName in (
'Joshua Nelson',
'Exavier Hamilton',
'Fahali Campbell',
'Daniel Kier',
'Michael Dubrow',
'Michael Steel',
'Nina Moshiri',
'Francisco Duran'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Ashley Cullinan'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Michael Johnson'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Nicholas Gilliam'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Jacob Grubb'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Diego Cabello Alvarado',
	ManagerEmail = 'diego.alvarado@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Ellis Garcia'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Clinton Harris',
'Daniel Loftus',
'Scott Fernald'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Mark Guillermo'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Lloyd Smith',
'Phillip Zayas'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'John Anding',
	ManagerEmail = 'john.anding@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Benjamin Contreras',
'Christopher Butner',
'Corin Aurelio',
'Morgan Bui',
'Patricia Nicholas'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Pascal Dylewicz'
)
and Period = 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich',
	ManagerEmail = 'david.erlich@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Imelda Sanchez')
and Period in (202004, 202005)
--=====================================================================================================
-- MAY 2020 UPDATES
-- will remove once HR updates dw_org
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	--City = 'Pasadena',
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Kenney Barrientos',
'Neal Renzi')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	--City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Arameh Dilanchian')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Jeremy Hain'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Clarence Daniels'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Ivan Crume'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'robert.dickey@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Justin Sprague',
'Tyler Gavin'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Brandis Rembert',
'Celso Dockhorn',
'Douglas Vorbeck',
'Nicole Payne'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Richard Peck',
'Tracy Corsey'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'John Anding',
	ManagerEmail = 'john.anding@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Jessica Diamond',
'Kevin Jones',
'Martha Orellana'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Tonisha Brown')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	City = 'Roseville',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'John Kimble Jr')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	ManagerEmail = 'michiko.solon@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Nicholas Spencer')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Jason Menne'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Kirk Blackshear')
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	NCAFlag = 'Y'
WHERE EmployeeName in (
'Francisco Duran')
and Period >= 202004
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	--City = 'WestlakeLakeview', --ALREADY Lakeview
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Daniel Kier',
'Fahali Campbell',
'Joshua Nelson',
'Michael Dubrow'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	--City = 'WestlakeLakeview', --ALREADY Lakeview
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Exavier Hamilton',
'Francisco Duran',
'Nina Moshiri',
'Michael Steel'--GRADUATED 05/19
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	--City = 'Plano', --ALREADY Plano
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Walter Zimmermann'
)
and Period = 202005
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = 'Processor'
WHERE ManagerName = 'Debora Munoz'
and Period between 202003 and 202005
/*Did not include Employment Status due to potential terminations mid month that would make those
calls go to Dispatch. - Charlie 05/13/2020
*/
--=====================================================================================================
-- JUNE 2020 UPDATES
-- will remove once HR updates dw_org
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'robert.dickey@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'David Hernandez'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Grant Mill',
	ManagerEmail = 'grant.mills@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'FVP, Retail Call Center Ops',
	TitleGrouping = 'FVP, Retail Call Center Ops'
WHERE EmployeeName in (
'Kevin Price'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt',
	Title = 'Mgr, CDL Recruiting & Training',
	TitleGrouping = 'Mgr, CDL Recruiting & Training'
WHERE EmployeeName in (
'Afton Lambert'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Edith Torosyan'
--, --COMMENTED OUT 06/11
--'Natalia Navarro' --COMMENTED OUT 06/11
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jimmy Yang',
	ManagerEmail = 'jimmy.yang@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Darius Jackson'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Edith Torosyan',
	ManagerEmail = 'edith.torosyan@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Nick Bergh',
'Elizabet Ovakimyan'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final --NOT ON NICOLE FORM
SET ManagerName = 'Edith Torosyan',
	ManagerEmail = 'edith.torosyan@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE ManagerName = 'Darius Jackson'
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Clinton Harris'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET Title = NULL,
	TitleGrouping = NULL
WHERE EmployeeName in (
'Jeremy Hain',
'Walter Zimmermann'
)
and Period >= 202006 and TitleGrouping in ('Account Executive', 'Loan Officer')
-----------------------------------------------------
UPDATE #Final --NOT ON NICOLE FORM
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Ruben Sanchez'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final --NOT ON NICOLE FORM
SET ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Plano'
WHERE ManagerName = 'Kevin Price'
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Cesar Rodriguez Flores')
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'stanley.rodriguez@pnmac.com'
)
and Period = 202006
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Stanley Rodriguez',
	ManagerEmail = 'stanley.rodriguez@pnmac.com',
	--City = 'Sacramento',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Gracie Kapaun'
WHERE EmployeeName in (
'Jazmyne Rogers'
)
and Period >= 202006 and ManagerName = 'Michelle Sims'
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brian Schooler',
	ManagerEmail = 'brian.schooler@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Addy Dosunmu',
'Daniel Turner',
'Dejan Lolic',
'Justin Syracuse',
'Maria Espana'
)
and Period = 202006
--=====================================================================================================
-- JULY 2020 UPDATES
-- will remove once HR updates dw_org
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Barry Clay II'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Mike Payne'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Corey Gaston'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Chanhnett Turincio',
'Travis John Lemley'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Clinton Harris',
	ManagerEmail = 'clinton.harris@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Evan Phillips',
'Vincent Cooper',
'Mike Ezell'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Edith Torosyan',
	ManagerEmail = 'edith.torosyan@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Samson Nargizyan'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Michael Gingras'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Curt Coleman'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Alex Bozymowski'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Scott Kiley'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Donald Carlson',
'Jeremiah Kneeland',
'Michael Powers'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	ManagerEmail = 'michiko.solon@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Hector Centeno'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Matt Saladino'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Conrad Stobnicki',
'Cristobal Garcia'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Mitchell Dubois'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Thomas Zinschlag'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patrick Quinlan',
	ManagerEmail = 'patrick.quinlan@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Jeffrey Smith'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Jessica McGillewie'
)
and Period = 202007
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Natalia Navarro'
)
and Period = 202007
--=====================================================================================================
-- AUGUST 2020 UPDATES
-- will remove once HR updates dw_org
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Teresa Henry',
	ManagerEmail = 'teresa.henry@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Andy Reta',
	TitleGrouping = 'Contractor'
WHERE EmployeeName in (
'Justin Sprague'
)
and Period in (202008, 202009, 202010) and TitleGrouping = 'Account Executive'
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	--City = 'Plano',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Peter Harris',
'Joshua Leatherman'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	--City = 'Tampa',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Tiffany Lewis'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	--City = 'Tampa',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Jonathan Ryan'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Allen Brunner',
	ManagerEmail = 'allen.brunner@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Thomas Johnson'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Austin Schreibman',
	ManagerEmail = 'austin.schreibman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Areg Nazarian'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Clinton Harris',
	ManagerEmail = 'clinton.harris@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Jake Crocker',
'John Rodgers',
'Keith Williams'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Michael Payne'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Janelle Okuma'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Diego Cabello Alvarado',
	ManagerEmail = 'diego.alvarado@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Ryan Ward',
'Daniel Craun'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Edith Torosyan',
	ManagerEmail = 'edith.torosyan@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Arthur Hachikian',
'Timothy Woods'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Brian Butler',
'Chris Pyhel'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Christopher Bowman',
'Christopher Bozel',
'Tim Snow'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jimmy Yang',
	ManagerEmail = 'jimmy.yang@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Adam Sher'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName = 'Jonathan Ryan',
	ManagerEmail = 'jonathan.ryan@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Connie Duong',
'Jonathan Franco'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName = 'Joshua Leatherman',
	ManagerEmail = 'joshua.leatherman@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Sheryl Contreras',
'Juan Soto',
'Kim Hong'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Adejumoke Dosunmu',
'Maria Espana'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Madison Salter',
	ManagerEmail = 'madison.salter@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Taylor Harris'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Logan Sagely'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeName in (
'Abed Almaoui',
'Daniel Turner',
'Dejan Lolic',
'Earl Nagaran',
'Ihsan Moosapanah',
'Jake Jacobs',
'Justin Syracuse',
'Michael Weber'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Peter Harris', --Not Considered in Lock Goals August 2020
	ManagerEmail = 'peter.harris@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Hayden Bailey',
'Jason Thomas',
'Sairraj Stephens'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Matthew Mercado'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre'
WHERE EmployeeName in (
'Taylor Crume'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tiffany Lewis',
	ManagerEmail = 'tiffany.lewis@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Lynette Oliver',
'Nicholas Gilliam'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Olive Njombua'
)
and Period = 202008
-----------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Carl Illum'
WHERE ManagerName = 'Olive Njombua'
and Period = 202008
--=====================================================================================================
-- SEPTEMBER 2020 UPDATES
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Jimmy Yang',
	ManagerEmail = 'jimmy.yang@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeName in (
'Randall Alford'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joshua Leatherman',
	ManagerEmail = 'joshua.leatherman@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Araceli Jimenez',
'Sonia Lozano'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Peter Harris',
	ManagerEmail = 'peter.harris@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Rod Walker',
'Ignacio Barrientos'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Chadd Grogg',
	ManagerEmail = 'chadd.grogg@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeName in (
'Amy Hodge',
'Brandon Peterson',
'Christopher Markes',
'Daniel Postak',
'Dennis Giardina',
'Eric Jones',
'Fidencio Velazquez',
'Garrett Bateman',
'Krystle Pierre',
'Maria Corona',
'Matthew Thorpe',
'Ryan Caldwell'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'dwight.dickey@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Tramell Nash',
'Rodney Perkins',
'Barry Clay II'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Eric Palomares',
'Kelley Christianer'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills'
WHERE EmployeeName in (
'Aril Allahverdi',
'Daniel Pollock',
'Nicholas Schmidt'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeName in (
'George Kala',
'Marilyn Cotitta',
'Ryan Wilson'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Richard Kennimer'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Macy Gunderson'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName = 'Rich Ferre',
	ManagerEmail = 'rich.ferre@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Sydney Barnes',
'Jeffries Johnson'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName_TwoUp = 'Carl Illum'
WHERE ManagerName = 'Olive Njombua' and Period = 202009
-----------------------------------------------------
UPDATE #Final --Not Considered in Lock Goals August 2020
SET ManagerName_TwoUp = 'Kevin Price'
WHERE ManagerName = 'Natalia Navarro' and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeName in (
'Dejan Lolic'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET City = 'Plano'
WHERE EmployeeName in (
'Yuri Lebedev'
)
and Period >= 202008 and TitleGrouping = 'Account Executive' and City = 'Edina'
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'dwight.dickey@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum'
WHERE EmployeeName in (
'Shannon Vaughn'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Jonathan Wilson',
'Rebecca Holland',
'Veronica Tovar'
)
and Period in (202008, 202009)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brad Thompson',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance'
WHERE EmployeeName in (
'Colin Wickers'
)
and Period = 202009
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt',
	Title = 'NCA Sales Manager',
	TitleGrouping = 'NCA Sales Manager'
WHERE EmployeeName in (
'Joshua Nelson'
)
and Period = 202009
--=====================================================================================================
-- OCTOBER 2020 UPDATES
--=====================================================================================================
UPDATE F

SET F.ManagerName = S.SalesManager,
	F.ManagerEmail = S.ManagerEmail,
	F.ManagerName_TwoUp = S.SiteLead,
	F.ChannelManager = S.ChannelManager,
	F.SiteLead = S.SiteLead

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation202010 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeName = S.LoanOfficer

WHERE F.Period = 202010
-----------------------------------------------------
/*REPEATED TO CONSIDER JOIN IN UPDATE ABOVE - CHARLIE 10/22/2020*/
UPDATE #Final
SET ManagerEmail = 'eddie.bailey@pnmac.com'
WHERE ManagerEmail = 'william.bailey@pnmac.com'
-----------------------------------------------------
UPDATE #Final
SET ChannelManager = 'No Channel Manager'
WHERE Period = 202010 and EmployeeName in (
'Shannon Vaughn',
'Tramell Nash',
'Barry Clay II',
'Rodney Perkins'
)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Rich Ferre',
	ManagerEmail = 'rich.ferre@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Reid Wright'
)
and Period = 202010
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
    ManagerCity = 'Plano',
    ManagerName_TwoUp = 'Stephen Brandt',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Jessie Corral'
)
and Period = 202010
-----------------------------------------------------
UPDATE #Final
SET --ManagerName = 'Brad Thompson',
	--ManagerEmail = 'bradley.thompson@pnmac.com',
	--ManagerCity = 'Plano',
	--ManagerName_TwoUp = 'Olive Njombua',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance'
WHERE EmployeeName in (
'Monica Ochoa'
)
and Period in (202010)
and TitleGrouping in ('Account Executive', 'Loan Officer')
-----------------------------------------------------
UPDATE #Final --UPDATED FOR 10/15 EFFECTIVE CHANGE AS REID IS TAKING OVER MID-MONTH AS APPROVED BY SALES
SET ManagerName = 'Reid Wright',
	ManagerEmail = 'reid.wright@pnmac.com'
WHERE ManagerName = 'Tyler Smedley'
	and Period = 202010
--=====================================================================================================
-- NOVEMBER 2020 UPDATES
--=====================================================================================================
UPDATE F

SET F.ManagerName = S.SalesManager,
	F.ManagerEmail = S.ManagerEmail,
	F.ManagerName_TwoUp = S.SiteLeader, --Not SiteLead
	F.ChannelManager = S.ChannelManager,
	F.SiteLead = S.SiteLeader --Not SiteLead

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation202011 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals
ON F.EmployeeName = S.LoanOfficer and F.TitleGrouping in ('Account Executive', 'Loan Officer')

WHERE F.Period = 202011
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brock Walker',
	ManagerEmail = 'brock.walker@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance'
WHERE EmployeeName in (
'Monica Ochoa'
)
and Period in (202011, 202012)
and TitleGrouping in ('Account Executive', 'Loan Officer')
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
TitleGrouping = 'Specialist, Loan Refinance',
ManagerName = 'Richard Kennimer',
ManagerEmail = 'richard.kennimer@pnmac.com'
WHERE EmployeeName in (
'Rachel	Vasquez'
) and Period = 202011
and TitleGrouping in ('Account Executive', 'Loan Officer')
-----------------------------------------------------
Update #Final
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
    ManagerName = 'DJ Ford',
    ManagerEmail = 'dj.ford@pnmac.com'
where Period = 202011
and EmployeeName = 'Jane Riley'
and TitleGrouping in ('Account Executive', 'Loan Officer')
-----------------------------------------------------
Update #Final
Set Title = 'NCA, Sales Manager',
    TitleGrouping = 'NCA Sales Manager',
    ManagerName = 'Kevin Price',
    ManagerEmail = 'kevin.price@pnmac.com'
where Period = 202011
and EmployeeName = 'Eric Jones'
-----------------------------------------------------
Update #Final
Set Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com'
where Period = 202011
and EmployeeName = 'Chris Franklin'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Adriana Gonzalez',
	ManagerCity = 'Tampa',
	ManagerEmail = 'adriana.gonzalez@pnmac.com',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Kristen Malave'
) and Period = 202011
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Stacie Jenkins',
'John McGillewie'
) and Period = 202011
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Dwight Dickey',
	ManagerEmail = 'dwight.dickey@pnmac.com'
WHERE EmployeeName in (
'Scott Zeller'
) and Period in (202011, 202012)
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com'
WHERE EmployeeName in (
'Jared Fisher'
) and Period = 202011
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan'
WHERE EmployeeName in (
'Lynette Oliver'
) and Period = 202011
-----------------------------------------------------
UPDATE #Final
SET Title = 'Analyst, Call Monitoring',
	TitleGrouping = 'Analyst, Call Monitor',
	ManagerCity = 'Pasadena',
	ManagerName = 'Debora Munoz',
	ManagerEmail = 'debora.munoz@pnmac.com'
WHERE EmployeeName in (
'Corin Aurelio'
) and Period = 202011
-----------------------------------------------------
UPDATE #Final
SET	ManagerName = 'Steven Garcia',
	ManagerEmail = 'steven.garcia@pnmac.com',
	ManagerCity = 'Roseville'
WHERE EmployeeName in ('Bart Johnson',
			'Isaiah Kinnon')
and Period = 202011
--=====================================================================================================
-- DECEMBER 2020 UPDATES
--=====================================================================================================
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	--ManagerName = 'Afton Lambert',
	--ManagerEmail = 'afton.lambert@pnmac.com',
	--ManagerCity = 'Plano',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Rachel Bettine',
'RyLee Gorham',
'Thomas Wahl',--'Tommy Wahl',
'Wesley Topham',
'Antonio Planzo',
'Ashly Cox',
'Corey Cardone',
'Sejong Killian',
'Jordan Zilbar',
'Braheem Crews',
'Ivan Arroyave',
'Caleb Welvaert',
'Kevin Lovely',
'Tomas Lara'
) and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	--ManagerName = 'Afton Lambert',
	--ManagerEmail = 'afton.lambert@pnmac.com',
	--ManagerCity = 'Plano',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Gabrielle Tamala',
'Matthew Bland'
) and Period = 202012
-----------------------------------------------------
Update #Final
SET Title = 'Project Manager',
    TitleGrouping = 'Project Manager'
WHERE Period = 202011
and EmployeeName in (
'Sevag Karrian'
)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales'
WHERE EmployeeName in (
'Brian Butler',
'Brandis Rembert'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President'
WHERE EmployeeName in (
'Adriana Gonzalez'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President'
WHERE EmployeeName in (
'Aaron Hatfield'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Carl Illum',
	Title = 'Mgr, CDL Recruiting & Training',
	TitleGrouping = 'Mgr, CDL Recruiting & Training'
WHERE EmployeeName in (
'Arin Baghermian',
'Jeremiah Kneeland'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET 	ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance'
WHERE EmployeeName in (
'Mercedes Breaux'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET 	Title = 'LO, Special Projects',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Barry Clay II',
'Tramell Nash',
'Shannon Vaughn',
'Rodney Perkins'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET 	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Jane Riley',
'Macy Gunderson'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET 	ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Freddie Garcia Flores',
'Yeisha Gonzalez'
)
-----------------------------------------------------
UPDATE #Final
SET 	ManagerName = 'Adriana Gonzalez',
	ManagerEmail = 'adriana.gonzalez@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Carleen Tillman'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET 	ManagerName = 'Adriana Gonzalez',
	ManagerEmail = 'adriana.gonzalez@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	TransferDate = '12/16/2020' --requested by LO prod 1/13/21
WHERE EmployeeName in (
'David Esteras',
'Juliette Lee Tan'
)
and Period = 202012
--and CAST(GETDATE() AS DATE) >= '12/16/20'
-----------------------------------------------------
UPDATE #Final --REPEAT FROM 202011 DUE TO NO CHANGE FROM HR
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'John McGillewie'
) and Period = 202012
and ManagerName = 'Billy Connell'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Carleen Tillman'
) and Period = 202012
and TitleGrouping <> 'Account Executive'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Robert Chaplin'
) and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Eric Jones',
	ManagerEmail = 'eric.jones@pnmac.com'
WHERE EmployeeName in (
'Jared Fisher'
) and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	TransferDate = '12/16/2020', --requested 1/13/2021
    ManagerName = 'Afton Lambert',
    ManagerEmail = 'afton.lambert@pnmac.com',
    ManagerCity = 'Plano',
    ManagerName_TwoUp = 'Shaun Eric Wilson',
    ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName = 'Mark Carter' and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, CDL Recruiting & Training',
    TitleGrouping = 'Mgr, CDL Recruiting & Training',
    ManagerName = 'Shaun Eric Wilson',
    ManagerEmail = 'shaun.wilson@pnmac.com',
    ManagerCity = 'Plano',
    ManagerName_TwoUp = 'Carl Illum'--'Olive Njombua'
WHERE EmployeeName = 'Shante Viamontes' and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
    TitleGrouping = 'Specialist, Refinance Loan',
    ManagerName = 'Kevin Price',
    ManagerEmail = 'kevin.price@pnmac.com',
    ManagerCity = 'Phoenix',
    ManagerName_TwoUp = 'Grant Mills',---'Nathan Dyce',
    ChannelManager = NULL,--'No Channel Manager',
    SiteLead = NULL--'Nathan Dyce'
WHERE EmployeeName = 'Krystle Pierre' and Period = 202012
--and CAST(GETDATE() AS DATE) >= '12/16/20'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	TransferDate = '12/16/2020',
    ManagerName = 'Adriana Gonzalez',
    ManagerEmail = 'adriana.gonzalez@pnmac.com',
    ManagerCity = 'Tampa',
    ManagerName_TwoUp = 'Shaun Eric Wilson',
    ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName = 'Jeremy Rosa' and Period = 202012
--and CAST(GETDATE() AS DATE) >= '12/16/20'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Spec III, Home Loan',
    TitleGrouping = 'Spec III, Home Loan',
    ManagerName = 'Linda Parsons',
    ManagerEmail = 'linda.parsons@pnmac.com',
    ManagerCity = 'StLouis',
    ManagerName_TwoUp = 'Don Maday',
    ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeName = 'Morgan Bui' and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
    TitleGrouping = 'Specialist, Refinance Loan',
    ManagerName = 'Natalia Navarro',
    ManagerEmail = 'natalia.navarro@pnmac.com',
    ManagerCity = 'Phoenix',
    ManagerName_TwoUp = 'Kevin Price',
    ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeName = 'Tomas Lara' and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
	SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Kristen Malave'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Josh Williams'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eddie Bailey',
	ManagerEmail = 'eddie.bailey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Donald Williams'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Maritza Chiaway'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Josh Nelson',
	ManagerEmail = 'joshua.nelson@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'JP Pettus'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
    SiteLead = 'Grant Mills'
WHERE EmployeeName in (
'Jeffrey Johnson'
)
and Period = 202012
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brock Walker',
	ManagerEmail = 'brock.walker@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
    SiteLead = 'Grant Mills'
WHERE EmployeeName in (
'Michael Araiza'
)
and Period = 202012
--=====================================================================================================
-- DECEMBER 2020 UPDATES
--=====================================================================================================
--COMMENTED OUT DUE TO MISTAKE IN ESCR SHEET - ALLOCATED TO AMBER
--UPDATE #Final
--SET 	ManagerName = 'Jay Kneeland',
--	ManagerEmail = 'jeremiah.kneeland@pnmac.com',
--	ManagerCity = 'WestlakeLakeview',
--	ManagerName_TwoUp = 'Grant Mills',
--	ChannelManager = 'No Channel Manager',
--        SiteLead = 'Grant Mills'
--WHERE EmployeeName in (
--'Amber Pannone'
--)
--and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Chris Franklin',
		ManagerEmail = 'chris.franklin@pnmac.com',
		ManagerCity = 'Plano',
		ManagerName_TwoUp = 'Olive Njombua',
		ChannelManager = 'Aaron Hatfield',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
	'Rachel Vasquez'
	)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Jeffries Johnson',
		ManagerEmail = 'jeffries.johnson@pnmac.com',
		ManagerCity = 'Roseville',
		ManagerName_TwoUp = 'Rich Ferre',
		ChannelManager = 'Ryan Finkas',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
	'William Barnes'
	)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Macy Gunderson',
		ManagerEmail = 'macy.gunderson@pnmac.com',
		ManagerCity = 'Tampa',
		ManagerName_TwoUp = 'DJ Ford',
		ChannelManager = 'Adriana Gonzalez',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
	'Daniel Loftus'
	)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
	'Amber Pannone'
	)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Christina Kelly',
	ManagerEmail = 'christina.kelly@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Sokhom Sim'
)
and Period = 202101

UPDATE #Final
SET ManagerName = 'Katherine Smith',
	ManagerEmail = 'katherine.smith@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
    SiteLead = 'Grant Mills'
WHERE EmployeeName in (
'Jeffrey Johnson'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Richard Kennimer',
	ManagerEmail = 'richard.kennimer@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Valeria Saravia'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Andree Pinson',
	ManagerEmail = 'andree.pinson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Gabrielle Simo'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Penny Mrva',
	ManagerEmail = 'penny.mrva@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Neal Marchin',
'Clay Hagler' --ADDED DUE TO OLIVE REQUEST FOR GOALS
)
and Period = 202101

UPDATE #Final
SET ManagerName = 'Matthew Hinckley',
	ManagerEmail = 'matthew.hinckley@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Aaron Hatfield',
    SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Stacie Jenkins',
'Angey Wu', --ADDED DUE TO OLIVE REQUEST FOR GOALS
'Charles Shepherd', --ADDED DUE TO OLIVE REQUEST FOR GOALS
'Irwing Enriquez', --ADDED DUE TO OLIVE REQUEST FOR GOALS
'Mauro Serrano', --ADDED DUE TO OLIVE REQUEST FOR GOALS
'Roberto Arias' --ADDED DUE TO OLIVE REQUEST FOR GOALS
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Christina Kelly',
	ManagerEmail = 'christina.kelly@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
        SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'John McGillewie'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Allen Brunner',
	ManagerEmail = 'allen.brunner@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
        SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Michael Peck'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Todd Bugbee',
	ManagerEmail = 'todd.bugbee@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
        SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Brigette Sherman',
'Monie Frost'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Ben Erickson',
	ManagerEmail = 'ben.erickson@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Angela Cornell',
'Zachary Knudsen'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Duane Kirkpatrick'
)
and Period = 202101

UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Eric Leonard'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Jeffries Johnson',
	ManagerEmail = 'jeffries.johnson@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Greg Woods'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Tyler Smedley',
	ManagerEmail = 'tyler.smedley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Justin Hansen'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Jeffries Johnson',
	ManagerEmail = 'jeffries.johnson@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Kane Wilkin'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Tyler Smedley',
	ManagerEmail = 'tyler.smedley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Michael Kreitner'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Dylan Kohl'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Madison Salter',
	ManagerEmail = 'madison.salter@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Taitlyn Dompor'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Diego Cabello Alvarado',
	ManagerEmail = 'diego.alvarado@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Ashlyn Pinckard'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Tate Fackrell',
	ManagerEmail = 'tate.fackrell@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Jeff Wheeler'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
        SiteLead = 'Rich Ferre'
WHERE EmployeeName in (
'Frazier Caldwell'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Aizen Malki',
	ManagerEmail = 'david.malki@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Youn Lee'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Eddie Machuca',
	ManagerEmail = 'eddie.machuca@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Dominique Sinsay'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Eddie Machuca',
	ManagerEmail = 'eddie.machuca@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Felix Kim'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Aizen Malki',
	ManagerEmail = 'david.malki@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Andre Oliveira'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Eddie Machuca',
	ManagerEmail = 'eddie.machuca@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Scott Park'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Michiko Solon',
	ManagerEmail = 'michiko.solon@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
        SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Robert Chaplin'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Melissa Barone',
	ManagerEmail = 'melissa.barone@pnmac.com',
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
        SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Paul Funk'
)
and Period = 202101

--UPDATE #Final
--SET 	ManagerName = 'Eric Jones',
--	ManagerEmail = 'eric.jones@pnmac.com',
--	ManagerCity = 'Phoenix',
--	ManagerName_TwoUp = 'Kevin Price',
--	ChannelManager = 'No Channel Manager',
--        SiteLead = 'Kevin Price'
--WHERE EmployeeName in (
--'Sean Fitzgerald-McGill'
--)
--and Period = 202101

UPDATE #Final --UPDATED
SET 	ManagerName = 'Chadd Grogg',
	ManagerEmail = 'chadd.grogg@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
    SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Sean Fitzgerald-McGill'
)
and Period = 202101

--UPDATE #Final
--SET 	ManagerName = 'Natalia Navarro',
--	ManagerEmail = 'natalia.navarro@pnmac.com',
--	ManagerCity = 'Phoenix',
--	ManagerName_TwoUp = 'Kevin Price',
--	ChannelManager = 'No Channel Manager',
--    SiteLead = 'Kevin Price'
--WHERE EmployeeName in (
--'Colton Young'
--)
--and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Ryan Wilson',
	ManagerEmail = 'ryan.p.wilson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
    SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Colton Young',
'Drew Kozel'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Macy Gunderson',
	ManagerEmail = 'macy.gunderson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Sejong Killian'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Caleb Welvaert'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Tiffany Lewis',
	ManagerEmail = 'tiffany.lewis@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Jordan Zilbar'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Brian Butler',
	ManagerEmail = 'brian.butler@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Antonio Planzo'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Corey Cardone'
)
and Period = 202101


UPDATE #Final
SET 	ManagerName = 'Macy Gunderson',
	ManagerEmail = 'macy.gunderson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Ivan Arroyave'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Ashly Cox'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Braheem Crews'
)
and Period = 202101

--UPDATE #Final
--SET 	ManagerName = 'Garrett Bateman',
--	ManagerEmail = 'garrett.bateman@pnmac.com',
--	ManagerCity = 'Phoenix',
--	ManagerName_TwoUp = 'Grant Mills',
--	ChannelManager = 'No Channel Manager',
--        SiteLead = 'Grant Mills'
--WHERE EmployeeName in (
--'Matthew Bland'
--)
--and Period = 202101

UPDATE #Final --NICOLE UPDATE COMMENTED OUT
SET 	ManagerName = 'Brock Walker',
	ManagerEmail = 'brock.walker@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
        SiteLead = 'Grant Mills'
WHERE EmployeeName in (
'Matthew Bland'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Brock Walker',
	ManagerEmail = 'brock.walker@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
        SiteLead = 'Grant Mills'
WHERE EmployeeName in (
'Michael Araiza'
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName in (
'Carleen Tillman',
'Caleb Welvaert'
)
and Period = 202101
-----------------------------------------------------
--COMMENTING OUT AS NATALIA IS BECOMING CHANNEL MANAGER
--UPDATE #Final
--SET 	ManagerName = 'Natalia Navarro',
--	ManagerEmail = 'natalia.navarro@pnmac.com',
--	ManagerCity = 'Phoenix',
--	ManagerName_TwoUp = 'Kevin Price',
--	ChannelManager = 'No Channel Manager',
--        SiteLead = 'Kevin Price'
--WHERE EmployeeName in (
--'Daniel Loftus'
--)
--and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Eddie Bailey',
	ManagerEmail = 'eddie.bailey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Daniel Loftus'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Floyd Taylor'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President'
WHERE EmployeeName in (
'Natalia Navarro'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA Sales Manager'
WHERE EmployeeName in (
'Ryan Wilson'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeName in (
'Aizen Malki'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Matthew Hinckley'
)
and Period = 202101


UPDATE #Final
SET 	Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Loan Refinance'
WHERE EmployeeName in (
'Cynthia Rivera'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Gayle Yanes'
)
and Period = 202101

UPDATE #Final
SET 	ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
        SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Cynthia Rivera',
'Shaun Riley',
'Jonathan Pedraza'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Eddie Machuca'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Tate Fackrell'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'Specialist, Refinance Loan',
    	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Tyler Stephens'
)
and Period = 202101

UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA, Sales Manager',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Garrett Bateman'
)
and Period = 202101


UPDATE #Final
SET 	Title = 'Specialist, Refinance Loan',
    	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Garrett Bateman',
	ManagerEmail = 'garrett.bateman@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Krystle Pierre'
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Timothy Esterly',
	ManagerEmail = 'timothy.esterly@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
    SiteLead = 'Olive Njombua'
WHERE EmployeeName in (
'Shannon Smallman' --ADDED BY OLIVE FOR LOCK GOALS
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford'
WHERE EmployeeName in (
'Andrew Abrams' --ADDED BY OLIVE FOR LOCK GOALS
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tate Fackrell',
	ManagerEmail = 'tate.fackrell@pnmac.com'
WHERE ManagerName = 'Sydney Barnes'
and Period = 202101
and EmploymentStatus = 'Active'
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jimmy Yang',
	ManagerEmail = 'jimmy.yang@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Benjamin Wharton',
'Randall Alford'
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Christian Silva'
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'David Erlich',
	ManagerEmail = 'david.erlich@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Sevak Abkarian'
)
and Period = 202101
-----------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE EmployeeName in (
'Craig Jones',
'Dylan Greene',
'Jennifer Brucker',
'Lawrence Mike',
'Michael Fascetti',
'Michael Mekler',
'Nestor Velasco',
'Rick Campos',
'Shannon Metcalf'
) and ManagerName = 'Arin Baghermian'
-----------------------------------------------------
UPDATE #Final
SET TenuredFlag = 'N'
Where EmployeeName in ('Mark Carter')
and Period >= 202101

-----------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
Where EmployeeName in ('Ricardo Campos', 'Mike Mekler')
and Period = 202101
-----------------------------------------------------
--UPDATE #Final
--SET PurchaseFlag = 'Y'
--where EmployeeEmail in (
--'alejandro.rojas@pnmac.com',
--'bethany.mcmullen@pnmac.com',
--'jake.fillipp@pnmac.com',
--'kali.thompson@pnmac.com',
--'eysvetleina.seneres@pnmac.com',
--'melonique.jones@pnmac.com',
--'michael.howarth@pnmac.com',
--'nicole.stober@pnmac.com',
--'rachael.segui@pnmac.com'
--) and Period = 202102
--=====================================================================================================
-- FEBRUARY 2021 UPDATES
--=====================================================================================================
UPDATE #Final
SET ManagerName = 'Jay Bisla'
WHERE EmployeeEmail in ('alec.irwin@pnmac.com') and Period in (202102, 202103)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Arin Baghermian',
	ManagerEmail = 'arin.baghermian@pnmac.com'
WHERE EmployeeEmail in ('kali.thompson@pnmac.com') and Period in (202102, 202103)
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Arin Baghermian'
WHERE EmployeeEmail in ('nicole.stober@pnmac.com') and Period in (202102, 202103)
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Arin Baghermian',
	ManagerEmail = 'arin.baghermian@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'michael.howarth@pnmac.com',
'bethany.mcmullen@pnmac.com'
)
and Period in (202102, 202103)
-----------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE EmployeeEmail in (
'alejandro.rojas@pnmac.com',
'bethany.mcmullen@pnmac.com',
'jake.fillipp@pnmac.com',
'kali.thompson@pnmac.com',
'eysvetleina.seneres@pnmac.com',
'melonique.jones@pnmac.com',
'michael.howarth@pnmac.com',
'nicole.stober@pnmac.com',
'rachael.segui@pnmac.com',
'stephen.tartamella@pnmac.com',
'roger.cuevas@pnmac.com'
) and ManagerName = 'Arin Baghermian'
--and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Aizen Malki',
	ManagerEmail = 'david.malki@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Benjamin Wharton',
'Randall Alford'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eddie Machuca',
	ManagerEmail = 'eddie.machuca@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeName in (
'Christian Silva',
'Sevak Abkarian'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA, Sales Manager',
		ManagerName = 'Natalia Navarro',
		ManagerEmail = 'natalia.navarro@pnmac.com',
		ManagerCity = 'Phoenix',
		ManagerName_TwoUp = 'Kevin Price',
		ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Patricia Mendez'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Patricia Mendez',
	ManagerEmail = 'patricia.mendez@pnmac.com',
	ManagerCity = 'Phoenix',
	ChannelManager = 'Natalia Navarro',
	ManagerName_TwoUp = 'Kevin Price',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Steven Garcia'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA, Sales Manager',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Katherine Orabuena',
'Juanita Moreno'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA, Sales Manager',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeName in (
'Daniel Postak'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Juanita Moreno',
	ManagerEmail = 'juanita.moreno@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Elena Heraldez',
'Emmanuel Huerta',
'Reese Hanlin'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Daniel Postak',
	ManagerEmail = 'daniel.postak@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Margaret Erickson',
'Stephanie Joseph'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET --Title = 'Loan Officer',
	--TitleGrouping = 'Account Executive',
	ManagerName = 'Brian Butler',
	ManagerEmail = 'brian.butler@pnmac.com',
	ManagerCity = 'Tampa',
	--ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeName in (
'Kaitlin Smith'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Eric Jones',
	ManagerEmail = 'eric.jones@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Earl Nagaran'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
	SiteLead = 'DJ Ford'
WHERE EmployeeName in (
'Nicholas Massari'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Orlando Cassara',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'George Kala'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Patricia Mendez',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix'
WHERE EmployeeName in (
'Scott Bacon'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Ryan Wilson',
	ManagerEmail = 'ryan.p.wilson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Ihsan Moosapanah'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
--'Kali Thompson',
'Megan Cleary',
'Rami Addicks'
)
and Period = 202102
-----------------------------------------------------
--UPDATE #Final
--SET Title = 'Loan Officer',
--	TitleGrouping = 'Account Executive',
--	ManagerName = 'Arin Baghermian',
--	ManagerEmail = 'arin.baghermian@pnmac.com',
--	ManagerCity = 'Pasadena',
--	ManagerName_TwoUp = 'Shaun Eric Wilson',
--	ChannelManager = 'No Channel Manager',
--	SiteLead = 'Shaun Eric Wilson'
--WHERE EmployeeName in (
--'Michael Howarth',
--'Bethany McMullen'
----'Alec Irwin'
--)
--and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Kneeland',--changed Jeremiah to Jay 3-18-2021
	ManagerEmail = 'jeremiah.kneeland@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Nick Spence'
)
and Period in (202102, 202103)
-----------------------------------------------------
--UPDATE #Final
--SET Title = 'Loan Officer',
--	TitleGrouping = 'Account Executive',
--	ManagerName = 'Jay Bisla',
--	ManagerEmail = 'harjoyte.bisla@pnmac.com',
--	ManagerCity = 'Roseville',
--	ManagerName_TwoUp = 'Shaun Eric Wilson',
--	ChannelManager = 'No Channel Manager',
--	SiteLead = 'Shaun Eric Wilson'
--WHERE EmployeeName in (
--'Nikki Stober'
--)
--and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Brian Schooler',
	ManagerEmail = 'brian.schooler@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'daniel.ngo@pnmac.com',
'christopher.reynosa@pnmac.com',
'ryan.woodard@pnmac.com',
'connor.burns@pnmac.com',
'courtney.bettcher@pnmac.com',
'lydia.shepherd@pnmac.com',
'graham.palmer@pnmac.com',
'jonghyun.lee@pnmac.com',
'andrew.hamilton1@pnmac.com',
'hannah.brown@pnmac.com',
'kevin.kwiatek@pnmac.com',
'kathryne.gates@pnmac.com'
)
and Period = 202102
-----------------------------------------------------
UPDATE  #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'freddie.garciaflores@pnmac.com',
'jared.falk@pnmac.com'
)
and Period = 202102
-----------------------------------------------------
UPDATE  #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'carli.kelley@pnmac.com'
)
and Period = 202102
-----------------------------------------------------
UPDATE  #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'vireak.seang@pnmac.com'
)
and Period = 202102
-----------------------------------------------------
UPDATE  #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Tyler Smedley',
	ManagerEmail = 'tyler.smedley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
'austin.crusius@pnmac.com'
)
and Period = 202102
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Arin Baghermian',
	ManagerEmail = 'arin.baghermian@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'nicole.stober@pnmac.com',
'kali.thompson@pnmac.com'
)
and Period in (202102, 202103)

-----------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202102 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]------------------------------------------------

WHERE F.Period = 202102
-----------------------------------------------------
UPDATE #Final
SET OfficePhoneNumber = NULL
where EmployeeEmail in (
--'zanetta.hoffman@pnmac.com', --Commented out on 04/07/2021 due to change in the Directory as requested by Anand
--'sandrea.allen@pnmac.com', --Commented out on 04/07/2021 due to change in the Directory as requested by Anand
'laquasha.smith@pnmac.com'
)

UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202103 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]------------------------------------------------

WHERE F.Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
       SiteLead = NULL
WHERE EmployeeName in (
	'Taylor Fiorelli',
	'Meridith Lavallee',
	'April Williams'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Analyst, QC Performance',
    TitleGrouping = 'Analyst, QC Performance',
	ManagerName = 'Elen Pirijanyan',
	ManagerEmail = 'elen.pirijanyan@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Carl Illum',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in (
	'ermine.kaladzhyan@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Thomas Zinschlag',
	ManagerEmail = 'thomas.zinschlag@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
	'josh.williams@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Chadd Grogg',
	ManagerEmail = 'chadd.grogg@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
    SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
	'israel.ramosalarcon@pnmac.com'
)
and Period = 202103
-----------------------------------------------------

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'jose.ramirez@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'lorena.peral@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Edward Taylor',
	ManagerEmail = 'edward.taylor@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
	SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
'ottokar.pek@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Patricia Mendez',
	ManagerEmail = 'patricia.mendez@pnmac.com',
	ManagerCity = 'Phoenix',
	ChannelManager = 'Natalia Navarro',
	ManagerName_TwoUp = 'Kevin Price',
	SiteLead = 'Kevin Price'
WHERE EmployeeName in (
'Steven Garcia'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Kneeland', --changed Jeremiah to Jay 3-18-2021
	ManagerEmail = 'jeremiah.kneeland@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeName in (
'Elijah Kneeland'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'henry.nguyen@pnmac.com',
	'kevin.argueta@pnmac.com',
	'erik.luna@pnmac.com',
	'andrew.nguyen@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'daniel.graziosi@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'carlos.lopez@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
    TitleGrouping = 'Specialist, Refinance Loan'
WHERE EmployeeEmail in (
	'rachel.bettine@pnmac.com'
	)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Juanita Moreno',
	ManagerEmail = 'juanita.moreno@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeEmail in (
'devin.sundheim@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patricia Mendez',
	ManagerEmail = 'patricia.mendez@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeEmail in (
'isaiah.kinnon@pnmac.com',
'juliana.martinez@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kaitey Gates',
	ManagerEmail = 'kaitey.gates@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeEmail in (
'aurora.torrefranca@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
	SiteLead = 'Grant Mills'
WHERE EmployeeEmail in (
'john.pettus@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Garrett Bateman',
	ManagerEmail = 'garrett.bateman@pnmac.com',
	ManagerCity = 'Phoenix'
WHERE EmployeeEmail in (
'lorraina.soto@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET CDLSales = 'Y',
	ManagerName = 'Taylor Johnson',
	ManagerEmail = 'taylor.johnson@pnmac.com',
	ManagerCity = 'Phoenix'
WHERE EmployeeEmail in (
'alyssa.perez@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Daniel Postak',
	ManagerEmail = 'daniel.postak@pnmac.com',
	ManagerCity = 'Phoenix'
WHERE EmployeeEmail in (
'joseph.archibeque@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix'
WHERE EmployeeEmail in (
'bart.johnson@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Tampa'
WHERE EmployeeEmail in (
'nicolas.libertella@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'lorena.peral@pnmac.com'
)
and Period = 202103
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	PurchaseFlag = 'Y',
	ManagerName = 'Evan Tuchman',
    ManagerName_TwoUp = 'Nathan Dyce',
    ManagerEmail ='evan.tuchman@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeName in ('Anthony Trozera')
and EmployeeEmail in ('anthony.trozera@pnmac.com')
and Period >= 202103

--====================================================================
-- APRIL 2021 UPDATES
--====================================================================
---------------------------------------------------------------------------------
UPDATE #Final
SET Department = 'MFD BDL Client Mgmt',
	Title = 'Mgr II, Pipeline Account',
	TitleGrouping = 'Mgr II, Pipeline Account',
	ManagerName = 'David Miller', --Not Considered in Lock Goals August 2020
	ManagerEmail = 'david.miller@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = NULL,
	ManagerName_TwoUp = NULL,
	SiteLead = NULL
WHERE EmployeeName in (
'Sairraj Stephens'
)
and Period in (202104, 202105)
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Anthony Tabor',
	ManagerEmail = 'anthony.tabor@pnmac.com',
	City = 'Pasadena',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeEmail in
('aaron.arce@pnmac.com')
and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET HireDate = '2021-02-22'
WHERE EmployeeEmail in (
'jackie.sager@pnmac.com'
) and Period >= 202102
--------------------------------------------------------------------------------
UPDATE #Final
SET HireDate = '2021-02-16'
WHERE EmployeeEmail in (
'daniel.ngo@pnmac.com',
'christopher.reynosa@pnmac.com',
'ryan.woodard@pnmac.com',
'connor.burns@pnmac.com',
'courtney.bettcher@pnmac.com',
'lydia.shepherd@pnmac.com',
'graham.palmer@pnmac.com',
'jonghyun.lee@pnmac.com',
'andrew.hamilton1@pnmac.com',
'hannah.brown@pnmac.com',
'kevin.kwiatek@pnmac.com',
'kathryne.gates@pnmac.com'
) and Period >= 202102
--------------------------------------------------------------------------------
UPDATE #Final --added on 4-12 Cherise Mejia has transitioned to Auditor I, QA  in mid March
SET Title = 'Specialist I, Lead',
    TitleGrouping = 'Dispatch Agent',
	ManagerName = 'Craig Cachopo',
	ManagerEmail = 'craig.cachopo@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'James Gilbert'
WHERE EmployeeEmail in (
'cherise.mejia@pnmac.com'
)
and EmployeeName in (
'Cherise Mejia'
)
and Period = 202103
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ben Erickson',
	ManagerEmail = 'ben.erickson@pnmac.com',
	ManagerCity = 'Summerlin'
WHERE EmployeeName in (
	'Shannon Vaughn',
	'Tramell Nash',
	'Barry Clay II',
	'Rodney Perkins'
)
and Period >= 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET City = 'Pasadena'
WHERE Period = 202104
and EmployeeName = 'Asia Smith'
and EmployeeEmail = 'laquasha.smith@pnmac.com'
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'will.langhagen@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'richard.peck@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y',
	ManagerName = 'Anthony Trozera',
	ManagerEmail = 'anthony.trozera@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in (
'jonathan.franco@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'sydney.barnes@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'daniel.loftus@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Juanita Moreno',
	ManagerEmail = 'juanita.moreno@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'adejumoke.dosunmu@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Joshua Leatherman',
	ManagerEmail = 'joshua.leatherman@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
	SiteLead = 'Olive Njombua'
WHERE EmployeeEmail in (
'zaria.davis@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jane Riley',
	ManagerEmail = 'jane.riley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'jerold.dienes@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Garrett Bateman',
	ManagerEmail = 'garrett.bateman@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'james.spring@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'jason.minor@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Christina Kelly',
	ManagerEmail = 'christina.kelly@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
	SiteLead = 'Olive Njombua'
WHERE EmployeeEmail in (
'monica.deluna@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brandis Rembert',
	ManagerEmail = 'brandis.rembert@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'alfred.reams@pnmac.com',
'michael.payne@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Adriana Gonzalez',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'jane.riley@pnmac.com',
'william.bailey@pnmac.com',
'brandis.rembert@pnmac.com',
'tiffany.lewis@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
	SiteLead = 'Grant Mills'
WHERE EmployeeEmail in (
'chadd.grogg@pnmac.com',
'eric.jones@pnmac.com',
'daniel.postak@pnmac.com',
'patricia.mendez@pnmac.com',
'kaitey.gates@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kelley Christianer',
	ManagerEmail = 'kelley.christianer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
	SiteLead = 'Grant Mills'
WHERE EmployeeEmail in (
'christopher.bowman@pnmac.com',
'francisco.duran@pnmac.om',
'john.pettus@pnmac.com',
'christopher.bozel@pnmac.com',
'curt.coleman@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'April Williams',
	ManagerEmail = 'april.williams@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'clarence.daniels@pnmac.com',
'michele.heck@pnmac.com',
'donald.williams@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Andree Pinson',
	ManagerEmail = 'andree.pinson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Patrick Quinlan',
	SiteLead = 'Olive Njombua'
WHERE EmployeeEmail in (
'zaria.davis@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Joshua Leatherman',
	ManagerEmail = 'joshua.leatherman@pnmac.com'
WHERE EmployeeEmail in (
'zaria.davis@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
	TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com'
WHERE EmployeeEmail in (
'amanda.tubbs@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Scott Bridges',
	Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President'
WHERE EmployeeEmail in (
'damon.johnson@pnmac.com'
)
and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Nathan Dyce',
	Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President'
WHERE EmployeeEmail in (
'frank.frayer@pnmac.com'
)
and Period = 202104

-----------------------------------------------------
UPDATE #Final
SET 	Title = 'NCA, Sales Manager',
    	TitleGrouping = 'NCA, Sales Manager',
		ManagerName = 'Anthony McDevitt',
		ManagerEmail = 'anthony.mcdevitt@pnmac.com',
		ManagerCity = 'Moorpark',
		ManagerName_TwoUp = 'Grant Mills',
		ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
		'kelley.christianer@pnmac.com',
		'michael.dubrow@pnmac.com'
)
and Period = 202104
-----------------------------------------------------
UPDATE #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
		ManagerName = 'Adriana Gonzalez',
		ManagerEmail = 'adriana.gonzalez@pnmac.com',
		ManagerCity = 'Tampa',
		ManagerName_TwoUp = 'DJ Ford',
		ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
		'andrew.abrams@pnmac.com'
)
and Period = 202104
-----------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202104 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202104
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'daniel.graziosi@pnmac.com'
)
and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Kneeland',
	ManagerEmail = 'jeremiah.kneeland@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
where EmployeeEmail in
(
'babak.javaherpour@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
where EmployeeEmail in
(
'daniel.silvey@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Taylor Johnson',
	ManagerEmail = 'taylor.johnson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'ruben.avila@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Kelley Christianer',
	ManagerEmail = 'kelley.christianer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'diana.tulia@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Natalia Navarro',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'brandon.avila1@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Daniel Postak',
	ManagerEmail = 'daniel.postak@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Frank Frayer',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'tomas.lara@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michael Dubrow',
	ManagerEmail = 'michael.dubrow@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
	SiteLead = 'Grant Mills'
where EmployeeEmail in
(
'julian.velasco@pnmac.com',
'christina.guzman@pnmac.com'
) and Period = 202104
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Juanita Moreno',
	ManagerEmail = 'juanita.moreno@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Natalia Navarro',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'mariah.rosario@pnmac.com'
) and Period = 202104
--====================================================================
-- MAY 2021 UPDATES
--====================================================================
/*USED TO REVERT MAY CHANGES TO APRIL FOR STAFFING CHANGES*/
--UPDATE F

--SET F.ManagerName = S.ManagerName,
--	F.ManagerEmail = S.ManagerEmail,
--	F.ManagerName_TwoUp = S.ManagerName_TwoUp,
--	F.ChannelManager = S.ChannelManager,
--	F.SiteLead = S.SiteLead,
--	F.City = S.City

--FROM #Final F

--inner join #Final S
--ON F.EmployeeEmail = S.EmployeeEmail and S.Period = 202104 and S.TitleGrouping in ('Account Executive', 'Loan Officer')

--WHERE F.Period = 202105
-----------------------------------------------------
UPDATE  #Final
SET     Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales'
WHERE EmployeeEmail in (
		--'dominic.cifarelli@pnmac.com', --REMOVED TO REVERT TO LO FOR MAY 2021
		--'pia.collins@pnmac.com', --REMOVED TO REVERT TO LO FOR MAY 2021
		'adam.schertzer@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Sr Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = 'Evan Tuchman',
	ManagerName_TwoUp = '',
	SiteLead = ''
WHERE EmployeeEmail in (
		'dominic.cifarelli@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = 'Evan Tuchman',
	ManagerName_TwoUp = '',
	SiteLead = ''
WHERE EmployeeEmail in (
		'pia.collins@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE  #Final
SET     TitleGrouping = NULL
WHERE EmployeeEmail in (
		'aimee.vallero@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE  #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
		ManagerName = 'Ben Erickson',
		ManagerEmail = 'ben.erickson@pnmac.com',
		ManagerCity = 'Summerlin',
		ManagerName_TwoUp = 'Matt Moebius',
		ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
		'andrew.simmons@pnmac.com',
		'ed.vandervelde@pnmac.com',
		'julia.shupe@pnmac.com'

)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Ed Vandervelde',
	ManagerEmail = 'ed.vandervelde@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'barry.clay@pnmac.com',
'jason.thomas@pnmac.com',
'rodney.perkins@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE  #Final
SET 	Title = 'Loan Officer',
		TitleGrouping = 'Account Executive',
		ManagerName = 'Ben Erickson',
		ManagerEmail = 'ben.erickson@pnmac.com',
		ManagerCity = 'Summerlin',
		ManagerName_TwoUp = 'Rich Ferre',
		ChannelManager = 'Matt Moebius',
		SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
		'jeffries.johnson@pnmac.com',
		'will.langhagen@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'aaron.arce@pnmac.com'
) and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Sales & Chnnl Mgmt',
	TitleGrouping = 'Vice President',
	ManagerName = 'Rich Ferre',
	ManagerEmail = 'rich.ferre@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Scott Bridges',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail = 'ben.erickson@pnmac.com' and Period = 202105
-----------------------------------------------------
UPDATE  #Final
SET 	Title = 'Mgr, Sales',
    	TitleGrouping = 'Manager - Sales',
		ManagerName = 'Ben Erickson',
		ManagerEmail = 'ben.erickson@pnmac.com',
		ManagerCity = 'Summerlin',
		ManagerName_TwoUp = 'Rich Ferre',
		ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
		'will.langhagen@pnmac.com',
		'jeffries.johnson@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202105 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202105
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tiffany Lewis',
	ManagerEmail = 'tiffany.lewis@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Damon Johnson',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail = 'sarojni.brij@pnmac.com'
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Julia Shupe', ManagerEmail = 'julia.shupe@pnmac.com'
WHERE EmployeeEmail = 'paul.rosadoii@pnmac.com'
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET TitleGrouping = 'Dispatch Agent'
WHERE EmployeeEmail in (
'chad.eckols@pnmac.com',
'jaerica.chambers@pnmac.com',
'laquita.echols@pnmac.com',
'brandy.lawson@pnmac.com',
'amy.hubbard@pnmac.com',
'courtney.caldwell@pnmac.com',
'andrea.coleman@pnmac.com',
'armando.jasso@pnmac.com',
'evelyn.smoot@pnmac.com',
'chad.major@pnmac.com',
'cynthia.mccall@pnmac.com') and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Pia Collins',
	ManagerEmail = 'Pia.Collins@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'jenny.twaddle@pnmac.com',
'jazlyn.briant@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dominic Cifarelli',
	ManagerEmail = 'dominic.cifarelli@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'madison.brown@pnmac.com',
'sara.aguayo@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in
(
'anastasios.marcopulos@pnmac.com',
'david.gharibian@pnmac.com',
'alexander.field@pnmac.com',
'timothy.galstyan@pnmac.com',
'gabriel.phelps@pnmac.com',
'james.bushong@pnmac.com',
'josh.siguenza@pnmac.com',
'bill.quigley@pnmc.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET	ManagerName = 'Aizen Malki',
	ManagerEmail = 'david.malki@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in
(
'joseph.mooney@pnmac.com',
'romel.nicolas@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Aizen Malki',
	ManagerEmail = 'david.malki@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'brian.smalley@pnmac.com',
'connie.serrano@pnmac.com',
'ed.varon@pnmac.com',
'gabriel.mann@pnmac.com',
'jami.manning@pnmac.com',
'kenney.barrientos@pnmac.com',
'logan.padilla@pnmac.com',
'paul.funk@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Department = 'MFD CDL Prod Supportt',
	Title = 'Mgr I, Pipeline Account',
	TitleGrouping = 'Mgr I, Pipeline Account',
	ManagerName = 'Steve Schmalen',
	ManagerEmail = 'stephen.schmalen@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ChannelManager = NULL,
	ManagerName_TwoUp = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'aryan.fakoor@pnmac.com'
)
and Period >= 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'kaitlin.smith@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'agustinatina.castro@pnmac.com'
)
and Period = 202105
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'johncarlo.menjivar@pnmac.com'
)
and Period = 202105
--====================================================================
-- JUNE 2021 UPDATES
--====================================================================
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in
(
'aaron.garcia@pnmac.com',
'ashley.grajo@pnmac.com',
'hunter.johnson@pnmac.com',
'lamia.jarveaux@pnmac.com',
'michael.stokdyk@pnmac.com',
'parik.ravi@pnmac.com',
'timothy.galstyan@pnmac.com'
)
and Period = 202106
-----------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202106 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202106


UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'April Williams',
	ManagerEmail = 'april.williams@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'travis.vorbeck@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Anthony Trozera',
	ManagerEmail = 'anthony.trozera@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'sevak.bazikyan@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Melissa Barone',
	ManagerEmail = 'melissa.barone@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in
(
'roger.henkin@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'David Erlich',
	ManagerEmail = 'david.erlich@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'johncarlo.menjivar@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'denise.meck@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Brandis Rembert',
	ManagerEmail = 'brandis.rembert@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'jonathan.garcia@pnmac.com',
'richard.herrin@pnmac.com'
)
and Period >= 202106

-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Richard Kennimer',
	ManagerEmail = 'richard.kennimer@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Andree Pinson',
    SiteLead = 'Olive Njombua'
WHERE EmployeeEmail in
(
'andrew.shepherd@pnmac.com'
)
and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Evan Tuchman',
	ManagerEmail = 'evan.tuchman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'dominic.cifarelli@pnmac.com',
'pia.collins@pnmac.com'
) and Period = 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'nicholas.gilliam@pnmac.com'
) and Period = 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Andree Pinson',
	ManagerEmail = 'andree.pinson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'james.bruce@pnmac.com'
) and Period = 202106
-----------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Sales & Chnnl Mgmt',
	TitleGrouping = 'Vice President',
	ManagerName = 'Olive Njombua',
	ManagerEmail = 'olive.njombua@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Scott Bridges',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail = 'andree.pinson@pnmac.com' and Period >= 202106
-----------------------------------------------------
UPDATE #Final
SET --NCAFlag = 'N',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeName = 'Preston Orellana'
and EmployeeEmail in
	(
	'preston.orellana@pnmac.com'
	)
and Period in (202105, 202106, 202107)
--====================================================================
-- JULY 2021 UPDATES
--====================================================================
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202107 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202107
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Orlando Cassara',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in (
'john.garrett@pnmac.com',
'lauren.ogden@pnmac.com'
)
and Period = 202107 --Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Michiko Solon',
	ManagerEmail = 'michiko.solon@pnmac.com',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
	SiteLead = 'Nathan Dyce',
	City = 'Pasadena',
	ManagerCity = 'Pasadena'
WHERE EmployeeEmail = 'nathaniel.clark@pnmac.com'
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in
	(
	'pavandeep.mann@pnmac.com'
	)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET NCAFlag = 'Y',
	Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in
	(
	'grae.carson@pnmac.com'
	)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Josh Baker',
	ManagerEmail = 'josh.baker@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in (
'ivan.grigorian@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Sydney Barnes',
	ManagerEmail = 'sydney.barnes@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
	SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
'mitchell.peralta@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Andree Pinson',
	ManagerEmail = 'andree.pinson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'travis.lemley@pnmac.com')
and Period in (202107, 202108)--Added August Due to HR Delay
------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist I, Home Loan',
	TitleGrouping = 'Specialist I, Home Loan',
	ManagerName = 'Crystal Miller',
	ManagerEmail = 'crystal.miller@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Tami Wallace',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in
(
'john.mcgillewie@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist II, Home Loan',
	TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = 'Liz Keefe',
	ManagerEmail = 'elizabeth.keefe@pnmac.com',
	ManagerCity = 'StLouis',
	ManagerName_TwoUp = 'Jenny Boker',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in
(
'monica.ochoa@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Andrew Abrams',
	ManagerEmail = 'andrew.abrams@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'logan.hayes@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Anthony Trozera',
	ManagerEmail = 'anthony.trozera@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'aaron.garcia@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Brian Butler',
	ManagerEmail = 'brian.butler@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'joseph.hagel@pnmac.com',
'blake.ryan@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay

-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Ruben Sanchez',
	ManagerEmail = 'ruben.sanchez@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'cynthia.perez@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'David Erlich',
	ManagerEmail = 'david.erlich@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'erik.bates@pnmac.com'
)
and Period in (202107, 202108)--Added August Due to HR Delay

UPDATE #Final
SET Title = 'NCA Sales Manager',
    TitleGrouping = 'NCA Sales Manager',
	ManagerName = 'Frank Frayer',
	ManagerEmail = 'frank.frayer@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'brandon.reish@pnmac.com'
) and Period in (202107, 202108)--Added August Due to HR Delay

UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'Orlando.Cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'nicole.payne@pnmac.com'
) and Period in (202107, 202108)--Added August Due to HR Delay
--====================================================================
-- AUGUST 2021 UPDATES
--====================================================================
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202108 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202108
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ben Erickson',
	ManagerEmail = 'ben.erickson@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'gary.darden@pnmac.com'
) and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Refinance Loan',
    TitleGrouping = 'Specialist, Refinance Loan',
	ManagerName = 'Chris Franklin',
	ManagerEmail = 'chris.franklin@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'AJ Hatfield',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
'yvonne.holloway@pnmac.com'
)
and Period in (202108, 202109)
------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Andrew Simmons',
	ManagerEmail = 'andrew.simmons@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ben Erickson',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'ed.vandervelde@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Gary Darden',
	ManagerEmail = 'gary.darden@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ben Erickson',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'barry.clay@pnmac.com',
'jason.martinez@pnmac.com',
'jason.thomas@pnmac.com',
'nicholas.hunter@pnmac.com',
'rodney.perkins@pnmac.com',
'vincent.chu@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'tatum.thompson@pnmac.com',
'madison.ware@pnmac.com',
'khadeeja.ali@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'matthew.mcglinn@pnmac.com',
'rachel.vasquez@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'shalimar.santiago@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nicole Payne',
	ManagerEmail = 'nicole.payne@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'caroline.sessa@pnmac.com'
) and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Brock Walker',
	ManagerEmail = 'brock.walker@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Anthony McDevitt',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'jane.hurst@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Meridith Lavallee',
	ManagerEmail = 'meridith.lavallee@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'douglas.vorbeck@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Andrew Simmons',
	ManagerEmail = 'andrew.simmons@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ben Erickson',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'derek.beutel@pnmac.com',
'dominique.benton@pnmac.com',
'roland.obregon@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Brandis Rembert',
	ManagerEmail = 'brandis.rembert@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'nadim.alemian@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Thomas Zinschlag',
	ManagerEmail = 'thomas.zinschlag@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
	'thieulong.hoang@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Melissa Barone',
	ManagerEmail = 'melissa.barone@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in
(
'russell.thorne@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Matt Ellis',
	ManagerEmail = 'matt.ellis@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in
(
'tonya.watkins@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Kaitey Gates',
	ManagerEmail = 'kaitey.gates@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Frank Frayer',
    SiteLead = 'Kevin Price'
WHERE EmployeeEmail in
(
'roberto.montero@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist I, Home Loan',
	TitleGrouping = 'Specialist I, Home Loan',
	ManagerName = 'Felicia Johnson',
	ManagerEmail = 'felicia.johnson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Ruben Berger',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in
(
'robyn.moore@pnmac.com'
)
and Period in (202107, 202108)--update request was never submitted. Felicia's request based on incorrect closed loan social survey report numbers

-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Chadd Grogg',
	ManagerEmail = 'chadd.grogg@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Frank Frayer',
    SiteLead = 'Kevin Price'
WHERE EmployeeEmail in
(
'bart.johnson@pnmac.com'
)
and Period = 202108

-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'joseph.hagel@pnmac.com','nadim.alemian@pnmac.com','thieulong.hoang@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Sherri Viamontes',
	ManagerEmail = 'shante.viamontes@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in
(
'conner.ricca@pnmac.com',
'dylan.chung@pnmac.com',
'makenzie.buck@pnmac.com',
'shelbi.janssen@pnmac.com',
'patrick.clark@pnmac.com',
'cody.anderson@pnmac.com',
'spencer.ovshak@pnmac.com',
'warren.sartor@pnmac.com',
'sarah.murphy@pnmac.com',
'maryhelen.williams@pnmac.com',
'andrew.mccullough@pnmac.com',
'david.clark@pnmac.com',
'steven.owens@pnmac.com',
'jacobie.fullerton@pnmac.com',
'james.randall@pnmac.com',
'jordan.skousen@pnmac.com',
'joshua.hylan@pnmac.com',
'amber.prasopoulos@pnmac.com',
'andrew.liu@pnmac.com',
'art.soto@pnmac.com',
'ashley.rico@pnmac.com',
'samuel.uzzan@pnmac.com',
'thomas.glenn@pnmac.com',
'daisy.mar@pnmac.com',
'mohagoney.moore@pnmac.com',
'connor.loftis@pnmac.com',
'quinten.minke@pnmac.com',
'eman.amawi@pnmac.com'
)
and Period = 202108
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Thomas Zinschlag',
	ManagerEmail = 'thomas.zinschlag@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Orlando Cassara',
	ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in (
'erica.taylor@pnmac.com'
)
and Period = 202108
--====================================================================
-- SEPTEMBER 2021 UPDATES
--====================================================================
--UPDATE F

--SET F.ManagerName = F2.ManagerName,
--	F.ManagerEmail = F2.ManagerEmail,
--	F.ManagerName_TwoUp = F2.ManagerName_TwoUp,
--	F.ChannelManager = F2.ChannelManager,
--	F.SiteLead = F2.SiteLead,
--	F.City = F2.City,
--	F.ManagerCity = F2.ManagerCity,
--	F.Title = F2.Title,
--	F.TitleGrouping = F2.TitleGrouping

--FROM #Final F

--inner join #Final F2
--ON F.EmployeeEmail = F2.EmployeeEmail and F2.Period = 202108 and F2.TitleGrouping in ('Account Executive', 'Loan Officer')

--WHERE F.Period = 202109

UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202109 S --Table Created To Consolidate Sales Changes with Channel Manager for Lock Goals (excluding Training and Special Projects LOs)
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jimmy Yang',
	ManagerEmail = 'jimmy.yang@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'michiko.solon@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'Orlando.Cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'daniel.silvey@pnmac.com'
) and Period = 202109--Added August Due to HR Delay
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Moorpark',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'benjamin.wharton@pnmac.com'
) and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Benjamin Wharton',
	ManagerEmail = 'benjamin.wharton@pnmac.com',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
	SiteLead = 'Nathan Dyce',
	City = 'Pasadena',
	ManagerCity = 'Pasadena'
WHERE EmployeeEmail in
(
'kris.bacani@pnmac.com',
'nicholas.spencer@pnmac.com',
'gary.zakaryan@pnmac.com',
'ryan.cohen@pnmac.com',
'david.yang@pnmac.com',
'lauren.ballard@pnmac.com',
'sarkis.babakhanyan@pnmac.com',
'nathaniel.clark@pnmac.com',
'tanner.barge@pnmac.com'
)
and Period = 202109
 -----------------------------------------------------
UPDATE #Final
SET CDLSales = 'Y',
	Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'sean.puckett@pnmac.com'
) and Period in (202109,202110)
-----------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Aaron Hatfield',
	ManagerEmail = 'aaron.hatfield@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'michael.stephan@pnmac.com'
) and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Michael Stephan',
	ManagerEmail = 'michael.stephan@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = 'Aaron Hatfield',
    SiteLead = 'Olive Njombua'
WHERE EmployeeEmail in
(
'andrew.mccullough@pnmac.com',
'shelbi.janssen@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'carmen.hanson@pnmac.com'
)
and Period = 202109

----------------------------------------------------------------------------

UPDATE #Final
SET Title = 'Loan Officer',
	Titlegrouping = 'Account Executive',
	ManagerName = 'Thomas Zinschlag',
	ManagerEmail = 'thomas.zinschlag@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Orlando Cassara',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
	'brian.butler@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Richard Peck',
	ManagerEmail = 'richard.peck@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'khadeeja.ali@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'David Risse',
	ManagerEmail = 'david.risse@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ryan Finkas',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'tatum.thompson@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Gary Darden',
	ManagerEmail = 'gary.darden@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ben Erickson',
    SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in
(
'angelica.williams1@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'maritza.chiaway@pnmac.com',
'james.young@pnmac.com',
'cody.bergstrom@pnmac.com',
'ashlee.warner@pnmac.com',
'jake.crocker@pnmac.com',
'todd.luvisi@pnmac.com',
'mike.agne@pnmac.com',
'nicholas.massari@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Patricia Mendez',
	ManagerEmail = 'patricia.mendez@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Frank Frayer',
	Sitelead = 'Kevin Price'
WHERE EmployeeEmail in (
'gerardo.carranza@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE F

SET TitleGrouping = 'Account Executive',
	Title = 'Loan Officer'

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202109 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202109 and F.TitleGrouping <> 'Account Executive'
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'scott.zeller@pnmac.com',
'miranda.bartlett@pnmac.com',
'joseph.garcia@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Arin Baghermian',
	ManagerEmail = 'arin.baghermian@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'vage.tsaturyan@pnmac.com',
'stephanie.mcgrath@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Austin Schreibman',
	ManagerEmail = 'austin.schreibman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'asiah.dorsey@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Benjamin Wharton',
	ManagerEmail = 'benjamin.wharton@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Adam Adoree',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in
(
'tanner.barge@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Daniel Kier',
	ManagerEmail = 'daniel.kier@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in
(
'xavier.moya@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Sean Puckett',
	ManagerEmail = 'sean.puckett@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'roberto.annoni@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
    SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in
(
'dustin.fletcher@pnmac.com'
)
and Period = 202109
----------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Nicholas Gilliam',
	ManagerEmail = 'nicholas.gilliam@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adam Adoree',
    SiteLead = 'DJ Ford'
WHERE EmployeeEmail in
(
'amanda.tubbs@pnmac.com'
)
and Period = 202109
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Johnson',
	ManagerEmail = 'taylor.johnson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
where EmployeeEmail in
(
'susan.flores@pnmac.com'
) and Period = 202109
--====================================================================
-- OCTOBER 2021 UPDATES
--====================================================================
UPDATE F

SET F.ManagerName = F2.ManagerName,
	F.ManagerEmail = F2.ManagerEmail,
	F.ManagerName_TwoUp = F2.ManagerName_TwoUp,
	F.ChannelManager = F2.ChannelManager,
	F.SiteLead = F2.SiteLead,
	F.City = F2.City,
	F.ManagerCity = F2.ManagerCity,
	F.Title = F2.Title,
	F.TitleGrouping = F2.TitleGrouping

FROM #Final F

inner join #Final F2
ON F.EmployeeEmail = F2.EmployeeEmail and F2.Period = 202109 and F2.TitleGrouping in ('Account Executive', 'Loan Officer')

WHERE F.Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y',
	Title = 'EVP, Retail Production',
	TitleGrouping = 'Executive Vice President',
	ManagerName = 'Scott Bridges',
	ManagerEmail = 'scott.bridges@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Doug Jones',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'nathan.dyce@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'SVP, Reg Sales Leader',
	TitleGrouping = 'Senior Vice President',
	ManagerName = 'Nathan Dyce',
	ManagerEmail = 'nathan.dyce@pnmac.com',
	ManagerCity = 'Pasadena',
	--ManagerName_TwoUp = 'Doug Jones',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'adam.adoree@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Jimmy Kim',
	ManagerEmail = 'jimmy.kim@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'diana.yegiyan@pnmac.com'
,'anthony.alas@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeEmail in (
'jason.massie@pnmac.com'
)
and Period >= 202110
---------------------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202110 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202110
----------------------------------------------------------------------------
UPDATE F

SET F.TrainingEndDate = '11/05/2021'

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202110 S
ON F.EmployeeEmail = S.[Employee Email]--on F.EmployeeName = S.[Loan Officer]

WHERE S.Training = 'Y'
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'aaron.arce@pnmac.com',
'david.malki@pnmac.com',
'anthony.tabor@pnmac.com',
'aubray.breaux@pnmac.com',
'austin.schreibman@pnmac.com',
'benjamin.wharton@pnmac.com',
'eddie.machuca@pnmac.com',
'edith.torosyan@pnmac.com',
'jimmy.kim@pnmac.com',
'jimmy.yang@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Jimmy Kim',
	ManagerEmail = 'jimmy.kim@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = 'Jason Massie',
	SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'andrew.romero@pnmac.com',
'carlos.lopez@pnmac.com',
'derek.esterberg@pnmac.com',
'erik.bates@pnmac.com',
'erik.karibas@pnmac.com',
'imelda.sanchez@pnmac.com',
'johncarlo.menjivar@pnmac.com',
'lorena.peral@pnmac.com',
'nuvia.ivey@pnmac.com',
'stephen.castaneda@pnmac.com',
'vartan.davtyan@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'morgan.duprey@pnmac.com'
) and Period = 202110
------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'michael.kreitner@pnmac.com'
) and Period = 202110
------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Aubray Breaux',
	ManagerEmail = 'aubray.breaux@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = 'Jason Massie',
	SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'david.erlich@pnmac.com'
) and Period = 202110
------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Melissa Barone',
	ManagerEmail = 'melissa.barone@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'phillip.brown1@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'robel.moreno@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Manager, CDL Recruiting & Training',
    TitleGrouping = 'Manager, CDL Recruiting & Training',
	ManagerName = 'Shaun Eric Wilson',
	ManagerEmail = 'shaun.wilson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'nicole.stober@pnmac.com'
) and Period = 202110
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'bill.quigley@pnmac.com'
) and Period = 202110

--====================================================================
-- NOVEMBER 2021 UPDATES
--====================================================================
--UPDATE F

--SET F.ManagerName = F2.ManagerName,
--	F.ManagerEmail = F2.ManagerEmail,
--	F.ManagerName_TwoUp = F2.ManagerName_TwoUp,
--	F.ChannelManager = F2.ChannelManager,
--	F.SiteLead = F2.SiteLead,
--	F.City = F2.City,
--	F.ManagerCity = F2.ManagerCity,
--	F.Title = F2.Title,
--	F.TitleGrouping = F2.TitleGrouping

--FROM #Final F

--inner join #Final F2
--ON F.EmployeeEmail = F2.EmployeeEmail and F2.Period = 202110 and F2.TitleGrouping in ('Account Executive', 'Loan Officer')

--WHERE F.Period = 202111

UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202111 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'nelson.massari@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Nelson Massari',
	ManagerEmail = 'nelson.massari@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager =  'Orlando Cassara',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'denise.meck@pnmac.com'
,'david.esteras@pnmac.com'
,'corey.cardone@pnmac.com'
,'alcides.marquina@pnmac.com'
,'chad.hodges@pnmac.com'
,'christina.medina@pnmac.com'
,'stephen.toth@pnmac.com'
,'alexander.soria@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'N',
	Title = 'Specialist II, Home Loan',
    TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = 'Shawn Park',
	ManagerEmail = 'shawn.park@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Gregory Tillman',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'jasmin.echols@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'N',
	DivisionGroup = 'MFD',
	Department = 'MFD CDL Closing Review',
	Title = 'Specialist II, Home Loan',
    TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = 'Christian CAviness',
	ManagerEmail = 'christian.caviness@pnmac.com',
	ManagerCity = 'Phoenix',
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = 'Mandy Henderson'
WHERE EmployeeEmail in (
'conner.ricca@pnmac.com'
) and Period >= 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Julia Shupe',
	ManagerEmail = 'julia.shupe@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Ben Erickson',
	SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
'kenny.fatino@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
    TitleGrouping = 'Vice President',
	ManagerName = 'Tara Kinney',
	ManagerEmail = 'tara.kinney@pnmac.com',
	ManagerCity = 'Tennessee',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'eric.busalacchi@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'ryan.p.wilson@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Matt Ellis',
	ManagerEmail = 'matt.ellis@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'patrick.banker@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Garrett Bateman',
	ManagerEmail = 'garrett.bateman@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'jimmy.maokhamphiou@pnmac.com',
'kalilah.buchanan@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Robel Moreno',
	ManagerEmail = 'robel.moreno@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'jeff.borgognoni@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'al.nasser@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'brice.capps@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Robel Moreno',
	ManagerEmail = 'robel.moreno@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'carole.thompson@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = NULL,
	ManagerCity = NULL,
	ManagerName_TwoUp = NULL,
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'michael.pemberton@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'cindy.hudgins@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE ManagerEmail in (
'nicole.stober@pnmac.com'
)
and TitleGrouping = 'Account Executive'
and Period >= 202111


UPDATE #Final
SET CostCenter = '1201-300-93200',
	Department = 'CDL New Cust Acquisition',
	DepartmentId = 93200
WHERE EmployeeEmail = 'alan.croasdale@pnmac.com'
and Period >= 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'phillip.brown1@pnmac.com'
) and Period >= 202109
---------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'Y',
	TenuredFlag ='N',
	Department = 'CDL Sales',
	Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'david.miller@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'demar.hosey@pnmac.com'
,'victoria.groeger@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
 'ricardo.arreola@pnmac.com'
,'douglas.vorbeck@pnmac.com'
,'keith.williams@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'misael.torres@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Macy Gunderson',
	ManagerEmail = 'macy.gunderson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'erin.garrison@pnmac.com'
,'christopher.ward@pnmac.com'
,'kaitlin.smith@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Macy Gunderson',
	ManagerEmail = 'macy.gunderson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'william.urbance@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Michael Kreitner',
	ManagerEmail = 'michael.kreitner@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Rich Ferre'
WHERE EmployeeEmail in (
 'davis.elgin@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'mary.karapetyan@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Jay Bisla',
	ManagerEmail = 'harjoyte.bisla@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'kyle.ellsworth@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Robel Moreno',
	ManagerEmail = 'robel.moreno@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'justin.duncan@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'Y',
	TenuredFlag ='N',
	Department = 'CDL Sales',
	Title = 'Specialist, Loan Refinance',
	TitleGrouping  = 'Specialist, Loan Refinance',
	ManagerName = 'Gary Darden',
	ManagerEmail = 'gary.darden@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Rich Ferre',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'richard.ponce@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Eric Jones',
	ManagerEmail = 'eric.jones@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'peter.perez@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Juanita Moreno',
	ManagerEmail = 'juanita.moreno@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'kelly.uberti@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Katherine Orabuena',
	ManagerEmail = 'katherine.orabuena@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'margaret.erickson@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Patricia Mendez',
	ManagerEmail = 'patricia.mendez@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'adam.abrams@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ryan Kading',
	ManagerEmail = 'stephen.kading@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'martin.peychev@pnmac.com'
) and Period = 202111
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Taylor Johnson',
	ManagerEmail = 'taylor.johnson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in (
'matthew.bland@pnmac.com'
) and Period = 202111

--====================================================================
-- DECEMBER 2021 UPDATES
--====================================================================
--UPDATE F

--SET F.ManagerName = F2.ManagerName,
--	F.ManagerEmail = F2.ManagerEmail,
--	F.ManagerName_TwoUp = F2.ManagerName_TwoUp,
--	F.ChannelManager = F2.ChannelManager,
--	F.SiteLead = F2.SiteLead,
--	F.City = F2.City,
--	F.ManagerCity = F2.ManagerCity,
--	F.Title = F2.Title,
--	F.TitleGrouping = F2.TitleGrouping

--FROM #Final F

--inner join #Final F2
--ON F.EmployeeEmail = F2.EmployeeEmail and F2.Period = 202111 and F2.TitleGrouping in ('Account Executive', 'Loan Officer')

--WHERE F.Period = 202112
-----------------------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202112 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Austin Schreibman',
	ManagerEmail = 'austin.schreibman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = 'Jason Massie',
    SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in
(
'roudvik.abdalian@pnmac.com'
)
and Period = 202112
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping  = 'Specialist, Loan Refinance',
	ManagerName = 'Jeffries Johnson',
	ManagerEmail = 'jeffries.johnson@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'william.barnes@pnmac.com'
) and Period >= 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'N',
	Title = 'Specialist II, Home Loan',
    TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = NULL,
	ManagerEmail = NULL,
	ManagerCity = NULL,
	ManagerName_TwoUp = NULL,
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'scott.moyer@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'truc.le@pnmac.com'
,'christian.smith@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
	'sasha.drawdy@pnmac.com'
	,'austin.romeo@pnmac.com'
	,'colton.borke@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Kelley Christianer',
	ManagerEmail = 'kelley.christianer@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = 'Anthony McDevitt',
	SiteLead = 'Grant Mills'
WHERE EmployeeEmail in (
'jeremiah.kneeland@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Sean Puckett',
	ManagerEmail = 'sean.puckett@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'katerina.farese@pnmac.com'
)
and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Brandis Rembert',
	ManagerEmail = 'brandis.rembert@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Damon Johnson',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'william.urbance@pnmac.com'
)
and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Bill Quigley',
	ManagerEmail = 'bill.quigley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Damon Johnson',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'gavin.pate@pnmac.com'
)
and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Designer II, Instructional',
    TitleGrouping = 'Retail Training',
	ManagerName = 'Brad Thompson',
	ManagerEmail = 'bradley.thompson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Olive Njombua',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'colin.wickers@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
    TitleGrouping = 'Specialist, Loan Refinance',
	ManagerName = 'Michael Stephan',
	ManagerEmail = 'michael.stephan@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Aaron Hatfield',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'luis.perez@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Aaron Arce',
	ManagerEmail = 'aaron.arce@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = 'Jason Massie',
	SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'mary.karapetyan@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'david.miller@pnmac.com'
,'demar.hosey@pnmac.com'
,'jhanya.williamson@pnmac.com'
,'kyle.ellsworth@pnmac.com'
,'roberto.annoni@pnmac.com'
,'victoria.groeger@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'yoonji.yeom@pnmac.com'
) and Period = 202112
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Tennessee',
	ManagerName_TwoUp = 'Eric Busalacchi',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
	'donavan.akers@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Josh Nelson',
	ManagerEmail = 'joshua.nelson@pnmac.com',
	ManagerCity = 'Tennessee',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'john.garrett@pnmac.com'
	,'lauren.ogden@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Jessie Corral',
	ManagerEmail = 'jessie.corral@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'gevorg.karapetian@pnmac.com'
	,'armen.grigoryan@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Nikki Stober',
	ManagerEmail = 'nicole.stober@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'andrea.simpson@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Purchase Loan',
	TitleGrouping = 'Specialist, Purchase Loan',
	ManagerName = 'Pia Collins',
	ManagerEmail = 'pia.collins@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = NULL,
	ManagerName_TwoUp = 'Nathan Dyce',
	SiteLead = NULL
WHERE EmployeeEmail in (
	'armando.jasso@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ChannelManager = 'No Channel Manager',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
	'angel.vilorio@pnmac.com')
	and Period = 202112
----------------------------------------------------------------------------------
UPDATE #Final
SET CDLSales = 'N',
	Title = 'Specialist II, Home Loan',
	TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = 'Joe Owens',
	ManagerEmail = 'joey.owens@pnmac.com',
	ManagerCity = 'Phoenix',
	ChannelManager = NULL,
	ManagerName_TwoUp = 'Mandy Henderson',
	SiteLead = NULL
WHERE EmployeeEmail in (
	'scott.moyer@pnmac.com')
	and Period >= 202112
----------------------------------------------------------------------------------
--UPDATE #Final
--SET ManagerName = 'Matt Moebius',
--	ManagerEmail = 'matthew.moebius@pnmac.com',
--	ManagerCity = 'Roseville',
--	ManagerName_TwoUp = 'Ryan Finkas',
--	ChannelManager = NULL,
--	SiteLead = NULL
--WHERE EmployeeEmail in (
--	 'david.risse@pnmac.com'
--	,'edward.taylor@pnmac.com'
--	,'joe.mckinley@pnmac.com'
--	,'richard.peck@pnmac.com'
--	,'sydney.barnes@pnmac.com')
--	and Period = 202112
------------------------------------------------------------------------------------
--UPDATE #Final
--SET ManagerName = 'Ben Erickson',
--	ManagerEmail = 'ben.erickson@pnmac.com',
--	ManagerCity = 'Roseville',
--	ManagerName_TwoUp = 'Ryan Finkas',
--	ChannelManager = NULL,
--	SiteLead = NULL
--WHERE EmployeeEmail in (
--	 'david.risse@pnmac.com'
--	,'edward.taylor@pnmac.com'
--	,'joe.mckinley@pnmac.com'
--	,'richard.peck@pnmac.com'
--	,'sydney.barnes@pnmac.com')
--	and Period = 202112
----======================================================================================================
------LOOP to find those whose managers are in MFD, will function until an employee is more than 15 ------
----levels removed from C-Level---------------------------------------------------------------------------
----======================================================================================================
--Declare @updatecounter int
--Set @updatecounter = 1

--While @updatecounter <= 15

--Begin

--Update SM

--Set DivisionGroup = 'MFD'

--From #Final SM

--Where
--((Select DivisionGroup
--From #Final
--Where EmployeeId = SM.ManagerId
--and Period = SM.Period) = 'MFD'
--or SM.ManagerId in (Select e.EmployeeId
--					From dw_org.dbo.employee e
--					left join dw_org.dbo.department d
--					on e.DepartmentId = d.DepartmentId
--					Where e.RowCurrentFlag = 'Y'
--					and (D.Name like '%PCG%'
--						 and e.PreferredName <> 'Kimberly Nichols'
--					     or D.Name like '%Underwriting-Retail%'
--					     or D.Name like '%MFD%')))
--and DivisionGroup Is Null

--Set @updatecounter = @updatecounter + 1

--End
-----------------------------------------------------

UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202201 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202201
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'FVP, Regional Sales Leader',
	TitleGrouping = 'First Vice President',
	ManagerName = 'Scott Bridges',
	ManagerEmail = 'scott.bridges@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'ryan.finkas@pnmac.com'
) and Period = 202201
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Scott Bridges',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
	'ben.erickson@pnmac.com'
	,'matthew.moebius@pnmac.com')
	and Period = 202201
----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
	'david.risse@pnmac.com'
	,'edward.taylor@pnmac.com'
	,'joe.mckinley@pnmac.com')
	and Period = 202201
----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ben Erickson',
	ManagerEmail = 'ben.erickson@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
	'richard.peck@pnmac.com'
	,'sydney.barnes@pnmac.com')
	and Period = 202201
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeEmail in (
'eddie.machuca@pnmac.com'
)
and Period >= 202201
-----------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Eddie Machuca',
	ManagerEmail = 'eddie.machuca@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'aaron.arce@pnmac.com'
,'anthony.tabor@pnmac.com'
,'benjamin.wharton@pnmac.com'
,'edith.torosyan@pnmac.com'
,'felix.kim@pnmac.com'
) and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET Title = 'NCA, Sales Manager',
    TitleGrouping = 'NCA, Sales Manager',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail = 'justin.syracuse@pnmac.com'
and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET Title = 'NCA, Sales Manager',
    TitleGrouping = 'NCA, Sales Manager',
	ManagerName = 'Eric Busalacchi',
	ManagerEmail = 'eric.busalacchi@pnmac.com',
	ManagerCity = 'Tennessee',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
        SiteLead = NULL
WHERE EmployeeEmail in (
'corey.marcelin@pnmac.com'
,'jacobie.fullerton@pnmac.com'
)
and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET CDLSales = 'N',
	DivisionGroup = 'MFD',
	Department = 'MFD CDL Condition Review',
	Title = 'Specialist II, Home Loan',
    TitleGrouping = 'Specialist II, Home Loan',
	ManagerName = NULL,
	ManagerEmail = NULL,
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = NULL
WHERE EmployeeEmail in (
'siena.lee@pnmac.com'
) and Period>= 202201
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Tiffany Lewis',
	ManagerEmail = 'tiffany.lewis@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'meredith.denson@pnmac.com'
)
and Period = 202201
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Floyd Taylor',
	ManagerEmail = 'floyd.taylor@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Adriana Gonzalez',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'david.kennedy@pnmac.com'
)
and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ben Erickson',
	ManagerEmail = 'ben.erickson@pnmac.com',
	ManagerCity = 'Summerlin',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'richard.peck@pnmac.com'
) and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President',
	ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Scott Bridges'
WHERE EmployeeEmail in (
'ryan.kading@pnmac.com'
) and Period = 202201
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Ryan Kading',
	ManagerEmail = 'ryan.kading@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeEmail in (
'juanita.moreno@pnmac.com'
,'eric.jones@pnmac.com'
,'patricia.mendez@pnmac.com'
,'taylor.johnson@pnmac.com'
) and Period = 202201
-----------------------------------------------------------
UPDATE  #Final
SET Title = 'LO, Special Projects',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'todd.rasmussen@pnmac.com'
)
and Period = 202201
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Ryan Finkas'
WHERE EmployeeEmail in (
'reid.wright@pnmac.com'
)
and Period = 202201
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tate Fackrell',
	ManagerEmail = 'tate.fackrell@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Ryan Finkas'
WHERE EmployeeEmail in (
'brian.stoddard@pnmac.com'
)
and Period = 202201
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Joe McKinley',
	ManagerEmail = 'joe.mckinley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'callie.lieding@pnmac.com'
)
and Period = 202201
-----------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tyler Smedley',
	ManagerEmail = 'tyler.smedley@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'marcelina.peter@pnmac.com'
)
and Period = 202201
----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Purchase Loan',
	TitleGrouping = 'Specialist, Purchase Loan',
	ManagerName = 'Pia Collins',
	ManagerEmail = 'pia.collins@pnmac.com',
	ManagerCity = 'Plano',
	ChannelManager = NULL,
	ManagerName_TwoUp = 'Nathan Dyce',
	SiteLead = NULL
WHERE EmployeeEmail in (
	'armando.jasso@pnmac.com')
	and Period = 202201
----------------------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202202 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET EmploymentStatus = 'Active',
	ManagerName = 'Felicia Johnson',
	ManagerEmail = 'felicia.johnson@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Teresa Henry'
WHERE EmployeeEmail in (
 'janet.khanibikunle@pnmac.com'
) and Period = 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
	ManagerName = 'Josh Baker',
	ManagerEmail = 'josh.baker@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in (
 'rachael.segui@pnmac.com'
,'timothy.galstyan@pnmac.com'
,'david.merzian@pnmac.com'
) and Period between 202111 and 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
	PurchaseFlag = 'Y',
	ManagerName = 'Evan Tuchman',
	ManagerEmail = 'evan.tuchman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'richard.kennimer@pnmac.com'
) and Period = 202202
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Richard Kennimer',
	ManagerEmail = 'richard.kennimer@pnmac.com',
	ManagerCity = 'Pasadena',
	ChannelManager = 'Evan Tuchman',
	SiteLead = 'Nathan Dyce',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeEmail in (
'harris.khatri@pnmac.com'
) and Period = 202202
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tracy Ledet',
	ManagerEmail = 'tracy.ledet@pnmac.com',
	ManagerCity = 'Summerlin',
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = 'Chase Gilbert'
WHERE EmployeeEmail in (
'janette.colombo@pnmac.com',
'jean.moise@pnmac.com',
'lisa.brown@pnmac.com',
'maria.beltrano@pnmac.com',
'miah.sanchez@pnmac.com',
'samantha.eskridge@pnmac.com',
'celest.rubiera@pnmac.com'
) and Period = 202202
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Craig Cachopo',
	ManagerEmail = 'craig.cachopo@pnmac.com',
	ManagerCity = 'Summerlin',
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = 'Chase Gilbert'
WHERE EmployeeEmail in (
'alan.villegas@pnmac.com',
'dora.barrera@pnmac.com',
'jennifer.flores@pnmac.com'
) and Period = 202202
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Bill Widener',
	ManagerEmail = 'william.widener@pnmac.com',
	ManagerCity = 'Summerlin',
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = 'Chase Gilbert'
WHERE EmployeeEmail in (
'brittney.derrick@pnmac.com',
'gonzalo.zanartu@pnmac.com'
) and Period = 202202
-----------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Annette Santana',
	ManagerEmail = 'annette.santana@pnmac.com',
	ManagerCity = 'Summerlin',
	ChannelManager = NULL,
	SiteLead = NULL,
	ManagerName_TwoUp = 'Chase Gilbert'
WHERE EmployeeEmail in (
'michael.bosco@pnmac.com'
) and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Brandis Rembert',
	ManagerEmail = 'brandis.rembert@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
'carlos.ramirez@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'carlos.ramirez@pnmac.com'
,'roberto.annoni@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping  = 'Specialist, Loan Refinance',
	ManagerName = 'Aaron Arce',
	ManagerEmail = 'aaron.arce@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'matthew.piccari@pnmac.com',
 'meghan.kearney@pnmac.com',
 'anahit.mkrtchyan@pnmac.com'
) and Period = 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'isaac.solorio@pnmac.com'
 ,'todd.maier@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping  = 'Specialist, Loan Refinance',
	ManagerName = 'Justin Syracuse',
	ManagerEmail = 'justin.syracuse@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'lorraina.soto@pnmac.com'
,'rachel.bettine@pnmac.com'
) and Period = 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Wayne Davey',
	ManagerEmail = 'wayne.davey@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'alec.gable@pnmac.com'
,'gavin.pate@pnmac.com'
,'jonathan.pitkevitsch@pnmac.com'
,'misael.torres@pnmac.com'
,'stacey.roth@pnmac.com'
,'tracie.jones@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Nikki Stober',
	ManagerEmail = 'nicole.stober@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'manuel.guido@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
 'william.jameson@pnmac.com'
,'alexis.arevalos@pnmac.com'
,'michael.tashchyan@pnmac.com'
,'dakota.ballard@pnmac.com'
,'dylan.maister@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Josh Nelson',
	ManagerEmail = 'joshua.nelson@pnmac.com',
	ManagerCity = 'Tennessee',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
 'donavan.akers@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Bill Quigley',
	ManagerEmail = 'bill.quigley@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'Damon Johnson',
	SiteLead = 'DJ Ford'
WHERE EmployeeEmail in (
 'carlos.ramirez@pnmac.com'
)
and Period = 202202
-----------------------------------------------------
UPDATE #Final
SET City = 'Tampa'
WHERE EmployeeEmail in (
 'chris.nicholson@pnmac.com'
 ) and Period = 202202

UPDATE #Final
SET ManagerEmail = 'dwight.dickey@pnmac.com'
WHERE ManagerEmail = 'robert.dickey@pnmac.com'

UPDATE #Final
SET EmployeeEmail = 'juan.tobar@pnmac.com'
WHERE EmployeeId = '011161'
and EmployeeEmail is null

UPDATE #Final
SET ManagerName = 'Brian Butler'
WHERE ManagerName = 'BRIAN Bulter'

UPDATE #Final
SET ManagerName = 'Joe McKinley'
WHERE ManagerName = 'Joe Mckinley'

Update #Final
Set ManagerName = 'David Risse'
where ManagerName = 'Dave Risse'

UPDATE #Final
SET ManagerName_TwoUp = 'Kevin Price', SiteLead = 'Kevin Price'
WHERE ManagerName_TwoUp = 'Grant Mills'
and Period = 202101
and ManagerName in ('Garrett Bateman', 'Ryan Wilson')

UPDATE #Final
SET ManagerName_TwoUp = 'Kevin Price', SiteLead = 'Kevin Price'
WHERE ManagerName_TwoUp = 'Grant Mills'
and Period = 202102
and ManagerCity = 'Phoenix'
and EmploymentStatus in ('Active', 'LOA')
and TitleGrouping = 'Account Executive'

UPDATE #Final
SET ManagerCity = 'Pasadena'
WHERE ManagerName = 'Aizen Malki' and ManagerCity = 'Moorpark' and ManagerName_TwoUp = 'Nathan Dyce'

UPDATE #Final
SET ManagerName_TwoUp = 'Olive Njombua'
WHERE ManagerName_TwoUp = 'Carl Illum' and Period >= 202008

UPDATE #Final
SET ManagerCity = 'Phoenix'
WHERE ManagerCity = 'Roseville' and ManagerName = 'Steven Garcia' and NCAFlag = 'Y'

UPDATE #Final
SET ManagerName_TwoUp = 'Kevin Price'
WHERE ManagerName in ('Chadd Grogg', 'Natalia Navarro')
	and EmploymentStatus = 'Active'
	and TitleGrouping in ('Account Executive')
	and Period >= 202010
	and ManagerName_TwoUp = 'Grant Mills'
-----------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'armen.grigoryan@pnmac.com',
'gevorg.karapetian@pnmac.com',
'carlos.ramirez@pnmac.com',
'roberto.annoni@pnmac.com'
)
and Period = 202201

UPDATE #Final--UPDATED ON 10/23/2020 AS REQUESTED BY SALES
SET ManagerName_TwoUp = 'Shaun Eric Wilson'
WHERE ManagerName in ('Brian Schooler', 'Josh Nelson')
	and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202203 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202203
-----------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Fiorelli',
	ManagerEmail = 'taylor.fiorelli@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'corey.marcelin@pnmac.com'
)
and Period = 202203

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Matt Ellis',
	ManagerEmail = 'matt.ellis@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Eric Busalacchi',
	SiteLead = 'Tara Kinney'
WHERE EmployeeEmail in (
'jacobie.fullerton@pnmac.com'
)
and Period = 202203

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Dominic Cifarelli',
	ManagerEmail = 'Dominic Cifarelli',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = 'Evan Tuchman',
	SiteLead = 'Nathan Dyce'
WHERE EmployeeEmail in (
'michael.stephan@pnmac.com'
)
and Period = 202203

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
	 'koron.davis@pnmac.com'
	,'manuel.guido@pnmac.com'
	,'mitch.stark@pnmac.com'
	,'nathan.camp@pnmac.com'
	,'patrick.huynh@pnmac.com'
	,'paul.ranieri@pnmac.com'
	,'quinton.potter@pnmac.com'
	,'alec.gable@pnmac.com'
	,'jonathan.pitkevitsch@pnmac.com'
	,'stacey.roth@pnmac.com'
)
and Period = 202203

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'daniel.kier@pnmac.com'
)
and Period = 202203

UPDATE #Final
SET Title = 'Specialist, Purchase Loan',
	TitleGrouping = 'Specialist, Purchase Loan',
	ManagerName = 'John Anding',
	ManagerEmail = 'john.anding@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'meghan.kearney@pnmac.com'
)
and Period >= 202203

UPDATE #Final
SET CDLSales = 'Y',
	Title = 'Specialist, Purchase Loan',
	TitleGrouping = 'Specialist, Purchase Loan',
	ManagerName = 'Dominic Cifarelli',
	ManagerEmail = 'dominic.cifarelli@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'dakota.parker@pnmac.com'
)
and Period = 202203
-----------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202204 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202204
-----------------------------------------------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Ryan Finkas'
WHERE EmployeeEmail in (
'tate.fackrell@pnmac.com'
)
and Period = 202204

UPDATE #Final
SET NCAFlag = 'N',
	Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'katherine.smith@pnmac.com'
)
and Period = 202204

UPDATE #Final
SET NCAFlag = 'N',
	TenuredDate = '2022-04-01'
WHERE EmployeeEmail in (
'brian.stoddard@pnmac.com'
)
and Period = 202204

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'daniel.kier@pnmac.com'
)
and Period = 202204
-----------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Taylor Johnson',
	ManagerEmail = 'taylor.johnson@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'Natalia Navarro',
	SiteLead = 'Kevin Price'
where EmployeeEmail in
(
'katherine.orabuena@pnmac.com'
) and Period = 202204
-----------------------------------------------------
UPDATE #Final
SET Title = 'NCA Sales Manager',
	TitleGrouping = 'NCA Sales Manager',
	ManagerName = 'Anthony McDevitt',
	ManagerEmail = 'anthony.mcdevitt@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'matt.ellis@pnmac.com'
)
and Period = 202204
--------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Nikki Stober',
	ManagerEmail = 'nicole.stober@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Shaun Eric Wilson',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Shaun Eric Wilson'
WHERE EmployeeEmail in (
'grace.simon@pnmac.com'
)
and Period = 202204
--------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Loan Refinance',
	TitleGrouping  = 'Specialist, Loan Refinance',
	ManagerName = 'Justin Syracuse',
	ManagerEmail = 'justin.syracuse@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
 'lorraina.soto@pnmac.com'
,'rachel.bettine@pnmac.com'
) and Period = 202202
---------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
WHERE EmployeeEmail in (
'andrew.abrams@pnmac.com'
)
and Period = 202204

-----------------------------------------------------------------------
--====================================================================
--MAY 2022 Lock Goals Staffing Allocation
--====================================================================
UPDATE F --1.1

SET F.TitleGrouping = 'Account Executive',
	F.ManagerName = H.ManagerName,
	F.ManagerEmail = H.ManagerEmail,
	F.City = H.City,
	F.ManagerCity = H.City,
	F.ManagerName_TwoUp = H.SiteLead,
	F.ChannelManager = H.ChannelManager,
	F.SiteLead = H.SiteLead

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_May2022Validation H
ON F.EmployeeEmail = H.EmployeeEmail

WHERE F.Period = 202205
-----------------------------------------------------------------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202205 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202205
-----------------------------------------------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'LO, New Customer Acq',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Natalia Navarro',
	ManagerEmail = 'natalia.navarro@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Kevin Price'
WHERE EmployeeEmail in
(
'taylor.johnson@pnmac.com'
,'katherine.orabuena@pnmac.com'
--,'ihsan.moosapanah@pnmac.com'
--,'daniel.loftus@pnmac.com'

) and Period = 202205

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Edith Torosyan',
	ManagerEmail = 'edith.torosyan@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = 'Eddie Machuca',
	SiteLead = 'Adam Adoree'
where EmployeeEmail in
(
'johncarlo.menjivar@pnmac.com'
,'felix.kim@pnmac.com'
,'anthony.tabor@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
where EmployeeEmail in
(
'felix.kim@pnmac.com'
,'aaron.arce@pnmac.com'
,'anthony.tabor@pnmac.com'
,'jimmy.kim@pnmac.com'
,'katherine.smith@pnmac.com'
,'jessie.corral@pnmac.com'
,'daniel.silvey@pnmac.com'
,'sean.puckett@pnmac.com'
,'wayne.davey@pnmac.com'
,'andrew.abrams@pnmac.com'
,'christina.kelly@pnmac.com'
,'penny.mrva@pnmac.com'
,'timothy.esterly@pnmac.com'
,'chris.franklin@pnmac.com'
,'travis.lemley@pnmac.com'
,'james.bruce@pnmac.com'
,'tyler.smedley@pnmac.com'
,'richard.peck@pnmac.com'
,'brandon.ternes@pnmac.com'
,'brian.nguyen@pnmac.com'
,'henry.sorensen@pnmac.com'
,'jacob.snyder@pnmac.com'
,'kasseem.cartwright@pnmac.com'
,'kyle.sturgeon@pnmac.com'
,'matthew.gregson@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'LO, New Customer Acq',
	TitleGrouping = 'Account Executive'
where EmployeeEmail in
(
 'brock.walker@pnmac.com'
,'taylor.johnson@pnmac.com'
,'kelley.christianer@pnmac.com'
,'patricia.mendez@pnmac.com'
,'kaitey.gates@pnmac.com'
,'matt.ellis@pnmac.com'
,'juanita.moreno@pnmac.com'
,'michael.dubrow@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Evan Tuchman',
	ManagerEmail = 'evan.tuchman@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Nathan Dyce',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in (
 'aaron.hatfield@pnmac.com'
,'andree.pinson@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Jason Massie',
	ManagerEmail = 'jason.massie@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in (
 'Eddie.Machuca@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'NCA Sales Manager',
	TitleGrouping = 'NCA Sales Manager',
	ManagerName = 'Kevin Price',
	ManagerEmail = 'kevin.price@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in (
 'Natalia.Navarro@pnmac.com'
,'Ryan.Kading@pnmac.com'
,'justin.syracuse@pnmac.com'
,'chadd.grogg@pnmac.com'
,'eric.jones@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'NCA Sales Manager',
	TitleGrouping = 'NCA Sales Manager',
	ManagerName = 'Grant Mills',
	ManagerEmail = 'grant.mills@pnmac.com',
	ManagerCity = 'WestlakeLakeview',
	ManagerName_TwoUp = 'Grant Mills',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in (
 'anthony.mcdevitt@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Justin Syracuse',
	ManagerEmail = 'justin.syracuse@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Kevin Price'
where EmployeeEmail in
(
'nicholas.schmidt@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Ryan Kading',
	ManagerEmail = 'stephen.kading@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Kevin Price'
where EmployeeEmail in
(
'matt.ellis@pnmac.com'
) and Period = 202205

UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Chadd Grogg',
	ManagerEmail = 'chadd.grogg@pnmac.com',
	ManagerCity = 'Phoenix',
	ManagerName_TwoUp = 'Kevin Price',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Kevin Price'
where EmployeeEmail in
(
'rafael.sanchez@pnmac.com'
) and Period = 202205
--====================================================================
-- JUNE 2022 PLACEHOLDER
--====================================================================
--UPDATE F

--SET F.ManagerName = F2.ManagerName,
--	F.ManagerEmail = F2.ManagerEmail,
--	F.ManagerName_TwoUp = F2.ManagerName_TwoUp,
--	F.ChannelManager = F2.ChannelManager,
--	F.SiteLead = F2.SiteLead,
--	F.City = F2.City,
--	F.ManagerCity = F2.ManagerCity,
--	F.Title = F2.Title,
--	F.TitleGrouping = F2.TitleGrouping

--FROM #Final F

--inner join #Final F2
--ON F.EmployeeEmail = F2.EmployeeEmail and F2.Period = 202205 and F2.TitleGrouping in ('Account Executive', 'Loan Officer')

--WHERE F.Period = 202206
-----------------------------------------------------------------------------------
UPDATE F

SET F.ManagerName = S.[Sales Manager],
	F.ManagerEmail = S.[Manager Email],
	F.ManagerName_TwoUp = S.[Site Leader],
	F.ChannelManager = S.[Channel Manager],
	F.SiteLead = S.[Site Leader],
	F.City = S.[Site],
	F.ManagerCity = S.[Site]

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202206 S
ON F.EmployeeEmail = S.[Employee Email]

WHERE F.Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'ben.erickson@pnmac.com',
'matthew.moebius@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'jason.massie@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
where EmployeeEmail in
(
'austin.schreibman@pnmac.com',
'edith.torosyan@pnmac.com',
'brian.schooler@pnmac.com',
'joe.mckinley@pnmac.com',
'will.langhagen@pnmac.com',
'david.risse@pnmac.com',
'andrew.simmons@pnmac.com',
'gary.darden@pnmac.com',
'floyd.taylor@pnmac.com',
'nelson.massari@pnmac.com',
'peter.harris@pnmac.com',
'joshua.nelson@pnmac.com'
,'aaron.arce@pnmac.com'
,'anthony.tabor@pnmac.com'
,'felix.kim@pnmac.com'
,'jessie.corral@pnmac.com',
'chris.franklin@pnmac.com',
'christina.kelly@pnmac.com',
'james.bruce@pnmac.com',
'penny.mrva@pnmac.com',
'timothy.esterly@pnmac.com',
'travis.lemley@pnmac.com',
'nicole.stober@pnmac.com',
'katherine.smith@pnmac.com',
'tyler.smedley@pnmac.com',
'sean.puckett@pnmac.com',
'wayne.davey@pnmac.com',
'pascal.dylewicz@pnmac.com'

) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive'
where EmployeeEmail in
(
'corey.case@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Adam Adoree',
	ManagerEmail = 'adam.adoree@pnmac.com',
	ManagerCity = 'Pasadena',
	ManagerName_TwoUp = 'Adam Adoree',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
 'david.malki@pnmac.com'
,'aubray.breaux@pnmac.com'
,'benjamin.wharton@pnmac.com'
,'jimmy.yang@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'DJ Ford',
	ManagerEmail = 'dj.ford@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
 'bill.quigley@pnmac.com'
,'macy.gunderson@pnmac.com'
,'april.williams@pnmac.com'
,'morgan.duprey@pnmac.com'
,'nicole.payne@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Afton Lambert',
	ManagerEmail = 'afton.lambert@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
'garrett.bateman@pnmac.com'
,'robel.moreno@pnmac.com'
,'taylor.fiorelli@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
	TitleGrouping = 'Manager - Sales',
	ManagerName = 'Ryan Finkas',
	ManagerEmail = 'ryan.finkas@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
 'jeffries.johnson@pnmac.com'
,'marc.henry@pnmac.com'
,'michael.kreitner@pnmac.com'
,'edward.taylor@pnmac.com'
,'harjoyte.bisla@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Damon Johnson',
	ManagerEmail = 'damon.johnson@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'DJ Ford'
where EmployeeEmail in
(
 'michael.payne@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Orlando Cassara',
	ManagerEmail = 'orlando.cassara@pnmac.com',
	ManagerCity = 'Tampa',
	ManagerName_TwoUp = 'DJ Ford',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'DJ Ford'
where EmployeeEmail in
(
 'nader.snobar@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Matt Moebius',
	ManagerEmail = 'matthew.moebius@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = 'No Channel Manager',
	SiteLead = 'Ryan Finkas'
where EmployeeEmail in
(
 'reid.wright@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Dwight Dickey',
	ManagerEmail = 'dwight.dickey@pnmac.com',
	ManagerCity = 'Nashville',
	ManagerName_TwoUp = 'Tara Kinney',
	ChannelManager = 'Afton Lambert',
	SiteLead = 'Tara Kinney'
where EmployeeEmail in
(
 'rod.walker@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'VP, Retail Channel Management',
	TitleGrouping = 'Vice President',
	ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
 'adriana.gonzalez@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Carl Illum',
	ManagerEmail = 'carl.illum@pnmac.com',
	ManagerCity = 'Plano',
	ManagerName_TwoUp = 'Stephen Brandt',
	ChannelManager = NULL,
	SiteLead = NULL
where EmployeeEmail in
(
 'shante.viamontes@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
	TitleGrouping = 'Account Executive',
	ManagerName = 'Marc Henry',
	ManagerEmail = 'marc.henry@pnmac.com',
	ManagerCity = 'Roseville',
	ManagerName_TwoUp = 'Ryan Finkas',
	ChannelManager = 'Matt Moebius',
	SiteLead = 'Ryan Finkas'
WHERE EmployeeEmail in (
'tate.fackrell@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Mgr, Sales',
    TitleGrouping = 'Manager - Sales',
    ManagerName = 'Ryan Finkas',
    ManagerEmail = 'ryan.finkas@pnmac.com',
    ManagerCity = 'Roseville',
    ManagerName_TwoUp = 'Ryan Finkas',
    ChannelManager = NULL,
    SiteLead = NULL
where EmployeeEmail in
(
'harjoyte.bisla@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Marc Henry',
    ManagerEmail = 'marc.henry@pnmac.com',
    ManagerCity = 'Roseville',
    ManagerName_TwoUp = 'Ryan Finkas',
    ChannelManager = 'Matt Moebius',
    SiteLead = 'Ryan Finkas'
WHERE EmployeeEmail in (
'tate.fackrell@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Specialist, Purchase Loan',
    TitleGrouping = 'Specialist, Purchase Loan',
    ManagerName = 'Josh Baker',
    ManagerEmail = 'josh.baker@pnmac.com',
    ManagerCity = 'Pasadena',
    ManagerName_TwoUp = 'Nathan Dyce',
    ChannelManager = NULL,
    SiteLead = NULL
WHERE EmployeeEmail in (
'matthew.piccari@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Aizen Malki',
    ManagerEmail = 'david.malki@pnmac.com',
    ManagerCity = 'Pasadena',
    ManagerName_TwoUp = 'Adam Adoree',
    ChannelManager = 'No Channel Manager',
    SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'david.mkrtchyan@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Aubray Breaux',
    ManagerEmail = 'aubray.breaux@pnmac.com',
    ManagerCity = 'Pasadena',
    ManagerName_TwoUp = 'Adam Adoree',
    ChannelManager = 'No Channel Manager',
    SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'michael.ammari@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Jason Massie',
    ManagerEmail = 'jason.massie@pnmac.com',
    ManagerCity = 'Pasadena',
    ManagerName_TwoUp = 'Adam Adoree',
    ChannelManager = 'No Channel Manager',
    SiteLead = 'Adam Adoree'
WHERE EmployeeEmail in (
'terrell.jean@pnmac.com'
)
and Period = 202206
-----------------------------------------------------------------------------------------
UPDATE #Final
SET ManagerName = 'Tara Kinney',
    ManagerEmail = 'tara.kinney@pnmac.com',
    ManagerCity = 'Tennessee',
    ManagerName_TwoUp = 'Scott Bridges',
    ChannelManager = NULL,
    SiteLead = NULL
where EmployeeEmail in
(
'garrett.bateman@pnmac.com'
,'robel.moreno@pnmac.com'
,'taylor.fiorelli@pnmac.com'
) and Period = 202206
-----------------------------------------------------------------------------------------
--JULY 2022
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Richard Kennimer',
    ManagerEmail = 'richard.kennimer@pnmac.com',
    ManagerCity = 'Pasadena',
    ChannelManager = 'Evan Tuchman',
    SiteLead = 'Nathan Dyce',
    ManagerName_TwoUp = 'Nathan Dyce'
WHERE EmployeeEmail in (
'devin.wilson@pnmac.com'
) and Period = 202207
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive',
    ManagerName = 'Natalia Navarro',
    ManagerEmail = 'natalia.navarro@pnmac.com',
    ManagerCity = 'Phoenix',
    ChannelManager = 'natalia.navarro@pnmac.com',
    SiteLead = 'Kevin Price',
    ManagerName_TwoUp = 'Kevin Price'
WHERE EmployeeEmail in (
'justin.syracuse@pnmac.com'
) and Period = 202207
-----------------------------------------------------------------------------------------
UPDATE #Final
SET Title = 'Loan Officer',
    TitleGrouping = 'Account Executive'
WHERE EmployeeEmail in (
'warren.wilkins@pnmac.com'
) and Period = 202207
-----------------------------------------------------------------------------------------
--
--
--
-----------------------------------------------------------------------------------------
/*SETTING  ManagerID based on ManagerEmail*/
UPDATE F

SET F.ManagerID = S.EmployeeID


FROM #Final F

inner join #Final S--rrd.dbo.HUB_CDL_Staffing S --NOTE
ON F.ManagerEmail = S.EmployeeEmail and S.Period = CONVERT(nvarchar(6), GETDATE(), 112)
-----------------------------------------------------------------------
/*SET SALES CHANNEL MANAGER & SITE LEAD*/
UPDATE #Final

SET ChannelManager = 'No Channel Manager'

WHERE TitleGrouping in ('Account Executive', 'Loan Officer') and Period <= 202009
-----------------------------------------------------------------------
Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerEmail = 'andree.pinson@pnmac.com'
and Period >= 202205)
or (EmployeeEmail = 'andree.pinson@pnmac.com'
and Period >= 202205)

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerEmail = 'aaron.hatfield@pnmac.com'
and Period >= 202205)
or (EmployeeEmail = 'aaron.hatfield@pnmac.com'
and Period >= 202205)
-----------------------------------------------------------------------
/*SET SALES CHANNEL MANAGER & SITE LEAD*/
UPDATE #Final
SET ChannelManager = CASE
					  WHEN Period >= 202206 AND ManagerEmail IN (
					  'dwight.dickey@pnmac.com',
					  'joshua.leatherman@pnmac.com',
					  'matthew.hinckley@pnmac.com'
					 --  'Garrett Bateman',--Removed 06/21/2021
						--'Robel Moreno',--Removed 06/21/2021
						--'Taylor Fiorelli'--Removed 06/21/2021
					   ) THEN 'Afton Lambert'
					   WHEN Period >= 202206 AND ManagerEmail in (
						'aaron.hatfield@pnmac.com',
						'andree.pinson@pnmac.com',
						'anthony.trozera@pnmac.com',
						'dominic.cifarelli@pnmac.com',
						'john.anding@pnmac.com',
						'jonathan.ryan@pnmac.com',
						'josh.baker@pnmac.com',
						'pia.collins@pnmac.com',
						'richard.kennimer@pnmac.com',
						'ruben.sanchez@pnmac.com',
						'todd.bugbee@pnmac.com'
						) THEN 'Evan Tuchman'
						WHEN Period >= 202206
						THEN 'No Channel Manager'
				      WHEN Period >= 202205 AND ManagerName IN (
					   'Josh Nelson'
					   ) THEN 'Eric Busalacchi'
					  WHEN Period >= 202205 AND ManagerName IN (
					   'Nelson Massari'
					   ) THEN 'Orlando Cassara'
					  WHEN Period >= 202205 AND ManagerName IN (
					   'Floyd Taylor' ,'Macy Gunderson'
					   ) THEN 'Damon Johnson'
					   WHEN Period >= 202205 AND ManagerName IN (
					   'Jay Bisla'
					   ) THEN 'Ben Erickson'
					   WHEN Period >= 202205 and ManagerName in (
					    'Aaron Hatfield', --1.1
						'Andree Pinson' --1.1
						) THEN 'Evan Tuchman'
					   WHEN Period >= 202205 and ManagerName in (
					    'Dwight Dickey', --1.1
						'Joshua Leatherman', --1.1
						'Matthew Hinckley', --1.1
						'Peter Harris' --1.1
						) THEN 'Afton Lambert'
					  WHEN Period >= 202205 and ManagerName in (
					  'Chadd Grogg', --1.1
						'Eric Jones', --1.1
						'Justin Syracuse', --1.1
						'Anthony McDevitt', --1.1
						'Natalia Navarro', --1.1
						'Ryan Kading' --1.1
					  ) THEN 'No Channel Manager'
					  WHEN Period >= 202205 and ManagerName in (
					  'Benjamin Wharton', --1.1
						'Edith Torosyan', --1.1
						'Eddie Machuca' --1.1
					)THEN 'Jason Massie'
					 --  WHEN Period >= 202205 and ManagerName in (
						--'Aaron Arce', --1.1
						--'Anthony Tabor', --1.1
						--'Felix Kim', --1.1
						--'Chris Franklin', --1.1
						--'Penny Mrva', --1.1
						--'Taylor Silvey', --1.1
						--'Christina Kelly', --1.1
						--'James Bruce', --1.1
						--'Timothy Esterly', --1.1
						--'Travis John Lemley', --1.1
						--'Brock Walker', --1.1
						--'Kelley Christianer', --1.1
						--'Matt Ellis', --1.1
						--'Michael Dubrow', --1.1
						--'Taylor Johnson', --1.1
						--'Juanita Moreno', --1.1
						--'Kaitey Gates', --1.1
						--'Patricia Mendez', --1.1
						--'Jimmy Kim', --1.1
						--'Richard Peck', --1.1
						--'Andrew Abrams', --1.1
						--'Sean Puckett', --1.1
						--'Katherine Smith', --1.1
						--'Tyler Smedley', --1.1
						--'Jessie Corral', --1.1
						--'Wayne Davey' --1.1
					 --  ) THEN 'No Channel Manager'
					   WHEN Period = 202204 and ManagerName in (
						'Nelson Massari'
						) THEN 'Adriana Gonzalez'
					   WHEN Period >= 202204
					   and ManagerName in (
						'Andrew Abrams'
						) THEN 'Damon Johnson'
						WHEN Period >=202204 and ManagerName in (
						'Matt Ellis'
						) THEN 'Anthony McDevitt'
						WHEN Period >= 202204 and ManagerName in (
							'Katherine Smith'
							)
							THEN 'Matt Moebius'
						WHEN Period >= 202203 and ManagerName in (
							'Taylor Johnson'
							)
							THEN 'Natalia Navarro'
						WHEN Period >= 202203 and ManagerName in (
							'Kaitey Gates'
							)
							THEN 'Ryan Kading'
						WHEN Period >= 202202 and ManagerName in (
							'Richard Kennimer'
							)
							THEN 'Evan Tuchman'
						WHEN Period >= 202201 and ManagerName in (
						'Patricia Mendez'
						,'Juanita Moreno'
						,'Eric Jones'
						,'Taylor Johnson'
						) THEN 'Ryan Kading'
						WHEN Period >= 202201 and ManagerName in (
						'Aaron Arce'
						,'Anthony Tabor'
						,'Benjamin Wharton'
						,'Edith Torosyan'
						,'Felix Kim'

						) THEN 'Eddie Machuca'
						WHEN Period >= 202201 and ManagerName in (
						'Richard Peck'
						,'Sydney Barnes'
						) THEN 'Ben Erickson'
						WHEN Period >= 202201 and ManagerName in (
						'Edward Taylor'
						,'David Risse'
						,'Joe McKinley'
						) THEN 'Matt Moebius'
						WHEN Period >= 202111 and ManagerName in (
						'Garrett Bateman'
						,'Melissa Barone'
						,'Robel Moreno'
						,'Taylor Fiorelli'
						,'Corey Marcelin'
						,'Jacobie Fullerton'
						) THEN 'Eric Busalacchi'
						WHEN Period between 202111 and 202203 and ManagerName in (
						'Matt Ellis'
						) THEN 'Eric Busalacchi'
						WHEN Period >= 202111 and ManagerName in (
						'Brandon Reish'
						,'Chadd Grogg'
						,'Eric Jones'
						,'Kaitey Gates'
						,'Patricia Mendez'
						,'Justin Syracuse'
						) THEN 'Natalia Navarro' --Frank Frayer's team goes under Natalia (Frank resigned)
						WHEN Period between 202111 and 202203 and ManagerName in (
						'Nelson Massari'
						) THEN 'Orlando Cassara'
						--WHEN Period >= 202110 and ManagerName in (
						--'Melissa Barone'
						--) THEN 'No Channel Manager'
						WHEN Period >= 202110 and ManagerName in (
						'Garrett Bateman' --ADDED FOR 202101
						) THEN 'No Channel Manager'
						WHEN Period >= 202110 and ManagerName in (
						'Taylor Fiorelli', --Already listed
						'April Williams', --ADDED 202110
						'Nicole Payne', --Already listed; already below for 202110
						'Thomas Zinschlag',--Already listed
						'Morgan Duprey' --ADDED 202110; already below for 202110
						) THEN 'Orlando Cassara'
						WHEN Period = 202110 and ManagerName in (
						'Floyd Taylor' --ADDED 202110
						) THEN 'Adriana Gonzalez'
					   WHEN Period > 202110 and ManagerName in (
						'Macy Gunderson' --Already listed
						) THEN 'Adriana Gonzalez'
						WHEN Period >= 202110 and ManagerName in (
						'Taylor Silvey', --ADDED 202110
						'Macy Gunderson', --Already listed
						'Meridith Lavallee' --Already listed
						) THEN 'Adriana Gonzalez'
						WHEN Period between 202110 and 202203 and ManagerName in (
						'Andrew Abrams'
						) THEN 'Adriana Gonzalez'
						WHEN Period >= 202110 and ManagerName in (
						'Ryan Kading' --ADDED 202110
						) THEN 'Natalia Navarro'
						WHEN Period >= 202110 and ManagerName in (
						'Edith Torosyan', --ADDED 202110
						'Jimmy Yang', --ADDED 202110; listed below
						'Michiko Solon', --ADDED 202110
						'Aizen Malki', --ADDED 202110
						'Aaron Arce', --ADDED 202110
						'Benjamin Wharton' --ADDED 202110
						) THEN 'Jason Massie'
						--WHEN Period < 202110 and ManagerName in (
						--'Melissa Barone'
						--) THEN 'Jason Massie' --NOT SURE THIS IS ACCURATE
						--WHEN Period >= 202110 and ManagerName in (
						--	'Benjamin Wharton'
						--	) THEN 'Jason Massie' --INCLUDED ABOVE

						WHEN Period >= 202110 and ManagerName in (
							'Robel Moreno'
						) THEN 'No Channel Manager'
						WHEN Period >= 202110 and ManagerName in (
							'Jimmy Kim' --Already above
						) THEN 'Jason Massie'
						WHEN Period >= 202110 and ManagerName in (
							'Bill Quigley'
						) THEN 'Damon Johnson'
						WHEN Period >= 202110 and ManagerName in (
							'Nicole Payne', --Already above
							'Morgan Duprey' --ADDED 202110; already above
						) THEN 'Orlando Cassara'
						--WHEN Period >= 202110 and ManagerName in (
						--	'Nicole Payne'
						--) THEN 'Orlando Cassara' --REPEAT
						WHEN Period >= 202110 and ManagerName in (
							'Michael Kreitner'
						) THEN 'Matt Moebius'
						--WHEN Period >= 202110 and EmployeeName in (
						--	'Aubray Breaux',
						--	'Arin Baghermian',
						--	'Aizen Malki',
						--	'Eddie Machuca'
						--) THEN 'Adam Adoree'

						WHEN Period >= 202109 and ManagerName in (
							'Sean Puckett',
							'Damon Johnson'
						) THEN 'Damon Johnson'
						WHEN Period >= 202109 and ManagerName in (
							'Taylor Silvey'
						) THEN 'Orlando Cassara'
						WHEN Period >= 202109 and ManagerName in (
							'Michael Stephan'
						) THEN 'Aaron Hatfield'
						WHEN Period >= 202109 and ManagerName in (
							'Benjamin Wharton'
							) THEN 'Adam Adoree'
						WHEN Period >= 202108 and ManagerName in (
							'Gary Darden'
							) THEN 'Ben Erickson'
						WHEN Period >= 202107 and ManagerName in (
							'April Williams'
							) THEN 'Adriana Gonzalez'
						WHEN Period between 202107 and 202109 and ManagerName in (
							'Brian Butler'
							) THEN 'Orlando Cassara'
						WHEN Period >= 202107 and ManagerName in (
							'Travis John Lemley'--New SM
							) THEN 'Andree Pinson'
						WHEN Period >= 202107 and ManagerName in (
							'Nicole Payne'
							) THEN 'Orlando Cassara'
						WHEN Period >= 202107 and ManagerName in (
							'Brandon Reish'
							) THEN 'Frank Frayer'
						WHEN Period >= 202107 and ManagerName in (
							'Eric Busalacchi',--Transferred to Nashvile Site
							'Ryan Kading',--New SM
							'Matt Ellis'--New SM
							) THEN 'No Channel Manager'
						WHEN Period >= 202106 and ManagerName in (
							'Daniel Kier'
							) THEN 'Anthony McDevitt'
						WHEN Period >= 202106 and ManagerName in (
							'Olive Njombua'
							) THEN 'No Channel Manager'
						WHEN Period >= 202106 and ManagerName = 'Nicholas Gilliam'
							THEN 'Damon Johnson'
						WHEN Period >= 202106 and ManagerName in (
							'Pia Collins',
							'Dominic Cifarelli',
							'Josh Baker'
							)
							THEN 'Evan Tuchman'
						WHEN Period >= 202106 and ManagerName in (
							'Christina Kelly',
							'Joshua Leatherman',
							'Richard Kennimer',
							'Timothy Esterly',
							'James Bruce',
							'Travis John Lemley'
							)
							THEN 'Andree Pinson'
						WHEN Period = 202105 and ManagerName = 'Damon Johnson'
							THEN 'Damon Johnson'
						WHEN Period >= 202105 and (EmployeeEmail in (
							'jazlyn.briant@pnmac.com',
							'jenny.twaddle@pnmac.com',
							'madison.brown@pnmac.com',
							'sara.aguayo@pnmac.com'
							)
							or ManagerName = 'Evan Tuchman') THEN 'Evan Tuchman'
						WHEN Period >= 202105 and ManagerName in (
							'Melissa Barone'
							) THEN 'No Channel Manager'
						WHEN Period >= 202105 and ManagerName in (
							'Jeffries Johnson',
							'Julia Shupe',
							'Ed Vandervelde',
							'Will Langhagen',
							'Andrew Simmons'
							) THEN 'Ben Erickson'
						WHEN Period >= 202104 and ManagerName in (
							'Sydney Barnes',
							'Will Langhagen',
							'Richard Peck'
							) THEN 'Ryan Finkas'
						WHEN Period >= 202104 and ManagerName in (
							'Taylor Fiorelli'
							) THEN 'Orlando Cassara'
						WHEN Period between 202104 and 202106 and ManagerName in (
							'April Williams'
							) THEN 'Orlando Cassara'
						WHEN Period >= 202104 and ManagerName in (
							'Taylor Johnson'
							) THEN 'Natalia Navarro'
						WHEN Period >= 202104 and ManagerName in (
							'Chadd Grogg',
							'Daniel Postak',
							'Eric Jones',
							'Kaitey Gates',
							'Patricia Mendez'
							) THEN 'Frank Frayer'
						WHEN Period >= 202104 and ManagerName in (
							'Anthony Trozera',
							'Pia Collins',
							'Dominic Cifarelli'
							) THEN 'Evan Tuchman'
						WHEN Period >= 202104 and ManagerName in (
							'Brandis Rembert',
							'Eddie Bailey',
							'Jane Riley',
							'Tiffany Lewis'
							) THEN 'Damon Johnson'
						WHEN Period >= 202104 and ManagerName in (
							'Kelley Christianer',
							'Michael Dubrow'
							) THEN 'Anthony McDevitt'
						WHEN Period >= 202104 and ManagerName in (
							'Andrew Abrams',
							'Meridith Lavallee'
							) THEN 'Adriana Gonzalez'
						WHEN Period between 202104 and 202203 and ManagerName in (
							'Andrew Abrams'
							) THEN 'Adriana Gonzalez'
						WHEN Period between 202104 and 202106 and ManagerName in (
							'Brian Butler'
							) THEN 'Adriana Gonzalez'
						WHEN Period >= 202101 and ManagerName in (
							'Damon Johnson',
							'Jane Riley',
							'Eddie Bailey',
							'Brandis Rembert',
							'Macy Gunderson'
							) THEN 'Adriana Gonzalez'
						WHEN Period >= 202101 and ManagerName in (
							'Penny Mrva',
							'Peter Harris',
							'Chris Franklin',
							'Dwight Dickey'
							) THEN 'Aaron Hatfield'
						WHEN Period >= 202101 and ManagerName in (
							'Chadd Grogg',
							'Eric Jones',
							'Ryan Wilson',
							'Steven Garcia',
							'Patricia Mendez',
							'Juanita Moreno',
							'Daniel Postak',
							'Katherine Orabuena'
							) THEN 'Natalia Navarro'
						WHEN ManagerName in (
							'Edith Torosyan',
							'Jimmy Yang',
							'Melissa Barone',
							'Michiko Solon',
							'Aizen Malki', --ADDED FOR 202101
							'Aaron Arce' --ADDED 202105
							) THEN 'Adam Adoree'
						WHEN ManagerName in (
							'Brock Walker',
							'Frank Frayer',
							'Katherine Smith'
							) THEN 'Anthony McDevitt'
						WHEN ManagerName in (
							'Allen Brunner',
							'John Anding',
							'Jonathan Ryan',
							'Ruben Sanchez',
							'Todd Bugbee'
							) THEN 'Evan Tuchman'
						WHEN ManagerName in (
							'Anthony Tabor',
							'Aubray Breaux',
							'Austin Schreibman',
							'David Erlich',
							'Eddie Machuca' --ADDED FOR 202101
							) THEN 'Jason Massie'
						WHEN ManagerName in (
							'Ben Erickson',
							'Madison Salter',
							'Marc Henry',
							'Reid Wright',
							'Sydney Barnes',
							'Tyler Smedley',
							'Tate Fackrell' --ADDED FOR 202101
							) THEN 'Matt Moebius'
						WHEN Period <= 202204 AND ManagerName in (
							'Jay Bisla' --May 2022 LG
							) THEN 'No Channel Manager'
						WHEN Period < 202205 and ManagerName in (
							'Josh Nelson'
							) THEN 'No Channel Manager'
						WHEN ManagerName in (
							'Adriana Gonzalez',
							'Afton Lambert',
							'Emma Mullen',
							--'Jay Bisla', May 2022 LG
							'Damon Johnson',
							'Eddie Bailey',
							'Chadd Grogg',
							'Natalia Navarro',
							'Steven Garcia',
							'Aaron Hatfield',
							'Dwight Dickey',
							'Penny Mrva',
							'Peter Harris',
							'Eric Jones' --December 2020
							) THEN 'No Channel Manager'
						WHEN Period between 202101 and 202204 and ManagerName IN(
							'Floyd Taylor' --ADDED FOR 202101
							--'Brian Butler' --ADDED FOR 202101
							) THEN 'Orlando Cassara'
					    WHEN Period < 202205 and ManagerName in (
							'Macy Gunderson'
							) THEN 'Orlando Cassara'
						WHEN ManagerName in (
							--'Clinton Harris',
							'Eric Busalacchi',
							'Thomas Zinschlag',
							'Tiffany Lewis',
							'Jane Riley' --December 2020
							--'Brian Butler' --ADDED FOR 202101
							) THEN 'Orlando Cassara'
						WHEN Period < 202110 and ManagerName in (
							'Clinton Harris',
							'Brian Butler' --ADDED FOR 202101
							) THEN 'Orlando Cassara'
						WHEN ManagerName in (
							'Andree Pinson',
							'Christina Kelly',
							'Joshua Leatherman',
							'Richard Kennimer',
							'Timothy Esterly'
							) THEN 'Patrick Quinlan'
						WHEN ManagerName in (
							'David Risse',
							'Diego Cabello Alvarado',
							'Edward Taylor',
							'Jeffries Johnson',
							'Joe McKinley'
							) THEN 'Ryan Finkas'
						WHEN ManagerName in (
							'Matthew Hinckley' --ADDED FOR 202101
							) THEN 'Aaron Hatfield'
						WHEN ManagerName in (
							'Garrett Bateman' --ADDED FOR 202101
							) THEN 'Natalia Navarro'
						ELSE NULL
					END
WHERE TitleGrouping in ('Account Executive', 'Loan Officer') and Period >= 202011--*

UPDATE #Final
SET ChannelManager = CASE
						WHEN Period in (202101,202102) and EmployeeName in (
							'Aizen Malki'
							) THEN 'Adam Adoree'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Arin Baghermian'
							) THEN 'Evan Tuchman'
						WHEN Period in (202012) and EmployeeName in (
							'Aubray Breaux'
							) THEN 'No Channel Manager'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Brandis Rembert'
							) THEN 'Orlando Cassara'
						WHEN Period in (202012) and EmployeeName in (
							'Brian Butler'
							) THEN 'Orlando Cassara'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Cynthia Rivera'
							) THEN 'Orlando Cassara'
						WHEN Period in (202102) and EmployeeName in (
							'Daniel Postak'
							) THEN 'Natalia Navarro'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Eddie Machuca'
							) THEN 'Jason Massie'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Floyd Taylor'
							) THEN 'No Channel Manager'
						WHEN Period in (202101) and EmployeeName in (
							'Garrett Bateman'
							) THEN 'No Channel Manager'
						WHEN Period in (202012) and EmployeeName in (
							'Jeremiah Kneeland'
							) THEN 'Anthony McDevitt'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Krystle Pierre'
							) THEN 'No Channel Manager'
						WHEN Period in (202101) and EmployeeName in (
							'Matthew Hinckley'
							) THEN 'Patrick Quinlan'
						WHEN Period in (202012) and EmployeeName in (
							'Morgan Bui'
							) THEN 'Evan Tuchman'
						WHEN Period in (202102) and EmployeeName in (
							'Patricia Mendez'
							) THEN 'Natalia Navarro'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Ryan Wilson'
							) THEN 'No Channel Manager'
						WHEN Period in (202012,202101,202102) and EmployeeName in (
							'Shante Viamontes'
							) THEN 'Matt Moebius'
						WHEN Period in (202012) and EmployeeName in (
							'Sydney Barnes'
							) THEN 'No Channel Manager'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Tate Fackrell'
							) THEN 'Matt Moebius'
							ELSE ChannelManager
					END
----------
UPDATE #Final

SET ChannelManager = 'No Channel Manager'

WHERE TitleGrouping in ('Account Executive', 'Loan Officer') and Period >= 202010--*
and ChannelManager is null
----------
UPDATE #Final
SET ChannelManager = 'No Channel Manager'
WHERE ChannelManager like 'No Channel Manager%'
----------
UPDATE F

SET F.SiteLead = CASE
					WHEN F.ManagerName_TwoUp in ('DJ Ford', 'Grant Mills', 'Kevin Price', 'Nathan Dyce', 'Carl Illum', 'Olive Njombua', 'Rich Ferre', 'Shaun Eric Wilson', 'Stephen Brandt', 'Tara Kinney', 'Adam Adoree','Ryan Finkas') THEN F.ManagerName_TwoUp
					WHEN E.ManagerName_ThreeUp in ('DJ Ford', 'Grant Mills', 'Kevin Price', 'Nathan Dyce', 'Carl Illum', 'Olive Njombua', 'Rich Ferre', 'Shaun Eric Wilson', 'Stephen Brandt','Tara Kinney', 'Adam Adoree','Ryan Finkas') THEN E.ManagerName_ThreeUp
					ELSE NULL
				END
FROM #Final F

left join #EmpTemp E
ON E.EmployeeId = F.EmployeeId and E.Period = F.Period

WHERE F.TitleGrouping in ('Account Executive', 'Loan Officer')
----------
UPDATE #Final
SET SiteLead = CASE
					WHEN City = 'Plano' and Period >= 202205 THEN 'Tara Kinney' --1.0
					WHEN City = 'Nashville' and Period >= 202105 THEN 'Tara Kinney'
					WHEN City = 'Plano' and Period >= 202008 THEN 'Olive Njombua'
					WHEN City = 'Plano' THEN 'Carl Illum'
					WHEN City = 'Tampa' THEN 'DJ Ford'
					WHEN Period >= 202205 and City = 'WestlakeLakeview' THEN 'Kevin Price'
					WHEN City = 'WestlakeLakeview' THEN 'Grant Mills'
					WHEN City = 'Phoenix' THEN 'Kevin Price'
					WHEN Period >= 202110 and City in ('Pasadena', 'Moorpark') and PurchaseFlag = 'N' and NCAFlag = 'N' THEN 'Adam Adoree'
					WHEN City in ('Pasadena', 'Moorpark') THEN 'Nathan Dyce'
					WHEN City in ('Summerlin', 'Honolulu', 'Roseville') AND Period <= 202112 THEN 'Rich Ferre'
					WHEN City in ('Summerlin', 'Roseville') AND Period > 202112 THEN 'Ryan Finkas'
					ELSE NULL
				END
WHERE
TitleGrouping in ('Account Executive', 'Loan Officer')
and (TerminationDate is null or TerminationDate >= '1/1/2020')
and SiteLead is null
----------
UPDATE #Final --PFG NEEDS UPDATES FOR COMP PURPOSES ON PEOPLE WHO ARE NO LONGER LOAN OFFICERS
SET SiteLead = CASE
						WHEN Period in (202012) and EmployeeName in (
							'Aubray Breaux'
							) THEN 'Nathan Dyce'
						--WHEN Period in (202012) and EmployeeName in (
						--	'Melissa Franklin'
						--	) THEN 'Olive Njombua'
						WHEN Period in (202012) and EmployeeName in (
							'Jeremiah Kneeland',
							'Morgan Bui'
							) THEN 'Kevin Price'
						WHEN Period in (202012) and EmployeeName in (
							'Brian Butler'
							) THEN 'DJ Ford'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Krystle Pierre'
							) THEN 'Kevin Price'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Arin Baghermian'
							) THEN 'Nathan Dyce'
						WHEN Period in (202012,202101) and EmployeeName in (
							'Brandis Rembert'
							) THEN 'DJ Ford'
						WHEN Period in (202012) and EmployeeName in (
							'Sydney Barnes'
							) THEN 'Rich Ferre'
						WHEN Period in (202101) and EmployeeName in (
							'Garrett Bateman'
							) THEN 'Kevin Price'
						WHEN Period in (202101) and EmployeeName in (
							'Matthew Hinckley'
							) THEN 'Olive Njombua'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Ryan Wilson'
							) THEN 'Kevin Price'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Floyd Taylor'
							) THEN 'DJ Ford'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Tate Fackrell'
							) THEN 'Rich Ferre'
						WHEN Period in (202101,202102) and EmployeeName in (
							'Aizen Malki',
							'Eddie Machuca'
							) THEN 'Nathan Dyce'
						WHEN Period in (202102) and EmployeeName in (
							'Cynthia Rivera'
							) THEN 'DJ Ford'
						WHEN Period in (202102) and EmployeeName in (
							'Daniel Postak',
							'Patricia Mendez'
							) THEN 'Kevin Price'
						WHEN Period in (202012, 202101, 202102) and EmployeeName in (
							'Shante Viamontes'
							) THEN 'Rich Ferre'
						ELSE SiteLead
					END
----------
UPDATE #Final
SET ManagerName_TwoUp = SiteLead
WHERE
TitleGrouping in ('Account Executive', 'Loan Officer') and Period >= 202011
-----------------------------------------------------------------------
UPDATE #Final
SET ManagerName_TwoUp = 'Kevin Price',
	SiteLead = 'Kevin Price'
WHERE
TitleGrouping in ('Account Executive', 'Loan Officer')
and Period >= 202011
and SiteLead = 'Grant Mills'
and ManagerName in ('Eric Jones', 'Steven Garcia')
-----------------------------------------------------------------------
UPDATE #Final --All NCA is reporting to Kevin Price as of May 2022
SET ManagerName_TwoUp = 'Kevin Price',
	SiteLead = 'Kevin Price'
WHERE
Period >= 202205
and SiteLead = 'Grant Mills'
and ManagerName_TwoUp = 'Grant Mills'
-----------------------------------------------------------------------
UPDATE #Final
SET CostCenter = '1201-300-93200',
	Department = 'CDL New Cust Acquisition',
	DepartmentId = 93200
WHERE EmployeeEmail = 'michael.flowers@pnmac.com'
and Period in (202108, 202109)
-----------------------------------------------------------------------
UPDATE #Final
SET NCAFlag = 'Y'
WHERE
(Period between 202009 and 202203 and ManagerName in (
						'Katherine Smith')
)
or (Period between 202009 and 202203 and EmployeeName in (
						'Katherine Smith')
)
or
(Period >= 202009 and ManagerName in (
						'Chadd Grogg',
						'Frank Frayer',
						'Natalia Navarro')
)
or (Period >= 202009 and EmployeeName in (
						'Chadd Grogg',
						'Frank Frayer',
						'Natalia Navarro')
)
or (Period >= 202009 and ManagerName in (
						'Ryan Wilson')
)
or (Period >= 202009 and EmployeeName in (
						'Ryan Wilson')
)
or (Period >= 202105 and ManagerName in (
						'Melissa Barone')
)
or (Period >= 202105 and EmployeeName in (
						'Melissa Barone')
)
or (Period >= 202107 and ManagerName in (
						'Eric Busalacchi')
)
or (Period >= 202107 and EmployeeName in (
						'Eric Busalacchi')
)
or CostCenter = '1201-300-93200'
or Title like 'LO, New Customer Acq%'
or (NCAFlag = 'N' and EmployeeName in (
					'Matthew Bland',
					'Wesley Topham',
					'Thomas Wahl',--'Tommy Wahl',
					'RyLee Gorham',
					'Rachel Bettine',
					'Jeffrey Halsey',
					'Gabrielle Tamala')
)

Update #Final
Set NCAFlag = 'Y'
Where
ManagerName = 'Katherine Orabuena'
and Period between 202102 and 202204
or EmployeeName = 'Katherine Orabuena'
and Period >= 202102

UPDATE #Final
SET NCAFlag = 'N'
WHERE
EmployeeEmail in (
'tobias.blanchard@pnmac.com',
'joseph.wagner@pnmac.com',
'ryan.cohen@pnmac.com')
and Period = 202106

UPDATE #Final
SET NCAFlag = 'N'
WHERE EmployeeName = 'Preston Orellana'
and EmployeeEmail in
	(
	'preston.orellana@pnmac.com'
	)
and Period in (202105, 202106, 202107)

UPDATE #Final
SET NCAFlag = 'N'
WHERE EmployeeName = 'Cynthia Perez'
and EmployeeEmail in
	(
	'cynthia.perez@pnmac.com'
	)
and Period >= 202107

UPDATE #Final
SET CostCenter = '1201-300-93200',
	Department = 'CDL New Cust Acquisition',
	DepartmentId = 93200
WHERE EmployeeEmail = 'michael.flowers@pnmac.com'
and Period in (202108, 202109)

UPDATE #Final
SET NCAFlag = 'N',
	CostCenter = '1201-300-93100',
	DepartmentId = 93100
WHERE EmployeeEmail = 'adejumoke.dosunmu@pnmac.com'
and Period = 202205

UPDATE #Final
SET CostCenter = '1201-300-93200'
WHERE NCAFlag = 'Y' and TitleGrouping = 'Account Executive' and EmployeeEmail = 'eric.farnell@pnmac.com' and CostCenter <> '1201-300-93200' and Period in (202109,202110) --Reported to Sales in Oct.

/*SPECIAL PROJECTS FLAG*/
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE TitleGrouping in ('Account Executive', 'Loan Officer') and EmployeeName in (
'David Hernandez'
)
and Period between 202102 and 202104
-----------------------
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE TitleGrouping in ('Account Executive', 'Loan Officer') and EmployeeName in (
'Shannon Vaughn',
'Tramell Nash',
'Barry Clay II',
'Rodney Perkins'
)
and Period between 202009 and 202205
-----------------------
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE TitleGrouping in ('Account Executive', 'Loan Officer')
and Title in ('LO, Special Projects', 'Special Projects Loan Officer', ' Special Projects Loan Officer')
and Period between 202012 and 202205
-----------------------
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE ManagerName = 'Ben Erickson' and EmployeeName = 'Jason Thomas' and Period between 202104 and 202205
-----------------------
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE ManagerName in ('Ed Vandervelde' , 'Andrew Simmons') and Period between 202005 and 202205
-----------------------
UPDATE #Final
SET ManagerName = 'Ben Erickson - SP'
WHERE ManagerName = 'Ben Erickson' and SpecialProjectsFlag = 'Y' and Period <= 202205
-----------------------
UPDATE #Final
SET SpecialProjectsFlag = 'Y'
WHERE (ManagerName = 'Gary Darden' OR EmployeeName = 'Gary Darden') and Period between 202108 and 202205
-----------------------

UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE ManagerEmail in (
'richard.kennimer@pnmac.com'
) and Period >= 202202
-----------------------
--=====Added 6/3/2016 to identify AEs working purchase teams, for reporting purposes
UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE ManagerName = 'Josh Baker'
and Period >= 202106
or EmployeeName = 'Josh Baker'
and Period >= 202106

UPDATE #Final
SET PurchaseFlag = 'Y'
WHERE ManagerName = 'Anthony Trozera'
and Period >= 202104
or EmployeeName = 'Anthony Trozera'
and Period >= 202104

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Arin Baghermian'
and Period >= 202103
or EmployeeName = 'Arin Baghermian'
and Period >= 202103

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Jonathan Ryan'
and Period >= 202008
or EmployeeName = 'Jonathan Ryan'
and Period >= 202008

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Ruben Sanchez'
and Period >= 202006
or EmployeeName = 'Ruben Sanchez'
and Period >= 202006

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerName in (
'John Anding')
or
EmployeeName = 'John Anding')
and Period >= 202002

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName in (
'Todd Bugbee')
or
EmployeeName = 'Todd Bugbee'

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Kevin Price'
and Period between 201710 and 202005
or EmployeeName = 'Kevin Price'
and Period between 201710 and 202005


Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Allen Brunner'
and Period >= 201712
or EmployeeName = 'Allen Brunner'
and Period >= 201712

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Evan Tuchman'
and Period >= 201803
or EmployeeName = 'Evan Tuchman'
and Period >=201803

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Benjamin Williams'
and Period >= 201806
or EmployeeName = 'Benjamin Williams'
and Period >= 201806 and Period < 201909

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerName = 'Pia Collins'
and Period >= 202105)
or (EmployeeName = 'Pia Collins'
and Period >= 202105)

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerName = 'Dominic Cifarelli'
and Period >= 202105)
or (EmployeeName = 'Dominic Cifarelli'
and Period >= 202105)

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerName = 'andree.pinson@pnmac.com'
and Period >= 202205)
or (EmployeeName = 'andree.pinson@pnmac.com'
and Period >= 202205)

Update #Final
Set PurchaseFlag = 'Y'
Where
(ManagerEmail = 'aaron.hatfield@pnmac.com'
and Period >= 202205)
or (EmployeeEmail = 'aaron.hatfield@pnmac.com'
and Period >= 202205)

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName = 'Nathan Dyce'
and Period < 201712


--'Francis Garcia', --- eff 8/29/16, commented out 8/30/16 ae
--'Clayton Spruce')  ---- ae added 08/23/2016  code below

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName in ('Jason Pliska')
and Period <= 201602


---Per Rich Clayton's team refi as of Oct
Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName in ('Clayton Spruce')
and Period between  201604 and 201609

Update #Final
Set PurchaseFlag = 'Y'
Where
ManagerName in ('Francis Garcia')
and Period between 201508 and 201608
and TitleGrouping in ('Account Executive', 'Loan Officer')

Update #Final
Set PurchaseFlag = 'N'
Where PurchaseFlag Is Null

UPDATE #Final
SET SiteLead = 'Adam Adoree', ManagerName_TwoUp = 'Adam Adoree'
WHERE (SiteLead = 'Nathan Dyce' or ManagerName_TwoUp = 'Nathan Dyce')
and Period >= 202110
and TitleGrouping = 'Account Executive'
and PurchaseFlag = 'N'
and NCAFlag = 'N'

UPDATE #Final --Miras 05/03/2022
SET PurchaseFlag = 'Y',
	SiteLead = 'Nathan Dyce',
	ManagerName_TwoUp = 'Nathan Dyce'
WHERE ChannelManager = 'Evan Tuchman'
and Period = 202205
and TitleGrouping = 'Account Executive'



UPDATE #Final
SET PurchaseFlag = 'Y', NCAFlag = 'Y'
WHERE Period between 202203 and 202205 and (EmployeeEmail in ( --NEEDS TO CONTINUE TO BE >=
'natalia.navarro@pnmac.com',
'taylor.johnson@pnmac.com',
'devin.wilson@pnmac.com',
'fidencio.velazquez@pnmac.com',
'giovanni.fernandez@pnmac.com ',
'jeremy.white1@pnmac.com',
'juan.tobar@pnmac.com',
'matthew.bland@pnmac.com',
'paul.ruliffson@pnmac.com',
'andrew.pena@pnmac.com',
'susan.flores@pnmac.com',
'isaac.trujillo@pnmac.com')
OR
ManagerName = 'Taylor Johnson')

UPDATE #Final
SET NCAFlag = 'N',
	PurchaseFlag = 'N'
WHERE Period = 202204
	AND (ManagerName IN (
	'Eric Busalacchi'
	,'Tara Kinney'
	,'Aubray Breaux'
	) OR EmployeeName IN (
	'eric.busalacchi@pnmac.com'
	,'tara.kinney@pnmac.com'
	) OR ChannelManager IN (
	'Eric Busalacchi'
	) OR SiteLead IN (
	'Tara Kinney'
	))

--UPDATE #Final
--SET PurchaseFlag = 'Y', NCAFlag = 'Y'
--WHERE Period between 202205 and 202206
--and EmployeeEmail in ( --NEEDS TO CONTINUE TO BE >=
--'katherine.orabuena@pnmac.com')

--Update #Final
--Set PurchaseFlag = 'Y', NCAFlag = 'Y'
--Where
--(ManagerEmail = 'natalia.navarro@pnmac.com'
--and Period = 202206)
--or (EmployeeEmail = 'natalia.navarro@pnmac.com'
--and Period = 202206)

--Update #Final
--Set PurchaseFlag = 'Y', NCAFlag = 'Y'
--Where
--(ManagerEmail in ('ryan.kading@pnmac.com', 'stephen.kading@pnmac.com')--
--and Period = 202206)
--or (EmployeeEmail in ('ryan.kading@pnmac.com', 'stephen.kading@pnmac.com')
--and Period = 202206)

UPDATE #Final
SET PurchaseFlag = 'Y', NCAFlag = 'Y'
WHERE Period = 202205
and EmployeeEmail in ( --NEEDS TO CONTINUE TO BE >=
'katherine.orabuena@pnmac.com')


--
UPDATE #Final
SET NCAFlag = 'N'
WHERE NCAFlag = 'Y' and EmploymentStatus = 'Active' and City = 'Nashville'
and Period >= 202206



--UPDATE #Final
--SET SiteLead = 'Ryan Finkas', ManagerName_TwoUp = 'Ryan Finkas'
--WHERE (SiteLead = 'Rich Ferre' or ManagerName_TwoUp = 'Rich Ferre')
--and Period >= 202112
--and TitleGrouping = 'Account Executive'
--and PurchaseFlag = 'N'
--and NCAFlag = 'N'

--=====Added 11/22/2017 to identify processors working SLP teams, for reporting purposes
Update #Final
Set SLPTeamFlag = 'Y'
Where
employeename in ('Anastashia Smith','Jazmin Ruiz','Jessica Espino','Jessica Taylor','Raquel Rosales','William Becknell', 'Candon Howard', 'Michael Hamilton','Tonisha Brown','Rachel Harris')

Update #Final
Set SLPTeamFlag = 'N'
Where SLPTeamFlag is null
--END OF TEAM FLAG SECTION
--======================================================================================================
----Set remaining records to CDL------------------------------------------------------------------------
--======================================================================================================
Update #Final
Set DivisionGroup = 'CDL'
Where DivisionGroup Is Null

IF OBJECT_ID('tempdb..#CDLSales_CollegeLOProgram') is not null
DROP TABLE #CDLSales_CollegeLOProgram

SELECT EmployeeEmail

INTO #CDLSales_CollegeLOProgram

FROM #Final

WHERE Title in ('CDL Loan Associate', 'Loan Associate, CDL','Loan Associate', ' Loan Associate, CDL')

GROUP BY EmployeeEmail


UPDATE F
SET CDLSales_CollegeLOProgram = 'Y'
FROM #Final F----------------alias added by Rucha
inner join #CDLSales_CollegeLOProgram C
ON F.EmployeeEmail = C.EmployeeEmail-----------------------------------

UPDATE #Final
SET CDLSales_CollegeLOProgram = 'Y'
WHERE EmployeeEmail in
(
 'amber.prasopoulos@pnmac.com'
, 'andrew.liu@pnmac.com'
, 'art.soto@pnmac.com'
, 'jordan.skousen@pnmac.com'
, 'joshua.hylan@pnmac.com'
)

UPDATE #Final
SET CDLSales = 'Y'
WHERE Department in ('CDL Sales', 'CDL New Cust Acquisition', 'Retail Production:Admin')

UPDATE #Final
SET CDLSales = 'Y'
WHERE TitleGrouping in ('Account Executive', 'Loan Officer')
and CDLSales = 'N'

UPDATE #Final
SET CDLSales = 'Y'
WHERE TitleGrouping in ('Manager - Sales')
and Department in ('Plano, TX CC Sales #4', 'Pasadena, CA CC Sales #3', 'Sacramento CA CC Sale #4')
and CDLSales = 'N'

UPDATE #Final
SET CDLSales = 'Y'
WHERE EmployeeName = 'Andre Yerkanyan'
and Period = 201803 and CDLSales = 'N'

UPDATE #Final --PFG NEEDS UPDATES FOR COMP PURPOSES ON PEOPLE WHO ARE NO LONGER LOAN OFFICERS
SET CDLSales = 'Y'
WHERE EmployeeName = 'Morgan Bui' and Period = 202012

UPDATE #Final
SET CDLSales = 'N'
WHERE Department like '%MFD%' and CDLSales = 'Y'

UPDATE #Final
SET TitleGrouping = Title
WHERE TitleGrouping = 'Client Coordinator'
and (CDLSales = 'Y' or Department not like '%Dispatch%')
and EmployeeName <> 'Andre Yerkanyan'

UPDATE #Final
SET CSRFlag = 'Y'
WHERE Title in ('Rep I, Customer Service','Rep II, Customer Service','Sr Rep, Customer Service','Senior Representative, Customer Service','Rep, Customer Service Sales')


/*TRAINING START AND END DATES*/
UPDATE F

SET F.TrainingEndDate = S.TrainingEndDate,
	F.TrainingClass = S.TrainingClass

FROM #Final F

left join rrd.dbo.HUBSupport_CDL_Staffing_TrainingEndDates S
ON F.EmployeeEmail = S.EmployeeEmail and F.HireDate_Original = S.HireDate---------------------------------------------

WHERE CDLSales = 'Y'
--------------------------------------------------------------------------------------------------------------
UPDATE F

SET TrainingEndDate = '2/12/2021'

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202102 H
ON F.EmployeeEmail = H.[Employee Email] and H.Training = 'Y'-------------------------------------

WHERE F.CDLSales = 'Y'
--------------------------------------------------------------------------------------------------------------
UPDATE #Final
SET TrainingEndDate = '5/21/21'
WHERE EmployeeEmail in (
'kristie.laboca@pnmac.com',
'jason.martinez@pnmac.com',
'robert.haviland@pnmac.com',
'evan.green@pnmac.com',
'rebecca.tanner@pnmac.com',
'andrew.nguyen@pnmac.com',
'brock.likens@pnmac.com',
'david.larsen@pnmac.com',
'david.mccanlas@pnmac.com',
'edgar.gillies@pnmac.com',
'eric.almazan@pnmac.com',
'erik.luna@pnmac.com',
'harris.khatri@pnmac.com',
'henry.nguyen@pnmac.com',
'ian.burkhardt@pnmac.com',
'john.curran@pnmac.com',
'john.pagano@pnmac.com',
'justin.beck@pnmac.com',
'kevin.argueta@pnmac.com',
'orlando.sanchez@pnmac.com',
'akop.yerkanyan@pnmac.com',
'alan.chichakly@pnmac.com',
'jazlyn.briant@pnmac.com',
'jenny.twaddle@pnmac.com',
'john.kim@pnmac.com',
'madison.brown@pnmac.com',
'michael.osborne@pnmac.com',
'patty.schultz@pnmac.com',
'sara.aguayo@pnmac.com',
'brad.dupen@pnmac.com',
'cesar.peralta@pnmac.com',
'andrew.miller@pnmac.com',
'jeremy.white1@pnmac.com',
'mitchell.mascari@pnmac.com',
'paul.ruliffson@pnmac.com',
'robin.castro@pnmac.com',
'ruben.rodriguez1@pnmac.com',
'angela.walters@pnmac.com',
'courtney.sandison@pnmac.com',
'derrick.christensen@pnmac.com',
'justin.friedle@pnmac.com',
'nija.ross@pnmac.com',
'antoine.meleak@pnmac.com',
'babak.javaherpour@pnmac.com',
'christopher.aziz@pnmac.com',
'cindy.pena@pnmac.com',
'julie.daly@pnmac.com',
'olufunmilola.omotoso@pnmac.com',
'rafael.cortez@pnmac.com',
'william.moffatt@pnmac.com',
'candice.williams1@pnmac.com',
'carlo.abarro@pnmac.com',
'carlos.lopez@pnmac.com',
'david.mkrtchyan@pnmac.com',
'edgar.landeros@pnmac.com',
'henry.marron@pnmac.com',
'justin.mccarthy@pnmac.com',
'leo.jordan@pnmac.com',
'miren.alvarez@pnmac.com',
'deisy.alvarez@pnmac.com',
'denise.alvarez@pnmac.com',
'jeffery.dorothy@pnmac.com',
'jeremy.rohrer@pnmac.com',
'jill.cunningham@pnmac.com',
'josue.rojano@pnmac.com',
'huong.tran@pnmac.com',
'marcoalvarez.hernandez@pnmac.com',
'rebecca.bischoff@pnmac.com',
'romeo.connor@pnmac.com',
'zina.anderson@pnmac.com',
'lauren.ballard@pnmac.com',
'alan.williams@pnmac.com',
'correna.watson@pnmac.com',
'daniel.graziosi@pnmac.com',
'ian.frank@pnmac.com',
'lindsey.corriette@pnmac.com',
'raymond.hays@pnmac.com',
'ronald.gilmore@pnmac.com',
'sherena.walters@pnmac.com',
'daniel.silvey@pnmac.com'
)

UPDATE F

SET TrainingEndDate = '9/17/2021',
	F.TrainingClass = 19

FROM #Final F

inner join rrd.dbo.HUBSupport_CDL_Staffing_SalesAllocation_WithGoals_202109 H
ON F.EmployeeEmail = H.[Employee Email] and H.Training = 'Y'-------------------------------------

--WHERE F.CDLSales = 'Y'

/*LEGACY TRAINING END DATE LOGIC: THOSE WITH 4 - ARE TO BE INCLUDED BACK IN CASE*/
----UPDATE #Final
----SET TrainingEndDate = '6/28/2019',
----	TenuredDate = '6/28/2019',
----	TenuredFlag = 'Y'
----WHERE EmployeeName in (
----'Amir Rizvi',
----'Brandon Locke',
----'Cameron Freeland',
----'Charles Noorzaie',
----'Gilbert Herrera',
----'James Byers',
----'Jelani Keller',
----'Jonathan Cummins',
----'Jorje Cruz',
------'Michael Angelo', /*REMOVED DUE TO HIRE DATE CHANGE SINCE HE IS NOW DEDICATED TO REFI*/
----'Natalia Navarro',
----'Reid Wright',
----'Roberto Arias',
----'Scott Coughlin',
----'Shannon Vaughn',
----'Karen Flores',
----'Larry Martin',
----'Marcel Montano'
----)

----UPDATE #Final
----SET TrainingEndDate = '6/28/2019'
----WHERE EmployeeName in (
----'Michael Angelo'
----)


----UPDATE #Final
----SET TrainingEndDate = '8/2/2019',
----	TenuredDate = '8/2/2019',
----	TenuredFlag = 'Y'
----WHERE EmployeeName in (
----'Abigail Wilson',
----'Alfred Reams',
----'Angel Potts',
----'Arshage Aroush',
------'Arthur Hachikian', /*REMOVED DUE TO HIRE DATE CHANGE SINCE HE IS NOW DEDICATED TO REFI*/
----'Alex Khosravi',
----'Chris Franklin',
----'Evan Souza',
----'Jason Tomiello',
----'Jimmy Maokhamphiou',
----'Juanita Giovanni',
----'Patrick Kirk',
----'Peter Harris',
----'Sarah Brown',
----'Severiano Rico'
----)

----UPDATE #Final
----SET TrainingEndDate = '8/2/2019'
----WHERE EmployeeName in (
----'Arthur Hachikian'
----)

----UPDATE #Final
----SET TrainingEndDate = '8/9/2019',
----	TenuredDate = '8/9/2019',
----	TenuredFlag = 'Y'
----WHERE EmployeeName in (
----'Alex Khosravi'
----)

----UPDATE #Final
----SET TrainingEndDate = '10/1/2019'
----WHERE EmployeeName in (
----'Andrew Arakelian',
----'Andrew Ventura',
----'Christian Silva',
----'Claude Claybrook',
----'Derek Esterberg',
----'Dustyn Pierson',
----'Gary Zakaryan',
----'Jason Carvalho',
----'Jessie Corral',
----'Jirir Wosgerijyan',
----'Michael Derderian',
----'Paul Potthast',
----'Robert Macias',
----'Robert McGaughy',
----'Ross Ahkiong',
----'Ruben Luna Jr',
----'Samuel Grant',
----'Stephen Castaneda',
----'Steven Bruce',
----'Steven Garcia',
----'Tristan Summers',
----'Vartan Davtyan',
----'Victor Martinez',
----'Walter Zimmermann',
----'Wesley Black'
----)

---------------------------------------------------------
----UPDATE #Final
----SET TenuredFlag = CASE WHEN CAST(GETDATE() AS DATE) < '10/2/2019' THEN 'N' ELSE 'Y' END
----WHERE EmployeeName in (
----'Angel Potts',
----'Juanita Giovanni',
----'Natalia Navarro'
----)
---------------------------------------------------------
----UPDATE #Final
----SET TenuredFlag = CASE WHEN CAST(GETDATE() AS DATE) < '11/2/2019' THEN 'N' ELSE 'Y' END
----WHERE EmployeeName in (
----'Abigail Wilson',
----'Severiano Rico',
----'Vartan Davtyan'
----)

---------------------------------------------------------
-------- Below are still in training and anticipated to be trained by 12/1,
-------- Please verify this once the graduation end date is known - FS
---------------------------------------------------------
----/*REMOVED DUE TO UPDATED DATES
----UPDATE #Final
----SET TrainingEndDate = '12/1/2019'
----WHERE
----EmployeeEmail in (
----'adam.emmert@pnmac.com',
----'amelia.stratton@pnmac.com',
----'ben.curcio@pnmac.com',
----'braxton.bearden@pnmac.com',
----'bruce.ramirez@pnmac.com',
----'carlos.castro@pnmac.com',
----'daily.webb@pnmac.com',
----'dalia.rodriguez@pnmac.com',
----'daniel.kirby@pnmac.com',
----'darrin.woll@pnmac.com',
----'dino.rousseve@pnmac.com',
----'elsie.tejeda@pnmac.com',
----'erik.bates@pnmac.com',
----'erik.karibas@pnmac.com',
----'fred.aghili@pnmac.com',
----'gevork.dzhabroyan@pnmac.com',
----'hung.nguyen@pnmac.com',
----'jack.cooper@pnmac.com',
----'janelle.okuma@pnmac.com',
----'jeremy.brunson@pnmac.com',
----'jolene.regan@pnmac.com',
----'keith.seeley@pnmac.com',
----'kevin.carlson@pnmac.com',
----'leslie.baum@pnmac.com',
----'lisa.arroyo@pnmac.com',
----'mark.carpenter@pnmac.com',
----'marlon.bivens@pnmac.com',
----'marvin.zayas@pnmac.com',
----'mauro.serrano@pnmac.com',
----'michael.kramar@pnmac.com',
----'robert.tovar@pnmac.com',
----'sarkis.babakhanyan@pnmac.com',
----'shawnta.cody@pnmac.com',
----'solina.neth@pnmac.com',
----'sydney.barnes@pnmac.com',
----'tate.fackrell@pnmac.com',
----'ted.coburn@pnmac.com',
----'tyler.smedley@pnmac.com',
----'victor.lai@pnmac.com'
----)
----and period>=201908
----*/

----UPDATE #Final
----SET TrainingEndDate = '11/8/2019'
----WHERE EmployeeName in (
----'Amelia Stratton',
------'Ben Curcio', --GRADUATING 11/15
----'Braxton Bearden',
----'Bruce Ramirez',
----'Daily Webb',
----'Dalia Rodriguez',
----'Daniel Kirby',
----'Darrin Woll',
----'Dino Rousseve',
------'Erik Karibas', --GRADUATING 11/15
----'Fred Aghili',
----'Hung Nguyen',
----'Jack Cooper',
----'Janelle Okuma',
----'Jeremy Brunson',
----'Jolene Regan',
----'Keith Seeley',
----'Kevin Carlson',
----'Marlon Bivens',
----'Michael Kramar',
----'Mark Carpenter',--Added 11/5
------'Mauro Serrano', --GRADUATING 11/15
----'Sarkis Babakhanyan',
----'Shawnta Cody',
----'Solina Neth',
------'Sydney Barnes', --GRADUATING 11/15
----'Tate Fackrell',
------'Ted Coburn', --GRADUATING 11/15
----'Tyler Smedley',
----'Erik Bates',--Added 11/5
----'Robert Tovar'--Added 11/5
----)
----and Period >= 201908

----UPDATE #Final
----SET TrainingEndDate = '11/15/2019'
----WHERE EmployeeName in (
------'Adam Emmert',--Added 11/5 --GRADUATING 12/30 as of 12/3
------'Carlos Castro', --GRADUATING 12/2
------'Elsie Tejeda', --GRADUATING 12/6
----'Gevork Dzhabroyan',
----'Leslie Baum',
------'Lisa Arroyo', --GRADUATING 12/6
----'Marvin Zayas',
------'Victor Lai' --GRADUATING 12/6
----'Ben Curcio', --Added 11/14
----'Erik Karibas', --Added 11/14
----'Mauro Serrano', --Added 11/14
----'Sydney Barnes', --Added 11/14
----'Ted Coburn', --Added 11/14
----'Elsie Tejeda', --Added 11/14
----'Victor Lai' --Added 11/14
----)
----and Period >= 201908

----UPDATE #Final
----SET TrainingEndDate = '11/22/2019'
----WHERE EmployeeName in (
----'Lisa Arroyo' --Added 11/14
----)
----and Period >= 201908

----UPDATE #Final
----SET TrainingEndDate = '12/2/2019'
----WHERE EmployeeName in (
----'Carlos Castro' --Added 11/14
----)
----and Period >= 201908

----/*REMOVED DUE TO UPDATED DATES
----UPDATE #Final
----SET TrainingEndDate = '12/6/2019'
----WHERE EmployeeName in (
----'Lisa Arroyo', --GRADUATING 11/29***
----'Elsie Tejeda',--GRADUATING 11/15***
----'Victor Lai' --GRADUATING 11/15***
----)
----and Period >= 201908
----*/


UPDATE #Final
SET TrainingStartDate = '5/20/2019'
WHERE EmployeeName in (
'Roberto Arias'
)

UPDATE #Final
SET TrainingStartDate = '6/24/2019'
WHERE EmployeeName in (
'Abigail Wilson',
'Arshage Aroush',
'Evan Souza',
'Peter Harris',
'Sarah Brown'
)

UPDATE #Final
SET TrainingStartDate = '8/19/2019'
WHERE EmployeeName in (
'Andrew Arakelian',
'Andrew Ventura',
'Christian Silva',
'Derek Esterberg',
'Dustyn Pierson',
'Gevork Dzhabroyan',
'Jason Carvalho',
'Jessie Corral',
'Marck Garcia',
'Paul Potthast',
'Stephen Castaneda',
'Steven Bruce',
'Tristan Summers',
'Vartan Davtyan',
'Walter Zimmermann'
)

UPDATE #Final
SET TrainingStartDate = '9/30/2019'
WHERE EmployeeName in (
'Amelia Stratton',
'Braxton Bearden',
'Carlos Castro',
'Daily Webb',
'Dalia Rodriguez',
'Daniel Kirby',
'Darrin Woll',
'Erik Karibas',
'Hung Nguyen',
'Jack Cooper',
'Janelle Okuma',
'Jolene Regan',
'Keith Seeley',
'Kevin Carlson',
'Leslie Baum',
'Lisa Arroyo',
'Robert Tovar',
'Sarkis Babakhanyan',
'Solina Neth',
'Tate Fackrell',
'Tyler Smedley',
'Victor Lai'
)

----UPDATE #Final
----SET TrainingEndDate = '12/27/2019'
----WHERE EmployeeName in (
----'Aaron Arce',
----'Corey Golden',
----'Eric Busalacchi',
----'Eric Aron',--NCA
----'Gary Sahakian',--NCA
----'Gwendolyn Munder',
----'Ian Bey',
----'Jane Riley',
----'Jessica McGillewie',
----'Julia Shupe',
----'Justin Huse',
----'Michael Thompson',
----'Michael Henry', --RLS Turned LO
----'Nathan Jackson',
----'Rod Walker',
----'Taylor Fiorelli',
----'Tyler Richardson',
----'Will Langhagen')

----UPDATE #Final
----SET TrainingEndDate = '12/19/2019'
----WHERE EmployeeName in (
----'Adam Emmert')

UPDATE #Final
SET TrainingStartDate = '11/18/2019'
WHERE EmployeeName in (
'Aaron Arce',
'Corey Golden',
'Eric Busalacchi',
'Ian Bey',
'Jane Riley',
'Michael Thompson',
'Taylor Fiorelli',
'Tyler Richardson',
'Will Langhagen')

UPDATE #Final
SET TrainingStartDate = '11/22/2019'
WHERE EmployeeName in (
'Julia Shupe')

UPDATE #Final
SET TrainingStartDate = '11/25/2019'
WHERE EmployeeName in (
'Justin Huse')

UPDATE #Final
SET TrainingStartDate = '11/26/2019'
WHERE EmployeeName in (
'Gwendolyn Munder')

UPDATE #Final
SET TrainingStartDate = '11/27/2019'
WHERE EmployeeName in (
'Jessica McGillewie')

UPDATE #Final
SET TrainingEndDate = '12/27/2019'
WHERE EmployeeName in (
'Krystan Keyes',
'Gary Sahakian',
'Eric Aron'
)

UPDATE #Final
SET TrainingStartDate = '11/18/2019'
WHERE EmployeeName in (
'Krystan Keyes',
'Gary Sahakian',
'Eric Aron'
)

UPDATE #Final
SET TrainingStartDate = '01/24/2022'
WHERE TrainingClass = 22

----UPDATE #Final
----SET TrainingEndDate = '1/7/2020'
----WHERE EmployeeName in (
----'Ricardo Arreola')

----UPDATE #Final
----SET TrainingEndDate = '1/31/2020'
----WHERE EmployeeName in (
----'Krystan Keyes')

----UPDATE #Final
----SET TrainingEndDate = '2/14/2020'
----WHERE EmployeeName in (
----'Afton Lambert',
----'Angelique Muccio',
----'Anthony Soto',
----'Brock Walker',
----'Bryan Ross',
----'Carol Dion',
----'Charles Shepherd',
----'Debra Creelman',
----'Floyd Taylor',
----'Gabriel Vallarta',
----'Guillom Hines',
----'Johann Bonar',
----'Kuno Kaulbars',
----'Macy Gunderson',
----'Micah Ramos',
----'Quintrell Hillard',
----'Ricardo De Carlo',
----'Roberto Montoya',
----'Sevada Babakhani',
----'Shauntelle Walker',
----'Tabatha Atkins',
----'Tony Russo',
----'William Long')

----UPDATE #Final
----SET TrainingEndDate = '2/19/2020'
----WHERE EmployeeName in (
----'Tiffany Lewis')

----UPDATE #Final
----SET TrainingEndDate = '3/30/2020'
----WHERE EmployeeName in (
----'Ashley Cullinan',
----'Benjamin Contreras',
----'Beverly Lynch',
----'Christopher Butner',
----'Clinton Harris',
----'Corin Aurelio',
----'Daniel Loftus',
----'Donald Lucas',
----'Ellis Garcia',
----'Jacob Grubb',
----'John Ingersoll',
----'John Wilbanks',
----'Lloyd Smith',
----'Mark Guillermo',
----'Matthew Gillespie',
----'Michael Johnson',
----'Monica Ochoa',
----'Morgan Bui',
----'Nicholas Gilliam',
----'Pascal Dylewicz',
----'Phillip Zayas',
----'Robin Hallford',
----'Scott Fernald',
----'Patricia Nicholas'
----)

----UPDATE #Final
----SET TrainingEndDate = '5/15/2020'
----WHERE EmployeeName in (
----'Arameh Dilanchian',
----'Brandis Rembert',
----'Celso Dockhorn',
----'Clarence Daniels',
----'Daniel Kier',
----'Douglas Vorbeck',
----'Exavier Hamilton',
----'Fahali Campbell',
----'Francisco Duran',
----'Ivan Crume',
----'Jason Menne',
----'Jeremy Hain',
----'Jessica Diamond',
----'John Kimble Jr',
----'Joshua Nelson',
----'Justin Sprague',
----'Kenney Barrientos',
----'Kevin Jones',
----'Kirk Blackshear',
----'Martha Orellana',
----'Michael Dubrow',
----'Neal Renzi',
----'Nicholas Spencer',
----'Nicole Payne',
----'Nina Moshiri',
----'Richard Peck',
----'Tonisha Brown',
----'Tracy Corsey',
----'Tyler Gavin',
----'Alex Melgarejo'--NOT ON NICOLE'S LIST
----)

----UPDATE #Final
----SET TrainingEndDate = '5/20/2020'
----WHERE EmployeeName in (
----'Michael Steel',
----'Sevak Abkarian',
----'Royal Cameron'
----)

----UPDATE #Final
----SET TrainingEndDate = '5/29/2020'
----WHERE EmployeeName in (
----'Cesar Rodriguez Flores'
----)

----UPDATE #Final
----SET TrainingEndDate = '6/26/2020'
----WHERE EmployeeName in (
----'Alex Bozymowski',
----'Barry Clay II',
----'Chanhnett Turincio',
----'Conrad Stobnicki',
----'Corey Gaston',
----'Cristobal Garcia',
----'Curt Coleman',
----'Donald Carlson',
----'Evan Phillips',
----'Hector Centeno',
----'Jeremiah Kneeland',
----'Matt Saladino',
----'Michael Gingras',
----'Michael Powers',
----'Mitchell Dubois',
----'Samson Nargizyan',
----'Scott Kiley',
----'Thomas Zinschlag',
----'Travis John Lemley',
----'Vincent Cooper',
----'Mike Ezell'
----)

--------------------------------------------------------
UPDATE #Final
SET TrainingStartDate = HireDate
WHERE TrainingEndDate is not null and TrainingStartDate is null
--------------------------------------------------------
/*TRANSFER DATE SECTION*/
UPDATE #Final
Set TransferDate = '04/01/22'
where Period >= 202204 and EmployeeEmail in (
	 'tate.fackrell@pnmac.com'
	 )
UPDATE #Final
Set TransferDate = '03/16/22'
where Period = 202203 and EmployeeEmail in (
	  'argishti.tsaturyan@pnmac.com'
	 ,'carina.ramos@pnmac.com'
	 ,'david.alamo@pnmac.com'
	 ,'devin.sundheim@pnmac.com'
	 ,'diana.tulia@pnmac.com'
	 ,'emily.morris@pnmac.com'
	 ,'maha.saeed@pnmac.com'
	 ,'moses.hernandez@pnmac.com'
	 ,'patrick.redmen@pnmac.com'
	 ,'ronald.wright@pnmac.com'
	 ,'sydney.ferre@pnmac.com'
	 )
UPDATE #Final
Set TransferDate = '03/01/22'
where Period = 202203 and EmployeeEmail in (
	 'corey.marcelin@pnmac.com'
	,'daniel.kier@pnmac.com'
	,'jacobie.fullerton@pnmac.com'
	,'todd.maier@pnmac.com'
	,'isaac.solorio@pnmac.com'
	,'donavan.akers@pnmac.com'
	,'alec.gable@pnmac.com'
	,'misael.torres@pnmac.com'
	,'michael.peluso@pnmac.com'
	,'manuel.guido@pnmac.com'
	,'isaac.solorio@pnmac.com'
	,'gavin.pate@pnmac.com'
	,'jonathan.pitkevitsch@pnmac.com'
	,'michael.peluso@pnmac.com'
	,'todd.maier@pnmac.com'
	,'tracie.jones@pnmac.com'
	,'stacey.roth@pnmac.com'
	,'dylan.maio@pnmac.com'
	)

Update #Final
Set TransferDate = '01/15/22'
where Period >= 202201 and EmployeeEmail in (
	'reid.wright@pnmac.com '
	)


UPDATE #Final
Set TransferDate = '04/02/22'
where Period >= 202204 and EmployeeEmail in (
	'emily.morris@pnmac.com'
	,'moses.hernandez@pnmac.com'
	,'argishti.tsaturyan@pnmac.com'
	,'maha.saeed@pnmac.com'
	,'ritynai.yoeuth@pnmac.com'
	,'david.alamo@pnmac.com'
	,'devin.sundheim@pnmac.com'
	,'grace.simon@pnmac.com'
	,'gregory.sarine@pnmac.com'
	,'jamie.truelove@pnmac.com'
	,'patrick.redmen@pnmac.com'
	,'sydney.ferre@pnmac.com'
	 )

Update #Final
Set TransferDate = '12/16/21'
where Period >= 202112 and EmployeeEmail in (
	'brad.harley@pnmac.com'
	,'brittany.gleason@pnmac.com'
	,'brooke.roe@pnmac.com'
	,'krystal.wedlow@pnmac.com'
	,'nathaniel.husser@pnmac.com'
	,'daniel.sipp@pnmac.com'
	,'andrea.simpson@pnmac.com'
	,'john.garrett@pnmac.com'
	,'angel.vilorio@pnmac.com'
	,'meredith.denson@pnmac.com'
	)

Update #Final
Set HireDate = '12/16/21'
where Period >= 202112 and EmployeeEmail in (
	 'caroline.sessa@pnmac.com'
	,'manushak.marsoubian@pnmac.com'
	,'carlos.ramirez@pnmac.com'
	,'lauren.ogden@pnmac.com'
	,'armen.grigoryan@pnmac.com'
	,'gevorg.karapetian@pnmac.com'
	)

Update #Final
Set TransferDate = '12/01/21' -- Jeremiah and Sasha have been with pennymac for years and became LO in dec. this is to have him as nontenured for de
where Period >= 202112 and EmployeeEmail in (
	'jeremiah.kneeland@pnmac.com'
	,'sasha.drawdy@pnmac.com'
	,'david.miller@pnmac.com'
	,'roberto.annoni@pnmac.com'
	)
Update #Final
Set TransferDate = '01/01/22' -- Jeremiah and Sasha have been with pennymac for years and became LO in dec. this is to have him as nontenured for de
where Period >= 202201 and EmployeeEmail in (
	'demar.hosey@pnmac.com'
	)

UPDATE #Final
SET TransferDate = '06/16/2021'
WHERE EmployeeName in (
'Grae Carson'
) and Period >= 202106 and HireDate = '2019-10-21'

UPDATE #Final
SET TransferDate = '07/01/2021'
WHERE EmployeeName in (
'Suzanne Tonoli'
) and Period >= 202107 and HireDate = '2020-11-09'

UPDATE #Final
SET TransferDate = '12/16/2020'
WHERE EmployeeName in (
'JP Pettus'
) and Period >= 202012 and HireDate = '7/2/20'

UPDATE #Final
SET TransferDate = '11/18/19'
WHERE EmployeeName = 'Michael Henry' and Period >= 201911 and HireDate = '2/4/19'

UPDATE #Final
SET TransferDate = '3/2/20'
WHERE EmployeeName = 'Mark Guillermo' and Period >= 202003 and HireDate = '10/31/16'

UPDATE #Final
SET TransferDate = '2/1/20'
WHERE EmployeeName = 'Carlos Castro' and Period >= 202002 and HireDate = '9/23/19'

UPDATE #Final
SET TransferDate = '12/1/2019'
WHERE EmployeeName in (
'Severiano Rico') and Period >= 201912 and HireDate = '6/24/19'

UPDATE #Final
SET TransferDate = '3/16/2020'
WHERE EmployeeName in (
'Rodney Perkins',
'Tramell Nash',
'Ignacio Barrientos',
'Sarah Brown'
) and Period >= 202003 and HireDate <= '6/17/19'

UPDATE #Final
SET TransferDate = '3/30/2020'
WHERE EmployeeName in (
'Francisco Duran'
) and Period >= 202003 and HireDate = '12/22/14'

UPDATE #Final
SET TransferDate = '4/1/2020'
WHERE EmployeeName in (
'Nicholas Spencer',
'Martha Orellana',
'Arameh Dilanchian',
'Neal Renzi',
'Kevin Jones',
'Tonisha Brown'
) and Period >= 202004 and HireDate <= '8/26/19'

UPDATE #Final
SET TransferDate = '6/1/2020'
WHERE EmployeeName in (
'David Hernandez',
'Edith Torosyan',
'Darius Jackson',
'Conrad Stobnicki'
) and Period >= 202006 and HireDate <= '9/9/19'

UPDATE #Final
SET TransferDate = '8/16/2020'
WHERE EmployeeName in (
'Jonathan Wilson',
'Rebecca Holland'
) and Period >= 202008 and HireDate <= '7/1/18'--Date by which all were hired. In case rehired, will not use this TransferDate.

UPDATE #Final
SET TransferDate = '8/16/2020'
WHERE EmployeeName in (
'Veronica Tovar'
) and Period between 202008 and 202204 and HireDate <= '7/1/18'

UPDATE #Final
SET TransferDate = '11/16/2020'
WHERE EmployeeName in (
'Kristen Malave',
'Stacie Jenkins',
'John McGillewie'
) and Period >= 202011 and HireDate <= '8/1/20'

UPDATE #Final
SET TransferDate = '12/1/2020'
WHERE EmployeeName in (
'Rachel Bettine',
'RyLee Gorham',
'Thomas Wahl',--'Tommy Wahl',
'Wesley Topham'
) and Period >= 202012 and HireDate <= '11/1/20'

UPDATE #Final
SET TransferDate = '2/22/2021'
WHERE EmployeeEmail in (
'bethany.mcmullen@pnmac.com',
'kali.thompson@pnmac.com',
'michael.howarth@pnmac.com',
'nicole.stober@pnmac.com'
) and Period >= 202102 and HireDate <= '9/11/20' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '2/16/2021'
WHERE EmployeeEmail in (
'carli.kelley@pnmac.com',
'alec.irwin@pnmac.com',
'megan.cleary@pnmac.com',
'rami.addicks@pnmac.com',
'vireak.seang@pnmac.com',
'nick.spence@pnmac.com'
) and Period >= 202102 and HireDate <= '11/20/20' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '3/16/2021'
WHERE EmployeeEmail in (
'daniel.graziosi@pnmac.com',
'andrew.nguyen@pnmac.com',
'henry.nguyen@pnmac.com',
'carlos.lopez@pnmac.com',
'erik.luna@pnmac.com',
'kevin.argueta@pnmac.com'
) and Period >= 202103 and HireDate <= '11/20/20' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '6/28/2021'
WHERE EmployeeEmail in (
'robert.villapando@pnmac.com'
) and Period >= 202106 and HireDate <= '09/16/19' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '7/01/2021'
WHERE EmployeeEmail in (
'mitchell.peralta@pnmac.com'
) and Period >= 202107 and HireDate <= '03/26/21' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '7/6/2021'
WHERE EmployeeEmail in (
'amanda.tubbs@pnmac.com'
) and Period >= 202107 and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '7/6/2021'
WHERE EmployeeEmail in (
'artuz.manning@pnmac.com'
) and Period >= 202107 and HireDate <= '07/06/2021' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '2/1/2022'
WHERE EmployeeEmail in (
'andrew.shepherd@pnmac.com',
'cameron.minton@pnmac.com',
'coby.perry@pnmac.com',--
'corrie.hopkins@pnmac.com',
'harris.khatri@pnmac.com',--
'jackie.sager@pnmac.com',--
'jeffrey.smith@pnmac.com',
'justin.beck@pnmac.com',
'logan.gwinn@pnmac.com',--
'michael.bojaj@pnmac.com',
'roberto.montoya@pnmac.com',
'stacie.jenkins@pnmac.com',
'yuri.lebedev@pnmac.com'
) and Period >= 202202 and HireDate <= '02/01/2022' and TitleGrouping in ('Account Executive', 'Loan Officer')
and PurchaseFlag ='Y'

UPDATE #Final
SET TransferDate = '3/1/2022'
WHERE EmployeeEmail in (
'michael.stephan@pnmac.com'
) and Period >= 202203 and HireDate <= '03/01/2022' and TitleGrouping in ('Account Executive', 'Loan Officer')
and PurchaseFlag ='Y'

UPDATE #Final
Set TransferDate = '05/01/22'
where EmployeeEmail in (
	 'aaron.arce@pnmac.com'
	,'andrew.abrams@pnmac.com'
	,'anthony.tabor@pnmac.com'
	,'brock.walker@pnmac.com'
	,'chris.franklin@pnmac.com'
	,'christina.kelly@pnmac.com'
	,'daniel.silvey@pnmac.com'
	,'felix.kim@pnmac.com'
	,'james.bruce@pnmac.com'
	,'jimmy.kim@pnmac.com'
	,'juanita.moreno@pnmac.com'
	,'kaitey.gates@pnmac.com'
	,'katherine.smith@pnmac.com'
	,'kelley.christianer@pnmac.com'
	,'matt.ellis@pnmac.com'
	,'michael.dubrow@pnmac.com'
	,'patricia.mendez@pnmac.com'
	,'penny.mrva@pnmac.com'
	,'richard.peck@pnmac.com'
	,'sean.puckett@pnmac.com'
	,'taylor.johnson@pnmac.com'
	,'timothy.esterly@pnmac.com'
	,'travis.lemley@pnmac.com'
	,'tyler.smedley@pnmac.com'
	,'wayne.davey@pnmac.com'
	,'jessie.corral@pnmac.com'
	,'charles.shepherd@pnmac.com'
	,'eric.gutman@pnmac.com'
	,'jacob.battaglia@pnmac.com'
	,'jesse.leon@pnmac.com'
	,'joseph.garcia@pnmac.com'
	,'justin.forman@pnmac.com'
	,'matthew.mcglinn@pnmac.com'
	,'muzna.jabeen@pnmac.com'
	,'rachel.vasquez@pnmac.com'
	,'riham.willis@pnmac.com'
	,'sarah.murphy@pnmac.com'
	,'taha.shakir@pnmac.com'
	,'ronald.wright@pnmac.com'
	,'miranda.bartlett@pnmac.com'
	,'john.mardirosian@pnmac.com',
	'charles.shepherd@pnmac.com',
	'jacob.battaglia@pnmac.com',
	'miranda.bartlett@pnmac.com',
	'muzna.jabeen@pnmac.com',
	'riham.willis@pnmac.com',
	'taha.shakir@pnmac.com',
	'veronica.tovar@pnmac.com',
	'eric.gutman@pnmac.com',
	'jesse.leon@pnmac.com',
	'joseph.garcia@pnmac.com',
	'justin.forman@pnmac.com',
	'matthew.mcglinn@pnmac.com',
	'rachel.vasquez@pnmac.com',
	'sarah.murphy@pnmac.com',
	'conner.routen@pnmac.com'
	 ) and Period >= 202205 and HireDate <= '05/01/2022' and TitleGrouping in ('Account Executive', 'Loan Officer')


UPDATE #Final
Set TransferDate = '06/01/22'
where Period = 202206 and EmployeeEmail in (
	 'andrew.simmons@pnmac.com'
	,'austin.schreibman@pnmac.com'
	,'brian.schooler@pnmac.com'
	,'david.risse@pnmac.com'
	,'Edith.Torosyan@pnmac.com'
	,'floyd.taylor@pnmac.com'
	,'gary.darden@pnmac.com'
	,'joe.mckinley@pnmac.com'
	,'nelson.massari@pnmac.com'
	,'peter.harris@pnmac.com'
	,'will.langhagen@pnmac.com'
	,'alejandro.guzman@pnmac.com'
	,'angela.cornell@pnmac.com'
	,'angelica.williams1@pnmac.com'
	,'derek.beutel@pnmac.com'
	,'dominique.benton@pnmac.com'
	,'ed.vandervelde@pnmac.com'
	,'erik.bates@pnmac.com'
	,'janice.randall@pnmac.com'
	,'jany.alvarez@pnmac.com'
	,'jason.martinez@pnmac.com'
	,'jason.thomas@pnmac.com'
	,'ken.huff@pnmac.com'
	,'melinda.woods@pnmac.com'
	,'michael.morales1@pnmac.com'
	,'robynn.olson@pnmac.com'
	,'rodney.perkins@pnmac.com'
	,'tramell.nash@pnmac.com'
	,'vincent.chu@pnmac.com'
	,'joshua.nelson@pnmac.com'
	 ) and Period >= 202206 and HireDate <= '06/01/2022' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
Set TransferDate = '06/01/22'
where EmployeeEmail in (
     'andrew.simmons@pnmac.com'
    ,'austin.schreibman@pnmac.com'
    ,'brian.schooler@pnmac.com'
    ,'david.risse@pnmac.com'
    ,'Edith.Torosyan@pnmac.com'
    ,'floyd.taylor@pnmac.com'
    ,'gary.darden@pnmac.com'
    ,'joe.mckinley@pnmac.com'
    ,'nelson.massari@pnmac.com'
    ,'peter.harris@pnmac.com'
    ,'will.langhagen@pnmac.com'
    ,'alejandro.guzman@pnmac.com'--
    ,'angela.cornell@pnmac.com'--
    ,'angelica.williams1@pnmac.com'--
    ,'derek.beutel@pnmac.com'--
    ,'dominique.benton@pnmac.com'--
    ,'ed.vandervelde@pnmac.com'--
    ,'erik.bates@pnmac.com'--
    ,'janice.randall@pnmac.com'--
    ,'jany.alvarez@pnmac.com'--
    ,'jason.martinez@pnmac.com'--
    ,'jason.thomas@pnmac.com'--
    ,'ken.huff@pnmac.com'--
    ,'melinda.woods@pnmac.com'--
    ,'michael.morales1@pnmac.com'--
    ,'robynn.olson@pnmac.com'--
    ,'rodney.perkins@pnmac.com'--
    ,'tramell.nash@pnmac.com'--
    ,'vincent.chu@pnmac.com'--
    ,'joshua.nelson@pnmac.com'
	,'todd.rasmussen@pnmac.com'--Todd Rassumssen
	,'nicholas.hunter@pnmac.com'--Nicholas Hunger
	,'kristie.laboca@pnmac.com'--Kristie Laboca
	,'nicole.stober@pnmac.com'
	,'mario.amaya@pnmac.com'
) and Period >= 202206 and HireDate <= '06/01/2022' and TitleGrouping in ('Account Executive', 'Loan Officer')

UPDATE #Final
SET TransferDate = '6/1/2022'
WHERE EmployeeEmail in (
'amanda.tubbs@pnmac.com'
) and Period >= 202107 and TitleGrouping in ('Account Executive', 'Loan Officer')

/*LOA END DATE SECTION*/
UPDATE #Final
SET LOAEndDate = '12/01/2021'
WHERE EmployeeEmail in (
	'samantha.piccirillo@pnmac.com'
	,'veronica.tovar@pnmac.com'
	)
and LOAEndDate IS NULL
and Period between 202112 and 202204

UPDATE #Final
SET LOAEndDate = '6/7/18'
WHERE EmployeeName = 'Jonnie Maretti' and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '9/1/2019'
WHERE EmployeeName = 'Randall Alford' and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '10/21/2019'
WHERE EmployeeName = 'Richard Kennimer' and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '10/24/2019'
WHERE EmployeeName = 'Anthony Trozera' and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '1/13/2020'
WHERE EmployeeName = 'Carlos Castro' and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '2/10/2020'
WHERE EmployeeName in ('Jolene Regan', 'Natalia Navarro')
and LOAEndDate is null

UPDATE #Final
SET LOAEndDate = '4/22/2020'
WHERE EmployeeName in ('Imelda Sanchez')
and LOAEndDate is null
and Period >= 202004

UPDATE #Final
SET LOAEndDate = '5/12/2020'
WHERE EmployeeName = 'Benedick Magcalas'
and LOAEndDate is null
and Period >= 202005

UPDATE #Final
SET LOAEndDate = '11/5/2020'
WHERE EmployeeName = 'Matthew Thorpe'
and LOAEndDate is null
and LOADate < '11/5/2020'
and Period >= 202011

UPDATE #Final
SET LOAEndDate = '1/4/2021'
WHERE EmployeeName = 'David Kater'
and LOAEndDate is null
and LOADate < '1/4/2021'
and Period >= 202101

UPDATE #Final
SET LOAEndDate = '1/6/2021'
WHERE EmployeeName = 'Christina Sullivan'
and LOAEndDate is null
and LOADate < '1/6/2021'
and Period >= 202101

UPDATE #Final
SET LOAEndDate = '02/17/2021'
WHERE EmployeeName = 'Jacob Arciero'
and LOAEndDate is null
and Period >= 202102

UPDATE #Final
SET LOAEndDate = '1/12/2021'
WHERE EmployeeName = 'Kyle Yu'
and LOAEndDate is null
and LOADate < '1/12/2021'
and Period >= 202101

UPDATE #Final
SET LOAEndDate = '2/23/2021'
WHERE EmployeeName = 'Juan Barron'
and LOAEndDate is null
and Period >= 202102

UPDATE #Final
SET LOAEndDate = '3/9/2021'
WHERE EmployeeEmail = 'john.fayad@pnmac.com'
and LOAEndDate is null
and Period >= 202103

UPDATE #Final
SET LOAEndDate = '3/30/2021'
WHERE EmployeeEmail = 'david.kelly@pnmac.com'
and LOAEndDate is null
and Period >= 202103

UPDATE #Final
SET LOAEndDate = '3/25/2021'
WHERE EmployeeEmail = 'nicole.graham@pnmac.com'
and LOAEndDate is null
and Period >= 202103

UPDATE #Final
SET LOAEndDate = '4/11/2021'
WHERE EmployeeEmail = 'nick.bergh@pnmac.com'
and LOAEndDate is null
and Period >= 202104

UPDATE #Final
SET LOAEndDate = '5/1/2021'
WHERE EmployeeEmail = 'emmett.kinsella@pnmac.com'
and LOAEndDate is null
and Period >= 202105

UPDATE #Final
SET LOAEndDate = '5/19/2021'
WHERE EmployeeEmail = 'jasmin.echols@pnmac.com'
and LOAEndDate is null
and Period >= 202105

UPDATE #Final
SET LOAEndDate = '5/17/2021'
WHERE EmployeeEmail = 'abigail.wilson@pnmac.com'
and LOAEndDate is null
and Period >= 202105

UPDATE #Final
SET LOAEndDate = '06/01/2021'
WHERE EmployeeEmail = 'daniel.craun@pnmac.com'
and Period >= 202106

UPDATE #Final
SET LOAEndDate = '06/01/2021'
WHERE EmployeeEmail = 'vincent.cooper@pnmac.com'
and LOAEndDate is null
and Period >= 202106

UPDATE #Final
SET LOAEndDate = '07/07/2021'
WHERE EmployeeEmail = 'bruce.gurnowski@pnmac.com'
and LOAEndDate is null
and Period >= 202107

UPDATE #Final
SET LOAEndDate = '07/20/2021'
WHERE EmployeeEmail = 'hannah.brown@pnmac.com'
and LOAEndDate is null
and Period >= 202107

UPDATE #Final
SET LOAEndDate = '07/26/2021'
WHERE EmployeeEmail = 'braxton.bearden@pnmac.com'
and LOAEndDate is null
and Period >= 202107

UPDATE #Final
SET LOAEndDate = '08/17/2021'
WHERE EmployeeEmail = 'taylor.crume@pnmac.com'
and LOAEndDate is null
and Period >= 202108

UPDATE #Final
SET LOAEndDate = '08/30/2021'
WHERE EmployeeEmail = 'caitlin.shambaugh@pnmac.com'
and LOAEndDate is null
and Period >= 202108

UPDATE #Final
SET LOAEndDate = '09/20/2021'
WHERE EmployeeEmail = 'alessandra.malta@pnmac.com'
and LOAEndDate is null
and Period >= 202109

UPDATE #Final
SET LOAEndDate = '9/23/2021'
WHERE EmployeeEmail = 'abigail.wilson@pnmac.com'
and LOAEndDate is null
and Period >= 202109

UPDATE #Final
SET LOAEndDate = '10/06/2021'
WHERE EmployeeEmail = 'freddie.garciaflores@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/06/2021'
WHERE EmployeeEmail = 'keith.williams@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/15/2021'
WHERE EmployeeEmail = 'connie.serrano@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/15/2021'
WHERE EmployeeEmail = 'kim.hong@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/21/2021'
WHERE EmployeeEmail = 'al.nasser@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/26/2021'
WHERE EmployeeEmail = 'galen.ikonomov@pnmac.com'
and LOAEndDate is null
and Period >= 202110


UPDATE #Final
SET LOAEndDate = '11/01/2021'
WHERE EmployeeEmail = 'brittany.garcia@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '10/29/2021'
WHERE EmployeeEmail = 'stephen.castaneda@pnmac.com'
and LOAEndDate is null
and Period >= 202110

UPDATE #Final
SET LOAEndDate = '11/01/2021'
WHERE EmployeeEmail = 'garrett.greene@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202111

UPDATE #Final
SET LOAEndDate = '11/04/2021'
WHERE EmployeeEmail = 'michael.fascetti@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202111

UPDATE #Final
SET LOAEndDate = '11/08/2021'
WHERE EmployeeEmail = 'tabatha.atkins@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202111

UPDATE #Final
SET EmploymentStatus = 'Active'
WHERE EmployeeEmail = 'tabatha.atkins@pnmac.com'
and LOAEndDate = '11/08/2021'

UPDATE #Final
SET LOAEndDate = '11/09/2021'
WHERE EmployeeEmail = 'paul.t.szymanski@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202111

UPDATE #Final
SET LOAEndDate = '11/16/2021'
WHERE EmployeeEmail = 'lauren.ballard@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202111

UPDATE #Final
SET LOAEndDate = '12/01/2021'
WHERE EmployeeEmail = 'jake.crocker@pnmac.com'
and LOAEndDate IS NULL
and Period >= 202112


UPDATE #Final
SET LOAEndDate = '12/07/2021'
WHERE EmployeeEmail in (
	'jany.alvarez@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202112
--====LOAEnddate 2022 start
UPDATE #Final
SET LOAEndDate = '01/04/2022'
WHERE EmployeeEmail in (
	'correna.watson@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202201

UPDATE #Final
SET LOAEndDate = '01/10/2022'
WHERE EmployeeEmail in (
	'andrew.shepherd@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202201

UPDATE #Final
SET LOAEndDate = '01/24/2022'
WHERE EmployeeEmail in (
	'khadeeja.ali@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202201

UPDATE #Final
SET LOAEndDate = '01/01/2022'
WHERE EmployeeEmail in (
	'maritza.chiaway@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202201

UPDATE #Final
SET LOAEndDate = '02/02/2022'
WHERE EmployeeEmail in (
	'brian.stoddard@pnmac.com'
	,'paul.ruliffson@pnmac.com'
	)
and Period >= 202202

UPDATE #Final
SET LOAEndDate = '02/22/2022'
WHERE EmployeeEmail in (
	'erik.karibas@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202202

UPDATE #Final
SET LOAEndDate = '02/24/2022'
WHERE EmployeeEmail in (
	'guillom.hines@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202202

UPDATE #Final
SET LOAEndDate = '03/03/2022'
WHERE EmployeeEmail in (
	'ian.burkhardt@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202203

UPDATE #Final
SET LOAEndDate = '03/07/2022'
WHERE EmployeeEmail in (
	'alexander.soria@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202203

UPDATE #Final
SET LOAEndDate = '03/10/2022'
WHERE EmployeeEmail in (
	'michael.mikulich@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202203

UPDATE #Final
SET LOAEndDate = '03/28/2022'
WHERE EmployeeEmail in (
	'anita.jones@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202203

UPDATE #Final
SET LOAEndDate = '04/04/2022'
WHERE EmployeeEmail in (
	'gerardo.carranza@pnmac.com'

	)
and LOAEndDate IS NULL
and Period >= 202204

UPDATE #Final
SET LOAEndDate = '04/27/2022'
WHERE EmployeeEmail in (
	'nathaniel.husser@pnmac.com'
	,'leo.jordan@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202204

UPDATE #Final
SET LOAEndDate = '05/09/2022'
WHERE EmployeeEmail in (
	'michael.bojaj@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202205

UPDATE #Final
SET LOAEndDate = '05/17/2022'
WHERE EmployeeEmail in (
	'rachel.connolly@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202205


UPDATE #Final
SET LOAEndDate = '05/28/2022'
WHERE EmployeeEmail in (
	'kc.packer@pnmac.com'
	)
and LOAEndDate IS NULL
and Period = 202205

UPDATE #Final
SET LOAEndDate = '05/25/2022'
WHERE EmployeeEmail in (
	'rod.walker@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202205

UPDATE #Final
SET LOAEndDate = '05/16/2022'
WHERE EmployeeEmail in (
	'kevin.jones@pnmac.com'
	)
and LOAEndDate IS NULL
and Period >= 202205


UPDATE #Final
SET LOAEndDate = '06/08/2022'
WHERE Period = 202206
and EmployeeEmail in (
    'paul.yoo@pnmac.com'
	--,'jamilynn.merolle@pnmac.com' --Lock goals g sheet shows LOAstart date was 6/01/2022 --Charlie remove 06/10/22 becuase LOA was extended
    )
and LOAEndDate IS NULL
and Period >= 202206

UPDATE #Final
SET LOAEndDate = '06/14/2022'
WHERE EmployeeEmail in (
    'jamilynn.merolle@pnmac.com'
    )
and LOAEndDate IS NULL
and Period >= 202206


----------------------------------------------
UPDATE #Final
SET LOAEndDate = NULL
WHERE LOAEndDate < LOADate or LOADate is null

--UPDATE #Final
--SET LOAEndDate = NULL
--WHERE CONVERT(VARCHAR(6),LOAEndDate,112) < Period

UPDATE #Final
SET LOAEndPeriod = rrd.dbo.udf_MonthYear_Int(LOAEndDate)
----------------------------------------------

/*TENURED DATE SECTION*/
UPDATE #Final
SET TenuredDate = CASE
					When TitleGrouping in ('Account Executive','Loan Officer')
					and TrainingEndDate is not null
					and TrainingEndDate > ISNULL(TransferDate, '01/01/1900')
					and TrainingEndDate > ISNULL(LOADate, '01/01/1900') Then
						CASE
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(TrainingEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,TrainingEndDate))
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(TrainingEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,TrainingEndDate))
							when PurchaseFlag= 'N' and day(TrainingEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,TrainingEndDate))
							when PurchaseFlag= 'N' and day(TrainingEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,TrainingEndDate))
						end
					When TitleGrouping in ('Account Executive','Loan Officer')
					and DateDiff(day,LOADate,LOAEndDate)>30
					and ISNULL(LOADate, '01/01/1900') >= ISNULL(TrainingEndDate, '02/01/1900')
					and ISNULL(LOADate, '01/01/1900') >= ISNULL(Transferdate, '02/01/1900') then
						CASE
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(LOAEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,LOAEndDate))
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(LOAEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,LOAEndDate))
							when PurchaseFlag= 'N' and day(LOAEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,LOAEndDate))
							when PurchaseFlag= 'N' and day(LOAEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,LOAEndDate))
						end

					When TitleGrouping in ('Account Executive','Loan Officer')
					and Transferdate is not null
					and Transferdate > ISNULL(TrainingEndDate, '01/01/1900')
					and Transferdate > ISNULL(LOADate, '01/01/1900') then
						CASE
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(Transferdate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,Transferdate))
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(Transferdate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,Transferdate))
							when PurchaseFlag= 'N' and day(Transferdate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,Transferdate))
							when PurchaseFlag= 'N' and day(Transferdate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,Transferdate))
						end
					When TitleGrouping in ('Account Executive','Loan Officer') then
						CASE
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(hiredate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,HireDate))
							when (PurchaseFlag = 'Y' or NCAFlag = 'Y') and day(hiredate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,5,HireDate))
							when PurchaseFlag= 'N' and day(hiredate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,HireDate))
							when PurchaseFlag= 'N' and day(hiredate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,HireDate))
						end
					when TitleGrouping = 'Processor' then
						CASE
							when DATEPART(d,HireDate) <= 15 then rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,HireDate))
							else rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,HireDate))
						end
					else rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,HireDate))

				end

UPDATE #Final
SET TenuredFlag = case
					when rrd.dbo.udf_MonthYear_Int(TenuredDate) <= Period then 'Y'
					else 'N'
				  end

UPDATE #Final
SET TenuredNextMoFlag = case
							when rrd.dbo.udf_MonthYear_Int(Dateadd(m,-1,TenuredDate)) = Period
							then 'Y'
							else 'N'
						end

/*ORIGINAL TENURED DATE SECTION*/
UPDATE #Final
SET OriginalTenuredDate = CASE
					When TitleGrouping in ('Account Executive','Loan Officer')
						and TrainingEndDate is not null Then
						CASE
							when PurchaseFlag= 'Y' and day(TrainingEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,TrainingEndDate))
							when PurchaseFlag= 'Y' and day(TrainingEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,TrainingEndDate))
							when PurchaseFlag= 'N' and day(TrainingEndDate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,TrainingEndDate))
							when PurchaseFlag= 'N' and day(TrainingEndDate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,TrainingEndDate))
						end

					When TitleGrouping in ('Account Executive','Loan Officer') then
						CASE
							when PurchaseFlag= 'Y' and day(hiredate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,HireDate))
							when PurchaseFlag= 'Y' and day(hiredate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,5,HireDate))
							when PurchaseFlag= 'N' and day(hiredate)>15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,4,HireDate))
							when PurchaseFlag= 'N' and day(hiredate)<=15 then  rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,HireDate))
						end

					when TitleGrouping = 'Processor' then
						CASE
							when DATEPART(d,HireDate) <= 15 then rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,HireDate))
							else rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,3,HireDate))
						end
					else rrd.dbo.udf_FirstDayOfMonth(DATEADD(m,2,HireDate))

				end

UPDATE #Final
SET OriginalTenuredFlag = case
					when rrd.dbo.udf_MonthYear_Int(TenuredDate) <= Period then 'Y'
					else 'N'
				  end




UPDATE #Final
SET OriginalTenuredNextMoFlag = case
							when rrd.dbo.udf_MonthYear_Int(Dateadd(m,-1,TenuredDate)) = Period
							then 'Y'
							else 'N'
						end


UPDATE #Final
SET HireDate = ISNULL(TransferDate,HireDate)
WHERE TitleGrouping in ('Account Executive', 'Loan Officer')

--Sid temp updates 2021-09-07
update #Final
SET SiteLead='Kevin Price'
,ManagerName_TwoUp='Kevin Price'
,City='Phoenix'
,ChannelManager=case when EmployeeEmail ='david.clark@pnmac.com' or EmployeeEmail='steven.owens@pnmac.com' then 'Frank Frayer'
					 else 'Natalia Navarro' end
where EmployeeEmail in ('amber.prasopoulos@pnmac.com',
'art.soto@pnmac.com',
'david.clark@pnmac.com',
'david.sambell@pnmac.com',
'juan.alvarez@pnmac.com',
'steven.owens@pnmac.com',
'wesley.marsh@pnmac.com')
and period= 202109

update #Final
Set ManagerName='Ryan Wilson'
, ManagerEmail='ryan.p.wilson@pnmac.com'
where EmployeeEmail='amber.prasopoulos@pnmac.com'
and period= 202109

update #Final
Set ManagerName='Katherine Orabuena'
, ManagerEmail='katherine.orabuena@pnmac.com'
where (EmployeeEmail='art.soto@pnmac.com'
or EmployeeEmail='wesley.marsh@pnmac.com')
and period= 202109

update #Final
Set ManagerName='Juanita Moreno'
, ManagerEmail='juanita.moreno@pnmac.com'
where EmployeeEmail='juan.alvarez@pnmac.com'
and period= 202109

update #Final
Set ManagerName='Eric Jones'
, ManagerEmail='eric.jones@pnmac.com'
where EmployeeEmail='david.clark@pnmac.com'
and period= 202109

update #Final
Set ManagerName='Garrett Bateman'
, ManagerEmail='garrett.bateman@pnmac.com'
where EmployeeEmail='david.sambell@pnmac.com'
and period= 202109

update #Final
Set ManagerName='Patricia Mendez'
, ManagerEmail='patricia.mendez@pnmac.com'
where EmployeeEmail='steven.owens@pnmac.com'
and period= 202109

DELETE FROM #Final
WHERE EmployeeId = 'C02309'

DELETE FROM #Final
WHERE EmployeeId = '004537' and AE_NMLS_ID = 2068710

DELETE FROM #Final
WHERE EmployeeId = '013491' and AE_NMLS_ID = 797743

DELETE FROM #Final
WHERE EmployeeId = 'OT0764' --DispatchOffshore Agent had dups due to different employeeid

DELETE FROM #Final
WHERE EmployeeEmail = 'joshua.baker2@pnmac.com' and AE_NMLS_ID = 797743

UPDATE #Final
SET PurchaseFlag = 'N'
WHERE EmployeeEmail = 'joshua.baker2@pnmac.com'

DELETE FROM #Final
WHERE EmployeeId = '004537' and AE_NMLS_ID = 2290910

DELETE FROM #Final
WHERE EmployeeId = '013491' and AE_NMLS_ID = 2290910

DELETE FROM #Final
WHERE EmployeeId = '014206' and AE_NMLS_ID = 2068710

--Create Index idx_Period on #Final(Period)
--Create Index idx_TitleGrouping on #Final(TitleGrouping)

UPDATE F
SET F.EmploymentStatusDetail = F.EmploymentStatus
FROM #Final F

UPDATE F
SET F.EmploymentStatusDetail = D.EmploymentStatusDetail
FROM #Final F
inner join rrd.dbo.Staffing_EmployeeStatusDetail D
ON F.EmployeeId = D.EmployeeId and F.Period = D.Period
WHERE F.EmploymentStatus = 'Active'

IF OBJECT_ID ('rrd.dbo.HUB_CDL_Staffing_MA','U') is not null
DROP TABLE rrd.dbo.HUB_CDL_Staffing_MA

SELECT *
INTO rrd.dbo.HUB_CDL_Staffing_MA
FROM #Final
--=============================================================================================================================
--========================Index Table==========================================================================================
--=============================================================================================================================
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_EmployeeEmail')
DROP INDEX idx_HUB_Staffing_EmployeeEmail ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_EmployeeEmail] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[EmployeeEmail] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_EmployeeId')
DROP INDEX idx_HUB_Staffing_EmployeeId ON  [HUB_CDL_Staffing];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_EmployeeId] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[EmployeeId] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_EmployeeName')
DROP INDEX idx_HUB_Staffing_EmployeeName ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_EmployeeName] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[EmployeeName] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_Period')
DROP INDEX idx_HUB_Staffing_Period ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_Period] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[Period] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_Period_EmployeeEmail')
DROP INDEX idx_HUB_Staffing_Period_EmployeeEmail ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_Period_EmployeeEmail_MA] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[Period] ASC,
	[EmployeeEmail] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_Period_EmployeeId')
DROP INDEX idx_HUB_Staffing_Period_EmployeeId ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_Period_EmployeeId] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[Period] ASC,
	[EmployeeId] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_Period_EmployeeName')
DROP INDEX idx_HUB_Staffing_Period_EmployeeName ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_Period_EmployeeName] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[Period] ASC,
	[EmployeeName] ASC
);
----------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('HUB_CDL_Staffing_MA') AND NAME ='idx_HUB_Staffing_TitleGrouping')
DROP INDEX idx_HUB_Staffing_TitleGrouping ON  [HUB_CDL_Staffing_MA];

CREATE NONCLUSTERED INDEX [idx_HUB_Staffing_TitleGrouping] ON [dbo].[HUB_CDL_Staffing_MA]
(
	[TitleGrouping] ASC
);

--=============================================================================================================================
--========================REFRESH TABLE INSERT=================================================================================
--=============================================================================================================================
INSERT INTO rrd.dbo.HUB_TableRefreshLog (TableName, ReportFlag, HubFlag) VALUES ('rrd.dbo.HUB_CDL_Staffing_MA',0,1)


--DECLARE @html VARCHAR(MAX)
--DECLARE @Sub VARCHAR(150)


--SET @Sub = 'CDL Staffing Job Completed'
--SET @html='<H1 align="CENTER"> ::: rrd.dbo.CDLStaffing Table Completed ::: '

--	EXEC msdb..sp_send_dbmail
--		@profile_name = 'Default_SMTP',
--		@recipients ='ProductionReportingAndMonitoring@pnmac.com',
--		--@recipients ='MortgageOpsReportingAnalysis@pnmac.com',
--		@from_address='Production Reporting And Monitoring <ProductionReportingAndMonitoring@pnmac.com>',
--		--@from_address='Mortgage Ops Reporting <MortgageOpsReportingAnalysis@pnmac.com>',
--		@reply_to='ProductionReportingAndMonitoring@pnmac.com',
--		--@reply_to='MortgageOpsReportingAnalysis@pnmac.com',
--		@subject = @Sub,
--		@body_format='html',
--		@body = @html
