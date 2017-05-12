#!/pro/bin/perl

use strict;
use warnings;

# use POSIX qw( strftime );
use Tk;
use Tk::Clock;

my $m = MainWindow->new (-title => "World Clock");

my %TZ;
while (<DATA>) {
    if (m/^(\S+)\s+(GMT\S*)\s+(.*)$/) {
	$TZ{$1}   = [ $1, $2, undef, $3 ];
	$TZ{$2} ||= [ $1, $2, undef, $3 ];
	}
    if (m/^(.*?)(?:\s+\*)?\s+(GMT\S*)$/) {
	$TZ{$2} ||= [ $2, $2, undef, "" ];
	$TZ{$2}[2] ||= $1;
	exists $TZ{$TZ{$2}[1]} and
	    $TZ{$TZ{$2}[1]}[2] ||= $1;
	}
    }

# my $tz = strftime ("%Z", localtime);
foreach my $cd (
	[ "UCT",		"UCT",			"#ff0040"	],
	[ "Local",		$ENV{TZ}||"",		"Red"		],
	[ "London",		"Europe/London",	"OrangeRed"	],
	[ "Amsterdam",		"Europe/Amsterdam",	"Orange"	],
	[ "Moscow",		"Europe/Moscow",	"Yellow"	],
	[ "Tokyo",		"Asia/Tokyo",		"YellowGreen"	],
	[ "Los Angeles",	"America/Los_Angeles",	"Green"		],
	[ "New York",		"America/New_York",	"Turquoise"	],
	[ "Darwin",		"Australia/Darwin",	"Blue"		],
	[ "Catham",		"GMT+13:45",		"Violet"	],
	) {
    my ($city, $tz, $color) = @$cd;
    if (exists $TZ{$tz}) {
	$tz = $TZ{$tz}[1];
	$city = $TZ{$tz}[2];
	}

    my $c = $m->Clock (-background => "Black");
    $c->config (
	anaScale	=> 200,
	secsColor	=> "Green",
	tickColor	=> "Blue",
	tickFreq	=> 1,
	timeFont	=> "{Liberation Mono} 12",
	timeColor	=> "lightBlue",
	timeFormat	=> "HH:MM:SS",
	dateFont	=> "{Liberation Mono} 12",
	dateColor	=> "Gold",

	dateFormat => $city,
	timeZone   => $tz,
	handColor  => $color,
	);
    $c->pack (-side => "left", -expand => 1, -fill => "both");
    }

MainLoop;

__END__
ACDT	GMT+10:30	Australian Central Daylight Time
ACST	GMT+9:30	Australian Central Standard Time
ADT	GMT-3		Atlantic Daylight Time
AEDT	GMT+11		Australian Eastern Daylight Time
AEST	GMT+10		Australian Eastern Standard Time
AKDT	GMT-8		Alaska Daylight Time
AKST	GMT-9		Alaska Standard Time
AST	GMT-4		Atlantic Standard Time
AWDT	GMT+9		Australian Western Daylight Time
AWST	GMT+8		Australian Western Standard Time
BST	GMT+1		British Summer Time
CDT	GMT-5		Central Daylight Time
CEDT	GMT+2		Central European Daylight Time
CEST	GMT+2		Central European Summer Time
CET	GMT+1		Central European Time
CST	GMT+10:30	Central Summer(Daylight) Time
CST	GMT+9:30	Central Standard Time
CST	GMT-6		Central Standard Time
CXT	GMT+7		Christmas Island Time
EDT	GMT-4		Eastern Daylight Time
EEDT	GMT+3		Eastern European Daylight Time
EEST	GMT+3		Eastern European Summer Time
EET	GMT+2		Eastern European Time
EST	GMT+11		Eastern Summer(Daylight) Time
EST	GMT+10		Eastern Standard Time
EST	GMT-5		Eastern Standard Time
GMT	GMT		Greenwich Mean Time
HAA	GMT-3		Heure Avancée de l'Atlantique
HAC	GMT-5		Heure Avancée du Centre
HADT	GMT-9		Hawaii-Aleutian Daylight Time
HAE	GMT-4		Heure Avancée de l'Est
HAP	GMT-7		Heure Avancée du Pacifique
HAR	GMT-6		Heure Avancée des Rocheuses
HAST	GMT-10		Hawaii-Aleutian Standard Time
HAT	GMT-2:30	Heure Avancée de Terre-Neuve
HAY	GMT-8		Heure Avancée du Yukon
HNA	GMT-4		Heure Normale de l'Atlantique
HNC	GMT-6		Heure Normale du Centre
HNE	GMT-5		Heure Normale de l'Est
HNP	GMT-8		Heure Normale du Pacifique
HNR	GMT-7		Heure Normale des Rocheuses
HNT	GMT-3:30	Heure Normale de Terre-Neuve
HNY	GMT-9		Heure Normale du Yukon
IST	GMT+1		Irish Summer Time
MDT	GMT-6		Mountain Daylight Time
MESZ	GMT+2		Mitteleuropäische Sommerzeit
MEZ	GMT+1		Mitteleuropäische Zeit
MST	GMT-7		Mountain Standard Time
NDT	GMT-2:30	Newfoundland Daylight Time
NFT	GMT+11:30	Norfolk (Island) Time
NST	GMT-3:30	Newfoundland Standard Time
PDT	GMT-7		Pacific Daylight Time
PST	GMT-8		Pacific Standard Time
UTC	GMT		Coordinated Universal Time
WEDT	GMT+1		Western European Daylight Time
WEST	GMT+1		Western European Summer Time
WET	GMT		Western European Time
WST	GMT+9		Western Summer(Daylight) Time
WST	GMT+8		Western Standard Time

Addis Ababa	GMT+2
Adelaide	GMT+10:30
Aden		GMT+2
Algiers		GMT+0
Amman *		GMT+2
Amsterdam *	GMT+1
Anadyr *	GMT+12
Anchorage *	GMT-9
Ankara *	GMT+2
Antananarivo	GMT+2
Asuncion	GMT-5:00
Athens *	GMT+2
Atlanta *	GMT-5:00
Auckland	GMT+11
Baghdad *	GMT+3:00
Bangkok		GMT+6
Barcelona *	GMT+1
Beijing		GMT+7
Beirut *	GMT+2
Belgrade *	GMT+1
Berlin *	GMT+1
Bogota		GMT-6
Boston *	GMT-5:00
Brasilia	GMT-4
Brisbane	GMT+9:00
Brussels *	GMT+1
Bucharest *	GMT+2
Budapest *	GMT+1
Buenos Aires	GMT-4
Cairo *		GMT+2
Canberra	GMT+9:00
Cape Town	GMT+1
Caracas		GMT-5:00
Casablanca	GMT-1
Chatham Island	GMT+13:45
Chicago *	GMT-6
Copenhagen *	GMT+1
Darwin		GMT+10:30
Denver *	GMT-7
Detroit *	GMT-5:00
Dhaka		GMT+5
Dubai		GMT+3:00
Dublin *	GMT+0
Edmonton *	GMT-7
Frankfurt *	GMT+1
Geneva *	GMT+1
Guatemala	GMT-7
Halifax *	GMT-4
Hanoi		GMT+6
Harare		GMT+1
Havana *	GMT-5:00
Helsinki *	GMT+2
Hong Kong	GMT+7
Honolulu	GMT-11
Houston *	GMT-6
Indianapolis *	GMT-5:00
Islamabad	GMT+4
Istanbul *	GMT+2
Jakarta		GMT+6
Jerusalem *	GMT+2
Johannesburg	GMT+1
Kabul		GMT+5:30
Kamchatka *	GMT+12
Karachi		GMT+4
Kathmandu	GMT+6:45
Khartoum	GMT+2
Kingston	GMT-6
Kiritimati	GMT+13
Kolkata		GMT+6:30
Kuala Lumpur	GMT+7
Kuwait City	GMT+2
Kyiv *		GMT+2
Lagos		GMT+0
Lahore		GMT+4
La Paz		GMT-5:00
Lima		GMT-6
Lisbon *	GMT+0
London *	GMT
Los Angeles *	GMT-8
Madrid *	GMT+1
Managua		GMT-7
Manila		GMT+7
Melbourne	GMT+9:00
Mexico City *	GMT-6
Miami *		GMT-5:00
Minneapolis *	GMT-6
Minsk *		GMT+2
Montevideo	GMT-4
Montgomery *	GMT-6
Montreal *	GMT-5:00
Moscow *	GMT+3
Mumbai		GMT+6:30
Nairobi		GMT+2
Nassau *	GMT-5:00
New Delhi	GMT+6:30
New Orleans *	GMT-6
New York *	GMT-5
Odesa *		GMT+2
Oslo *		GMT+1
Ottawa *	GMT-5
Paris *		GMT+1
Perth		GMT+7
Philadelphia *	GMT-5
Phoenix		GMT-8
Prague *	GMT+1
Reykjavik	GMT-1
Rio de Janeiro	GMT-4
Riyadh		GMT+2
Rome *		GMT+1
San Francisco *	GMT-8
San Juan	GMT-5
San Salvador	GMT-7
Santiago	GMT-5
Santo Domingo	GMT-5
Sao Paulo	GMT-4
Seattle *	GMT-8
Seoul		GMT+8
Shanghai	GMT+7
Singapore	GMT+7
Sofia *		GMT+2
St. John's *	GMT-2:30
Stockholm *	GMT+1
St. Paul *	GMT-6
Suva		GMT+11
Sydney		GMT+9
Taipei		GMT+7
Tallinn *	GMT+2
Tashkent	GMT+4
Tegucigalpa	GMT-7
Tehran		GMT+4:30
Tokyo		GMT+8
Toronto *	GMT-5
Vancouver *	GMT-8
Vienna *	GMT+1
Vladivostok *	GMT+10
Warsaw *	GMT+1
Washington DC *	GMT-5
Winnipeg *	GMT-6
Yangon		GMT+7:30
Zagreb *	GMT+1
Zürich *	GMT+1
