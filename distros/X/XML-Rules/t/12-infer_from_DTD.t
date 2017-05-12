#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
#use Data::Dump qw(pp);

use XML::Rules;

SKIP: {
	skip "XML::DTDParser not installed, skipping the tests", 5 unless eval "use XML::DTDParser; 1";
{
	my $DTD = <<'*END*';
<!ELEMENT Locales ( LOCALE+ ) >

<!ELEMENT LOCALE ( CODE, NAME, SHORTDATE, LONGDATE, ACTIVE ) >
<!ATTLIST LOCALE ID ID #REQUIRED >

<!ELEMENT CODE ( #PCDATA ) >

<!ELEMENT NAME ( #PCDATA ) >

<!ELEMENT LONGDATE ( #PCDATA ) >

<!ELEMENT SHORTDATE ( #PCDATA ) >

<!ELEMENT ACTIVE ( #PCDATA ) >
*END*

	my $good = {
		"#stripspaces" => 7,
		LOCALE => "no content by ID",
		Locales => "no content",
		"ACTIVE,CODE,LONGDATE,NAME,SHORTDATE" => "content",
	};
	my $got = XML::Rules::inferRulesFromDTD( $DTD);

#	pp($got);

	is_deeply( $got, $good, "rules as expected");
}


{
	my $DTD = <<'*END*';
<!ELEMENT InputFields ( FIELD+ ) >

<!ELEMENT FIELD ( BASICVALIDATION?, BASICVALIDATIONPARAM? , EDITSTYLE, FIELDLENGTH,
	FIELDNOTES?, FIELDTITLE, PULLDOWN*, RETAINVALUE,
	RQBASICVALIDATION?, RQSPECIFICVALIDATION?, SECTION, SEQUENCENO, SITEFIELDREQUIRED,
	SPECIFICVALIDATION?, SPECIFICVALIDATIONPARAM?, STATIC, TRANSLATE?, USERWILLSEE ) >
<!ATTLIST FIELD ID ID #REQUIRED >

<!ELEMENT BASICVALIDATION ( #PCDATA ) >

<!ELEMENT BASICVALIDATIONPARAM ( #PCDATA ) >

<!ELEMENT EDITSTYLE ( #PCDATA ) >

<!ELEMENT FIELDLENGTH ( #PCDATA ) >

<!ELEMENT FIELDNOTES ( #PCDATA ) >

<!ELEMENT FIELDTITLE ( #PCDATA ) >

<!ELEMENT RETAINVALUE ( #PCDATA ) >

<!ELEMENT RQBASICVALIDATION ( #PCDATA ) >

<!ELEMENT RQSPECIFICVALIDATION ( #PCDATA ) >

<!ELEMENT SECTION ( #PCDATA ) >

<!ELEMENT SEQUENCENO ( #PCDATA ) >

<!ELEMENT SITEFIELDREQUIRED ( #PCDATA ) >

<!ELEMENT SPECIFICVALIDATION ( #PCDATA ) >

<!ELEMENT SPECIFICVALIDATIONPARAM ( #PCDATA ) >

<!ELEMENT STATIC ( #PCDATA ) >

<!ELEMENT TRANSLATE ( LOCALE+ ) >

<!ELEMENT USERWILLSEE ( #PCDATA ) >

<!ELEMENT LOCALE ( USERWILLSEE?, DESC?, FIELDNOTES? ) >
<!ATTLIST LOCALE ID NMTOKEN #REQUIRED >

<!ELEMENT PULLDOWN ( VALUE, DESC, TRANSLATE? ) >
<!ATTLIST PULLDOWN ID ID #REQUIRED >

<!ELEMENT VALUE ( #PCDATA ) >

<!ELEMENT DESC ( #PCDATA ) >
*END*

	my $good = {
		"#stripspaces" => 7,
		"BASICVALIDATION,BASICVALIDATIONPARAM,DESC,EDITSTYLE,FIELDLENGTH,FIELDNOTES,FIELDTITLE,RETAINVALUE,"
		. "RQBASICVALIDATION,RQSPECIFICVALIDATION,SECTION,SEQUENCENO,SITEFIELDREQUIRED,SPECIFICVALIDATION,"
		. "SPECIFICVALIDATIONPARAM,STATIC,USERWILLSEE,VALUE" => "content",
		"LOCALE" => "as array no content",
		"InputFields,TRANSLATE" => "no content",
		"FIELD,PULLDOWN" => 'no content by ID',
	};

	my $got = XML::Rules::inferRulesFromDTD( $DTD);

#	pp($got);

	is_deeply( $got, $good, "rules as expected");
}

{
	my $DTD = <<'*END*';
<!ELEMENT Jobs (Job+)>

<!ELEMENT Job (Text,Foo?)>
<!ATTLIST Job ID CDATA #REQUIRED>

<!ELEMENT Text (#PCDATA)>

<!ELEMENT Foo (Bar)>
<!ELEMENT Bar (#PCDATA)>
<!ATTLIST Bar whatever CDATA #REQUIRED>
*END*

	my $good = {
		"#stripspaces" => 7,
		Bar => "as is",
		Job => "as array no content",
		"Foo,Jobs" => "no content",
		Text => "content",
	};

	my $got = XML::Rules::inferRulesFromDTD( $DTD);

#	pp($got);

	is_deeply( $got, $good, "rules as expected");
}

{
	my $DTD = <<'*END*';
<!ELEMENT wddxPacket (header, data)>
<!ATTLIST wddxPacket version CDATA #FIXED "1.0">

<!ELEMENT header (#PCDATA)>

<!ELEMENT data (recordset+)>

<!ELEMENT recordset (field+)>
<!ATTLIST recordset rowCount CDATA #REQUIRED fieldNames CDATA "ad_name,industry_sector,category,company_name,jobposition,location_city,location_state,location_state2,location_state_region,location_country,location_country2,location_zip,work_frequency,job_type,where_work,start,job_duration,comp_type,bf,bt,bi,cf,ct,ci,tf,tt,benefits_id,travel,paid_relocation,description,required_edu,required_exp,entry_level,qualifications,contact_name,contact_email,contact_phone,contact_ext,contact_fax,contact_address1,contact_address2,contact_city,contact_state,contact_state2,contact_zip,contact_country,contact_country2,contact_method,special_instructions">

<!ELEMENT field (string)>
<!ATTLIST field name CDATA #REQUIRED>
<!--#info element=field repeat_set="name" repeat_list="ad_name,industry_sector,category,company_name,jobposition,location_city,location_state,location_state2,location_state_region,location_country,location_country2,location_zip,work_frequency,job_type,where_work,start,job_duration,comp_type,bf,bt,bi,cf,ct,ci,tf,tt,benefits_id,travel,paid_relocation,description,required_edu,required_exp,entry_level,qualifications,contact_name,contact_email,contact_phone,contact_ext,contact_fax,contact_address1,contact_address2,contact_city,contact_state,contact_state2,contact_zip,contact_country,contact_country2,contact_method,special_instructions"-->
<!--#info element=field attribute=name foo=bar-->

<!ELEMENT string (#PCDATA)>
*END*

	my $good = {
		"#stripspaces"    => 7,
		"data,wddxPacket" => "no content",
		"field,recordset" => "as array no content",
		"header,string"   => "content",
	};

	my $got = XML::Rules::inferRulesFromDTD( $DTD);

#	pp($got);

	is_deeply( $got, $good, "rules as expected");
}

{
	my $DTD = <<'*END*';
<?xml version="1.0" encoding="UTF-8"?>
<!ELEMENT JobPositionPosting (JobPositionPostingId*, HiringOrg+, PostDetail?, JobPositionInformation, HowToApply+, EEOStatement?, NumberToFill?, ProcurementInformation?)>
<!ATTLIST JobPositionPosting
	status (active | inactive) #IMPLIED
>
<!ELEMENT SummaryText (#PCDATA | Link)*>
<!ELEMENT P (#PCDATA | Link | Qualification | Img)*>
<!ELEMENT UL (LI+)>
<!ELEMENT LI (#PCDATA | Link | Qualification)*>
<!ELEMENT Link (#PCDATA)>
<!ATTLIST Link
	linkEnd CDATA #IMPLIED
	mailTo CDATA #IMPLIED
	idRef IDREF #IMPLIED
>
<!ELEMENT Img EMPTY>
<!ATTLIST Img
	src CDATA #REQUIRED
	width CDATA #IMPLIED
	height CDATA #IMPLIED
	alt CDATA #IMPLIED
	mediaType CDATA #IMPLIED
>
<!ELEMENT JobPositionLocation (PostalAddress | LocationSummary | SummaryText)>
<!ELEMENT LocationSummary (Municipality?, Region*, CountryCode?, PostalCode?)>
<!ELEMENT Qualification (#PCDATA)>
<!ATTLIST Qualification
	type (skill | experience | education | license | certification | equipment | other) #IMPLIED
	description CDATA #IMPLIED
	yearsOfExperience CDATA #IMPLIED
	level (1 | 2 | 3 | 4 | 5) #IMPLIED
	interest (1 | 2 | 3 | 4 | 5) #IMPLIED
	yearLastUsed CDATA #IMPLIED
	source CDATA #IMPLIED
	category CDATA #IMPLIED
>
<!ELEMENT Date (#PCDATA)>
<!ELEMENT StartDate (Date)>
<!ELEMENT EndDate ((Date | CurrentFlag), SummaryText?)>
<!ELEMENT CurrentFlag EMPTY>
<!ELEMENT PostalAddress (CountryCode, PostalCode?, Region*, Municipality?, DeliveryAddress?, Recipient*)>
<!ATTLIST PostalAddress
	type (postOfficeBoxAddress | streetAddress | militaryAddress | undefined) "undefined"
>
<!ELEMENT PostalCode (#PCDATA)>
<!ELEMENT CountryCode (#PCDATA)>
<!ELEMENT Region (#PCDATA)>
<!ELEMENT Municipality (#PCDATA)>
<!ELEMENT DeliveryAddress (AddressLine*, StreetName?, BuildingNumber?, Unit?, PostOfficeBox?)>
<!ELEMENT AddressLine (#PCDATA)>
<!ELEMENT StreetName (#PCDATA)>
<!ELEMENT BuildingNumber (#PCDATA)>
<!ELEMENT Unit (#PCDATA)>
<!ELEMENT PostOfficeBox (#PCDATA)>
<!ELEMENT Recipient (PersonName?, AdditionalText*, Organization?, OrganizationName?)>
<!ELEMENT AdditionalText (#PCDATA)>
<!ELEMENT Organization (#PCDATA)>
<!ELEMENT OrganizationName (#PCDATA)>
<!ELEMENT PersonName (FormattedName*, LegalName?, GivenName*, PreferredGivenName?, MiddleName?, FamilyName*, Affix*)>
<!ELEMENT FormattedName (#PCDATA)>
<!ATTLIST FormattedName
	type (presentation | legal | sortOrder) "presentation"
>
<!ELEMENT LegalName (#PCDATA)>
<!ELEMENT GivenName (#PCDATA)>
<!ELEMENT PreferredGivenName (#PCDATA)>
<!ELEMENT MiddleName (#PCDATA)>
<!ELEMENT FamilyName (#PCDATA)>
<!ATTLIST FamilyName
	primary (true | false | undefined) "undefined"
	prefix CDATA #IMPLIED
>
<!ELEMENT Affix (#PCDATA)>
<!ATTLIST Affix
	type (academicGrade | aristocraticPrefix | aristocraticTitle | familyNamePrefix | familyNameSuffix | formOfAddress | generation | qualification) #REQUIRED
>
<!ELEMENT PositionTitle (#PCDATA)>
<!ELEMENT JobPositionTitle (#PCDATA)>
<!ELEMENT CompensationDescription (Pay?, BenefitsDescription?, SummaryText?)>
<!ELEMENT Pay ((((RatePerHour | RatePerDay | SalaryAnnual | SalaryMonthly)+ | SummaryText), Bonus*, RelocationAmount?, ExpensesAccepted?))>
<!ELEMENT BenefitsDescription (P | UL)*>
<!ELEMENT RatePerHour (#PCDATA)>
<!ATTLIST RatePerHour
	currency CDATA #REQUIRED
>
<!ELEMENT RatePerDay (#PCDATA)>
<!ATTLIST RatePerDay
	currency CDATA #REQUIRED
>
<!ELEMENT SalaryAnnual (#PCDATA)>
<!ATTLIST SalaryAnnual
	currency CDATA #REQUIRED
>
<!ELEMENT SalaryMonthly (#PCDATA)>
<!ATTLIST SalaryMonthly
	currency CDATA #REQUIRED
>
<!ELEMENT PostDetail (StartDate, EndDate?, PostedBy?)>
<!ELEMENT PostedBy (Contact)>
<!ELEMENT Contact (PersonName?, PositionTitle?, PostalAddress*, (VoiceNumber | FaxNumber | PagerNumber | TTDNumber)*, E-mail*, WebSite*)>
<!ATTLIST Contact
	type CDATA #IMPLIED
>
<!ELEMENT E-mail (#PCDATA)>
<!ELEMENT WebSite (#PCDATA)>
<!ELEMENT URL (#PCDATA)>
<!ELEMENT HiringOrg (HiringOrgName, HiringOrgId*, WebSite?, Industry?, Contact*, OrganizationalUnit*)>
<!ATTLIST HiringOrg
	type (agent | principal | unspecified) "unspecified"
>
<!ELEMENT HiringOrgName (#PCDATA)>
<!ELEMENT HiringOrgId (#PCDATA)>
<!ATTLIST HiringOrgId
	idOwner CDATA #IMPLIED
>
<!ELEMENT NAICS (#PCDATA)>
<!ATTLIST NAICS
	primaryIndicator (primary | secondary | unknown) "primary"
>
<!ELEMENT Industry (NAICS | SummaryText)*>
<!ELEMENT JobPositionInformation (JobPositionTitle, JobPositionDescription?, JobPositionRequirements)>
<!ELEMENT JobPositionDescription (JobPositionPurpose?, JobPositionLocation*, Classification?, EssentialFunctions?, WorkEnvironment?, CompensationDescription?, SummaryText?)>
<!ELEMENT JobPositionRequirements (QualificationsRequired?, QualificationsPreferred?, TravelRequired?, WorkEligibilityStatus?, SummaryText?)>
<!ELEMENT TravelRequired (PercentageOfTime?, SummaryText?)>
<!ELEMENT JobPositionPurpose (#PCDATA)>
<!ELEMENT WorkEnvironment (P | UL | Qualification)+>
<!ELEMENT QualificationsPreferred (P | UL | Qualification)+>
<!ELEMENT EssentialFunctions (P | UL | Qualification)+>
<!ELEMENT QualificationsRequired (P | UL | Qualification)+>
<!ELEMENT WorkEligibilityStatus (#PCDATA)>
<!ELEMENT PercentageOfTime (#PCDATA)>
<!ELEMENT Classification (DirectHireOrContract?, Schedule?, Duration?, OTStatus?)>
<!ATTLIST Classification
	distribute (external | internal) "external"
>
<!ELEMENT DirectHireOrContract ((DirectHire | Contract | Temp | TempToPerm)?, SummaryText?)>
<!ELEMENT OTStatus ((Exempt | NonExempt)?, SummaryText?)>
<!ELEMENT Schedule ((FullTime | PartTime)?, ShiftDifferential?, SummaryText?)>
<!ELEMENT Duration ((Temporary | Regular)?, SummaryText?)>
<!ELEMENT Exempt EMPTY>
<!ELEMENT NonExempt EMPTY>
<!ELEMENT DirectHire EMPTY>
<!ELEMENT Contract EMPTY>
<!ELEMENT FullTime (HoursPerWeek?, DayOfWeek*, SummaryText?)>
<!ELEMENT PartTime (HoursPerWeek?, DayOfWeek*, SummaryText?)>
<!ELEMENT HoursPerWeek (#PCDATA)>
<!ELEMENT Temporary (TermLength?, SummaryText?)>
<!ELEMENT TermLength (#PCDATA)>
<!ELEMENT Regular EMPTY>
<!ELEMENT VoiceNumber (IntlCode?, AreaCode?, TelNumber, Extension?)>
<!ATTLIST VoiceNumber
	type (primary | secondary) #IMPLIED
	label CDATA #IMPLIED
>
<!ELEMENT FaxNumber (IntlCode?, AreaCode?, TelNumber, Extension?)>
<!ATTLIST FaxNumber
	type (primary | secondary) #IMPLIED
	label CDATA #IMPLIED
>
<!ELEMENT PagerNumber (IntlCode?, AreaCode?, TelNumber, Extension?)>
<!ATTLIST PagerNumber
	type (primary | secondary) #IMPLIED
	label CDATA #IMPLIED
>
<!ELEMENT TTDNumber (IntlCode?, AreaCode?, TelNumber, Extension?)>
<!ATTLIST TTDNumber
	type (primary | secondary) #IMPLIED
	label CDATA #IMPLIED
>
<!ELEMENT IntlCode (#PCDATA)>
<!ELEMENT AreaCode (#PCDATA)>
<!ELEMENT TelNumber (#PCDATA)>
<!ELEMENT Extension (#PCDATA)>
<!ELEMENT HowToApply (ApplicationMethods?, SummaryText?)>
<!ATTLIST HowToApply
	distribute (external | internal) "external"
>
<!ELEMENT ApplicationMethods (ByPhone | ByFax | ByEmail | ByWeb | InPerson | ByMail)*>
<!ELEMENT ByPhone (PersonName?, VoiceNumber, TTDNumber?, SummaryText?)>
<!ELEMENT ByFax (PersonName?, FaxNumber?, SummaryText?)>
<!ELEMENT ByEmail (PersonName?, E-mail?, SummaryText?)>
<!ELEMENT ByWeb (PersonName?, URL?, SummaryText?)>
<!ELEMENT InPerson (PersonName?, PostalAddress?, VoiceNumber?, TTDNumber?, SummaryText?)>
<!ELEMENT JobPositionPostingId (#PCDATA)>
<!ATTLIST JobPositionPostingId
	idOwner CDATA #IMPLIED
>
<!ELEMENT EEOStatement (#PCDATA)>
<!ELEMENT NumberToFill (#PCDATA)>
<!ELEMENT ByMail (PostalAddress?, SummaryText?)>
<!ELEMENT RelocationAmount (#PCDATA)>
<!ATTLIST RelocationAmount
	currency CDATA #REQUIRED
>
<!ELEMENT ProcurementInformation (BillRate?, AssignmentStartDate?, AssignmentEndDate?, ReportingData*)>
<!ELEMENT BillRate (FlatFee | Percentage | Rate)>
<!ELEMENT AssignmentEndDate (Date)>
<!ELEMENT FlatFee (#PCDATA)>
<!ATTLIST FlatFee
	currency CDATA #REQUIRED
>
<!ELEMENT Percentage (#PCDATA)>
<!ELEMENT Rate (#PCDATA)>
<!ATTLIST Rate
	unit CDATA #IMPLIED
	currency CDATA #REQUIRED
>
<!ELEMENT DayOfWeek (StartTime, EndTime)>
<!ATTLIST DayOfWeek
	day (1 | 2 | 3 | 4 | 5 | 6 | 7) #REQUIRED
>
<!ELEMENT StartTime (#PCDATA)>
<!ELEMENT EndTime (#PCDATA)>
<!ELEMENT ShiftDifferential (#PCDATA)>
<!ELEMENT TempToPerm EMPTY>
<!ELEMENT ReportingData (#PCDATA)>
<!ATTLIST ReportingData
	type CDATA #IMPLIED
>
<!ELEMENT Bonus (#PCDATA)>
<!ATTLIST Bonus
	frequency CDATA #IMPLIED
	range (true | false) "false"
	currency CDATA #REQUIRED
>
<!ELEMENT Temp EMPTY>
<!ELEMENT OrganizationalUnit (Description*)>
<!ATTLIST OrganizationalUnit
	type CDATA #IMPLIED
>
<!ELEMENT Description (#PCDATA)>
<!ELEMENT AssignmentStartDate (Date)>
<!ELEMENT ExpensesAccepted EMPTY>
*END*

	my $good = {
		"#stripspaces" => 0,
		'ApplicationMethods,AssignmentEndDate,AssignmentStartDate,BenefitsDescription,BillRate,Classification,CompensationDescription,'
		. 'DeliveryAddress,DirectHireOrContract,Duration,EndDate,EssentialFunctions,FullTime,Industry,JobPositionDescription,'
		. 'JobPositionInformation,JobPositionPosting,JobPositionRequirements,LocationSummary,OTStatus,PartTime,Pay,PersonName,'
		. 'PostDetail,PostedBy,ProcurementInformation,QualificationsPreferred,QualificationsRequired,Schedule,StartDate,'
		. 'Temporary,TravelRequired,WorkEnvironment' => "no content",
		"Affix,Bonus,FamilyName,FormattedName,HiringOrgId,JobPositionPostingId,LI,NAICS,P,RatePerDay,RatePerHour,ReportingData,"
		. "SalaryAnnual,SalaryMonthly" => "as array",
		"AreaCode,BuildingNumber,Contract,CountryCode,CurrentFlag,Date,DirectHire,E-mail,EEOStatement,EndTime,Exempt,"
		. "ExpensesAccepted,Extension,HiringOrgName,HoursPerWeek,IntlCode,JobPositionPurpose,JobPositionTitle,"
		. "LegalName,MiddleName,Municipality,NonExempt,NumberToFill,Organization,OrganizationName,Percentage,"
		. "PercentageOfTime,PositionTitle,PostOfficeBox,PostalCode,PreferredGivenName,Regular,ShiftDifferential,"
		. "StartTime,StreetName,TelNumber,Temp,TempToPerm,TermLength,URL,Unit,WorkEligibilityStatus" => "content",
		"Img,Link,Qualification" => "raw",
		"FlatFee,Rate,RelocationAmount,SummaryText" => "as is",
		"ByEmail,ByFax,ByMail,ByPhone,ByWeb,Contact,DayOfWeek,FaxNumber,HiringOrg,HowToApply,InPerson,JobPositionLocation,"
		. "OrganizationalUnit,PagerNumber,PostalAddress,Recipient,TTDNumber,UL,VoiceNumber" => "as array no content",
		"AdditionalText,AddressLine,Description,GivenName,Region,WebSite" => "content array",
	};

	my $got = XML::Rules::inferRulesFromDTD( $DTD);

#	pp($got);

	is_deeply( $got, $good, "rules as expected");
}
}