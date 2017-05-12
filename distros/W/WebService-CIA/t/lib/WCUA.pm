package WCUA;
use strict;
use warnings;
use HTTP::Response;
use base qw( LWP::UserAgent );

sub get {
    my ( $self, $url ) = @_;
    if ( $url =~ /uk\.html$/ ) {
        my $content = join "", <DATA>;
        return HTTP::Response->new( 200, "OK", undef, $content );
    } else {
        return HTTP::Response->new( 404, "Meh" );
    }
}

1;

__DATA__
<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->


<html>
<head>
<title>CIA - The World Factbook -- United Kingdom</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">


<link rel="stylesheet" href="../Factbook.css" type="text/css">
<!--
a {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #000000; text-decoration: none}
-->
</style>

</head>
<body bgcolor="#FFFFFF" text="#000000">


<div align="center">&nbsp; </div>

<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">
  <tr>
    <td colspan="3" align="center"> <div align="left"><a href="../countrylisting.html" class="Normal">Country
        List</a> | <a href="../index.html" class="Normal">World Factbook Home</a></div></td>
  </tr>

  <tr bgcolor="#CCCCCC">
    <td colspan="3" class="Banner" align="center">The World Factbook</td>
  </tr>
  <tr bgcolor="#CCCCCC">
    <td width="24%" align="center"> <img src="../graphics/text_cia_seal.jpg" width="58" height="58" alt="CIA Seal" border="0">
      &nbsp;<img src="../graphics/text_wfb_seal.jpg" width="58" height="58" alt="World Factbook Seal" border="0">
    </td>
    <td width="52%" align="center"> <font face="Verdana, Arial, Helvetica, sans-serif" color="#000000">
      <b> United Kingdom </b> </font> </td>

    <td width="24%" align="center">



	  		<div align="center"><font face="Verdana, Arial, Helvetica, sans-serif">
      		<img border="0"  src="../flags/uk-flag.gif" alt="Flag of United Kingdom">

    </td>
  </tr>
</table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">
  <tr>
		<td colspan="2">
			<center>
			<img src="../maps/uk-map.gif" alt="Map of United Kingdom">

			</center>
		</td>
	</tr>
</table>








<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->

<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Introduction</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>
          </tr>

        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Background:</div>
		</td>
		<td valign="top" bgcolor="#FFFFFF" width="80%">


			As the dominant industrial and maritime power of the 19th century, the United Kingdom of Great Britain and Ireland played a leading role in developing parliamentary democracy and in advancing literature and science. At its zenith, the British Empire stretched over one-fourth of the earth's surface. The first half of the 20th century saw the UK's strength seriously depleted in two World Wars and the Irish republic withdraw from the union. The second half witnessed the dismantling of the Empire and the UK rebuilding itself into a modern and prosperous European nation. As one of five permanent members of the UN Security Council, a founding member of NATO, and of the Commonwealth, the UK pursues a global approach to foreign policy; it currently is weighing the degree of its integration with continental Europe. A member of the EU, it chose to remain outside the Economic and Monetary Union for the time being. Constitutional reform is also a significant issue in the UK. The Scottish Parliament, the National Assembly for Wales, and the Northern Ireland Assembly were established in 1999, but the latter was suspended until May 2007 due to wrangling over the peace process.

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Geography</td>

            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>
          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">

			<div align="right">Location:</div>
		</td>
		<td valign="top" bgcolor="#FFFFFF" width="80%">

			Western Europe, islands including the northern one-sixth of the island of Ireland between the North Atlantic Ocean and the North Sea, northwest of France
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Geographic coordinates:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				54 00 N, 2 00 W
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Map references:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Europe
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Area:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">



					<i>total:</i> 244,820 sq km
			<br><i>land:</i> 241,590 sq km
			<br><i>water:</i> 3,230 sq km
			<br><i>note:</i> includes Rockall and Shetland Islands
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Area - comparative:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				slightly smaller than Oregon
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Land boundaries:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 360 km
			<br><i>border countries:</i> Ireland 360 km
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Coastline:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				12,429 km
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Maritime claims:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>territorial sea:</i> 12 nm
			<br><i>exclusive fishing zone:</i> 200 nm
			<br><i>continental shelf:</i> as defined in continental shelf orders or in accordance with agreed upon boundaries
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Climate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				temperate; moderated by prevailing southwest winds over the North Atlantic Current; more than one-half of the days are overcast
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Terrain:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				mostly rugged hills and low mountains; level to rolling plains in east and southeast
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Elevation extremes:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>lowest point:</i> The Fens -4 m
			<br><i>highest point:</i> Ben Nevis 1,343 m
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural resources:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				coal, petroleum, natural gas, iron ore, lead, zinc, gold, tin, limestone, salt, clay, chalk, gypsum, potash, silica sand, slate, arable land
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Land use:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>arable land:</i> 23.23%
			<br><i>permanent crops:</i> 0.2%
			<br><i>other:</i> 76.57% (2005)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Irrigated land:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				1,700 sq km (2003)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Total renewable water resources:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				160.6 cu km (2005)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Freshwater withdrawal (domestic/industrial/agricultural):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>Total:</i> 11.75  cu km/yr (22%/75%/3%)
			<br><i>Per capita:</i> 197  cu m/yr (1994)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural hazards:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				winter windstorms; floods
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Environment - current issues:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				continues to reduce greenhouse gas emissions (has met Kyoto Protocol target of a 12.5% reduction from 1990 levels and intends to meet the legally binding target and move toward a domestic goal of a 20% cut in emissions by 2010); by 2005 the government reduced the amount of industrial and commercial waste disposed of in landfill sites to 85% of 1998 levels and recycled or composted at least 25% of household waste, increasing to 33% by 2015
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Environment - international agreements:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>party to:</i> Air Pollution, Air Pollution-Nitrogen Oxides, Air Pollution-Persistent Organic Pollutants, Air Pollution-Sulfur 94, Air Pollution-Volatile Organic Compounds, Antarctic-Environmental Protocol, Antarctic-Marine Living Resources, Antarctic Seals, Antarctic Treaty, Biodiversity, Climate Change, Climate Change-Kyoto Protocol, Desertification, Endangered Species, Environmental Modification, Hazardous Wastes, Law of the Sea, Marine Dumping, Marine Life Conservation, Ozone Layer Protection, Ship Pollution, Tropical Timber 83, Tropical Timber 94, Wetlands, Whaling
			<br><i>signed, but not ratified:</i> none of the selected agreements
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Geography - note:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				lies near vital North Atlantic sea lanes; only 35 km from France and linked by tunnel under the English Channel; because of heavily indented coastline, no location is more than 125 km from tidal waters

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->

<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">People</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>

          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Population:</div>
		</td>

		<td valign="top" bgcolor="#FFFFFF" width="80%">

			60,776,238 (July 2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Age structure:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">



					<i>0-14 years:</i> 17.2% (male 5,349,053/female 5,095,837)
			<br><i>15-64 years:</i> 67% (male 20,605,031/female 20,104,313)
			<br><i>65 years and over:</i> 15.8% (male 4,123,464/female 5,498,540) (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Median age:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 39.6 years
			<br><i>male:</i> 38.5 years
			<br><i>female:</i> 40.7 years (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Population growth rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				0.275% (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Birth rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				10.67 births/1,000 population (2007 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Death rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				10.09 deaths/1,000 population (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Net migration rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				2.17 migrant(s)/1,000 population (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Sex ratio:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>at birth:</i> 1.05 male(s)/female
			<br><i>under 15 years:</i> 1.05 male(s)/female
			<br><i>15-64 years:</i> 1.025 male(s)/female
			<br><i>65 years and over:</i> 0.75 male(s)/female
			<br><i>total population:</i> 0.98 male(s)/female (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Infant mortality rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 5.01 deaths/1,000 live births
			<br><i>male:</i> 5.58 deaths/1,000 live births
			<br><i>female:</i> 4.4 deaths/1,000 live births (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Life expectancy at birth:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total population:</i> 78.7 years
			<br><i>male:</i> 76.23 years
			<br><i>female:</i> 81.3 years (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Total fertility rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				1.66 children born/woman (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">HIV/AIDS - adult prevalence rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				0.2% (2001 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">HIV/AIDS - people living with HIV/AIDS:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				51,000 (2001 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">HIV/AIDS - deaths:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				less than 500 (2003 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Nationality:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>noun:</i> Briton(s), British (collective plural)
			<br><i>adjective:</i> British
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Ethnic groups:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				white (of which English 83.6%, Scottish 8.6%, Welsh 4.9%, Northern Irish 2.9%) 92.1%, black 2%, Indian 1.8%, Pakistani 1.3%, mixed 1.2%, other 1.6% (2001 census)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Religions:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Christian (Anglican, Roman Catholic, Presbyterian, Methodist) 71.6%, Muslim 2.7%, Hindu 1%, other 1.6%, unspecified or none 23.1% (2001 census)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Languages:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				English, Welsh (about 26% of the population of Wales), Scottish form of Gaelic (about 60,000 in Scotland)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Literacy:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">



					<i>definition:</i> age 15 and over has completed five or more years of schooling
			<br><i>total population:</i> 99%
			<br><i>male:</i> 99%
			<br><i>female:</i> 99% (2003 est.)

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->

<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Government</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>
          </tr>

        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Country name:</div>
		</td>
		<td valign="top" bgcolor="#FFFFFF" width="80%">



				<i>conventional long form:</i> United Kingdom of Great Britain and Northern Ireland; note - Great Britain includes England, Scotland, and Wales
			<br><i>conventional short form:</i> United Kingdom
			<br><i>abbreviation:</i> UK
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Government type:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				constitutional monarchy
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Capital:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>name:</i> London
			<br><i>geographic coordinates:</i> 51 30 N, 0 10 W
			<br><i>time difference:</i> UTC 0 (5 hours ahead of Washington, DC during Standard Time)
			<br><i>daylight saving time:</i> +1hr, begins last Sunday in March; ends last Sunday in October
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Administrative divisions:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>England:</i> 34 two-tier counties, 32 London boroughs and 1 City of London or Greater London, 36 metropolitan counties, 46 unitary authorities
			<br><i>two-tier counties:</i> Bedfordshire, Buckinghamshire, Cambridgeshire, Cheshire, Cornwall and Isles of Scilly, Cumbria, Derbyshire, Devon, Dorset, Durham, East Sussex, Essex, Gloucestershire, Hampshire, Hertfordshire, Kent, Lancashire, Leicestershire, Lincolnshire, Norfolk, North Yorkshire, Northamptonshire, Northumberland, Nottinghamshire, Oxfordshire, Shropshire, Somerset, Staffordshire, Suffolk, Surrey, Warwickshire, West Sussex, Wiltshire, Worcestershire
			<br><i>London boroughs and City of London or Greater London:</i> Barking and Dagenham, Barnet, Bexley, Brent, Bromley, Camden, Croydon, Ealing, Enfield, Greenwich, Hackney, Hammersmith and Fulham, Haringey, Harrow, Havering, Hillingdon, Hounslow, Islington, Kensington and Chelsea, Kingston upon Thames, Lambeth, Lewisham, City of London, Merton, Newham, Redbridge, Richmond upon Thames, Southwark, Sutton, Tower Hamlets, Waltham Forest, Wandsworth, Westminster
			<br><i>metropolitan counties:</i> Barnsley, Birmingham, Bolton, Bradford, Bury, Calderdale, Coventry, Doncaster, Dudley, Gateshead, Kirklees, Knowlsey, Leeds, Liverpool, Manchester, Newcastle upon Tyne, North Tyneside, Oldham, Rochdale, Rotherham, Salford, Sandwell, Sefton, Sheffield, Solihull, South Tyneside, St. Helens, Stockport, Sunderland, Tameside, Trafford, Wakefield, Walsall, Wigan, Wirral, Wolverhampton


			<br><i>unitary authorities:</i> Bath and North East Somerset, Blackburn with Darwen, Blackpool, Bournemouth, Bracknell Forest, Brighton and Hove, City of Bristol, Darlington, Derby, East Riding of Yorkshire, Halton, Hartlepool, County of Herefordshire, Ile of Wight, City of Kingston upon Hull, Leicester, Luton, Medway, Middlesbrough, Milton Keynes, North East Lincolnshire, North Lincolnshire, North Somerset, Nottingham, Peterborough, Plymouth, Poole, Portsmouth, Reading, Redcar and Cleveland, Rutland, Slough, South Gloucestershire, Southampton, Southend-on-Sea, Stockton-on-Tees, Stoke-on-Trent, Swindon, Telford and Wrekin, Thurrock, Torbay, Warrington, West Berkshire, Windsor and Maidenhead, Wokingham, York
			<br><i>Northern Ireland:</i> 26 district council areas
			<br><i>district council areas:</i> Antrim, Ards, Armagh, Ballymena, Ballymoney, Banbridge, Belfast, Carrickfergus, Castlereagh, Coleraine, Cookstown, Craigavon, Derry, Down, Dungannon, Fermanagh, Larne, Limavady, Lisburn, Magherafelt, Moyle, Newry and Mourne, Newtownabbey, North Down, Omagh, Strabane
			<br><i>Scotland:</i> 32 unitary authorities
			<br><i>unitary authorities:</i> Aberdeen City, Aberdeenshire, Angus, Argyll and Bute, Clackmannanshire, Dumfries and Galloway, Dundee City, East Ayrshire, East Dunbartonshire, East Lothian, East Renfrewshire, City of Edinburgh, Eilean Siar (Western Isles), Falkirk, Fife, Glasgow City, Highland, Inverclyde, Midlothian, Moray, North Ayrshire, North Lanarkshire, Orkney Islands, Perth and Kinross, Renfrewshire, Shetland Islands, South Ayrshire, South Lanarkshire, Stirling, The Scottish Borders, West Dunbartonshire, West Lothian
			<br><i>Wales:</i> 22 unitary authorities
			<br><i>unitary authorities:</i> Blaenau Gwent; Bridgend; Caerphilly; Cardiff; Carmarthenshire; Ceredigion; Conwy; Denbighshire; Flintshire; Gwynedd; Isle of Anglesey; Merthyr Tydfil; Monmouthshire; Neath Port Talbot; Newport; Pembrokeshire; Powys; Rhondda, Cynon, Taff; Swansea; The Vale of Glamorgan; Torfaen; Wrexham
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Dependent areas:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Anguilla, Bermuda, British Indian Ocean Territory, British Virgin Islands, Cayman Islands, Falkland Islands, Gibraltar, Montserrat, Pitcairn Islands, Saint Helena, South Georgia and the South Sandwich Islands, Turks and Caicos Islands
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Independence:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				England has existed as a unified entity since the 10th century; the union between England and Wales, begun in 1284 with the Statute of Rhuddlan, was not formalized until 1536 with an Act of Union; in another Act of Union in 1707, England and Scotland agreed to permanently join as Great Britain; the legislative union of Great Britain and Ireland was implemented in 1801, with the adoption of the name the United Kingdom of Great Britain and Ireland; the Anglo-Irish treaty of 1921 formalized a partition of Ireland; six northern Irish counties remained part of the United Kingdom as Northern Ireland and the current name of the country, the United Kingdom of Great Britain and Northern Ireland, was adopted in 1927
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">National holiday:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				the UK does not celebrate one particular national holiday
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Constitution:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				unwritten; partly statutes, partly common law and practice
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Legal system:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				based on common law tradition with early Roman and modern continental influences; has nonbinding judicial review of Acts of Parliament under the Human Rights Act of 1998; accepts compulsory ICJ jurisdiction, with reservations
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Suffrage:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				18 years of age; universal
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Executive branch:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">



					<i>chief of state:</i> Queen ELIZABETH II (since 6 February 1952); Heir Apparent Prince CHARLES (son of the queen, born 14 November 1948)
			<br><i>head of government:</i> Prime Minister Gordon BROWN (since 27 June 2007)
			<br><i>cabinet:</i> Cabinet of Ministers appointed by the prime minister
			<br><i>elections:</i> none; the monarchy is hereditary; following legislative elections, the leader of the majority party or the leader of the majority coalition is usually the prime minister
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Legislative branch:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				bicameral Parliament consists of House of Lords (618 seats; consisting of approximately 500 life peers, 92 hereditary peers, and 26 clergy) and House of Commons (646 seats since 2005 elections; members are elected by popular vote to serve five-year terms unless the House is dissolved earlier)
			<br><i>elections:</i> House of Lords - no elections (note - in 1999, as provided by the House of Lords Act, elections were held in the House of Lords to determine the 92 hereditary peers who would remain there; elections are held only as vacancies in the hereditary peerage arise); House of Commons - last held 5 May 2005 (next to be held by May 2010)
			<br><i>election results:</i> House of Commons - percent of vote by party - Labor 35.2%, Conservative 32.3%, Liberal Democrats 22%, other 10.5%; seats by party - Labor 355, Conservative 198, Liberal Democrat 62, other 31; seats by party in the House of Commons as of 23 November 2007 - Labor 353, Conservative 194, Liberal Democrat 63, Scottish National Party/Plaid Cymru 9, Democratic Unionist 9, Sinn Fein 5, other 14
			<br><i>note:</i> in 1998 elections were held for a Northern Ireland Assembly (because of unresolved disputes among existing parties, the transfer of power from London to Northern Ireland came only at the end of 1999 and has been suspended four times, the latest occurring in October 2002 and lasting until 8 May 2007); in 1999, the UK held the first elections for a Scottish Parliament and a Welsh Assembly, the most recent of which were held in May 2007
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Judicial branch:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				House of Lords (highest court of appeal; several Lords of Appeal in Ordinary are appointed by the monarch for life); Supreme Courts of England, Wales, and Northern Ireland (comprising the Courts of Appeal, the High Courts of Justice, and the Crown Courts); Scotland's Court of Session and Court of the Justiciary
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Political parties and leaders:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Conservative [David CAMERON]; Democratic Unionist Party (Northern Ireland) [Rev. Ian PAISLEY]; Labor Party [Gordon BROWN]; Liberal Democrats [acting leader Vince CABLE]; Party of Wales (Plaid Cymru) [Ieuan Wyn JONES]; Scottish National Party or SNP [Alex SALMOND]; Sinn Fein (Northern Ireland) [Gerry ADAMS]; Social Democratic and Labor Party or SDLP (Northern Ireland) [Mark DURKAN]; Ulster Unionist Party (Northern Ireland) [Sir Reg EMPEY]
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Political pressure groups and leaders:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Campaign for Nuclear Disarmament; Confederation of British Industry; National Farmers' Union; Trades Union Congress
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">International organization participation:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				AfDB, Arctic Council (observer), AsDB, Australia Group, BIS, C, CBSS (observer), CDB, CE, CERN, EAPC, EBRD, EIB, ESA, EU, FAO, G-5, G-7, G-8, G-10, IADB, IAEA, IBRD, ICAO, ICC, ICCt, ICRM, IDA, IEA, IFAD, IFC, IFRCS, IHO, ILO, IMF, IMO, IMSO, Interpol, IOC, IOM, IPU, ISO, ITSO, ITU, MIGA, MONUC, NATO, NEA, NSG, OAS (observer), OECD, OPCW, OSCE, Paris Club, PCA, PIF (partner), SECI (observer), UN, UN Security Council, UNCTAD, UNESCO, UNFICYP, UNHCR, UNIDO, UNMIL, UNMIS, UNMOVIC, UNOMIG, UNRWA, UNWTO, UPU, WCO, WEU, WHO, WIPO, WMO, WTO, ZC
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Diplomatic representation in the US:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>chief of mission:</i> Ambassador Sir Nigel E. SHEINWALD
			<br><i>chancery:</i> 3100 Massachusetts Avenue NW, Washington, DC 20008
			<br><i>telephone:</i> [1] (202) 588-6500
			<br><i>FAX:</i> [1] (202) 588-7870
			<br><i>consulate(s) general:</i> Atlanta, Boston, Chicago, Houston, Los Angeles, Miami, New York, San Francisco
			<br><i>consulate(s):</i> Denver, Orlando
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Diplomatic representation from the US:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>chief of mission:</i> Ambassador Robert Holmes TUTTLE
			<br><i>embassy:</i> 24 Grosvenor Square, London, W1A 1AE
			<br><i>mailing address:</i> PSC 801, Box 40, FPO AE 09498-4040
			<br><i>telephone:</i> [44] (0) 20 7499-9000
			<br><i>FAX:</i> [44] (0) 20 7629-9124
			<br><i>consulate(s) general:</i> Belfast, Edinburgh
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Flag description:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				blue field with the red cross of Saint George (patron saint of England) edged in white superimposed on the diagonal red cross of Saint Patrick (patron saint of Ireland), which is superimposed on the diagonal white cross of Saint Andrew (patron saint of Scotland); properly known as the Union Flag, but commonly called the Union Jack; the design and colors (especially the Blue Ensign) have been the basis for a number of other flags including other Commonwealth countries and their constituent states or provinces, and British overseas territories

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->

<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Economy</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>

          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Economy - overview:</div>
		</td>

		<td valign="top" bgcolor="#FFFFFF" width="80%">

			The UK, a leading trading power and financial center, is one of the quintet of trillion dollar economies of Western Europe. Over the past two decades, the government has greatly reduced public ownership and contained the growth of social welfare programs. Agriculture is intensive, highly mechanized, and efficient by European standards, producing about 60% of food needs with less than 2% of the labor force. The UK has large coal, natural gas, and oil reserves; primary energy production accounts for 10% of GDP, one of the highest shares of any industrial nation. Services, particularly banking, insurance, and business services, account by far for the largest proportion of GDP while industry continues to decline in importance. Since emerging from recession in 1992, Britain's economy has enjoyed the longest period of expansion on record; growth has remained in the 2-3% range since 2004, outpacing most of Europe. The economy's strength has complicated the Labor government's efforts to make a case for Britain to join the European Economic and Monetary Union (EMU). Critics point out that the economy is doing well outside of EMU, and public opinion polls show a majority of Britons are opposed to the euro. The BROWN government has been speeding up the improvement of education, health services, and affordable housing at a cost in higher taxes and a widening public deficit.
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">GDP (purchasing power parity):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				$2.147 trillion (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">GDP (official exchange rate):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$2.472 trillion (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">GDP - real growth rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				2.9% (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">GDP - per capita (PPP):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$35,300 (2007 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">GDP - composition by sector:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>agriculture:</i> 0.9%
			<br><i>industry:</i> 23.6%
			<br><i>services:</i> 75.5% (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Labor force:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				30.71 million (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Labor force - by occupation:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>agriculture:</i> 1.4%
			<br><i>industry:</i> 18.2%
			<br><i>services:</i> 80.4% (2006 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Unemployment rate:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				5.4% (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Population below poverty line:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				14% (2006 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Household income or consumption by percentage share:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>lowest 10%:</i> 2.1%
			<br><i>highest 10%:</i> 28.5% (1999)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Distribution of family income - Gini index:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				34 (2005)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Inflation rate (consumer prices):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				2.4% (2007 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Investment (gross fixed):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				18.3% of GDP (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Budget:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>revenues:</i> $1.155 trillion
			<br><i>expenditures:</i> $1.237 trillion (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Public debt:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				43.3% of GDP (2007 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Agriculture - products:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				cereals, oilseed, potatoes, vegetables; cattle, sheep, poultry; fish
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Industries:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				machine tools, electric power equipment, automation equipment, railroad equipment, shipbuilding, aircraft, motor vehicles and parts, electronics and communications equipment, metals, chemicals, coal, petroleum, paper and paper products, food processing, textiles, clothing, other consumer goods
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Industrial production growth rate:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				0.7% (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Electricity - production:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				372.6 billion kWh (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Electricity - production by source:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">



					<i>fossil fuel:</i> 73.8%
			<br><i>hydro:</i> 0.9%
			<br><i>nuclear:</i> 23.7%
			<br><i>other:</i> 1.6% (2001)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Electricity - consumption:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				348.7 billion kWh (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Electricity - exports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				2.839 billion kWh (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Electricity - imports:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				11.16 billion kWh (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Oil - production:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				1.861 million bbl/day (2005 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Oil - consumption:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				1.82 million bbl/day (2005 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Oil - exports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				1.956 million bbl/day (2004)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Oil - imports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				1.654 million bbl/day (2004)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Oil - proved reserves:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				4.029 billion bbl (1 January 2006 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural gas - production:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				84.16 billion cu m (2005 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Natural gas - consumption:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				91.16 billion cu m (2005 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural gas - exports:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				8.843 billion cu m (2005 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural gas - imports:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				15.84 billion cu m (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Natural gas - proved reserves:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				509.2 billion cu m (1 January 2006 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Current account balance:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				-$111 billion (2007 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Exports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$415.6 billion f.o.b. (2007 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Exports - commodities:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				manufactured goods, fuels, chemicals; food, beverages, tobacco
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Exports - partners:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				US 13.9%, Germany 10.9%, France 10.4%, Ireland 7.1%, Netherlands 6.3%, Belgium 5.2%, Spain 4.5% (2006)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Imports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$595.6 billion f.o.b. (2007 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Imports - partners:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Germany 12.8%, US 8.9%, France 6.9%, Netherlands 6.6%, China 5.3%, Norway 4.9%, Belgium 4.5% (2006)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Economic aid - donor:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				ODA, $10.7 billion (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Reserves of foreign exchange and gold:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				$47.04 billion (2006 est.)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Debt - external:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$10.45 trillion (30 June 2007)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Stock of direct foreign investment - at home:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$1.135 trillion (2006 est.)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Stock of direct foreign investment - abroad:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$1.487 trillion (2006 est.)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Market value of publicly traded shares:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				$3.058 trillion (2005)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Currency (code):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				British pound (GBP)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Currency code:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				GBP
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Exchange rates:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				British pounds per US dollar - 0.4993 (2007), 0.5418 (2006), 0.5493 (2005), 0.5462 (2004), 0.6125 (2003)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Fiscal year:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				6 April - 5 April

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Communications</td>

            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>
          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">

			<div align="right">Telephones - main lines in use:</div>
		</td>
		<td valign="top" bgcolor="#FFFFFF" width="80%">

			33.602 million (2006)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Telephones - mobile cellular:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				69.657 million (2006)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Telephone system:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>general assessment:</i> technologically advanced domestic and international system
			<br><i>domestic:</i> equal mix of buried cables, microwave radio relay, and fiber-optic systems
			<br><i>international:</i> country code - 44; 40 coaxial submarine cables; satellite earth stations - 10 Intelsat (7 Atlantic Ocean and 3 Indian Ocean), 1 Inmarsat (Atlantic Ocean region), and 1 Eutelsat; at least 8 large international switching centers
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Radio broadcast stations:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				AM 219, FM 431, shortwave 3 (1998)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">

				<div align="right">Radios:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				84.5 million (1997)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Television broadcast stations:</div>

			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				228 (plus 3,523 repeaters) (1995)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Televisions:</div>
			</td>

			<td valign="top" bgcolor="#FFFFFF" width="80%">

				30.5 million (1997)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Internet country code:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				.uk
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Internet hosts:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				5.118 million (2007)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Internet Service Providers (ISPs):</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				more than 400 (2000)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Internet users:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				33.534 million (2006)

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->
<!-- Type="CFDSN" -->
<!-- Catalog="" -->

<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Transportation</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>
          </tr>

        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Airports:</div>
		</td>
		<td valign="top" bgcolor="#FFFFFF" width="80%">


			449 (2007)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Airports - with paved runways:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 310
			<br><i>over 3,047 m:</i> 8
			<br><i>2,438 to 3,047 m:</i> 33
			<br><i>1,524 to 2,437 m:</i> 131
			<br><i>914 to 1,523 m:</i> 79
			<br><i>under 914 m:</i> 59 (2007)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Airports - with unpaved runways:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 139
			<br><i>2,438 to 3,047 m:</i> 1
			<br><i>1,524 to 2,437 m:</i> 2
			<br><i>914 to 1,523 m:</i> 23
			<br><i>under 914 m:</i> 113 (2007)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Heliports:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				11 (2007)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Pipelines:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				condensate 565 km; condensate/gas 6 km; gas 21,575 km; liquid petroleum gas 59 km; oil 5,094 km; oil/gas/water 161 km; refined products 4,444 km (2006)
			</td>
			</tr>
			<tr>


			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Railways:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 16,567 km
			<br><i>broad gauge:</i> 303 km 1.600-m gauge (in Northern Ireland)
			<br><i>standard gauge:</i> 16,264 km 1.435-m gauge (5,361 km electrified) (2006)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Roadways:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 388,008 km
			<br><i>paved:</i> 388,008 km (includes 3,520 km of expressways) (2005)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Waterways:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				3,200 km (620 km used for commerce) (2003)
			</td>
			</tr>

			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Merchant marine:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>total:</i> 474 ships (1000 GRT or over) 11,723,618 GRT/12,315,588 DWT
			<br><i>by type:</i> bulk carrier 26, cargo 60, carrier 4, chemical tanker 56, container 156, liquefied gas 18, passenger 10, passenger/cargo 62, petroleum tanker 27, refrigerated cargo 17, roll on/roll off 24, vehicle carrier 14
			<br><i>foreign-owned:</i> 242 (Australia 1, Cyprus 1, Denmark 61, Finland 1, France 9, Germany 71, Greece 6, Hong Kong 2, Ireland 1, Italy 4, Japan 1, Netherlands 2, NZ 1, Norway 33, South Africa 4, Sweden 19, Switzerland 1, Taiwan 11, Turkey 2, US 11)
			<br><i>registered in other countries:</i> 412 (Algeria 12, Antigua and Barbuda 4, Argentina 4, Australia 2, Bahamas 68, Barbados 3, Bermuda 20, Brunei 8, Cape Verde 1, Cayman Islands 9, Cyprus 21, Faroe Islands 1, Gibraltar 3, Greece 15, Hong Kong 32, India 1, Indonesia 3, Italy 7, South Korea 1, Liberia 74, Luxembourg 7, Malta 12, Marshall Islands 17,  Netherlands 7, Norway 9, Panama 35, Papua New Guinea 6, Singapore 13, Slovakia 1, St Vincent and The Grenadines 9, Sweden 2, Thailand 3, Tonga 1, US 1, unknown 1) (2007)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Ports and terminals:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				Dover, Felixstowe, Forth Ports, Hound Point, Immingham, Liverpool, London, Milford Haven, Southampton, Teesport

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->

<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Military</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>

          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Military branches:</div>
		</td>

		<td valign="top" bgcolor="#FFFFFF" width="80%">

			Army, Royal Navy (includes Royal Marines), Royal Air Force
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Military service age and obligation:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				16-33 years of age (officers 17-28) for voluntary military service (with parental consent under 18); women serve in military services, but are excluded from ground combat positions and some naval postings; must be citizen of the UK, Commonwealth, or Republic of Ireland; reservists serve a minimum of 3 years, to age 45 or 55 (2007)
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Manpower available for military service:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>males age 16-49:</i> 14,607,724
			<br><i>females age 16-49:</i> 14,028,738 (2005 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Manpower fit for military service:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


					<i>males age 16-49:</i> 12,046,268
			<br><i>females age 16-49:</i> 11,555,893 (2005 est.)
			</td>

			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Military expenditures - percent of GDP:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">

				2.4% (2005 est.)

</table>
<!-- FileName="Connection_cf_dsn.htm" "" -->

<!-- Type="CFDSN" -->
<!-- Catalog="" -->
<!-- Schema="" -->
<!-- HTTP="true" -->



        <table cellspacing="0" cellpadding="6" border="0" width="90%" align="center">
          <tr>
            <td align="left" valign="middle" width="20%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">Transnational Issues</td>
            <td align="left" valign="middle" width="80%" height="31" class="SectionHeadingPrint" bgcolor="#CCCCCC">United Kingdom</td>
            </td>

          </tr>
        </table>


<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">



	<tr>

		<td width="20%" valign="top" class="FieldLabel">
			<div align="right">Disputes - international:</div>
		</td>

		<td valign="top" bgcolor="#FFFFFF" width="80%">

			in 2002, Gibraltar residents voted overwhelmingly by referendum to reject any "shared sovereignty" arrangement between the UK and Spain; the Government of Gibraltar insists on equal participation in talks between the two countries; Spain disapproves of UK plans to grant Gibraltar greater autonomy; Mauritius and Seychelles claim the Chagos Archipelago (British Indian Ocean Territory), and its former inhabitants since their eviction in 1965; most Chagossians reside in Mauritius, and in 2001 were granted UK citizenship, where some have since resettled; in May 2006, the High Court of London reversed the UK Government's 2004 orders of council that banned habitation on the islands; UK rejects sovereignty talks requested by Argentina, which still claims the Falkland Islands (Islas Malvinas) and South Georgia and the South Sandwich Islands; territorial claim in Antarctica (British Antarctic Territory) overlaps Argentine claim and partially overlaps Chilean claim; Iceland, the UK, and Ireland dispute Denmark's claim that the Faroe Islands' continental shelf extends beyond 200 nm
			</td>
			</tr>
			<tr>

			<td width="20%" valign="top" class="FieldLabel">
				<div align="right">Illicit drugs:</div>
			</td>
			<td valign="top" bgcolor="#FFFFFF" width="80%">


				producer of limited amounts of synthetic drugs and synthetic precursor chemicals; major consumer of Southwest Asian heroin, Latin American cocaine, and synthetic drugs; money-laundering center


</table>



<table width="90%" border="0" cellspacing="0" cellpadding="6" align="center">
  <tr>
		<td align="center">
<!-- 			<p class="LastUpdatePrint">This page was last updated on 1 January 2003</p><br>
 -->
 			<p class="LastUpdatePrint">	This page was last updated on 17 January, 2008</p><br>
      </td>

	</tr>
</table>
<div align="center">&nbsp; </div>


</body>
</html>

