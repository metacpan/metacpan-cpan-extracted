=head1 NAME

Time::OlsonTZ::Data - Olson timezone data

=head1 SYNOPSIS

    use Time::OlsonTZ::Data qw(olson_version);

    $version = olson_version;

    use Time::OlsonTZ::Data qw(
	olson_canonical_names olson_link_names olson_all_names
	olson_links olson_country_selection);

    $names = olson_canonical_names;
    $names = olson_link_names;
    $names = olson_all_names;
    $links = olson_links;
    $countries = olson_country_selection;

    use Time::OlsonTZ::Data qw(olson_tzfile);

    $filename = olson_tzfile("America/New_York");

=head1 DESCRIPTION

This module encapsulates the Olson timezone database, providing binary
tzfiles and ancillary data.  Each version of this module encapsulates
a particular version of the timezone database.  It is intended to be
regularly updated, as the timezone database changes.

=cut

package Time::OlsonTZ::Data;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.201902";

use parent "Exporter";
our @EXPORT_OK = qw(
	olson_version olson_code_version olson_data_version
	olson_canonical_names olson_link_names olson_all_names
	olson_links
	olson_country_selection
	olson_tzfile
);

my($datavol, $datadir);
sub _data_file($) {
	my($upath) = @_;
	unless(defined $datadir) {
		require File::Spec;
		($datavol, $datadir, undef) =
			File::Spec->splitpath($INC{"Time/OlsonTZ/Data.pm"});
	}
	my @nameparts = split(/\//, $upath);
	my $filename = pop(@nameparts);
	return File::Spec->catpath($datavol,
		File::Spec->catdir($datadir, "Data", @nameparts), $filename);
}

=head1 FUNCTIONS

=head2 Basic information

=over

=item olson_version

Returns the version number of the database that this module encapsulates.
Version numbers for the Olson database currently consist of a year number
and a lowercase letter, such as "C<2010k>"; they are not guaranteed to
retain this format in the future.

=cut

use constant olson_version => "2019b";

=item olson_code_version

Returns the version number of the code part of the database that this
module encapsulates.  This is now always the same as the value returned
by L</olson_version>.  Until late 2012 the database was distributed in
two parts, each with their own version number, so this was a distinct
piece of information.

=cut

use constant olson_code_version => "2019b";

=item olson_data_version

Returns the version number of the data part of the database that this
module encapsulates.  This is now always the same as the value returned
by L</olson_version>.  Until late 2012 the database was distributed in
two parts, each with their own version number, so this was a distinct
piece of information.

=cut

use constant olson_data_version => "2019b";

=back

=head2 Zone metadata

=over

=item olson_canonical_names

Returns the set of timezone names that this version of the database
defines as canonical.  These are the timezone names that are directly
associated with a set of observance data.  The return value is a reference
to a hash, in which the keys are the canonical timezone names and the
values are all C<undef>.

=cut

my $cn = q(+{ map { ($_ => undef) } qw(
	Africa/Abidjan Africa/Accra Africa/Algiers Africa/Bissau Africa/Cairo
	Africa/Casablanca Africa/Ceuta Africa/El_Aaiun Africa/Johannesburg
	Africa/Juba Africa/Khartoum Africa/Lagos Africa/Maputo Africa/Monrovia
	Africa/Nairobi Africa/Ndjamena Africa/Sao_Tome Africa/Tripoli
	Africa/Tunis Africa/Windhoek America/Adak America/Anchorage
	America/Araguaina America/Argentina/Buenos_Aires
	America/Argentina/Catamarca America/Argentina/Cordoba
	America/Argentina/Jujuy America/Argentina/La_Rioja
	America/Argentina/Mendoza America/Argentina/Rio_Gallegos
	America/Argentina/Salta America/Argentina/San_Juan
	America/Argentina/San_Luis America/Argentina/Tucuman
	America/Argentina/Ushuaia America/Asuncion America/Atikokan
	America/Bahia America/Bahia_Banderas America/Barbados America/Belem
	America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota
	America/Boise America/Cambridge_Bay America/Campo_Grande America/Cancun
	America/Caracas America/Cayenne America/Chicago America/Chihuahua
	America/Costa_Rica America/Creston America/Cuiaba America/Curacao
	America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver
	America/Detroit America/Edmonton America/Eirunepe America/El_Salvador
	America/Fort_Nelson America/Fortaleza America/Glace_Bay America/Godthab
	America/Goose_Bay America/Grand_Turk America/Guatemala America/Guayaquil
	America/Guyana America/Halifax America/Havana America/Hermosillo
	America/Indiana/Indianapolis America/Indiana/Knox
	America/Indiana/Marengo America/Indiana/Petersburg
	America/Indiana/Tell_City America/Indiana/Vevay
	America/Indiana/Vincennes America/Indiana/Winamac America/Inuvik
	America/Iqaluit America/Jamaica America/Juneau
	America/Kentucky/Louisville America/Kentucky/Monticello America/La_Paz
	America/Lima America/Los_Angeles America/Maceio America/Managua
	America/Manaus America/Martinique America/Matamoros America/Mazatlan
	America/Menominee America/Merida America/Metlakatla America/Mexico_City
	America/Miquelon America/Moncton America/Monterrey America/Montevideo
	America/Nassau America/New_York America/Nipigon America/Nome
	America/Noronha America/North_Dakota/Beulah America/North_Dakota/Center
	America/North_Dakota/New_Salem America/Ojinaga America/Panama
	America/Pangnirtung America/Paramaribo America/Phoenix
	America/Port-au-Prince America/Port_of_Spain America/Porto_Velho
	America/Puerto_Rico America/Punta_Arenas America/Rainy_River
	America/Rankin_Inlet America/Recife America/Regina America/Resolute
	America/Rio_Branco America/Santarem America/Santiago
	America/Santo_Domingo America/Sao_Paulo America/Scoresbysund
	America/Sitka America/St_Johns America/Swift_Current America/Tegucigalpa
	America/Thule America/Thunder_Bay America/Tijuana America/Toronto
	America/Vancouver America/Whitehorse America/Winnipeg America/Yakutat
	America/Yellowknife Antarctica/Casey Antarctica/Davis
	Antarctica/DumontDUrville Antarctica/Macquarie Antarctica/Mawson
	Antarctica/Palmer Antarctica/Rothera Antarctica/Syowa Antarctica/Troll
	Antarctica/Vostok Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau
	Asia/Aqtobe Asia/Ashgabat Asia/Atyrau Asia/Baghdad Asia/Baku
	Asia/Bangkok Asia/Barnaul Asia/Beirut Asia/Bishkek Asia/Brunei
	Asia/Chita Asia/Choibalsan Asia/Colombo Asia/Damascus Asia/Dhaka
	Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Famagusta Asia/Gaza Asia/Hebron
	Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Jakarta
	Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi
	Asia/Kathmandu Asia/Khandyga Asia/Kolkata Asia/Krasnoyarsk
	Asia/Kuala_Lumpur Asia/Kuching Asia/Macau Asia/Magadan Asia/Makassar
	Asia/Manila Asia/Nicosia Asia/Novokuznetsk Asia/Novosibirsk Asia/Omsk
	Asia/Oral Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qostanay
	Asia/Qyzylorda Asia/Riyadh Asia/Sakhalin Asia/Samarkand Asia/Seoul
	Asia/Shanghai Asia/Singapore Asia/Srednekolymsk Asia/Taipei
	Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Thimphu Asia/Tokyo
	Asia/Tomsk Asia/Ulaanbaatar Asia/Urumqi Asia/Ust-Nera Asia/Vladivostok
	Asia/Yakutsk Asia/Yangon Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores
	Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faroe
	Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia
	Atlantic/Stanley Australia/Adelaide Australia/Brisbane
	Australia/Broken_Hill Australia/Currie Australia/Darwin Australia/Eucla
	Australia/Hobart Australia/Lindeman Australia/Lord_Howe
	Australia/Melbourne Australia/Perth Australia/Sydney CET CST6CDT EET EST
	EST5EDT Etc/GMT Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2
	Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9
	Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14
	Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8
	Etc/GMT-9 Etc/UTC Europe/Amsterdam Europe/Andorra Europe/Astrakhan
	Europe/Athens Europe/Belgrade Europe/Berlin Europe/Brussels
	Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen
	Europe/Dublin Europe/Gibraltar Europe/Helsinki Europe/Istanbul
	Europe/Kaliningrad Europe/Kiev Europe/Kirov Europe/Lisbon Europe/London
	Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Minsk Europe/Monaco
	Europe/Moscow Europe/Oslo Europe/Paris Europe/Prague Europe/Riga
	Europe/Rome Europe/Samara Europe/Saratov Europe/Simferopol Europe/Sofia
	Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Ulyanovsk
	Europe/Uzhgorod Europe/Vienna Europe/Vilnius Europe/Volgograd
	Europe/Warsaw Europe/Zaporozhye Europe/Zurich Factory HST Indian/Chagos
	Indian/Christmas Indian/Cocos Indian/Kerguelen Indian/Mahe
	Indian/Maldives Indian/Mauritius Indian/Reunion MET MST MST7MDT PST8PDT
	Pacific/Apia Pacific/Auckland Pacific/Bougainville Pacific/Chatham
	Pacific/Chuuk Pacific/Easter Pacific/Efate Pacific/Enderbury
	Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos
	Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu
	Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro
	Pacific/Marquesas Pacific/Nauru Pacific/Niue Pacific/Norfolk
	Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn
	Pacific/Pohnpei Pacific/Port_Moresby Pacific/Rarotonga Pacific/Tahiti
	Pacific/Tarawa Pacific/Tongatapu Pacific/Wake Pacific/Wallis WET
) });
sub olson_canonical_names() {
	$cn = eval($cn) || die $@ if ref($cn) eq "";
	return $cn;
}

=item olson_link_names

Returns the set of timezone names that this version of the database
defines as links.  These are the timezone names that are aliases for
other names.  The return value is a reference to a hash, in which the
keys are the link timezone names and the values are all C<undef>.

=cut

sub olson_links();

my $ln;
sub olson_link_names() {
	return $ln ||= { map { ($_ => undef) } keys %{olson_links()} };
}

=item olson_all_names

Returns the set of timezone names that this version of the
database defines.  These are the L</olson_canonical_names> and the
L</olson_link_names>.  The return value is a reference to a hash, in
which the keys are the timezone names and the values are all C<undef>.

=cut

my $an;
sub olson_all_names() {
	return $an ||= {
		%{olson_canonical_names()},
		%{olson_link_names()},
	};
}

=item olson_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the canonical name of
the timezone to which that alias refers.  All such canonical names can
be found in the L</olson_canonical_names> hash.

=cut

my $li = q(+{
	"Africa/Addis_Ababa" => "Africa/Nairobi",
	"Africa/Asmara" => "Africa/Nairobi",
	"Africa/Asmera" => "Africa/Nairobi",
	"Africa/Bamako" => "Africa/Abidjan",
	"Africa/Bangui" => "Africa/Lagos",
	"Africa/Banjul" => "Africa/Abidjan",
	"Africa/Blantyre" => "Africa/Maputo",
	"Africa/Brazzaville" => "Africa/Lagos",
	"Africa/Bujumbura" => "Africa/Maputo",
	"Africa/Conakry" => "Africa/Abidjan",
	"Africa/Dakar" => "Africa/Abidjan",
	"Africa/Dar_es_Salaam" => "Africa/Nairobi",
	"Africa/Djibouti" => "Africa/Nairobi",
	"Africa/Douala" => "Africa/Lagos",
	"Africa/Freetown" => "Africa/Abidjan",
	"Africa/Gaborone" => "Africa/Maputo",
	"Africa/Harare" => "Africa/Maputo",
	"Africa/Kampala" => "Africa/Nairobi",
	"Africa/Kigali" => "Africa/Maputo",
	"Africa/Kinshasa" => "Africa/Lagos",
	"Africa/Libreville" => "Africa/Lagos",
	"Africa/Lome" => "Africa/Abidjan",
	"Africa/Luanda" => "Africa/Lagos",
	"Africa/Lubumbashi" => "Africa/Maputo",
	"Africa/Lusaka" => "Africa/Maputo",
	"Africa/Malabo" => "Africa/Lagos",
	"Africa/Maseru" => "Africa/Johannesburg",
	"Africa/Mbabane" => "Africa/Johannesburg",
	"Africa/Mogadishu" => "Africa/Nairobi",
	"Africa/Niamey" => "Africa/Lagos",
	"Africa/Nouakchott" => "Africa/Abidjan",
	"Africa/Ouagadougou" => "Africa/Abidjan",
	"Africa/Porto-Novo" => "Africa/Lagos",
	"Africa/Timbuktu" => "Africa/Abidjan",
	"America/Anguilla" => "America/Port_of_Spain",
	"America/Antigua" => "America/Port_of_Spain",
	"America/Argentina/ComodRivadavia" => "America/Argentina/Catamarca",
	"America/Aruba" => "America/Curacao",
	"America/Atka" => "America/Adak",
	"America/Buenos_Aires" => "America/Argentina/Buenos_Aires",
	"America/Catamarca" => "America/Argentina/Catamarca",
	"America/Cayman" => "America/Panama",
	"America/Coral_Harbour" => "America/Atikokan",
	"America/Cordoba" => "America/Argentina/Cordoba",
	"America/Dominica" => "America/Port_of_Spain",
	"America/Ensenada" => "America/Tijuana",
	"America/Fort_Wayne" => "America/Indiana/Indianapolis",
	"America/Grenada" => "America/Port_of_Spain",
	"America/Guadeloupe" => "America/Port_of_Spain",
	"America/Indianapolis" => "America/Indiana/Indianapolis",
	"America/Jujuy" => "America/Argentina/Jujuy",
	"America/Knox_IN" => "America/Indiana/Knox",
	"America/Kralendijk" => "America/Curacao",
	"America/Louisville" => "America/Kentucky/Louisville",
	"America/Lower_Princes" => "America/Curacao",
	"America/Marigot" => "America/Port_of_Spain",
	"America/Mendoza" => "America/Argentina/Mendoza",
	"America/Montreal" => "America/Toronto",
	"America/Montserrat" => "America/Port_of_Spain",
	"America/Porto_Acre" => "America/Rio_Branco",
	"America/Rosario" => "America/Argentina/Cordoba",
	"America/Santa_Isabel" => "America/Tijuana",
	"America/Shiprock" => "America/Denver",
	"America/St_Barthelemy" => "America/Port_of_Spain",
	"America/St_Kitts" => "America/Port_of_Spain",
	"America/St_Lucia" => "America/Port_of_Spain",
	"America/St_Thomas" => "America/Port_of_Spain",
	"America/St_Vincent" => "America/Port_of_Spain",
	"America/Tortola" => "America/Port_of_Spain",
	"America/Virgin" => "America/Port_of_Spain",
	"Antarctica/McMurdo" => "Pacific/Auckland",
	"Antarctica/South_Pole" => "Pacific/Auckland",
	"Arctic/Longyearbyen" => "Europe/Oslo",
	"Asia/Aden" => "Asia/Riyadh",
	"Asia/Ashkhabad" => "Asia/Ashgabat",
	"Asia/Bahrain" => "Asia/Qatar",
	"Asia/Calcutta" => "Asia/Kolkata",
	"Asia/Chongqing" => "Asia/Shanghai",
	"Asia/Chungking" => "Asia/Shanghai",
	"Asia/Dacca" => "Asia/Dhaka",
	"Asia/Harbin" => "Asia/Shanghai",
	"Asia/Istanbul" => "Europe/Istanbul",
	"Asia/Kashgar" => "Asia/Urumqi",
	"Asia/Katmandu" => "Asia/Kathmandu",
	"Asia/Kuwait" => "Asia/Riyadh",
	"Asia/Macao" => "Asia/Macau",
	"Asia/Muscat" => "Asia/Dubai",
	"Asia/Phnom_Penh" => "Asia/Bangkok",
	"Asia/Rangoon" => "Asia/Yangon",
	"Asia/Saigon" => "Asia/Ho_Chi_Minh",
	"Asia/Tel_Aviv" => "Asia/Jerusalem",
	"Asia/Thimbu" => "Asia/Thimphu",
	"Asia/Ujung_Pandang" => "Asia/Makassar",
	"Asia/Ulan_Bator" => "Asia/Ulaanbaatar",
	"Asia/Vientiane" => "Asia/Bangkok",
	"Atlantic/Faeroe" => "Atlantic/Faroe",
	"Atlantic/Jan_Mayen" => "Europe/Oslo",
	"Atlantic/St_Helena" => "Africa/Abidjan",
	"Australia/ACT" => "Australia/Sydney",
	"Australia/Canberra" => "Australia/Sydney",
	"Australia/LHI" => "Australia/Lord_Howe",
	"Australia/NSW" => "Australia/Sydney",
	"Australia/North" => "Australia/Darwin",
	"Australia/Queensland" => "Australia/Brisbane",
	"Australia/South" => "Australia/Adelaide",
	"Australia/Tasmania" => "Australia/Hobart",
	"Australia/Victoria" => "Australia/Melbourne",
	"Australia/West" => "Australia/Perth",
	"Australia/Yancowinna" => "Australia/Broken_Hill",
	"Brazil/Acre" => "America/Rio_Branco",
	"Brazil/DeNoronha" => "America/Noronha",
	"Brazil/East" => "America/Sao_Paulo",
	"Brazil/West" => "America/Manaus",
	"Canada/Atlantic" => "America/Halifax",
	"Canada/Central" => "America/Winnipeg",
	"Canada/Eastern" => "America/Toronto",
	"Canada/Mountain" => "America/Edmonton",
	"Canada/Newfoundland" => "America/St_Johns",
	"Canada/Pacific" => "America/Vancouver",
	"Canada/Saskatchewan" => "America/Regina",
	"Canada/Yukon" => "America/Whitehorse",
	"Chile/Continental" => "America/Santiago",
	"Chile/EasterIsland" => "Pacific/Easter",
	Cuba => "America/Havana",
	Egypt => "Africa/Cairo",
	Eire => "Europe/Dublin",
	"Etc/GMT+0" => "Etc/GMT",
	"Etc/GMT-0" => "Etc/GMT",
	"Etc/GMT0" => "Etc/GMT",
	"Etc/Greenwich" => "Etc/GMT",
	"Etc/UCT" => "Etc/UTC",
	"Etc/Universal" => "Etc/UTC",
	"Etc/Zulu" => "Etc/UTC",
	"Europe/Belfast" => "Europe/London",
	"Europe/Bratislava" => "Europe/Prague",
	"Europe/Busingen" => "Europe/Zurich",
	"Europe/Guernsey" => "Europe/London",
	"Europe/Isle_of_Man" => "Europe/London",
	"Europe/Jersey" => "Europe/London",
	"Europe/Ljubljana" => "Europe/Belgrade",
	"Europe/Mariehamn" => "Europe/Helsinki",
	"Europe/Nicosia" => "Asia/Nicosia",
	"Europe/Podgorica" => "Europe/Belgrade",
	"Europe/San_Marino" => "Europe/Rome",
	"Europe/Sarajevo" => "Europe/Belgrade",
	"Europe/Skopje" => "Europe/Belgrade",
	"Europe/Tiraspol" => "Europe/Chisinau",
	"Europe/Vaduz" => "Europe/Zurich",
	"Europe/Vatican" => "Europe/Rome",
	"Europe/Zagreb" => "Europe/Belgrade",
	GB => "Europe/London",
	"GB-Eire" => "Europe/London",
	GMT => "Etc/GMT",
	"GMT+0" => "Etc/GMT",
	"GMT-0" => "Etc/GMT",
	GMT0 => "Etc/GMT",
	Greenwich => "Etc/GMT",
	Hongkong => "Asia/Hong_Kong",
	Iceland => "Atlantic/Reykjavik",
	"Indian/Antananarivo" => "Africa/Nairobi",
	"Indian/Comoro" => "Africa/Nairobi",
	"Indian/Mayotte" => "Africa/Nairobi",
	Iran => "Asia/Tehran",
	Israel => "Asia/Jerusalem",
	Jamaica => "America/Jamaica",
	Japan => "Asia/Tokyo",
	Kwajalein => "Pacific/Kwajalein",
	Libya => "Africa/Tripoli",
	"Mexico/BajaNorte" => "America/Tijuana",
	"Mexico/BajaSur" => "America/Mazatlan",
	"Mexico/General" => "America/Mexico_City",
	NZ => "Pacific/Auckland",
	"NZ-CHAT" => "Pacific/Chatham",
	Navajo => "America/Denver",
	PRC => "Asia/Shanghai",
	"Pacific/Johnston" => "Pacific/Honolulu",
	"Pacific/Midway" => "Pacific/Pago_Pago",
	"Pacific/Ponape" => "Pacific/Pohnpei",
	"Pacific/Saipan" => "Pacific/Guam",
	"Pacific/Samoa" => "Pacific/Pago_Pago",
	"Pacific/Truk" => "Pacific/Chuuk",
	"Pacific/Yap" => "Pacific/Chuuk",
	Poland => "Europe/Warsaw",
	Portugal => "Europe/Lisbon",
	ROC => "Asia/Taipei",
	ROK => "Asia/Seoul",
	Singapore => "Asia/Singapore",
	Turkey => "Europe/Istanbul",
	UCT => "Etc/UTC",
	"US/Alaska" => "America/Anchorage",
	"US/Aleutian" => "America/Adak",
	"US/Arizona" => "America/Phoenix",
	"US/Central" => "America/Chicago",
	"US/East-Indiana" => "America/Indiana/Indianapolis",
	"US/Eastern" => "America/New_York",
	"US/Hawaii" => "Pacific/Honolulu",
	"US/Indiana-Starke" => "America/Indiana/Knox",
	"US/Michigan" => "America/Detroit",
	"US/Mountain" => "America/Denver",
	"US/Pacific" => "America/Los_Angeles",
	"US/Samoa" => "Pacific/Pago_Pago",
	UTC => "Etc/UTC",
	Universal => "Etc/UTC",
	"W-SU" => "Europe/Moscow",
	Zulu => "Etc/UTC",
});
sub olson_links() {
	$li = eval($li) || die $@ if ref($li) eq "";
	return $li;
}

=item olson_country_selection

Returns information about how timezones relate to countries, intended
to aid humans in selecting a geographical timezone.  This information
is derived from the C<zone.tab> and C<iso3166.tab> files in the database
source.

The return value is a reference to a hash, keyed by (ISO 3166 alpha-2
uppercase) country code.  The value for each country is a hash containing
these values:

=over

=item B<alpha2_code>

The ISO 3166 alpha-2 uppercase country code.

=item B<olson_name>

An English name for the country, possibly in a modified form, optimised
to help humans find the right entry in alphabetical lists.  This is
not necessarily identical to the country's standard short or long name.
(For other forms of the name, consult a database of countries, keying
by the country code.)

=item B<regions>

Information about the regions of the country that use distinct
timezones.  This is a hash, keyed by English description of the region.
The description is empty if there is only one region.  The value for
each region is a hash containing these values:

=over

=item B<olson_description>

Brief English description of the region, used to distinguish between
the regions of a single country.  Empty string if the country has only
one region for timezone purposes.  (This is the same string used as the
key in the B<regions> hash.)

=item B<timezone_name>

Name of the Olson timezone used in this region.  The named timezone is
guaranteed to exist in the database, but not necessarily as a canonical
name (it may be a link).  Typically, where there are aliases or identical
canonical zones, a name is chosen that refers to a location in the
country of interest.

=item B<location_coords>

Geographical coordinates of some point within the location referred to in
the timezone name.  This is a latitude and longitude, in ISO 6709 format.

=back

=back

This data structure is intended to help a human select the appropriate
timezone based on political geography, specifically working from a
selection of country.  It is of essentially no use for any other purpose.
It is not strictly guaranteed that every geographical timezone in the
database is listed somewhere in this structure, so it is of limited use
in providing information about an already-selected timezone.  It does
not include non-geographic timezones at all.  It also does not claim
to be a comprehensive list of countries, and does not make any claims
regarding the political status of any entity listed: the "country"
classification is loose, and used only for identification purposes.

=cut

my $cs;
sub olson_country_selection() {
	return $cs ||= do {
		my $fn = _data_file("country_selection.tzp");
		$@ = ""; do($fn) || die($@ eq "" ? "$fn: $!" : $@);
	}
}

=back

=head2 Zone data

=over

=item olson_tzfile(NAME)

Returns the pathname of the binary tzfile (in L<tzfile(5)> format)
describing the timezone named I<NAME> in the Olson database.  C<die>s if
the name does not exist in this version of the database.  The tzfile
is of at least version 2 of the format, and so does not suffer a Y2038
(32-bit time_t) problem.

=cut

sub olson_tzfile($) {
	my($tzname) = @_;
	$tzname = olson_links()->{$tzname} if exists olson_links()->{$tzname};
	unless(exists olson_canonical_names()->{$tzname}) {
		require Carp;
		Carp::croak("no such timezone `$tzname' ".
			"in the Olson @{[olson_version]} database");
	}
	return _data_file($tzname.".tz");
}

=back

=head1 BUGS

The Olson timezone database probably contains errors in the older
historical data.  These will be corrected, as they are discovered,
in future versions of the database.

Because legislatures commonly change civil timezone rules, in
unpredictable ways and often with little advance notice, the current
timezone data is liable to get out of date quite quickly.  The Olson
timezone database is frequently updated to keep it accurate for current
dates.  Frequently updating installations of this module from CPAN should
keep it similarly accurate.

For the same reason, the future data in the database is liable to be
very inaccurate.  The database includes, for each timezone, the current
best guess regarding its future behaviour, usually consisting of the
current rules being left unchanged indefinitely.  (In most cases it is
unlikely that the rules will actually never be changed, but the current
rules still constitute the best guess available of future behaviour.)

Because this module is intended to be frequently updated, long-running
programs (such as clock displays) will experience the module being
updated while in use.  This can happen with any module, but is of
particular interest with this one.  The behaviour in this situation is
not guaranteed, but here is a guide to current behaviour.  The running
module code is of course not influenced by the C<.pm> file changing.
The ancillary data is all currently stored in the module code, and so
will be equally unaffected.  Tzfiles pointed to by the module, however,
will change visibly.  Newly reading a tzfile is liable to see a newer
version of the zone's data than the module's metadata suggests.  A tzfile
could also theoretically disappear, if a zone's canonical name changes
(so the former canonical name becomes a link).  To avoid weirdness,
it is recommended to read in all required tzfiles near the start of
a program's run, so that it doesn't matter if the files subsequently
change due to an update.

=head1 SEE ALSO

L<App::olson>,
L<DateTime::TimeZone::Olson>,
L<DateTime::TimeZone::Tzfile>,
L<Time::OlsonTZ::Download>,
L<tzfile(5)>

=head1 AUTHOR

The Olson timezone database was compiled by Arthur David Olson, Paul
Eggert, and many others.  It is maintained by the denizens of the mailing
list <tz@iana.org> (formerly <tz@elsie.nci.nih.gov>).

The C<Time::OlsonTZ::Data> Perl module wrapper for the database was
developed by Andrew Main (Zefram) <zefram@fysh.org>.

=head1 COPYRIGHT

The Olson timezone database is is the public domain.

The C<Time::OlsonTZ::Data> Perl module wrapper for the database is
Copyright (C) 2010, 2011, 2012, 2013, 2014, 2017, 2018, 2019
Andrew Main (Zefram) <zefram@fysh.org>.

=head1 LICENSE

No license is required to do anything with public domain materials.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
