package Time::Zone::Olson;

use strict;
use warnings;

use FileHandle();
use File::Spec();
use Config;
use Carp();
use English qw( -no_match_vars );
use DirHandle();
use Encode();
use POSIX();
use Digest::SHA();
use File::Find();

BEGIN {
    if ( $OSNAME eq 'MSWin32' ) {
        require Win32API::Registry;
    }
}

our $VERSION = '0.41';

sub _SIZE_OF_TZ_HEADER                     { return 44 }
sub _SIZE_OF_TRANSITION_TIME_V1            { return 4 }
sub _SIZE_OF_TRANSITION_TIME_V2            { return 8 }
sub _SIZE_OF_TTINFO                        { return 6 }
sub _SIZE_OF_LEAP_SECOND_V1                { return 4 }
sub _SIZE_OF_LEAP_SECOND_V2                { return 8 }
sub _PAIR                                  { return 2 }
sub _STAT_MTIME_IDX                        { return 9 }
sub _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION { return 256 }
sub _MONTHS_IN_ONE_YEAR                    { return 12 }
sub _HOURS_IN_ONE_DAY                      { return 24 }
sub _MINUTES_IN_ONE_HOUR                   { return 60 }
sub _SECONDS_IN_ONE_MINUTE                 { return 60 }
sub _SECONDS_IN_ONE_HOUR                   { return 3_600 }
sub _SECONDS_IN_ONE_DAY                    { return 86_400 }
sub _NEGATIVE_ONE                          { return -1 }
sub _LOCALTIME_ISDST_INDEX                 { return 8 }
sub _LOCALTIME_YEAR_INDEX                  { return 5 }
sub _LOCALTIME_MONTH_INDEX                 { return 4 }
sub _LOCALTIME_DAY_INDEX                   { return 3 }
sub _LOCALTIME_HOUR_INDEX                  { return 2 }
sub _LOCALTIME_MINUTE_INDEX                { return 1 }
sub _LOCALTIME_SECOND_INDEX                { return 0 }
sub _LOCALTIME_BASE_YEAR                   { return 1900 }
sub _EPOCH_YEAR                            { return 1970 }
sub _EPOCH_WDAY                            { return 4 }
sub _DAYS_IN_JANUARY                       { return 31 }
sub _DAYS_IN_FEBRUARY_LEAP_YEAR            { return 29 }
sub _DAYS_IN_FEBRUARY_NON_LEAP             { return 28 }
sub _DAYS_IN_MARCH                         { return 31 }
sub _DAYS_IN_APRIL                         { return 30 }
sub _DAYS_IN_MAY                           { return 31 }
sub _DAYS_IN_JUNE                          { return 30 }
sub _DAYS_IN_JULY                          { return 31 }
sub _DAYS_IN_AUGUST                        { return 31 }
sub _DAYS_IN_SEPTEMBER                     { return 30 }
sub _DAYS_IN_OCTOBER                       { return 31 }
sub _DAYS_IN_NOVEMBER                      { return 30 }
sub _DAYS_IN_DECEMBER                      { return 31 }
sub _DAYS_IN_A_LEAP_YEAR                   { return 366 }
sub _DAYS_IN_A_NON_LEAP_YEAR               { return 365 }
sub _LAST_WEEK_VALUE                       { return 5 }
sub _LOCALTIME_WEEKDAY_HIGHEST_VALUE       { return 6 }
sub _DAYS_IN_ONE_WEEK                      { return 7 }
sub _EVERY_FOUR_HUNDRED_YEARS              { return 400 }
sub _EVERY_FOUR_YEARS                      { return 4 }
sub _EVERY_ONE_HUNDRED_YEARS               { return 100 }
sub _DEFAULT_DST_START_HOUR                { return 2 }
sub _DEFAULT_DST_END_HOUR                  { return 2 }
sub _DAY_OF_WEEK_AT_EPOCH                  { return 4 }
sub _MAX_SIZE_FOR_A_GUESS_FILE_CONTENTS    { return 4096 }
sub _MAXIMUM_32_BIT_SIGNED_NUMBER          { return 2_147_483_648 }
sub _MAXIMUM_32_BIT_UNSIGNED_NUMBER        { return 4_294_967_296 }
sub _MINIMUM_PERL_FOR_FORCE_BIG_ENDIAN     { return 5.010 }

sub _TZ_DEFINITION_KEYS {
    return
      qw(std_name std_sign std_hours std_minutes std_seconds dst_name dst_sign dst_hours dst_minutes dst_seconds start_julian_without_feb29 end_julian_without_feb29 start_julian_with_feb29 end_julian_with_feb29 start_month end_month start_week end_week start_day end_day start_hour end_hour start_minute end_minute start_second end_second);
}

my $_modern_regexs_work = 1;
my $_timezone_full_name_regex =
  eval ## no critic (ProhibitStringyEval) required to allow old perl (pre 5.10) to compile
  'qr/(?<tz>(?<area>\w+)(?:\/(?<location>[\w\-\/+]+))?)/smx'
  or do { $_modern_regexs_work = undef };
if ( !$_modern_regexs_work ) {
    $_timezone_full_name_regex = qr/((\w+)(?:\/([\w\-\/+]+)))/smx;
}

sub _TIMEZONE_FULL_NAME_REGEX {
    return $_timezone_full_name_regex;
}

sub _WIN32_ERROR_FILE_NOT_FOUND {
    return 2;
}    # ERROR_FILE_NOT_FOUND from winerror.h

sub _WIN32_ERROR_NO_MORE_ITEMS {
    return 259;
}    # ERROR_NO_MORE_ITEMS from winerror.h

my $_default_zoneinfo_directory = '/usr/share/zoneinfo';
if ( -e $_default_zoneinfo_directory ) {
}
else {
    if ( -e '/usr/lib/zoneinfo' ) {
        $_default_zoneinfo_directory = '/usr/lib/zoneinfo';
    }
    elsif ( -e '/usr/share/lib/zoneinfo' ) {    # solaris
        $_default_zoneinfo_directory = '/usr/share/lib/zoneinfo';
    }
}
my $_zonetab_cache = {};
my $_tzdata_cache  = {};

# source of olson => win32 timezones
# used to be http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml
# now is     https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml

my %olson_to_win32_timezones = (
    'Africa/Abidjan'       => ['Greenwich Standard Time'],
    'Africa/Accra'         => ['Greenwich Standard Time'],
    'Africa/Addis_Ababa'   => ['E. Africa Standard Time'],
    'Africa/Algiers'       => ['W. Central Africa Standard Time'],
    'Africa/Asmera'        => ['E. Africa Standard Time'],
    'Africa/Bamako'        => ['Greenwich Standard Time'],
    'Africa/Bangui'        => ['W. Central Africa Standard Time'],
    'Africa/Banjul'        => ['Greenwich Standard Time'],
    'Africa/Bissau'        => ['Greenwich Standard Time'],
    'Africa/Blantyre'      => ['South Africa Standard Time'],
    'Africa/Brazzaville'   => ['W. Central Africa Standard Time'],
    'Africa/Bujumbura'     => ['South Africa Standard Time'],
    'Africa/Cairo'         => ['Egypt Standard Time'],
    'Africa/Casablanca'    => ['Morocco Standard Time'],
    'Africa/Ceuta'         => ['Romance Standard Time'],
    'Africa/Conakry'       => ['Greenwich Standard Time'],
    'Africa/Dakar'         => ['Greenwich Standard Time'],
    'Africa/Dar_es_Salaam' => ['E. Africa Standard Time'],
    'Africa/Djibouti'      => ['E. Africa Standard Time'],
    'Africa/Douala'        => ['W. Central Africa Standard Time'],
    'Africa/El_Aaiun'      => ['Morocco Standard Time'],
    'Africa/Freetown'      => ['Greenwich Standard Time'],
    'Africa/Gaborone'      => ['South Africa Standard Time'],
    'Africa/Harare'        => ['South Africa Standard Time'],
    'Africa/Johannesburg'  => ['South Africa Standard Time'],
    'Africa/Juba' => [ 'South Sudan Standard Time', 'E. Africa Standard Time' ],
    'Africa/Kampala'    => ['E. Africa Standard Time'],
    'Africa/Khartoum'   => [ 'Sudan Standard Time', 'E. Africa Standard Time' ],
    'Africa/Kigali'     => ['South Africa Standard Time'],
    'Africa/Kinshasa'   => ['W. Central Africa Standard Time'],
    'Africa/Lagos'      => ['W. Central Africa Standard Time'],
    'Africa/Libreville' => ['W. Central Africa Standard Time'],
    'Africa/Lome'       => ['Greenwich Standard Time'],
    'Africa/Luanda'     => ['W. Central Africa Standard Time'],
    'Africa/Lubumbashi' => ['South Africa Standard Time'],
    'Africa/Lusaka'     => ['South Africa Standard Time'],
    'Africa/Malabo'     => ['W. Central Africa Standard Time'],
    'Africa/Maputo'     => ['South Africa Standard Time'],
    'Africa/Maseru'     => ['South Africa Standard Time'],
    'Africa/Mbabane'    => ['South Africa Standard Time'],
    'Africa/Mogadishu'  => ['E. Africa Standard Time'],
    'Africa/Monrovia'   => ['Greenwich Standard Time'],
    'Africa/Nairobi'    => ['E. Africa Standard Time'],
    'Africa/Ndjamena'   => ['W. Central Africa Standard Time'],
    'Africa/Niamey'     => ['W. Central Africa Standard Time'],
    'Africa/Nouakchott' => ['Greenwich Standard Time'],
    'Africa/Ouagadougou' => ['Greenwich Standard Time'],
    'Africa/Porto-Novo'  => ['W. Central Africa Standard Time'],
    'Africa/Sao_Tome'    =>
      [ 'Sao Tome Standard Time', 'Greenwich Standard Time' ],
    'Africa/Tripoli'                 => ['Libya Standard Time'],
    'Africa/Tunis'                   => ['W. Central Africa Standard Time'],
    'Africa/Windhoek'                => ['Namibia Standard Time'],
    'America/Adak'                   => ['Aleutian Standard Time'],
    'America/Anchorage'              => ['Alaskan Standard Time'],
    'America/Anguilla'               => ['SA Western Standard Time'],
    'America/Antigua'                => ['SA Western Standard Time'],
    'America/Araguaina'              => ['Tocantins Standard Time'],
    'America/Argentina/La_Rioja'     => ['Argentina Standard Time'],
    'America/Argentina/Rio_Gallegos' => ['Argentina Standard Time'],
    'America/Argentina/Salta'        => ['Argentina Standard Time'],
    'America/Argentina/San_Juan'     => ['Argentina Standard Time'],
    'America/Argentina/San_Luis'     => ['Argentina Standard Time'],
    'America/Argentina/Tucuman'      => ['Argentina Standard Time'],
    'America/Argentina/Ushuaia'      => ['Argentina Standard Time'],
    'America/Aruba'                  => ['SA Western Standard Time'],
    'America/Asuncion'               => ['Paraguay Standard Time'],
    'America/Bahia'                  => ['Bahia Standard Time'],
    'America/Bahia_Banderas'         => ['Central Standard Time (Mexico)'],
    'America/Barbados'               => ['SA Western Standard Time'],
    'America/Belem'                  => ['SA Eastern Standard Time'],
    'America/Belize'                 => ['Central America Standard Time'],
    'America/Blanc-Sablon'           => ['SA Western Standard Time'],
    'America/Boa_Vista'              => ['SA Western Standard Time'],
    'America/Bogota'                 => ['SA Pacific Standard Time'],
    'America/Boise'                  => ['Mountain Standard Time'],
    'America/Buenos_Aires'           => ['Argentina Standard Time'],
    'America/Cambridge_Bay'          => ['Mountain Standard Time'],
    'America/Campo_Grande'           => ['Central Brazilian Standard Time'],
    'America/Cancun'                 => ['Eastern Standard Time (Mexico)'],
    'America/Caracas'                => ['Venezuela Standard Time'],
    'America/Catamarca'              => ['Argentina Standard Time'],
    'America/Cayenne'                => ['SA Eastern Standard Time'],
    'America/Cayman'                 => ['SA Pacific Standard Time'],
    'America/Chicago'                => ['Central Standard Time'],
    'America/Chihuahua'              =>
      [ 'Mexico Standard Time 2', 'Mountain Standard Time (Mexico)' ],
    'America/Coral_Harbour'       => ['SA Pacific Standard Time'],
    'America/Cordoba'             => ['Argentina Standard Time'],
    'America/Costa_Rica'          => ['Central America Standard Time'],
    'America/Creston'             => ['US Mountain Standard Time'],
    'America/Cuiaba'              => ['Central Brazilian Standard Time'],
    'America/Curacao'             => ['SA Western Standard Time'],
    'America/Danmarkshavn'        => ['UTC'],
    'America/Dawson'              => ['Pacific Standard Time'],
    'America/Dawson_Creek'        => ['US Mountain Standard Time'],
    'America/Denver'              => ['Mountain Standard Time'],
    'America/Detroit'             => ['Eastern Standard Time'],
    'America/Dominica'            => ['SA Western Standard Time'],
    'America/Edmonton'            => ['Mountain Standard Time'],
    'America/Eirunepe'            => ['SA Pacific Standard Time'],
    'America/El_Salvador'         => ['Central America Standard Time'],
    'America/Fort_Nelson'         => ['US Mountain Standard Time'],
    'America/Fortaleza'           => ['SA Eastern Standard Time'],
    'America/Glace_Bay'           => ['Atlantic Standard Time'],
    'America/Godthab'             => ['Greenland Standard Time'],
    'America/Goose_Bay'           => ['Atlantic Standard Time'],
    'America/Grand_Turk'          => ['Turks And Caicos Standard Time'],
    'America/Grenada'             => ['SA Western Standard Time'],
    'America/Guadeloupe'          => ['SA Western Standard Time'],
    'America/Guatemala'           => ['Central America Standard Time'],
    'America/Guayaquil'           => ['SA Pacific Standard Time'],
    'America/Guyana'              => ['SA Western Standard Time'],
    'America/Halifax'             => ['Atlantic Standard Time'],
    'America/Havana'              => ['Cuba Standard Time'],
    'America/Hermosillo'          => ['US Mountain Standard Time'],
    'America/Indiana/Knox'        => ['Central Standard Time'],
    'America/Indiana/Marengo'     => ['US Eastern Standard Time'],
    'America/Indiana/Petersburg'  => ['Eastern Standard Time'],
    'America/Indiana/Tell_City'   => ['Central Standard Time'],
    'America/Indiana/Vevay'       => ['US Eastern Standard Time'],
    'America/Indiana/Vincennes'   => ['Eastern Standard Time'],
    'America/Indiana/Winamac'     => ['Eastern Standard Time'],
    'America/Indianapolis'        => ['US Eastern Standard Time'],
    'America/Inuvik'              => ['Mountain Standard Time'],
    'America/Iqaluit'             => ['Eastern Standard Time'],
    'America/Jamaica'             => ['SA Pacific Standard Time'],
    'America/Jujuy'               => ['Argentina Standard Time'],
    'America/Juneau'              => ['Alaskan Standard Time'],
    'America/Kentucky/Monticello' => ['Eastern Standard Time'],
    'America/Kralendijk'          => ['SA Western Standard Time'],
    'America/La_Paz'              => ['SA Western Standard Time'],
    'America/Lima'                => ['SA Pacific Standard Time'],
    'America/Los_Angeles'         => ['Pacific Standard Time'],
    'America/Louisville'          => ['Eastern Standard Time'],
    'America/Lower_Princes'       => ['SA Western Standard Time'],
    'America/Maceio'              => ['SA Eastern Standard Time'],
    'America/Managua'             => ['Central America Standard Time'],
    'America/Manaus'              => ['SA Western Standard Time'],
    'America/Marigot'             => ['SA Western Standard Time'],
    'America/Martinique'          => ['SA Western Standard Time'],
    'America/Matamoros'           => ['Central Standard Time'],
    'America/Mazatlan'            => ['Mountain Standard Time (Mexico)'],
    'America/Mendoza'             => ['Argentina Standard Time'],
    'America/Menominee'           => ['Central Standard Time'],
    'America/Merida'              => ['Central Standard Time (Mexico)'],
    'America/Metlakatla'          => ['Alaskan Standard Time'],
    'America/Mexico_City'         =>
      [ 'Mexico Standard Time', 'Central Standard Time (Mexico)' ],
    'America/Miquelon'               => ['Saint Pierre Standard Time'],
    'America/Moncton'                => ['Atlantic Standard Time'],
    'America/Monterrey'              => ['Central Standard Time (Mexico)'],
    'America/Montevideo'             => ['Montevideo Standard Time'],
    'America/Montreal'               => ['Eastern Standard Time'],
    'America/Montserrat'             => ['SA Western Standard Time'],
    'America/Nassau'                 => ['Eastern Standard Time'],
    'America/New_York'               => ['Eastern Standard Time'],
    'America/Nipigon'                => ['Eastern Standard Time'],
    'America/Nome'                   => ['Alaskan Standard Time'],
    'America/Noronha'                => ['UTC-02'],
    'America/North_Dakota/Beulah'    => ['Central Standard Time'],
    'America/North_Dakota/Center'    => ['Central Standard Time'],
    'America/North_Dakota/New_Salem' => ['Central Standard Time'],
    'America/Ojinaga'                => ['Mountain Standard Time'],
    'America/Panama'                 => ['SA Pacific Standard Time'],
    'America/Pangnirtung'            => ['Eastern Standard Time'],
    'America/Paramaribo'             => ['SA Eastern Standard Time'],
    'America/Phoenix'                => ['US Mountain Standard Time'],
    'America/Port-au-Prince'         => ['Haiti Standard Time'],
    'America/Port_of_Spain'          => ['SA Western Standard Time'],
    'America/Porto_Velho'            => ['SA Western Standard Time'],
    'America/Puerto_Rico'            => ['SA Western Standard Time'],
    'America/Punta_Arenas'           =>
      [ 'Magallanes Standard Time', 'SA Eastern Standard Time' ],
    'America/Rainy_River'   => ['Central Standard Time'],
    'America/Rankin_Inlet'  => ['Central Standard Time'],
    'America/Recife'        => ['SA Eastern Standard Time'],
    'America/Regina'        => ['Canada Central Standard Time'],
    'America/Resolute'      => ['Central Standard Time'],
    'America/Rio_Branco'    => ['SA Pacific Standard Time'],
    'America/Santa_Isabel'  => ['Pacific Standard Time (Mexico)'],
    'America/Santarem'      => ['SA Eastern Standard Time'],
    'America/Santiago'      => ['Pacific SA Standard Time'],
    'America/Santo_Domingo' => ['SA Western Standard Time'],
    'America/Sao_Paulo'     => ['E. South America Standard Time'],
    'America/Scoresbysund'  => ['Azores Standard Time'],
    'America/Sitka'         => ['Alaskan Standard Time'],
    'America/St_Barthelemy' => ['SA Western Standard Time'],
    'America/St_Johns'      => ['Newfoundland Standard Time'],
    'America/St_Kitts'      => ['SA Western Standard Time'],
    'America/St_Lucia'      => ['SA Western Standard Time'],
    'America/St_Thomas'     => ['SA Western Standard Time'],
    'America/St_Vincent'    => ['SA Western Standard Time'],
    'America/Swift_Current' => ['Canada Central Standard Time'],
    'America/Tegucigalpa'   => ['Central America Standard Time'],
    'America/Thule'         => ['Atlantic Standard Time'],
    'America/Thunder_Bay'   => ['Eastern Standard Time'],
    'America/Tijuana'       => ['Pacific Standard Time (Mexico)'],
    'America/Toronto'       => ['Eastern Standard Time'],
    'America/Tortola'       => ['SA Western Standard Time'],
    'America/Vancouver'     => ['Pacific Standard Time'],
    'America/Whitehorse'  => [ 'Yukon Standard Time', 'Pacific Standard Time' ],
    'America/Winnipeg'    => ['Central Standard Time'],
    'America/Yakutat'     => ['Alaskan Standard Time'],
    'America/Yellowknife' => ['Mountain Standard Time'],
    'Antarctica/Casey'    => ['Central Pacific Standard Time'],
    'Antarctica/Davis'    => ['SE Asia Standard Time'],
    'Antarctica/DumontDUrville' => ['West Pacific Standard Time'],
    'Antarctica/Macquarie'      => ['Central Pacific Standard Time'],
    'Antarctica/Mawson'         => ['West Asia Standard Time'],
    'Antarctica/McMurdo'        => ['New Zealand Standard Time'],
    'Antarctica/Palmer'         => ['SA Eastern Standard Time'],
    'Antarctica/Rothera'        => ['SA Eastern Standard Time'],
    'Antarctica/Syowa'          => ['E. Africa Standard Time'],
    'Antarctica/Vostok'         => ['Central Asia Standard Time'],
    'Arctic/Longyearbyen'       => ['W. Europe Standard Time'],
    'Asia/Aden'                 => ['Arab Standard Time'],
    'Asia/Almaty'               => ['Central Asia Standard Time'],
    'Asia/Amman'                => ['Jordan Standard Time'],
    'Asia/Anadyr'               => ['Russia Time Zone 11'],
    'Asia/Aqtau'                => ['West Asia Standard Time'],
    'Asia/Aqtobe'               => ['West Asia Standard Time'],
    'Asia/Ashgabat'             => ['West Asia Standard Time'],
    'Asia/Atyrau'               => ['West Asia Standard Time'],
    'Asia/Baghdad'              => ['Arabic Standard Time'],
    'Asia/Bahrain'              => ['Arab Standard Time'],
    'Asia/Baku'                 => ['Azerbaijan Standard Time'],
    'Asia/Bangkok'              => ['SE Asia Standard Time'],
    'Asia/Barnaul'              => ['Altai Standard Time'],
    'Asia/Beirut'               => ['Middle East Standard Time'],
    'Asia/Bishkek'              => ['Central Asia Standard Time'],
    'Asia/Brunei'               => ['Singapore Standard Time'],
    'Asia/Calcutta'             => ['India Standard Time'],
    'Asia/Chita'                => ['Transbaikal Standard Time'],
    'Asia/Choibalsan'           => ['Ulaanbaatar Standard Time'],
    'Asia/Colombo'              => ['Sri Lanka Standard Time'],
    'Asia/Damascus'             => ['Syria Standard Time'],
    'Asia/Dhaka'                => ['Bangladesh Standard Time'],
    'Asia/Dili'                 => ['Tokyo Standard Time'],
    'Asia/Dubai'                => ['Arabian Standard Time'],
    'Asia/Dushanbe'             => ['West Asia Standard Time'],
    'Asia/Famagusta'            => ['Turkey Standard Time'],
    'Asia/Gaza'                 => ['West Bank Standard Time'],
    'Asia/Hebron'               => ['West Bank Standard Time'],
    'Asia/Hong_Kong'            => ['China Standard Time'],
    'Asia/Hovd'                 => ['W. Mongolia Standard Time'],
    'Asia/Irkutsk'              => ['North Asia East Standard Time'],
    'Asia/Jakarta'              => ['SE Asia Standard Time'],
    'Asia/Jayapura'             => ['Tokyo Standard Time'],
    'Asia/Jerusalem'            => ['Israel Standard Time'],
    'Asia/Kabul'                => ['Afghanistan Standard Time'],
    'Asia/Kamchatka'    => [ 'Kamchatka Standard Time', 'Russia Time Zone 11' ],
    'Asia/Karachi'      => ['Pakistan Standard Time'],
    'Asia/Katmandu'     => ['Nepal Standard Time'],
    'Asia/Khandyga'     => ['Yakutsk Standard Time'],
    'Asia/Krasnoyarsk'  => ['North Asia Standard Time'],
    'Asia/Kuala_Lumpur' => ['Singapore Standard Time'],
    'Asia/Kuching'      => ['Singapore Standard Time'],
    'Asia/Kuwait'       => ['Arab Standard Time'],
    'Asia/Macau'        => ['China Standard Time'],
    'Asia/Magadan'      => ['Magadan Standard Time'],
    'Asia/Makassar'     => ['Singapore Standard Time'],
    'Asia/Manila'       => ['Singapore Standard Time'],
    'Asia/Muscat'       => ['Arabian Standard Time'],
    'Asia/Nicosia'      => ['GTB Standard Time'],
    'Asia/Novokuznetsk' => ['North Asia Standard Time'],
    'Asia/Novosibirsk'  => ['N. Central Asia Standard Time'],
    'Asia/Omsk'         => ['Omsk Standard Time'],
    'Asia/Qostanay'     => ['Central Asia Standard Time'],
    'Asia/Oral'         => ['West Asia Standard Time'],
    'Asia/Phnom_Penh'   => ['SE Asia Standard Time'],
    'Asia/Pontianak'    => ['SE Asia Standard Time'],
    'Asia/Pyongyang'    => ['North Korea Standard Time'],
    'Asia/Qatar'        => ['Arab Standard Time'],
    'Asia/Qyzylorda'    =>
      [ 'Qyzylorda Standard Time', 'Central Asia Standard Time' ],
    'Asia/Rangoon'       => ['Myanmar Standard Time'],
    'Asia/Riyadh'        => ['Arab Standard Time'],
    'Asia/Saigon'        => ['SE Asia Standard Time'],
    'Asia/Sakhalin'      => ['Sakhalin Standard Time'],
    'Asia/Samarkand'     => ['West Asia Standard Time'],
    'Asia/Seoul'         => ['Korea Standard Time'],
    'Asia/Shanghai'      => ['China Standard Time'],
    'Asia/Singapore'     => ['Singapore Standard Time'],
    'Asia/Srednekolymsk' => ['Russia Time Zone 10'],
    'Asia/Taipei'        => ['Taipei Standard Time'],
    'Asia/Tashkent'      => ['West Asia Standard Time'],
    'Asia/Tbilisi'       => ['Georgian Standard Time'],
    'Asia/Tehran'        => ['Iran Standard Time'],
    'Asia/Thimphu'       => ['Bangladesh Standard Time'],
    'Asia/Tokyo'         => ['Tokyo Standard Time'],
    'Asia/Tomsk'         => ['Tomsk Standard Time'],
    'Asia/Ulaanbaatar'   => ['Ulaanbaatar Standard Time'],
    'Asia/Urumqi'        => ['Central Asia Standard Time'],
    'Asia/Ust-Nera'      => ['Vladivostok Standard Time'],
    'Asia/Vientiane'     => ['SE Asia Standard Time'],
    'Asia/Vladivostok'   => ['Vladivostok Standard Time'],
    'Asia/Yakutsk'       => ['Yakutsk Standard Time'],
    'Asia/Yekaterinburg' => ['Ekaterinburg Standard Time'],
    'Asia/Yerevan'    => [ 'Armenian Standard Time', 'Caucasus Standard Time' ],
    'Atlantic/Azores' => ['Azores Standard Time'],
    'Atlantic/Bermuda'       => ['Atlantic Standard Time'],
    'Atlantic/Canary'        => ['GMT Standard Time'],
    'Atlantic/Cape_Verde'    => ['Cape Verde Standard Time'],
    'Atlantic/Faeroe'        => ['GMT Standard Time'],
    'Atlantic/Madeira'       => ['GMT Standard Time'],
    'Atlantic/Reykjavik'     => ['Greenwich Standard Time'],
    'Atlantic/South_Georgia' => ['UTC-02'],
    'Atlantic/St_Helena'     => ['Greenwich Standard Time'],
    'Atlantic/Stanley'       => ['SA Eastern Standard Time'],
    'Australia/Adelaide'     => ['Cen. Australia Standard Time'],
    'Australia/Brisbane'     => ['E. Australia Standard Time'],
    'Australia/Broken_Hill'  => ['Cen. Australia Standard Time'],
    'Australia/Currie'       => ['Tasmania Standard Time'],
    'Australia/Darwin'       => ['AUS Central Standard Time'],
    'Australia/Eucla'        => ['Aus Central W. Standard Time'],
    'Australia/Hobart'       => ['Tasmania Standard Time'],
    'Australia/Lindeman'     => ['E. Australia Standard Time'],
    'Australia/Lord_Howe'    => ['Lord Howe Standard Time'],
    'Australia/Melbourne'    => ['AUS Eastern Standard Time'],
    'Australia/Perth'        => ['W. Australia Standard Time'],
    'Australia/Sydney'       => ['AUS Eastern Standard Time'],
    'CST6CDT'                => ['Central Standard Time'],
    'EST5EDT'                => ['Eastern Standard Time'],
    'Etc/GMT'                => ['UTC'],
    'Etc/GMT+1'              => ['Cape Verde Standard Time'],
    'Etc/GMT+10'             => ['Hawaiian Standard Time'],
    'Etc/GMT+11'             => ['UTC-11'],
    'Etc/GMT+12'             => ['Dateline Standard Time'],
    'Etc/GMT+2'              => ['UTC-02'],
    'Etc/GMT+3'              => ['SA Eastern Standard Time'],
    'Etc/GMT+4'              => ['SA Western Standard Time'],
    'Etc/GMT+5'              => ['SA Pacific Standard Time'],
    'Etc/GMT+6'              => ['Central America Standard Time'],
    'Etc/GMT+7'              => ['US Mountain Standard Time'],
    'Etc/GMT+8'              => ['UTC-08'],
    'Etc/GMT+9'              => ['UTC-09'],
    'Etc/GMT-1'              => ['W. Central Africa Standard Time'],
    'Etc/GMT-10'             => ['West Pacific Standard Time'],
    'Etc/GMT-11'             => ['Central Pacific Standard Time'],
    'Etc/GMT-12'             => ['UTC+12'],
    'Etc/GMT-13'             => ['Tonga Standard Time'],
    'Etc/GMT-14'             => ['Line Islands Standard Time'],
    'Etc/GMT-2'              => ['South Africa Standard Time'],
    'Etc/GMT-3'              => ['E. Africa Standard Time'],
    'Etc/GMT-4'              => ['Arabian Standard Time'],
    'Etc/GMT-5'              => ['West Asia Standard Time'],
    'Etc/GMT-6'              => ['Central Asia Standard Time'],
    'Etc/GMT-7'              => ['SE Asia Standard Time'],
    'Etc/GMT-8'              => ['Singapore Standard Time'],
    'Etc/GMT-9'              => ['Tokyo Standard Time'],
    'Etc/UTC'                => ['UTC'],
    'Europe/Amsterdam'       => ['W. Europe Standard Time'],
    'Europe/Andorra'         => ['W. Europe Standard Time'],
    'Europe/Astrakhan'       => ['Astrakhan Standard Time'],
    'Europe/Athens'          => ['GTB Standard Time'],
    'Europe/Belgrade'        => ['Central Europe Standard Time'],
    'Europe/Berlin'          => ['W. Europe Standard Time'],
    'Europe/Bratislava'      => ['Central Europe Standard Time'],
    'Europe/Brussels'        => ['Romance Standard Time'],
    'Europe/Bucharest'       => ['GTB Standard Time'],
    'Europe/Budapest'        => ['Central Europe Standard Time'],
    'Europe/Busingen'        => ['W. Europe Standard Time'],
    'Europe/Chisinau'        => ['E. Europe Standard Time'],
    'Europe/Copenhagen'      => ['Romance Standard Time'],
    'Europe/Dublin'          => ['GMT Standard Time'],
    'Europe/Gibraltar'       => ['W. Europe Standard Time'],
    'Europe/Guernsey'        => ['GMT Standard Time'],
    'Europe/Helsinki'        => ['FLE Standard Time'],
    'Europe/Isle_of_Man'     => ['GMT Standard Time'],
    'Europe/Istanbul'        => ['Turkey Standard Time'],
    'Europe/Jersey'          => ['GMT Standard Time'],
    'Europe/Kaliningrad'     => ['Kaliningrad Standard Time'],
    'Europe/Kiev'            => ['FLE Standard Time'],
    'Europe/Kirov'           => ['Russian Standard Time'],
    'Europe/Lisbon'          => ['GMT Standard Time'],
    'Europe/Ljubljana'       => ['Central Europe Standard Time'],
    'Europe/London'          => ['GMT Standard Time'],
    'Europe/Luxembourg'      => ['W. Europe Standard Time'],
    'Europe/Madrid'          => ['Romance Standard Time'],
    'Europe/Malta'           => ['W. Europe Standard Time'],
    'Europe/Mariehamn'       => ['FLE Standard Time'],
    'Europe/Minsk'           => ['Belarus Standard Time'],
    'Europe/Monaco'          => ['W. Europe Standard Time'],
    'Europe/Moscow'          => ['Russian Standard Time'],
    'Europe/Oslo'            => ['W. Europe Standard Time'],
    'Europe/Paris'           => ['Romance Standard Time'],
    'Europe/Podgorica'       => ['Central Europe Standard Time'],
    'Europe/Prague'          => ['Central Europe Standard Time'],
    'Europe/Riga'            => ['FLE Standard Time'],
    'Europe/Rome'            => ['W. Europe Standard Time'],
    'Europe/Samara'          => ['Russia Time Zone 3'],
    'Europe/San_Marino'      => ['W. Europe Standard Time'],
    'Europe/Sarajevo'        => ['Central European Standard Time'],
    'Europe/Saratov' => [ 'Saratov Standard Time', 'Astrakhan Standard Time' ],
    'Europe/Simferopol' => ['Russian Standard Time'],
    'Europe/Skopje'     => ['Central European Standard Time'],
    'Europe/Sofia'      => ['FLE Standard Time'],
    'Europe/Stockholm'  => ['W. Europe Standard Time'],
    'Europe/Tallinn'    => ['FLE Standard Time'],
    'Europe/Tirane'     => ['Central Europe Standard Time'],
    'Europe/Ulyanovsk'  => ['Astrakhan Standard Time'],
    'Europe/Uzhgorod'   => ['FLE Standard Time'],
    'Europe/Vaduz'      => ['W. Europe Standard Time'],
    'Europe/Vatican'    => ['W. Europe Standard Time'],
    'Europe/Vienna'     => ['W. Europe Standard Time'],
    'Europe/Vilnius'    => ['FLE Standard Time'],
    'Europe/Volgograd'  =>
      [ 'Volgograd Standard Time', 'Russian Standard Time' ],
    'Europe/Warsaw'        => ['Central European Standard Time'],
    'Europe/Zagreb'        => ['Central European Standard Time'],
    'Europe/Zaporozhye'    => ['FLE Standard Time'],
    'Europe/Zurich'        => ['W. Europe Standard Time'],
    'Indian/Antananarivo'  => ['E. Africa Standard Time'],
    'Indian/Chagos'        => ['Central Asia Standard Time'],
    'Indian/Christmas'     => ['SE Asia Standard Time'],
    'Indian/Cocos'         => ['Myanmar Standard Time'],
    'Indian/Comoro'        => ['E. Africa Standard Time'],
    'Indian/Kerguelen'     => ['West Asia Standard Time'],
    'Indian/Mahe'          => ['Mauritius Standard Time'],
    'Indian/Maldives'      => ['West Asia Standard Time'],
    'Indian/Mauritius'     => ['Mauritius Standard Time'],
    'Indian/Mayotte'       => ['E. Africa Standard Time'],
    'Indian/Reunion'       => ['Mauritius Standard Time'],
    'MST7MDT'              => ['Mountain Standard Time'],
    'PST8PDT'              => ['Pacific Standard Time'],
    'Pacific/Apia'         => ['Samoa Standard Time'],
    'Pacific/Auckland'     => ['New Zealand Standard Time'],
    'Pacific/Bougainville' => ['Bougainville Standard Time'],
    'Pacific/Chatham'      => ['Chatham Islands Standard Time'],
    'Pacific/Easter'       => ['Easter Island Standard Time'],
    'Pacific/Efate'        => ['Central Pacific Standard Time'],
    'Pacific/Enderbury'    => ['Tonga Standard Time'],
    'Pacific/Fakaofo'      => ['Tonga Standard Time'],
    'Pacific/Fiji'         => ['Fiji Standard Time'],
    'Pacific/Funafuti'     => ['UTC+12'],
    'Pacific/Galapagos'    => ['Central America Standard Time'],
    'Pacific/Gambier'      => ['UTC-09'],
    'Pacific/Guadalcanal'  => ['Central Pacific Standard Time'],
    'Pacific/Guam'         => ['West Pacific Standard Time'],
    'Pacific/Honolulu'     => ['Hawaiian Standard Time'],
    'Pacific/Johnston'     => ['Hawaiian Standard Time'],
    'Pacific/Kiritimati'   => ['Line Islands Standard Time'],
    'Pacific/Kosrae'       => ['Central Pacific Standard Time'],
    'Pacific/Kwajalein'    => ['UTC+12'],
    'Pacific/Majuro'       => ['UTC+12'],
    'Pacific/Marquesas'    => ['Marquesas Standard Time'],
    'Pacific/Midway'       => ['UTC-11'],
    'Pacific/Nauru'        => ['UTC+12'],
    'Pacific/Niue'         => ['UTC-11'],
    'Pacific/Norfolk'      => ['Norfolk Standard Time'],
    'Pacific/Noumea'       => ['Central Pacific Standard Time'],
    'Pacific/Pago_Pago'    => ['UTC-11'],
    'Pacific/Palau'        => ['Tokyo Standard Time'],
    'Pacific/Pitcairn'     => ['UTC-08'],
    'Pacific/Ponape'       => ['Central Pacific Standard Time'],
    'Pacific/Port_Moresby' => ['West Pacific Standard Time'],
    'Pacific/Rarotonga'    => ['Hawaiian Standard Time'],
    'Pacific/Saipan'       => ['West Pacific Standard Time'],
    'Pacific/Tahiti'       => ['Hawaiian Standard Time'],
    'Pacific/Tarawa'       => ['UTC+12'],
    'Pacific/Tongatapu'    => ['Tonga Standard Time'],
    'Pacific/Truk'         => ['West Pacific Standard Time'],
    'Pacific/Wake'         => ['UTC+12'],
    'Pacific/Wallis'       => ['UTC+12'],
    'UTC'                  => ['UTC'],
);

sub _DEFAULT_ZONEINFO_DIRECTORY { return $_default_zoneinfo_directory }

sub new {
    my ( $class, %params ) = @_;
    my $self = {};
    bless $self, $class;
    if (   ( $OSNAME eq 'MSWin32' )
        && ( !$params{directory} )
        && ( !$ENV{TZDIR} ) )
    {
        $self->{_win32_registry} = 1;
    }
    else {
        $self->directory( $params{directory}
              || $ENV{TZDIR}
              || _DEFAULT_ZONEINFO_DIRECTORY() );
    }
    if ( defined $params{offset} ) {
        $self->offset( $params{offset} );
    }
    else {
        my $env_tz;
        if ( ( exists $ENV{TZ} ) && ( defined $ENV{TZ} ) ) {
            if ( ( $ENV{TZ} eq 'localtime' ) && ( $OSNAME eq 'solaris' ) ) {
            }
            else {
                $env_tz = $ENV{TZ};
            }
        }
        if ( ( defined $params{timezone} ) || ( defined $env_tz ) ) {
            $self->timezone( $params{timezone} || $env_tz );
        }
    }
    return $self;
}

sub _resolved_directory_path {
    my ($self) = @_;
    my $path = $self->directory();
    if ( defined $path ) {
        while ( my $readlink = readlink $path )
        {    # darwin has multiple layers of symlinks
            $path = $readlink;
        }
    }
    return $path;
}

sub directory {
    my ( $self, $new ) = @_;
    my $old = $self->{directory};
    if ( defined $new ) {
        $self->{directory} = $new;
    }
    return $old;
}

sub offset {
    my ( $self, $new ) = @_;
    my $old = $self->{offset};
    if ( defined $new ) {
        $self->{offset} = $new;
        delete $self->{tz};
    }
    return $old;
}

sub equiv {
    my ( $self, $compare_time_zone, $from_time ) = @_;
    $from_time = defined $from_time ? $from_time : time;
    my $class   = ref $self;
    my $compare = $class->new( 'timezone' => $compare_time_zone );
    my $now     = time;
    my %offsets_compare;
    foreach my $transition_time ( $compare->transition_times() ) {
        if ( $transition_time >= $from_time ) {
            $offsets_compare{$transition_time} =
              $compare->local_offset($transition_time);
        }
    }
    my %offsets_self;
    foreach my $transition_time ( $self->transition_times() ) {
        if ( $transition_time >= $from_time ) {
            $offsets_self{$transition_time} =
              $self->local_offset($transition_time);
        }
    }
    if ( scalar keys %offsets_compare == scalar keys %offsets_self ) {
        foreach my $transition_time ( sort { $a <=> $b } keys %offsets_compare )
        {
            if (
                ( defined $offsets_self{$transition_time} )
                && ( $offsets_self{$transition_time} ==
                    $offsets_compare{$transition_time} )
              )
            {
            }
            else {
                return;
            }
        }
        if ( $self->_tz_definition_equiv($compare) ) {
            return 1;
        }
    }
    return;
}

sub _tz_definition_equiv {
    my ( $self, $compare ) = @_;
    my $current_time_zone = $self->timezone();
    my $compare_time_zone = $compare->timezone();
    if ( ( defined $self->{_tzdata}->{$current_time_zone}->{tz_definition} )
        && (
            defined $compare->{_tzdata}->{$compare_time_zone}->{tz_definition} )
      )
    {
        my $current_tz_definition =
          $self->{_tzdata}->{$current_time_zone}->{tz_definition};
        my $compare_tz_definition =
          $compare->{_tzdata}->{$compare_time_zone}->{tz_definition};
        foreach my $key ( _TZ_DEFINITION_KEYS() ) {
            next if ( $key eq 'std_name' );
            next if ( $key eq 'dst_name' );
            if (    ( defined $current_tz_definition->{$key} )
                and ( defined $compare_tz_definition->{$key} ) )
            {
                if ( ( $key eq 'std_sign' ) or ( $key eq 'dst_sign' ) ) {
                    if ( $current_tz_definition->{$key} ne
                        $compare_tz_definition->{$key} )
                    {
                        return;
                    }
                }
                else {
                    if ( $current_tz_definition->{$key} !=
                        $compare_tz_definition->{$key} )
                    {
                        return;
                    }
                }
            }
            elsif ( defined $current_tz_definition->{$key} ) {
                return;
            }
            elsif ( defined $compare_tz_definition->{$key} ) {
                return;
            }
        }
    }
    elsif ( defined $self->{_tzdata}->{$current_time_zone}->{tz_definition} ) {
        return;
    }
    elsif ( defined $compare->{_tzdata}->{$compare_time_zone}->{tz_definition} )
    {
        return;
    }
    return 1;
}

sub _timezones {
    my ($self) = @_;
    if ( $self->win32_registry() ) {
        return $self->_win32_timezones();
    }
    else {
        return $self->_unix_timezones();
    }
}

sub _win32_timezones {
    my ($self) = @_;
    my %mapping = $self->win32_mapping();
    $self->{_zones} = [ keys %mapping ];
    my @sorted_zones = sort { $a cmp $b } @{ $self->{_zones} };
    return @sorted_zones;
}

sub _unix_timezones {
    my ($self) = @_;
    my @paths = (
        File::Spec->catfile( $self->directory(), 'zone1970.tab' ),
        File::Spec->catfile( $self->directory(), 'zone.tab' ),
    );
    if ( $OSNAME eq 'solaris' ) {
        push @paths,
          File::Spec->catfile( $self->directory(), 'tab', 'zone_sun.tab' );
    }
    if ( $self->{_unix_zonetab_path} ) {
        if ( $self->{_unix_zonetab_path} ne $paths[0] ) {
            unshift @paths, $self->{_unix_zonetab_path};
        }
    }
    my $last_path;
    foreach my $path (@paths) {
        if ( my @sorted_zones = $self->_read_unix_timezones($path) ) {
            $self->{_unix_zonetab_path} = $path;
            return @sorted_zones;
        }
        else {
            $last_path = $path;
        }
    }
    delete $self->{_unix_zonetab_path};
    Carp::croak("Failed to open $last_path for reading:$EXTENDED_OS_ERROR");
}

sub _read_unix_timezones {
    my ( $self, $path ) = @_;
    my $handle = FileHandle->new($path)
      or return ();
    my @stat = stat $handle
      or Carp::croak("Failed to stat $path:$EXTENDED_OS_ERROR");
    my $last_modified = $stat[ _STAT_MTIME_IDX() ];
    if (   ( $self->{_zonetab_last_modified} )
        && ( $self->{_zonetab_last_modified} == $last_modified ) )
    {
    }
    elsif (( $_zonetab_cache->{_zonetab_last_modified} )
        && ( $_zonetab_cache->{_zonetab_last_modified} == $last_modified ) )
    {

        foreach my $key (qw(_zonetab_last_modified _comments _zones)) {
            $self->{$key} = $_zonetab_cache->{$key};
        }
    }
    else {
        $self->{_zones}    = [];
        $self->{_comments} = {};
        while ( my $encoded = <$handle> ) {
            next if ( $encoded =~ /^[#]/smx );
            my $decoded;
            if ( $path =~ /zone1970[.]tab$/smx ) {
                $decoded = Encode::decode( 'UTF-8', $encoded, 1 );
            }
            else {
                $decoded = $encoded;
            }
            chomp $decoded;
            my ( $country_code, $coordinates, $timezone, $comment ) =
              split /\t/smx, $decoded;
            my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
            if ( $timezone =~ /^$timezone_full_name_regex$/smx ) {
                push @{ $self->{_zones} }, $timezone;
                $self->{_comments}->{$timezone} = $comment;
            }
        }
        close $handle
          or Carp::croak("Failed to close $path:$EXTENDED_OS_ERROR");
        $self->{_zonetab_last_modified} = $last_modified;
        foreach my $key (qw(_zonetab_last_modified _comments _zones)) {
            $_zonetab_cache->{$key} = $self->{$key};
        }
    }
    my @sorted_zones = sort { $a cmp $b } @{ $self->{_zones} };
    return @sorted_zones;
}

sub areas {
    my ($self) = @_;
    my %areas;
    foreach my $timezone ( $self->_timezones() ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $timezone =~ /^$timezone_full_name_regex$/smx ) {
            my ( $tz, $area, $location ) =
              $self->_matched_timezone_full_name_regex_all();
            $areas{$area} = 1;
        }
        else {
            Carp::croak(
                "'$timezone' does not have a valid format for a TZ timezone");
        }
    }
    my @sorted_areas = sort { $a cmp $b } keys %areas;
    return @sorted_areas;
}

sub locations {
    my ( $self, $area ) = @_;
    if ( !length $area ) {
        return ();
    }
    my %locations;
    foreach my $timezone ( $self->_timezones() ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $timezone =~ /^$timezone_full_name_regex$/smx ) {
            my ( $tz, $extracted_area, $location ) =
              $self->_matched_timezone_full_name_regex_all();
            if (   ( $area eq $extracted_area )
                && ($location) )
            {
                $locations{$location} = 1;
            }
        }
        else {
            Carp::croak(
                "'$timezone' does not have a valid format for a TZ timezone");
        }
    }
    my @sorted_locations = sort { $a cmp $b } keys %locations;
    return @sorted_locations;
}

sub comment {
    my ( $self, $tz ) = @_;
    $tz ||= $self->timezone();
    $self->_timezones();
    if ( $self->win32_registry() ) {
        $self->_read_win32_tzfile($tz);
    }
    if ( defined $self->{_comments}->{$tz} ) {
        return $self->{_comments}->{$tz};
    }
    else {
        return;
    }
}

sub area {
    my ($self) = @_;
    if ( !defined $self->{area} ) {
        $self->timezone();
    }
    return $self->{area};
}

sub location {
    my ($self) = @_;
    if ( !defined $self->{area} ) {
        $self->timezone();
    }
    return $self->{location};
}

sub _matched_timezone_full_name_regex_all {
    my ($self) = @_;
    my ( $tz, $area, $location );
    if ($_modern_regexs_work) {
        $tz       = $LAST_PAREN_MATCH{tz};
        $area     = $LAST_PAREN_MATCH{area};
        $location = $LAST_PAREN_MATCH{location};
    }
    else {
        ( $tz, $area, $location ) = ( $1, $2, $3 );
    }
    return ( $tz, $area, $location );
}

sub _matched_timezone_full_name_regex_tz {
    my ($self) = @_;
    ( my $tz, $self->{area}, my $location ) =
      $self->_matched_timezone_full_name_regex_all();
    if ( defined $location ) {
        $self->{location} = $location;
    }
    else {
        delete $self->{location};
    }
    return $tz;
}

sub timezone {
    my ( $self, $new ) = @_;
    my $old = $self->{tz};
    if ( defined $new ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $new =~ /^$timezone_full_name_regex$/smx ) {
            $self->{tz} = $self->_matched_timezone_full_name_regex_tz();
            if ( $self->win32_registry() ) {
                my %mapping = $self->win32_mapping();
                if ( !defined $mapping{$new} ) {
                    Carp::croak(
"'$new' is not a time zone in the existing Win32 registry"
                    );
                }
            }
            else {
                my @directories;
                foreach my $key (qw(area location)) {
                    if ( defined $self->{$key} ) {
                        push @directories, $self->{$key};
                    }
                }
                my $path =
                  File::Spec->catfile( $self->directory(), @directories );
                if ( !-f $path ) {
                    Carp::croak(
"'$new' is not a time zone in the existing Olson database"
                    );
                }
            }
        }
        elsif ( my $tz_definition = $self->_parse_tz_variable( $new, 'TZ' ) ) {
            $self->{_tzdata}->{ $tz_definition->{tz} } = {
                tz_definition    => $tz_definition,
                transition_times => [],
                no_tz_file       => 1,
            };
            $self->{tz} = $tz_definition->{tz};
        }
        else {
            Carp::croak(
                "'$new' does not have a valid format for a TZ timezone");
        }
        if ( ( defined $new ) && ( defined $old ) && ( $old eq $new ) ) {
            foreach my $key (qw(_zonetab_last_modified _comments _zones)) {
                delete $self->{$key};
            }
            $_tzdata_cache  = {};
            $_zonetab_cache = {};
        }
        delete $self->{offset};
    }
    elsif ( !defined $old ) {
        $self->{tz} = $self->_guess_tz();
        $old = $self->{tz};
    }
    return $old;
}

sub _guess_tz {
    my ($self) = @_;
    if ( $OSNAME eq 'MSWin32' ) {
        return $self->_guess_win32_tz();
    }
    else {
        return $self->_guess_olson_tz();
    }
}

sub determining_path {
    my ($self) = @_;
    if ( !defined $self->{determining_path} ) {
        $self->_guess_tz();
    }
    return $self->{determining_path};
}

sub _guess_olson_tz {
    my ($self)      = @_;
    my $path        = '/etc/localtime';
    my $base        = $self->_resolved_directory_path();
    my $quoted_base = quotemeta $base;
    if ( my $readlink = readlink $path ) {
        my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
        if ( $readlink =~ /$quoted_base.$timezone_full_name_regex$/smx ) {
            my $guessed = $self->_matched_timezone_full_name_regex_tz();
            $self->{determining_path} = $path;
            return $guessed;
        }
    }
    elsif (
        ( $EXTENDED_OS_ERROR == POSIX::EINVAL() )
        || (   ( $EXTENDED_OS_ERROR == POSIX::ENOENT() )
            && ( $OSNAME eq 'cygwin' ) )
      )
    {
        my @paths;
        my %paths = (
            'dragonfly' => [
                '/var/db/zoneinfo',    # dragonfly 5
            ],
            'freebsd' => [
                '/var/db/zoneinfo',    # freebsd 11
            ],
            'gnukfreebsd' => [
                '/etc/timezone',       # gnukfreebsd 10,
            ],
            'linux' => [
                '/etc/timezone',           # debian jessie
                '/etc/sysconfig/clock',    # rhel6, opensuse, empty in rhel7
            ],
            'cygwin' => [
'/proc/registry/HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/TimeZoneInformation/TimeZoneKeyName',
            ],
        );
        if ( $paths{$OSNAME} ) {
            foreach my $path ( @{ $paths{$OSNAME} } ) {
                if ( my $handle = FileHandle->new( $path, Fcntl::O_RDONLY() ) )
                {
                    if (
                        my $guessed =
                        $self->_guess_olson_tz_from_file_contents(
                            $path, $handle
                        )
                      )
                    {
                        $self->{determining_path} = $path;
                        return $guessed;
                    }
                }
            }
        }
    }
    my $guessed;
    if ( my $handle = FileHandle->new( $path, Fcntl::O_RDONLY() ) ) {
        my $digest = Digest::SHA->new('sha512');
        $digest->addfile($handle);
        my $localtime_digest = $digest->hexdigest();
        File::Find::find(
            {
                'no_chdir' => 1,
                'wanted'   => sub {
                    if (
                        my $possible = $self->_guess_olson_tz_from_filesystem(
                            $base, $localtime_digest
                        )
                      )
                    {
                        $guessed = $possible;
                    }
                },
            },
            $base
        );
    }
    return $guessed;
}

sub _guess_olson_tz_from_file_contents {
    my ( $self, $path, $handle ) = @_;
    my $result =
      $handle->read( my $buffer, _MAX_SIZE_FOR_A_GUESS_FILE_CONTENTS() );
    defined $result
      or Carp::croak("Failed to read from $path:$EXTENDED_OS_ERROR");
    close $handle
      or Carp::croak("Failed to close $path:$EXTENDED_OS_ERROR");
    chomp $buffer;
    my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
    foreach my $line ( split /\r?\n/smx, $buffer ) {
        if ( $OSNAME eq 'cygwin' ) {
            $line =~ s/\0$//smx;
            foreach
              my $possible ( sort { $a cmp $b } keys %olson_to_win32_timezones )
            {
                foreach my $win32_tz_name (
                    @{ $olson_to_win32_timezones{$possible} } )
                {
                    if (   ( $win32_tz_name eq $line )
                        && ( $possible =~ /^$timezone_full_name_regex$/smx ) )
                    {
                        my $guessed =
                          $self->_matched_timezone_full_name_regex_tz();
                        $self->{determining_path} = $path;
                        return $guessed;

                    }
                }
            }
        }
        if (
            $line =~ m{^
                                (?:(?:TIME)?ZONE=")? # for \/etc\/sysconfig\/clock
                                $timezone_full_name_regex
                                "? # for \/etc\/sysconfig\/clock
                                $}smx
          )
        {
            my $guessed = $self->_matched_timezone_full_name_regex_tz();
            $self->{determining_path} = $path;
            return $guessed;
        }
    }
    return;
}

sub _guess_olson_tz_from_filesystem {
    my ( $self, $base, $localtime_digest ) = @_;
    my $quoted_base              = quotemeta $base;
    my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
    if ( $File::Find::name =~ /^$quoted_base.$timezone_full_name_regex$/smx ) {
        my ( $tz, $area, $location ) =
          $self->_matched_timezone_full_name_regex_all();
        my $path;
        if ( $self->_check_area_location( $area, $location ) ) {
            if ( defined $location ) {
                $path = File::Spec->catfile( $base, $area, $location );
            }
            else {
                $path = File::Spec->catfile( $base, $area );
            }
        }
        else {
            return;
        }
        if ( -f $path ) {
            my $digest = Digest::SHA->new('sha512');
            $digest->addfile($path);
            my $test_digest = $digest->hexdigest();
            if ( $test_digest eq $localtime_digest ) {
                $self->{area}     = $area;
                $self->{location} = $location;
                return "$area/$location";
            }
        }
    }
    return;
}

sub _check_area_location {
    my ( $self, $check_area, $check_location ) = @_;
    foreach my $area ( $self->areas() ) {
        if ( $area eq $check_area ) {
            if ( defined $check_location ) {
                foreach my $location ( $self->locations($area) ) {
                    if ( $location eq $check_location ) {
                        return 1;
                    }
                }
            }
            else {
                return 1;
            }

        }
    }
    return;
}

sub _guess_win32_tz {
    my ($self) = @_;
    require Win32API::Registry;
    my $current_timezone_registry_path =
      'SYSTEM\CurrentControlSet\Control\TimeZoneInformation';
    Win32API::Registry::RegOpenKeyExW(
        Win32API::Registry::HKEY_LOCAL_MACHINE(),
        $self->_win32_registry_encode($current_timezone_registry_path),
        0,
        Win32API::Registry::KEY_QUERY_VALUE(),
        my $current_timezone_registry_key
      )
      or Carp::croak(
        "Failed to open LOCAL_MACHINE\\$current_timezone_registry_path:"
          . Win32API::Registry::regLastError() );
    my $win32_timezone_name;
    if (
        Win32API::Registry::RegQueryValueExW(
            $current_timezone_registry_key,
            $self->_win32_registry_encode('TimeZoneKeyName'),
            [], my $type, $win32_timezone_name, my $size,
        )
      )
    {
        $win32_timezone_name =
          $self->_win32_registry_decode($win32_timezone_name);
    }
    elsif (
        Win32API::Registry::regLastError() == _WIN32_ERROR_FILE_NOT_FOUND() )
    {
    }
    else {
        Carp::croak(
"Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\TimeZoneKeyName:"
              . Win32API::Registry::regLastError() );
    }
    if ($win32_timezone_name) {
    }
    else {
        $win32_timezone_name =
          $self->_guess_old_win32_tz( $current_timezone_registry_path,
            $current_timezone_registry_key );
    }
    Win32API::Registry::RegCloseKey($current_timezone_registry_key)
      or Carp::croak(
        "Failed to open LOCAL_MACHINE\\$current_timezone_registry_path:"
          . Win32API::Registry::regLastError() );
    my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
    my %mapping                  = $self->win32_mapping();
    foreach my $key ( sort { $a cmp $b } keys %mapping ) {
        if ( $mapping{$key} eq $win32_timezone_name ) {
            if ( $key =~ /^$timezone_full_name_regex$/smx ) {
                $self->_matched_timezone_full_name_regex_tz();
            }
            return $key;
        }
    }
    return;
}

sub _guess_old_win32_tz {
    my ( $self, $current_timezone_registry_path,
        $current_timezone_registry_key ) = @_;
    my $win32_timezone_name;

    Win32API::Registry::RegQueryValueExW(
        $current_timezone_registry_key,
        $self->_win32_registry_encode('StandardName'),
        [], my $type, my $standard_name, []
      )
      or Carp::croak(
"Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\StandardName:"
          . Win32API::Registry::regLastError() );
    $standard_name = $self->_win32_registry_decode($standard_name);
    my ( $description, $major, $minor, $build, $id ) = Win32::GetOSVersion();
    my $old_timezone_registry_path;
    if ( $id < 2 ) {
        $old_timezone_registry_path =
          'SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones';
    }
    else {
        $old_timezone_registry_path =
          'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones';
    }
    Win32API::Registry::RegOpenKeyExW(
        Win32API::Registry::HKEY_LOCAL_MACHINE(),
        $self->_win32_registry_encode($old_timezone_registry_path),
        0,
        Win32API::Registry::KEY_QUERY_VALUE() |
          Win32API::Registry::KEY_ENUMERATE_SUB_KEYS(),
        my $old_timezone_registry_key
      )
      or Carp::croak(
        "Failed to open LOCAL_MACHINE\\$old_timezone_registry_path:"
          . Win32API::Registry::regLastError() );
    my $enumerate_timezones         = 1;
    my $old_timezone_registry_index = 0;
    while ($enumerate_timezones) {
        if (
            Win32API::Registry::RegEnumKeyExW(
                $old_timezone_registry_key, $old_timezone_registry_index,
                my $subkey_name,
                [], [], [], [], [],
            )
          )
        {
            $subkey_name = $self->_win32_registry_decode($subkey_name);
            Win32API::Registry::RegOpenKeyExW(
                $old_timezone_registry_key,
                $self->_win32_registry_encode($subkey_name),
                0,
                Win32API::Registry::KEY_QUERY_VALUE(),
                my $old_timezone_specific_registry_key
              )
              or Carp::croak(
"Failed to open LOCAL_MACHINE\\$old_timezone_registry_path\\$subkey_name:"
                  . Win32API::Registry::regLastError() );
            Win32API::Registry::RegQueryValueExW(
                $old_timezone_specific_registry_key,
                $self->_win32_registry_encode('Std'),
                [],
                my $type,
                my $local_language_timezone_name,
                []
              )
              or Carp::croak(
"Failed to read LOCAL_MACHINE\\$current_timezone_registry_path\\$subkey_name\\Std:"
                  . Win32API::Registry::regLastError() );
            $local_language_timezone_name =
              $self->_win32_registry_decode($local_language_timezone_name);
            if ( $local_language_timezone_name eq $standard_name ) {
                $win32_timezone_name = $subkey_name;
            }
        }
        elsif (
            Win32API::Registry::regLastError() == _WIN32_ERROR_NO_MORE_ITEMS() )
        {    # ERROR_NO_MORE_TIMES from winerror.h
            $enumerate_timezones = 0;
        }
        else {
            Carp::croak(
"Failed to read from LOCAL_MACHINE\\$old_timezone_registry_path:"
                  . Win32API::Registry::regLastError() );
        }
        $old_timezone_registry_index += 1;
    }
    Win32API::Registry::RegCloseKey($old_timezone_registry_key)
      or Carp::croak(
        "Failed to close LOCAL_MACHINE\\$old_timezone_registry_path:"
          . Win32API::Registry::regLastError() );
    my $timezone_full_name_regex = _TIMEZONE_FULL_NAME_REGEX();
    if ( defined $win32_timezone_name ) {
        if ( $win32_timezone_name =~ /^$timezone_full_name_regex$/smx ) {
            $self->_matched_timezone_full_name_regex_tz();
        }
    }
    return $win32_timezone_name;
}

sub _is_leap_year {
    my ( $self, $year ) = @_;
    my $leap_year;
    if (
        ( $year % _EVERY_FOUR_HUNDRED_YEARS() == 0 )
        || (   ( $year % _EVERY_FOUR_YEARS() == 0 )
            && ( $year % _EVERY_ONE_HUNDRED_YEARS() != 0 ) )
      )
    {
        $leap_year = 1;
    }
    else {
        $leap_year = 0;
    }
    return $leap_year;
}

my $_x = 0;

sub _in_dst_according_to_v2_tz_rule {
    my ( $self, $check_time, $tz_definition ) = @_;

    my ( $dst_start_time, $dst_end_time );
    if (   ( defined $tz_definition->{start_day} )
        && ( defined $tz_definition->{end_day} )
        && ( defined $tz_definition->{start_week} )
        && ( defined $tz_definition->{end_week} )
        && ( defined $tz_definition->{start_month} )
        && ( defined $tz_definition->{end_month} ) )
    {
        my $check_year =
          ( $self->_gm_time($check_time) )[ _LOCALTIME_YEAR_INDEX() ] +
          _LOCALTIME_BASE_YEAR();
        $dst_start_time = $self->_get_time_for_wday_week_month_year_offset(
            day    => $tz_definition->{start_day},
            week   => $tz_definition->{start_week},
            month  => $tz_definition->{start_month},
            year   => $check_year,
            offset => (
                $tz_definition->{start_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{start_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{start_second} -
              $tz_definition->{std_offset_in_seconds}
        );
        $dst_end_time = $self->_get_time_for_wday_week_month_year_offset(
            day    => $tz_definition->{end_day},
            week   => $tz_definition->{end_week},
            month  => $tz_definition->{end_month},
            year   => $check_year,
            offset => (
                $tz_definition->{end_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{end_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{end_second} -
              $tz_definition->{dst_offset_in_seconds}
        );
    }
    elsif (( defined $tz_definition->{start_julian_with_feb29} )
        && ( defined $tz_definition->{end_julian_with_feb29} ) )
    {
        my $check_year =
          ( $self->_gm_time($check_time) )[ _LOCALTIME_YEAR_INDEX() ] +
          _LOCALTIME_BASE_YEAR();
        $dst_start_time = $self->_get_time_for_julian(
            day     => $tz_definition->{start_julian_with_feb29},
            year    => $check_year,
            without => 0,
            offset  => (
                $tz_definition->{start_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{start_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{start_second} -
              $tz_definition->{std_offset_in_seconds}
        );
        $dst_end_time = $self->_get_time_for_julian(
            day     => $tz_definition->{end_julian_with_feb29},
            year    => $check_year,
            without => 0,
            offset  => (
                $tz_definition->{end_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{end_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{end_second} -
              $tz_definition->{dst_offset_in_seconds}
        );
    }
    elsif (( defined $tz_definition->{start_julian_without_feb29} )
        && ( defined $tz_definition->{end_julian_without_feb29} ) )
    {
        my $check_year =
          ( $self->_gm_time($check_time) )[ _LOCALTIME_YEAR_INDEX() ] +
          _LOCALTIME_BASE_YEAR();
        $dst_start_time = $self->_get_time_for_julian(
            day     => $tz_definition->{start_julian_without_feb29},
            year    => $check_year,
            without => 1,
            offset  => (
                $tz_definition->{start_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{start_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{start_second} -
              $tz_definition->{std_offset_in_seconds}
        );
        $dst_end_time = $self->_get_time_for_julian(
            day     => $tz_definition->{end_julian_without_feb29},
            year    => $check_year,
            without => 1,
            offset  => (
                $tz_definition->{end_hour} *
                  _SECONDS_IN_ONE_MINUTE() *
                  _MINUTES_IN_ONE_HOUR()
              ) +
              ( $tz_definition->{end_minute} * _SECONDS_IN_ONE_MINUTE() ) +
              $tz_definition->{end_second} -
              $tz_definition->{dst_offset_in_seconds}
        );
    }
    if ( ( defined $dst_start_time ) && ( defined $dst_end_time ) ) {
        if ( $dst_start_time < $dst_end_time ) {
            if (   ( $dst_start_time <= $check_time )
                && ( $check_time < $dst_end_time ) )
            {
                return 1;
            }
        }
        else {
            if (   ( $check_time >= $dst_start_time )
                || ( $dst_end_time > $check_time ) )
            {
                return 1;
            }
        }
    }
    return 0;
}

sub _get_time_for_julian {
    my ( $self, %params ) = @_;
    my $check_year = _EPOCH_YEAR();
    my $time       = $params{offset};
    my $increment  = 0;
    my $leap_year  = 1;
    if ( $check_year > $params{year} ) {
        while ( $check_year > $params{year} ) {
            $check_year -= 1;
            if ( $self->_is_leap_year($check_year) ) {
                $increment = _DAYS_IN_A_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $leap_year = 1;
            }
            else {
                $increment = _DAYS_IN_A_NON_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $leap_year = 0;
            }
            $time -= $increment;
        }
    }
    else {
        while ( $check_year < $params{year} ) {
            if ( $self->_is_leap_year($check_year) ) {
                $increment = _DAYS_IN_A_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
            }
            else {
                $increment = _DAYS_IN_A_NON_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
            }
            $time       += $increment;
            $check_year += 1;
            if ( $self->_is_leap_year($check_year) ) {
                $leap_year = 1;
            }
            else {
                $leap_year = 0;
            }
        }
    }
    if ( $params{without} ) {
        $params{day} =
          (
            ($leap_year)
              && ( $params{day} >
                _DAYS_IN_JANUARY() + _DAYS_IN_FEBRUARY_LEAP_YEAR() )
          )
          ? $params{day}
          : $params{day} - 1;
    }
    $time += ( $params{day} * _SECONDS_IN_ONE_DAY() );
    return $time;
}

sub _get_time_for_wday_week_month_year_offset {
    my ( $self, %params ) = @_;

    my $check_year        = _EPOCH_YEAR();
    my $time              = $params{offset};
    my $check_day_of_week = _DAY_OF_WEEK_AT_EPOCH();
    my $increment         = 0;
    my $leap_year         = 1;
    if ( $check_year > $params{year} ) {
        while ( $check_year > $params{year} ) {
            $check_year -= 1;
            if ( $self->_is_leap_year($check_year) ) {
                $increment = _DAYS_IN_A_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $check_day_of_week -= _DAYS_IN_A_LEAP_YEAR();
                $leap_year = 1;
            }
            else {
                $increment = _DAYS_IN_A_NON_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $check_day_of_week -= _DAYS_IN_A_NON_LEAP_YEAR();
                $leap_year = 0;
            }
            $time -= $increment;
        }
        $check_day_of_week = abs $check_day_of_week % _DAYS_IN_ONE_WEEK();
    }
    else {
        while ( $check_year < $params{year} ) {
            if ( $self->_is_leap_year($check_year) ) {
                $increment = _DAYS_IN_A_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $check_day_of_week += _DAYS_IN_A_LEAP_YEAR();
            }
            else {
                $increment = _DAYS_IN_A_NON_LEAP_YEAR() * _SECONDS_IN_ONE_DAY();
                $check_day_of_week += _DAYS_IN_A_NON_LEAP_YEAR();
            }
            $time       += $increment;
            $check_year += 1;
            if ( $self->_is_leap_year($check_year) ) {
                $leap_year = 1;
            }
            else {
                $leap_year = 0;
            }
        }
    }

    $increment = 0;
    my $check_month   = 1;
    my @days_in_month = $self->_days_in_month($leap_year);
    while ( $check_month < $params{month} ) {

        $increment = $days_in_month[ $check_month - 1 ] * _SECONDS_IN_ONE_DAY();
        $check_day_of_week += $days_in_month[ $check_month - 1 ];
        $time              += $increment;
        $check_month       += 1;
    }

    if ( $params{week} == _LAST_WEEK_VALUE() ) {
        $time +=
          ( $days_in_month[ $check_month - 1 ] - 1 ) * _SECONDS_IN_ONE_DAY();
        $check_day_of_week += $days_in_month[ $check_month - 1 ] - 1;

        while ( ( $check_day_of_week % _DAYS_IN_ONE_WEEK() ) != $params{day} ) {

            $time              -= _SECONDS_IN_ONE_DAY();
            $check_day_of_week -= 1;
            if ( $check_day_of_week < 0 ) {
                $check_day_of_week = _LOCALTIME_WEEKDAY_HIGHEST_VALUE();
            }
        }
    }
    else {

        while ( ( $check_day_of_week % _DAYS_IN_ONE_WEEK() ) != $params{day} ) {
            $time              += _SECONDS_IN_ONE_DAY();
            $check_day_of_week += 1;
            $check_day_of_week = $check_day_of_week % _DAYS_IN_ONE_WEEK();
        }
        my $check_week = 1;
        $increment = _DAYS_IN_ONE_WEEK() * _SECONDS_IN_ONE_DAY();
        while ( $check_week < $params{week} ) {
            $check_week        += 1;
            $check_day_of_week += _DAYS_IN_ONE_WEEK();
            $time              += $increment;
        }

    }

    return $time;
}

sub tz_definition {
    my ($self) = @_;
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my $tz_definition = $self->{_tzdata}->{$tz}->{tz_definition}->{tz};
    return $tz_definition;
}

sub _get_tz_offset_according_to_v2_tz_rule {
    my ( $self, $time ) = @_;
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my $tz = $self->timezone();
    my ( $isdst, $gmtoff, $abbr );
    my $tz_definition = $self->{_tzdata}->{$tz}->{tz_definition};
    if ( defined $tz_definition->{std_name} ) {
        if ( defined $tz_definition->{dst_name} ) {
            if ( $self->_in_dst_according_to_v2_tz_rule( $time, $tz_definition )
              )
            {
                $isdst  = 1;
                $gmtoff = $tz_definition->{dst_offset_in_seconds};
                $abbr   = $tz_definition->{dst_name};
            }
            else {
                $isdst  = 0;
                $gmtoff = $tz_definition->{std_offset_in_seconds};
                $abbr   = $tz_definition->{std_name};
            }
        }
        else {
            $isdst  = 0;
            $gmtoff = $tz_definition->{std_offset_in_seconds};
            $abbr   = $tz_definition->{std_name};
        }
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub _negative_gm_time {
    my ( $self, $time ) = @_;
    my $year           = _EPOCH_YEAR() - 1;
    my $wday           = _EPOCH_WDAY() - 1;
    my $check_time     = 0;
    my $number_of_days = 0;
    my $leap_year;
  YEAR: while (1) {
        $leap_year      = $self->_is_leap_year($year);
        $number_of_days = $self->_number_of_days_in_a_year($leap_year);
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $wday       -= $number_of_days;
            $year       -= 1;
        }
        else {
            last YEAR;
        }
    }
    my $yday = $self->_number_of_days_in_a_year($leap_year);
    $year -= _LOCALTIME_BASE_YEAR();

    my $month         = _MONTHS_IN_ONE_YEAR();
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        $number_of_days = $days_in_month[ $month - 1 ];
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $wday       -= $number_of_days;
            $yday       -= $number_of_days;
            $month      -= 1;
        }
        else {
            last MONTH;
        }
    }
    $month -= 1;

    my $day       = $days_in_month[$month];
    my $increment = _SECONDS_IN_ONE_DAY();
  DAY: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $day        -= 1;
            $yday       -= 1;
            $wday       -= 1;
        }
        else {
            last DAY;
        }
    }

    $wday = abs $wday % _DAYS_IN_ONE_WEEK();

    my $hour = _HOURS_IN_ONE_DAY() - 1;
    $increment = _SECONDS_IN_ONE_HOUR();
  HOUR: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $hour       -= 1;
        }
        else {
            last HOUR;
        }
    }
    my $minute = _MINUTES_IN_ONE_HOUR() - 1;
    $increment = _SECONDS_IN_ONE_MINUTE();
  MINUTE: while (1) {
        if ( $check_time - $increment > $time ) {
            $check_time -= $increment;
            $minute     -= 1;
        }
        else {
            last MINUTE;
        }
    }
    my $seconds = _SECONDS_IN_ONE_MINUTE() - ( $check_time - $time );

    return ( $seconds, $minute, $hour, $day, $month, "$year", $wday, $yday, 0 );
}

sub _positive_gm_time {
    my ( $self, $time ) = @_;
    my $year           = _EPOCH_YEAR();
    my $wday           = _EPOCH_WDAY();
    my $check_time     = 0;
    my $number_of_days = 0;
    my $leap_year;
  YEAR: while (1) {
        $leap_year      = $self->_is_leap_year($year);
        $number_of_days = $self->_number_of_days_in_a_year($leap_year);
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $wday       += $number_of_days;
            $year       += 1;
        }
        else {
            last YEAR;
        }
    }
    $year -= _LOCALTIME_BASE_YEAR();

    my $month         = 0;
    my @days_in_month = $self->_days_in_month($leap_year);
    my $yday          = 0;
  MONTH: while (1) {

        $number_of_days = $days_in_month[$month];
        my $increment = $number_of_days * _SECONDS_IN_ONE_DAY();
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $wday       += $number_of_days;
            $yday       += $number_of_days;
            $month      += 1;
        }
        else {
            last MONTH;
        }
    }
    my $day       = 1;
    my $increment = _SECONDS_IN_ONE_DAY();
  DAY: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $day        += 1;
            $yday       += 1;
            $wday       += 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $hour = 0;
    $increment = _SECONDS_IN_ONE_HOUR();
  HOUR: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $hour       += 1;
        }
        else {
            last HOUR;
        }
    }
    my $minute = 0;
    $increment = _SECONDS_IN_ONE_MINUTE();
  MINUTE: while (1) {
        if ( $check_time + $increment <= $time ) {
            $check_time += $increment;
            $minute     += 1;
        }
        else {
            last MINUTE;
        }
    }
    my $seconds = $time - $check_time;

    return ( $seconds, $minute, $hour, $day, $month, "$year", $wday, $yday, 0 );
}

sub _gm_time {
    my ( $self, $time ) = @_;
    my @gmtime;
    if ( $time < 0 ) {
        @gmtime = $self->_negative_gm_time($time);
    }
    else {
        @gmtime = $self->_positive_gm_time($time);
    }
    if (wantarray) {
        return @gmtime;
    }
    else {
        my $formatted_date = POSIX::strftime( '%a %b %d %H:%M:%S %Y', @gmtime );
        $formatted_date =~
          s/^(\w+[ ]\w+[ ])0(\d+[ ])/$1 $2/smx;    # %e doesn't work on Win32
        return $formatted_date;
    }
}

sub time_local {
    my ( $self, @localtime ) = @_;
    my $time = 0;
    $localtime[ _LOCALTIME_YEAR_INDEX() ] += _LOCALTIME_BASE_YEAR();
    if ( $localtime[ _LOCALTIME_YEAR_INDEX() ] >= _EPOCH_YEAR() ) {
        return $self->_positive_time_local(@localtime);
    }
    else {
        return $self->_negative_time_local(@localtime);
    }
}

sub _positive_time_local {
    my ( $self, @localtime ) = @_;
    my $check_year = _EPOCH_YEAR();
    my $wday       = _EPOCH_WDAY();
    my $time       = 0;
    my $leap_year  = 0;
  YEAR: while (1) {

        if ( $check_year < $localtime[ _LOCALTIME_YEAR_INDEX() ] ) {
            $time += $self->_number_of_days_in_a_year($leap_year) *
              _SECONDS_IN_ONE_DAY();
            $check_year += 1;
            $leap_year = $self->_is_leap_year($check_year);
        }
        else {
            last YEAR;
        }
    }

    my $check_month   = 0;
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        if ( $check_month < $localtime[ _LOCALTIME_MONTH_INDEX() ] ) {
            $time += $days_in_month[$check_month] * _SECONDS_IN_ONE_DAY();
            $check_month += 1;
        }
        else {
            last MONTH;
        }
    }
    my $check_day = 1;
  DAY: while (1) {
        if ( $check_day < $localtime[ _LOCALTIME_DAY_INDEX() ] ) {
            $time      += _SECONDS_IN_ONE_DAY();
            $check_day += 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $check_hour = 0;
  HOUR: while (1) {
        if ( $check_hour < $localtime[ _LOCALTIME_HOUR_INDEX() ] ) {
            $time       += _SECONDS_IN_ONE_HOUR();
            $check_hour += 1;
        }
        else {
            last HOUR;
        }
    }
    my $check_minute = 0;
  MINUTE: while (1) {
        if ( $check_minute < $localtime[ _LOCALTIME_MINUTE_INDEX() ] ) {
            $time         += _SECONDS_IN_ONE_MINUTE();
            $check_minute += 1;
        }
        else {
            last MINUTE;
        }
    }
    $time += $localtime[ _LOCALTIME_SECOND_INDEX() ];
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_time_local($time);
    $time -= $gmtoff;

    return $time;
}

sub _days_in_month {
    my ( $self, $leap_year ) = @_;
    return (
        _DAYS_IN_JANUARY(),
        (
            $leap_year
            ? _DAYS_IN_FEBRUARY_LEAP_YEAR()
            : _DAYS_IN_FEBRUARY_NON_LEAP()
        ),
        _DAYS_IN_MARCH(),
        _DAYS_IN_APRIL(),
        _DAYS_IN_MAY(),
        _DAYS_IN_JUNE(),
        _DAYS_IN_JULY(),
        _DAYS_IN_AUGUST(),
        _DAYS_IN_SEPTEMBER(),
        _DAYS_IN_OCTOBER(),
        _DAYS_IN_NOVEMBER(),
        _DAYS_IN_DECEMBER(),
    );
}

sub _number_of_days_in_a_year {
    my ( $self, $leap_year ) = @_;
    if ($leap_year) {
        return _DAYS_IN_A_LEAP_YEAR();
    }
    else {
        return _DAYS_IN_A_NON_LEAP_YEAR();
    }
}

sub _negative_time_local {
    my ( $self, @localtime ) = @_;
    my $check_year = _EPOCH_YEAR() - 1;
    my $wday       = _EPOCH_WDAY();
    my $time       = 0;
    my $leap_year;
  YEAR: while (1) {

        if ( $check_year > $localtime[ _LOCALTIME_YEAR_INDEX() ] ) {
            $time -= $self->_number_of_days_in_a_year($leap_year) *
              _SECONDS_IN_ONE_DAY();
            $check_year -= 1;
            $leap_year = $self->_is_leap_year($check_year);
        }
        else {
            last YEAR;
        }
    }

    my $check_month   = _MONTHS_IN_ONE_YEAR() - 1;
    my @days_in_month = $self->_days_in_month($leap_year);
  MONTH: while (1) {

        if ( $check_month > $localtime[ _LOCALTIME_MONTH_INDEX() ] ) {
            $time -= $days_in_month[$check_month] * _SECONDS_IN_ONE_DAY();
            $check_month -= 1;
        }
        else {
            last MONTH;
        }
    }
    my $check_day = $days_in_month[$check_month];
  DAY: while (1) {
        if ( $check_day > $localtime[ _LOCALTIME_DAY_INDEX() ] ) {
            $time      -= _SECONDS_IN_ONE_DAY();
            $check_day -= 1;
        }
        else {
            last DAY;
        }
    }

    $wday = $wday % _DAYS_IN_ONE_WEEK();

    my $check_hour = _HOURS_IN_ONE_DAY() - 1;
  HOUR: while (1) {
        if ( $check_hour > $localtime[ _LOCALTIME_HOUR_INDEX() ] ) {
            $time       -= _SECONDS_IN_ONE_HOUR();
            $check_hour -= 1;
        }
        else {
            last HOUR;
        }
    }
    my $check_minute = _MINUTES_IN_ONE_HOUR();
  MINUTE: while (1) {
        if ( $check_minute > $localtime[ _LOCALTIME_MINUTE_INDEX() ] ) {
            $time         -= _SECONDS_IN_ONE_MINUTE();
            $check_minute -= 1;
        }
        else {
            last MINUTE;
        }
    }
    $time += $localtime[ _LOCALTIME_SECOND_INDEX() ];
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_time_local($time);
    $time -= $gmtoff;

    return $time;
}

sub _get_first_standard_time_type {
    my ( $self, $tz ) = @_;
    my $first_standard_time_type;
    if ( defined $self->{_tzdata}->{$tz}->{local_time_types}->[0] ) {
        $first_standard_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[0];
    }
  FIRST_STANDARD_TIME_TYPE:
    foreach
      my $local_time_type ( @{ $self->{_tzdata}->{$tz}->{local_time_types} } )
    {
        if ( $local_time_type->{isdst} ) {
        }
        else {
            $first_standard_time_type = $local_time_type;
            last FIRST_STANDARD_TIME_TYPE;
        }
    }
    return $first_standard_time_type;
}

sub _get_isdst_gmtoff_abbr_calculating_for_time_local {
    my ( $self, $time ) = @_;
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my ( $isdst, $gmtoff, $abbr );
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my $first_standard_time_type = $self->_get_first_standard_time_type($tz);
    my $transition_index         = 0;
    my $transition_time_found;
    my $previous_offset = $first_standard_time_type->{gmtoff};
    my $first_transition_time;
  TRANSITION_TIME:

    foreach my $transition_time_in_gmt ( $self->transition_times() ) {

        if ( !defined $first_transition_time ) {
            $first_transition_time = $transition_time_in_gmt;
        }
        my $local_time_index =
          $self->{_tzdata}->{$tz}->{local_time_indexes}->[$transition_index];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        if ( $local_time_type->{gmtoff} < $previous_offset ) {
            if (
                ( $transition_time_in_gmt > $time - $previous_offset )
                && ( $transition_time_in_gmt <=
                    $time - $local_time_type->{gmtoff} )
              )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
            elsif (
                $transition_time_in_gmt > $time - $local_time_type->{gmtoff} )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
        }
        else {
            if ( $transition_time_in_gmt > $time - $local_time_type->{gmtoff} )
            {
                $transition_time_found = 1;
                last TRANSITION_TIME;
            }
        }
        $transition_index += 1;
        $previous_offset = $local_time_type->{gmtoff};
    }
    my $offset_found;
    if (
           ( defined $first_transition_time )
        && ($first_standard_time_type)
        && ( $time <
            $first_transition_time + $first_standard_time_type->{gmtoff} )
      )
    {
        $gmtoff       = $first_standard_time_type->{gmtoff};
        $isdst        = $first_standard_time_type->{isdst};
        $abbr         = $first_standard_time_type->{abbr};
        $offset_found = 1;
    }
    elsif ( !$transition_time_found ) {
        my $tz_definition = $self->{_tzdata}->{$tz}->{tz_definition};
        $time -= $tz_definition->{dst_offset_in_seconds} || 0;
        ( $isdst, $gmtoff, $abbr ) =
          $self->_get_tz_offset_according_to_v2_tz_rule($time);
        if ( defined $gmtoff ) {
            $offset_found = 1;
        }
    }
    if ($offset_found) {
    }
    elsif (
        defined $self->{_tzdata}->{$tz}->{local_time_indexes}
        ->[ $transition_index - 1 ] )
    {
        my $local_time_index = $self->{_tzdata}->{$tz}->{local_time_indexes}
          ->[ $transition_index - 1 ];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        $gmtoff = $local_time_type->{gmtoff};
        $isdst  = $local_time_type->{isdst};
        $abbr   = $local_time_type->{abbr};
    }
    else {
        $gmtoff = $first_standard_time_type->{gmtoff};
        $isdst  = $first_standard_time_type->{isdst};
        $abbr   = $first_standard_time_type->{abbr};
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub _get_isdst_gmtoff_abbr_calculating_for_local_time {
    my ( $self, $time ) = @_;
    my ( $isdst, $gmtoff, $abbr );
    if ( defined $self->offset() ) {
        return ( 0, $self->offset() * _SECONDS_IN_ONE_MINUTE(), q[] );
    }
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my $transition_index = 0;
    my $transition_time_found;
    my $first_transition_time;
  TRANSITION_TIME:
    foreach my $transition_time_in_gmt ( $self->transition_times() ) {

        if ( !defined $first_transition_time ) {
            $first_transition_time = $transition_time_in_gmt;
        }
        if ( $transition_time_in_gmt > $time ) {
            $transition_time_found = 1;
            last TRANSITION_TIME;
        }
        $transition_index += 1;
    }
    my $first_standard_time_type = $self->_get_first_standard_time_type($tz);
    my $offset_found;
    if (   ( defined $first_transition_time )
        && ( $time < $first_transition_time ) )
    {
        $gmtoff       = $first_standard_time_type->{gmtoff};
        $isdst        = $first_standard_time_type->{isdst};
        $abbr         = $first_standard_time_type->{abbr};
        $offset_found = 1;
    }
    elsif ( !$transition_time_found ) {
        ( $isdst, $gmtoff, $abbr ) =
          $self->_get_tz_offset_according_to_v2_tz_rule($time);
        if ( defined $gmtoff ) {
            $offset_found = 1;
        }
    }
    if ($offset_found) {
    }
    elsif (
        defined $self->{_tzdata}->{$tz}->{local_time_indexes}
        ->[ $transition_index - 1 ] )
    {
        my $local_time_index = $self->{_tzdata}->{$tz}->{local_time_indexes}
          ->[ $transition_index - 1 ];
        my $local_time_type =
          $self->{_tzdata}->{$tz}->{local_time_types}->[$local_time_index];
        $gmtoff = $local_time_type->{gmtoff};
        $isdst  = $local_time_type->{isdst};
        $abbr   = $local_time_type->{abbr};
    }
    else {
        $gmtoff = $first_standard_time_type->{gmtoff};
        $isdst  = $first_standard_time_type->{isdst};
        $abbr   = $first_standard_time_type->{abbr};
    }
    return ( $isdst, $gmtoff, $abbr );
}

sub local_offset {
    my ( $self, $time ) = @_;
    if ( !defined $time ) {
        $time = time;
    }
    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_local_time($time);
    return int( $gmtoff / _SECONDS_IN_ONE_MINUTE() );
}

sub local_time {
    my ( $self, $time ) = @_;
    if ( !defined $time ) {
        $time = time;
    }

    my ( $isdst, $gmtoff, $abbr ) =
      $self->_get_isdst_gmtoff_abbr_calculating_for_local_time($time);
    $time += $gmtoff;

    if (wantarray) {
        my (@local_time) = $self->_gm_time($time);
        $local_time[ _LOCALTIME_ISDST_INDEX() ] = $isdst;
        return @local_time;
    }
    else {
        return $self->_gm_time($time);
    }
}

sub transition_times {
    my ($self) = @_;
    my $tz = $self->timezone();
    $self->_read_tzfile();
    return @{ $self->{_tzdata}->{$tz}->{transition_times} };
}

sub leap_seconds {
    my ($self) = @_;
    my $tz = $self->timezone();
    $self->_read_tzfile();
    my @leap_seconds =
      sort { $a <=> $b } keys %{ $self->{_tzdata}->{$tz}->{leap_seconds} };
    return @leap_seconds;
}

sub _read_header {
    my ( $self, $handle, $path ) = @_;
    my $result = $handle->read( my $buffer, _SIZE_OF_TZ_HEADER() );
    if ( defined $result ) {
        if ( $result != _SIZE_OF_TZ_HEADER() ) {
            Carp::croak(
"Failed to read entire header from $path.  $result bytes were read instead of the expected "
                  . _SIZE_OF_TZ_HEADER() );
        }
    }
    else {
        Carp::croak("Failed to read header from $path:$EXTENDED_OS_ERROR");
    }
    my ( $magic, $version, $ttisgmtcnt, $ttisstdcnt, $leapcnt, $timecnt,
        $typecnt, $charcnt )
      = unpack 'A4A1x15NNNNNN', $buffer;
    ( $magic eq 'TZif' ) or Carp::croak("$path is not a TZ file");
    my $header = {
        magic      => $magic,
        version    => $version,
        ttisgmtcnt => $ttisgmtcnt,
        ttisstdcnt => $ttisstdcnt,
        leapcnt    => $leapcnt,
        timecnt    => $timecnt,
        typecnt    => $typecnt,
        charcnt    => $charcnt
    };

    return $header;
}

sub _read_transition_times {
    my ( $self, $handle, $path, $timecnt, $sizeof_transition_time ) = @_;
    my $sizeof_transition_times = $timecnt * $sizeof_transition_time;
    my $result = $handle->read( my $buffer, $sizeof_transition_times );
    if ( defined $result ) {
        if ( $result != $sizeof_transition_times ) {
            Carp::croak(
"Failed to read all the transition times from $path.  $result bytes were read instead of the expected "
                  . $sizeof_transition_times );
        }
    }
    else {
        Carp::croak(
            "Failed to read transition times from $path:$EXTENDED_OS_ERROR");
    }
    my @transition_times;
    if ( $sizeof_transition_time == _SIZE_OF_TRANSITION_TIME_V1() ) {
        @transition_times = unpack 'N' . $timecnt, $buffer;
    }
    elsif ( $sizeof_transition_time == _SIZE_OF_TRANSITION_TIME_V2() ) {
        eval { @transition_times = unpack 'q>' . $timecnt, $buffer; 1; } or do {
            require Math::Int64;
            @transition_times =
              map { Math::Int64::net_to_int64($_) } unpack '(a8)' . $timecnt,
              $buffer;
        };
    }
    return \@transition_times;
}

sub _read_local_time_indexes {
    my ( $self, $handle, $path, $timecnt ) = @_;
    my $result = $handle->read( my $buffer, $timecnt );
    if ( defined $result ) {
        if ( $result != $timecnt ) {
            Carp::croak(
"Failed to read all the local time indexes from $path.  $result bytes were read instead of the expected "
                  . $timecnt );
        }
    }
    else {
        Carp::croak(
            "Failed to read local time indexes from $path:$EXTENDED_OS_ERROR");
    }
    my @local_time_indexes = unpack 'C' . $timecnt, $buffer;
    return \@local_time_indexes;
}

sub _read_local_time_types {
    my ( $self, $handle, $path, $typecnt ) = @_;
    my $sizeof_local_time_types = $typecnt * _SIZE_OF_TTINFO();
    my $result = $handle->read( my $buffer, $sizeof_local_time_types );
    if ( defined $result ) {
        if ( $result != $sizeof_local_time_types ) {
            Carp::croak(
"Failed to read all the local time types from $path.  $result bytes were read instead of the expected "
                  . $sizeof_local_time_types );
        }
    }
    else {
        Carp::croak(
            "Failed to read local time types from $path:$EXTENDED_OS_ERROR");
    }
    my @local_time_types;
    foreach my $local_time_type ( unpack '(a6)' . $typecnt, $buffer ) {
        my ( $c1, $c2, $c3 ) = unpack 'a4aa', $local_time_type;
        my $gmtoff;
        if ( $] > _MINIMUM_PERL_FOR_FORCE_BIG_ENDIAN() ) {
            $gmtoff = unpack 'l>', $c1;
        }
        else {
            $gmtoff = unpack 'N', $c1;
            if ( $gmtoff > _MAXIMUM_32_BIT_SIGNED_NUMBER() ) {
                $gmtoff = _MAXIMUM_32_BIT_UNSIGNED_NUMBER() - $gmtoff;
                $gmtoff *= _NEGATIVE_ONE();
            }
        }
        my $isdst   = unpack 'C', $c2;
        my $abbrind = unpack 'C', $c3;
        push @local_time_types,
          { gmtoff => $gmtoff, isdst => $isdst, abbrind => $abbrind };
    }
    return \@local_time_types;
}

sub _read_time_zone_abbreviation_strings {
    my ( $self, $handle, $path, $charcnt ) = @_;
    my $result = $handle->read( my $time_zone_abbreviation_strings, $charcnt );
    if ( defined $result ) {
        if ( $result != $charcnt ) {
            Carp::croak(
"Failed to read all the time zone abbreviations from $path.  $result bytes were read instead of the expected "
                  . $charcnt );
        }
    }
    else {
        Carp::croak(
"Failed to read time zone abbreviations from $path:$EXTENDED_OS_ERROR"
        );
    }
    return $time_zone_abbreviation_strings;
}

sub _read_leap_seconds {
    my ( $self, $handle, $path, $leapcnt, $sizeof_leap_second ) = @_;
    my $sizeof_leap_seconds = $leapcnt * _PAIR() * $sizeof_leap_second;
    my $result              = $handle->read( my $buffer, $sizeof_leap_seconds );
    if ( defined $result ) {
        if ( $result != $sizeof_leap_seconds ) {
            Carp::croak(
"Failed to read all the leap seconds from $path.  $result bytes were read instead of the expected "
                  . $sizeof_leap_seconds );
        }
    }
    else {
        Carp::croak(
            "Failed to read leap seconds from $path:$EXTENDED_OS_ERROR");
    }
    my @paired_leap_seconds = unpack 'N' . $leapcnt, $buffer;
    my %leap_seconds;
    while (@paired_leap_seconds) {
        my $time_leap_second_occurs      = shift @paired_leap_seconds;
        my $total_number_of_leap_seconds = shift @paired_leap_seconds;
        $leap_seconds{$time_leap_second_occurs} = $total_number_of_leap_seconds;
    }
    return \%leap_seconds;
}

sub _read_is_standard_time {
    my ( $self, $handle, $path, $ttisstdcnt ) = @_;
    my $result = $handle->read( my $buffer, $ttisstdcnt );
    if ( defined $result ) {
        if ( $result != $ttisstdcnt ) {
            Carp::croak(
"Failed to read all the is standard time values from $path.  $result bytes were read instead of the expected "
                  . $ttisstdcnt );
        }
    }
    else {
        Carp::croak(
"Failed to read is standard time values from $path:$EXTENDED_OS_ERROR"
        );
    }
    my @is_std_time = unpack 'C' . $ttisstdcnt, $buffer;
    return \@is_std_time;
}

sub _read_is_gmt {
    my ( $self, $handle, $path, $ttisgmtcnt ) = @_;
    my $result = $handle->read( my $buffer, $ttisgmtcnt );
    if ( defined $result ) {
        if ( $result != $ttisgmtcnt ) {
            Carp::croak(
"Failed to read all the is GMT values from $path.  $result bytes were read instead of the expected "
                  . $ttisgmtcnt );
        }
    }
    else {
        Carp::croak(
            "Failed to read is GMT values from $path:$EXTENDED_OS_ERROR");
    }
    my @is_gmt_time = unpack 'C' . $ttisgmtcnt, $buffer;
    return \@is_gmt_time;
}

sub _read_tz_definition {
    my ( $self, $handle, $path ) = @_;
    my $result =
      $handle->read( my $buffer, _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION() );
    if ( defined $result ) {
        if ( $result == _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION() ) {
            Carp::croak(
                "The tz definition at the end of $path could not be read in "
                  . _MAX_LENGTH_FOR_TRAILING_TZ_DEFINITION()
                  . ' bytes' );
        }
    }
    else {
        Carp::croak(
            "Failed to read tz definition from $path:$EXTENDED_OS_ERROR");
    }
    if ( $buffer =~ /^\n([^\n]+)\n*$/smx ) {
        return $self->_parse_tz_variable( $1, $path );

    }
    return;
}

sub _parse_tz_variable {
    my ( $self, $tz_variable, $path ) = @_;
    if ($_modern_regexs_work) {
        return $self->_modern_parse_tz_variable( $tz_variable, $path );
    }
    else {
        return $self->_ancient_parse_tz_variable( $tz_variable, $path );
    }
}

sub _ancient_parse_tz_variable {
    my ( $self, $tz_variable, $path ) = @_;
    my $abbr_regex = qr/([[:alpha:]]+|<[\-+]?\d+(?:\d+)?>)/smx;
    my $name_regex =
      qr/(?:$abbr_regex(\-)?(\d+)(?::(\d+))?$abbr_regex(\-)?(\d+)?)/smx;
    my $short_name_regex = qr/([[:alpha:]]+|<[[:alpha:]]*[\-+]?\d+>)/smx;
    my $month_regex      = qr/(M\d+[.]\d+[.]\d+(?:\/\-?\d+(?::\d+)?)?)/smx;
    my $julian_regex     = qr/J(\d+)\/(\d+)/smx;
    my $tz_definition    = { tz => $tz_variable };
    if ( $tz_variable =~ /^$name_regex,$month_regex,$month_regex$/smx ) {
        (
            $tz_definition->{std_name},  $tz_definition->{std_sign},
            $tz_definition->{std_hours}, $tz_definition->{std_minutes},
            $tz_definition->{dst_name},  $tz_definition->{dst_sign},
            $tz_definition->{dst_hours}, my $start_date,
            my $end_date
        ) = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
        my $month_breakdown_regex =
          qr/M(\d+)[.](\d+)[.](\d+)(?:\/([\-+]?\d+)(?::(\d+))?)?/smx;
        if ( $start_date =~ /^$month_breakdown_regex$/smx ) {
            (
                $tz_definition->{start_month}, $tz_definition->{start_week},
                $tz_definition->{start_day},   $tz_definition->{start_hour},
                $tz_definition->{start_minute}
            ) = ( $1, $2, $3, $4, $5 );
        }
        else {
            Carp::croak(
"Failed to parse the tz definition of $tz_variable from $path (1)"
            );
        }
        if ( $end_date =~ /^$month_breakdown_regex$/smx ) {
            (
                $tz_definition->{end_month}, $tz_definition->{end_week},
                $tz_definition->{end_day},   $tz_definition->{end_hour},
                $tz_definition->{end_minute}
            ) = ( $1, $2, $3, $4, $5 );
        }
        else {
            Carp::croak(
"Failed to parse the tz definition of $tz_variable from $path (2)"
            );
        }
    }
    elsif ( $tz_variable =~ /^$short_name_regex([\-+])?(\d+)(?::(\d+))?$/smx ) {
        (
            $tz_definition->{std_name},  $tz_definition->{std_sign},
            $tz_definition->{std_hours}, $tz_definition->{std_minutes},
            $tz_definition->{start_hour}
        ) = ( $1, $2, $3, $4, $5 );
    }
    elsif ( $tz_variable =~
        /^<([+]\d+)>(\-)?(\d+):(\d+)<([+]\d+)>,$julian_regex,$julian_regex$/smx
      )
    {
        (
            $tz_definition->{std_name},
            $tz_definition->{std_sign},
            $tz_definition->{std_hours},
            $tz_definition->{std_minutes},
            $tz_definition->{dst_name},
            $tz_definition->{start_julian_without_feb29},
            $tz_definition->{start_hour},
            $tz_definition->{end_julian_without_feb29},
            $tz_definition->{end_hour},
        ) = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
    }
    else {
        Carp::croak(
            "Failed to parse the tz definition of $tz_variable from $path (3)");
    }
    foreach my $key ( sort { $a cmp $b } keys %{$tz_definition} ) {
        if ( !defined $tz_definition->{$key} ) {
            delete $tz_definition->{$key};
        }
    }
    $self->_initialise_undefined_tz_definition_values($tz_definition);
    $self->_cleanup_bracketed_names($tz_definition);
    return $tz_definition;
}

sub _cleanup_bracketed_names {
    my ( $self, $tz_definition ) = @_;
    foreach my $key (qw(std_name dst_name)) {
        if ( defined $tz_definition->{$key} ) {
            $tz_definition->{$key} =~ s/^<([^>]+)>$/$1/smx;
        }
    }
    return;
}

sub _compile_modern_tz_regex {
    my $modern_tz_regex;
    eval ## no critic (ProhibitStringyEval) required to allow old perl (pre 5.10) to compile
      <<'_REGEX_' or ( !$_modern_regexs_work ) or Carp::croak("Failed to compile TZ regular expression:$EVAL_ERROR");
    my $timezone_abbr_name_regex =
      qr/(?:[^:\d,+-][^\d,+-]{2,}|[<]\w*[+-]?\d+[>])/smx;
    my $std_name_regex = qr/(?<std_name>$timezone_abbr_name_regex)/smx
      ;    # Name for standard offset from GMT
    my $std_sign_regex    = qr/(?<std_sign>[+-])/smx;
    my $std_hours_regex   = qr/(?<std_hours>\d+)/smx;
    my $std_minutes_regex = qr/(?::(?<std_minutes>\d+))/smx;
    my $std_seconds_regex = qr/(?::(?<std_seconds>\d+))/smx;
    my $std_offset_regex =
qr/$std_sign_regex?$std_hours_regex$std_minutes_regex?$std_seconds_regex?/smx
      ;    # Standard offset from GMT
    my $dst_name_regex = qr/(?<dst_name>$timezone_abbr_name_regex)/smx
      ;    # Name for daylight saving offset from GMT
    my $dst_sign_regex    = qr/(?<dst_sign>[+-])/smx;
    my $dst_hours_regex   = qr/(?<dst_hours>\d+)/smx;
    my $dst_minutes_regex = qr/(?::(?<dst_minutes>\d+))/smx;
    my $dst_seconds_regex = qr/(?::(?<dst_seconds>\d+))/smx;
    my $dst_offset_regex =
qr/$dst_sign_regex?$dst_hours_regex$dst_minutes_regex?$dst_seconds_regex?/smx
      ;    # Standard offset from GMT
    my $start_julian_without_feb29_regex =
      qr/(?:J(?<start_julian_without_feb29>\d{1,3}))/smx;
    my $start_julian_with_feb29_regex =
      qr/(?<start_julian_with_feb29>\d{1,3})/smx;
    my $start_month_regex = qr/(?<start_month>\d{1,2})/smx;
    my $start_week_regex  = qr/(?<start_week>[1-5])/smx;
    my $start_day_regex   = qr/(?<start_day>[0-6])/smx;
    my $start_month_week_day_regex =
      qr/(?:M$start_month_regex[.]$start_week_regex[.]$start_day_regex)/smx;
    my $start_date_regex =
qr/(?:$start_julian_without_feb29_regex|$start_julian_with_feb29_regex|$start_month_week_day_regex)/smx;
    my $start_hour_regex   = qr/(?<start_hour>\-?\d+)/smx;
    my $start_minute_regex = qr/(?::(?<start_minute>\d+))/smx;
    my $start_second_regex = qr/(?::(?<start_second>\d+))/smx;
    my $start_time_regex =
      qr/[\/]$start_hour_regex$start_minute_regex?$start_second_regex?/smx;
    my $start_datetime_regex = qr/$start_date_regex(?:$start_time_regex)?/smx;
    my $end_julian_without_feb29_regex =
      qr/(?:J(?<end_julian_without_feb29>\d{1,3}))/smx;
    my $end_julian_with_feb29_regex = qr/(?<end_julian_with_feb29>\d{1,3})/smx;
    my $end_month_regex             = qr/(?<end_month>\d{1,2})/smx;
    my $end_week_regex              = qr/(?<end_week>[1-5])/smx;
    my $end_day_regex               = qr/(?<end_day>[0-6])/smx;
    my $end_month_week_day_regex =
      qr/(?:M$end_month_regex[.]$end_week_regex[.]$end_day_regex)/smx;
    my $end_date_regex =
qr/(?:$end_julian_without_feb29_regex|$end_julian_with_feb29_regex|$end_month_week_day_regex)/smx;
    my $end_hour_regex   = qr/(?<end_hour>\-?\d+)/smx;
    my $end_minute_regex = qr/(?::(?<end_minute>\d+))/smx;
    my $end_second_regex = qr/(?::(?<end_second>\d+))/smx;
    my $end_time_regex =
      qr/[\/]$end_hour_regex$end_minute_regex?$end_second_regex?/smx;
    my $end_datetime_regex = qr/$end_date_regex(?:$end_time_regex)?/smx;
    $modern_tz_regex =
qr/($std_name_regex$std_offset_regex(?:$dst_name_regex(?:$dst_offset_regex)?,$start_datetime_regex,$end_datetime_regex)?)/smx;
_REGEX_
    return $modern_tz_regex;
}

my $_modern_tz_regex = _compile_modern_tz_regex();

sub _modern_parse_tz_variable {
    my ( $self, $tz_variable, $path ) = @_;
    if ( $tz_variable =~ /^$_modern_tz_regex$/smx ) {
        my $tz_definition = { tz => $1 };
        foreach my $key ( _TZ_DEFINITION_KEYS() ) {
            if ( defined $LAST_PAREN_MATCH{$key} ) {
                $tz_definition->{$key} = $LAST_PAREN_MATCH{$key};
            }
        }
        $self->_initialise_undefined_tz_definition_values($tz_definition);
        $self->_cleanup_bracketed_names($tz_definition);
        return $tz_definition;
    }
    else {
        Carp::croak(
            "Failed to parse the tz definition of $tz_variable from $path");
    }
}

sub _dst_offset_in_seconds {
    my ( $self, $tz_definition ) = @_;
    my $dst_offset_in_seconds = $tz_definition->{dst_seconds} || 0;
    if ( defined $tz_definition->{dst_minutes} ) {
        $dst_offset_in_seconds +=
          $tz_definition->{dst_minutes} * _SECONDS_IN_ONE_MINUTE();
    }
    if ( defined $tz_definition->{dst_hours} ) {
        $dst_offset_in_seconds +=
          $tz_definition->{dst_hours} *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
    }
    else {
        $dst_offset_in_seconds +=
          ( $tz_definition->{std_hours} ) *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
        if ( defined $tz_definition->{std_minutes} ) {
            $dst_offset_in_seconds +=
              $tz_definition->{std_minutes} * _SECONDS_IN_ONE_MINUTE();
        }
    }
    if (   ( defined $tz_definition->{dst_sign} )
        && ( $tz_definition->{dst_sign} eq q[-] ) )
    {
    }
    elsif ( defined $tz_definition->{dst_hours} ) {
        $dst_offset_in_seconds *= _NEGATIVE_ONE();
    }
    elsif (( defined $tz_definition->{std_sign} )
        && ( $tz_definition->{std_sign} eq q[-] ) )
    {
        $dst_offset_in_seconds +=
          _MINUTES_IN_ONE_HOUR() * _SECONDS_IN_ONE_MINUTE();
    }
    else {
        $dst_offset_in_seconds *= _NEGATIVE_ONE();
        $dst_offset_in_seconds +=
          _MINUTES_IN_ONE_HOUR() * _SECONDS_IN_ONE_MINUTE();
    }
    return $dst_offset_in_seconds;
}

sub _std_offset_in_seconds {
    my ( $self, $tz_definition ) = @_;
    my $std_offset_in_seconds = $tz_definition->{std_seconds} || 0;

    if ( defined $tz_definition->{std_minutes} ) {
        $std_offset_in_seconds +=
          $tz_definition->{std_minutes} * _SECONDS_IN_ONE_MINUTE();
    }
    if ( defined $tz_definition->{std_hours} ) {
        $std_offset_in_seconds +=
          $tz_definition->{std_hours} *
          _MINUTES_IN_ONE_HOUR() *
          _SECONDS_IN_ONE_MINUTE();
    }
    if (   ( defined $tz_definition->{std_sign} )
        && ( $tz_definition->{std_sign} eq q[-] ) )
    {
    }
    else {
        $std_offset_in_seconds *= _NEGATIVE_ONE();
    }
    return $std_offset_in_seconds;
}

sub _initialise_undefined_tz_definition_values {
    my ( $self, $tz_definition ) = @_;
    $tz_definition->{start_hour} =
      defined $tz_definition->{start_hour}
      ? $tz_definition->{start_hour}
      : _DEFAULT_DST_START_HOUR();
    $tz_definition->{start_minute} =
      defined $tz_definition->{start_minute}
      ? $tz_definition->{start_minute}
      : 0;
    $tz_definition->{start_second} =
      defined $tz_definition->{start_second}
      ? $tz_definition->{start_second}
      : 0;
    $tz_definition->{end_hour} =
      defined $tz_definition->{end_hour}
      ? $tz_definition->{end_hour}
      : _DEFAULT_DST_END_HOUR();
    $tz_definition->{end_minute} =
      defined $tz_definition->{end_minute}
      ? $tz_definition->{end_minute}
      : 0;
    $tz_definition->{end_second} =
      defined $tz_definition->{end_second}
      ? $tz_definition->{end_second}
      : 0;
    $tz_definition->{std_offset_in_seconds} =
      $self->_std_offset_in_seconds($tz_definition);
    $tz_definition->{dst_offset_in_seconds} =
      $self->_dst_offset_in_seconds($tz_definition);
    return;
}

sub _set_abbrs {
    my ( $self, $tz ) = @_;
    my $index = 0;
    foreach
      my $local_time_type ( @{ $self->{_tzdata}->{$tz}->{local_time_types} } )
    {
        if ( $self->{_tzdata}->{$tz}->{local_time_types}->[ $index + 1 ] ) {
            $local_time_type->{abbr} =
              substr $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings},
              $local_time_type->{abbrind},
              $self->{_tzdata}->{$tz}->{local_time_types}->[ $index + 1 ]
              ->{abbrind};
        }
        else {
            $local_time_type->{abbr} =
              substr $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings},
              $local_time_type->{abbrind};
        }
        $local_time_type->{abbr} =~ s/\0+$//smx;
        $index += 1;
    }
    return;
}

sub _sort_transition_times {
    my ( $self, $tz ) = @_;
    my @sorted_transition_times =
      sort { $a <=> $b } @{ $self->{_tzdata}->{$tz}->{transition_times} };
    my %transition_time_original_indexes;
    my $count = 0;
    foreach my $time ( @{ $self->{_tzdata}->{$tz}->{transition_times} } ) {
        if ( defined $transition_time_original_indexes{$time} ) {
            Carp::croak(
"There are two transition times for $time in $tz, which cannot be coped with at the moment.  Please file a bug with Time::Zone::Olson"
            );
        }
        else {
            $transition_time_original_indexes{$time} = $count;
        }
        $count += 1;
    }
    my @sorted_local_time_indexes;
    $count = 0;
    foreach my $time (@sorted_transition_times) {
        push @sorted_local_time_indexes,
          $self->{_tzdata}->{$tz}->{local_time_indexes}
          ->[ $transition_time_original_indexes{$time} ];
        $count += 1;
    }
    $self->{_tzdata}->{$tz}->{transition_times}   = \@sorted_transition_times;
    $self->{_tzdata}->{$tz}->{local_time_indexes} = \@sorted_local_time_indexes;
    return;
}

sub _read_v1_tzfile {
    my ( $self, $handle, $path, $header, $tz ) = @_;
    $self->{_tzdata}->{$tz}->{transition_times} =
      $self->_read_transition_times( $handle, $path, $header->{timecnt},
        _SIZE_OF_TRANSITION_TIME_V1() );
    $self->{_tzdata}->{$tz}->{local_time_indexes} =
      $self->_read_local_time_indexes( $handle, $path, $header->{timecnt} );
    $self->{_tzdata}->{$tz}->{local_time_types} =
      $self->_read_local_time_types( $handle, $path, $header->{typecnt} );
    $self->_sort_transition_times($tz);
    $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings} =
      $self->_read_time_zone_abbreviation_strings( $handle, $path,
        $header->{charcnt} );
    $self->_set_abbrs($tz);
    $self->{_tzdata}->{$tz}->{leap_seconds} =
      $self->_read_leap_seconds( $handle, $path, $header->{leapcnt},
        _SIZE_OF_LEAP_SECOND_V1() );
    $self->{_tzdata}->{$tz}->{is_std} =
      $self->_read_is_standard_time( $handle, $path, $header->{ttisstdcnt} );
    $self->{_tzdata}->{$tz}->{is_gmt} =
      $self->_read_is_gmt( $handle, $path, $header->{ttisgmtcnt} );
    return;
}

sub _read_v2_tzfile {
    my ( $self, $handle, $path, $header, $tz ) = @_;

    if (   ( $header->{version} )
        && ( $header->{version} >= 2 )
        && ( defined $Config{'d_quad'} )
        && ( $Config{'d_quad'} eq 'define' ) )
    {
        $self->{_tzdata}->{$tz} = {};
        $header = $self->_read_header( $handle, $path );
        $self->{_tzdata}->{$tz}->{transition_times} =
          $self->_read_transition_times( $handle, $path, $header->{timecnt},
            _SIZE_OF_TRANSITION_TIME_V2() );
        $self->{_tzdata}->{$tz}->{local_time_indexes} =
          $self->_read_local_time_indexes( $handle, $path, $header->{timecnt} );
        $self->_sort_transition_times($tz);
        $self->{_tzdata}->{$tz}->{local_time_types} =
          $self->_read_local_time_types( $handle, $path, $header->{typecnt} );
        $self->{_tzdata}->{$tz}->{time_zone_abbreviation_strings} =
          $self->_read_time_zone_abbreviation_strings( $handle, $path,
            $header->{charcnt} );
        $self->_set_abbrs($tz);
        $self->{_tzdata}->{$tz}->{leap_seconds} =
          $self->_read_leap_seconds( $handle, $path, $header->{leapcnt},
            _SIZE_OF_LEAP_SECOND_V2() );
        $self->{_tzdata}->{$tz}->{is_std} =
          $self->_read_is_standard_time( $handle, $path,
            $header->{ttisstdcnt} );
        $self->{_tzdata}->{$tz}->{is_gmt} =
          $self->_read_is_gmt( $handle, $path, $header->{ttisgmtcnt} );
        $self->{_tzdata}->{$tz}->{tz_definition} =
          $self->_read_tz_definition( $handle, $path );
    }
    return;
}

sub _win32_registry_encode {
    my ( $self, $string ) = @_;
    my $encoded = Encode::encode( 'UCS-2LE', $string, 1 ) . "\0";
    return $encoded;
}

sub _win32_registry_decode {
    my ( $self, $string ) = @_;
    my $decoded = Encode::decode( 'UCS-2LE', $string, 1 );
    $decoded =~ s/\0.*$//smx;
    return $decoded;
}

sub _read_win32_tzfile {
    my ( $self, $tz ) = @_;
    if ( $self->{_tzdata}->{$tz}->{tz_definition} ) {
        return;
    }
    my $timezone_specific_registry_path;
    my $timezone_specific_subkey;
    foreach my $win32_tz_name ( @{ $olson_to_win32_timezones{$tz} } ) {
        $timezone_specific_registry_path =
"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones\\$win32_tz_name";
        Win32API::Registry::RegOpenKeyExW(
            Win32API::Registry::HKEY_LOCAL_MACHINE(),
            $self->_win32_registry_encode($timezone_specific_registry_path),
            0,
            Win32API::Registry::KEY_QUERY_VALUE(),
            $timezone_specific_subkey,
        ) and last;
    }
    $timezone_specific_subkey
      or Carp::croak(
"Failed to open LOCAL_MACHINE\\$timezone_specific_registry_path:$EXTENDED_OS_ERROR"
      );
    Win32API::Registry::RegQueryValueExW( $timezone_specific_subkey,
        $self->_win32_registry_encode('Dlt'),
        [], [], my $daylight_name, [] )
      or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Dlt:$EXTENDED_OS_ERROR"
      );
    $daylight_name = $self->_win32_registry_decode($daylight_name);
    Win32API::Registry::RegQueryValueExW( $timezone_specific_subkey,
        $self->_win32_registry_encode('Std'),
        [], [], my $standard_name, [] )
      or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Std:$EXTENDED_OS_ERROR"
      );
    $standard_name = $self->_win32_registry_decode($standard_name);
    Win32API::Registry::RegQueryValueExW( $timezone_specific_subkey,
        $self->_win32_registry_encode('Display'),
        [], [], my $comment, [] )
      or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Display:$EXTENDED_OS_ERROR"
      );
    $comment = $self->_win32_registry_decode($comment);
    Win32API::Registry::RegQueryValueExW( $timezone_specific_subkey,
        $self->_win32_registry_encode('TZI'),
        [], [], my $binary, [] )
      or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\TZI:$EXTENDED_OS_ERROR"
      );

    my %mapping = $self->win32_mapping();

    $self->{_comments}->{$tz} = $comment;

    my $tz_definition = $self->_unpack_win32_tzi_structure($binary);

    $tz_definition->{std_name} = $standard_name;
    $tz_definition->{dst_name} = $daylight_name;

    $self->_initialise_undefined_tz_definition_values($tz_definition);
    $self->{_tzdata}->{$tz}->{tz_definition} = $tz_definition;
    $self->{_tzdata}->{$tz}->{transition_times} =
      $self->_read_win32_transition_times( $timezone_specific_subkey,
        $timezone_specific_registry_path );

    Win32API::Registry::RegCloseKey($timezone_specific_subkey)
      or Carp::croak(
"Failed to close LOCAL_MACHINE\\$timezone_specific_registry_path:$EXTENDED_OS_ERROR"
      );
    return;
}

sub win32_registry {
    my ($self) = @_;
    return $self->{_win32_registry};
}

sub _read_tzfile {
    my ($self) = @_;
    my $tz = $self->timezone();
    if ( $self->win32_registry() ) {
        $self->_read_win32_tzfile($tz);
    }
    elsif (( exists $self->{_tzdata}->{$tz}->{no_tz_file} )
        && ( $self->{_tzdata}->{$tz}->{no_tz_file} ) )
    {
    }
    else {
        my $path   = File::Spec->catfile( $self->directory, $tz );
        my $handle = FileHandle->new($path)
          or Carp::croak("Failed to open $path for reading:$EXTENDED_OS_ERROR");
        my @stat = stat $handle
          or Carp::croak("Failed to stat $path:$EXTENDED_OS_ERROR");
        my $last_modified = $stat[ _STAT_MTIME_IDX() ];
        if (   ( $self->{_tzdata}->{$tz}->{last_modified} )
            && ( $self->{_tzdata}->{$tz}->{last_modified} == $last_modified ) )
        {
        }
        elsif (( $_tzdata_cache->{$tz} )
            && ( $_tzdata_cache->{$tz}->{last_modified} )
            && ( $_tzdata_cache->{$tz}->{last_modified} == $last_modified ) )
        {
            $self->{_tzdata}->{$tz} = $_tzdata_cache->{$tz};
        }
        else {
            binmode $handle;
            my $header = $self->_read_header( $handle, $path );
            $self->_read_v1_tzfile( $handle, $path, $header, $tz );
            $self->_read_v2_tzfile( $handle, $path, $header, $tz );
            $self->{_tzdata}->{$tz}->{last_modified} = $last_modified;
            $_tzdata_cache->{$tz} = $self->{_tzdata}->{$tz};
        }
        close $handle
          or Carp::croak("Failed to close $path:$EXTENDED_OS_ERROR");
    }
    return;
}

sub _unpack_win32_tzi_structure {
    my ( $self, $binary ) = @_;
    my (
        $bias,            $standard_bias,        $daylight_bias,
        $standard_year,   $standard_month,       $standard_day_of_week,
        $standard_day,    $standard_hour,        $standard_minute,
        $standard_second, $standard_millisecond, $daylight_year,
        $daylight_month,  $daylight_day_of_week, $daylight_day,
        $daylight_hour,   $daylight_minute,      $daylight_second,
        $daylight_millisecond
    ) = unpack 'lllSSSSSSSSSSSSSS', $binary;
    my $negative_one        = _NEGATIVE_ONE();
    my $minutes_in_one_hour = _MINUTES_IN_ONE_HOUR();
    my $tz_definition       = {
        ( ( $bias + $standard_bias ) < 0 ? ( std_sign => q[-] ) : () ),
        std_hours => int(
            ( $bias + $standard_bias ) /
              _SECONDS_IN_ONE_MINUTE() *
              ( ( $bias + $standard_bias ) < 0 ? $negative_one : 1 )
        ),
        std_minutes => (
            (
                ( $bias + $standard_bias ) < 0
                ? $minutes_in_one_hour -
                  ( ( $bias + $standard_bias ) % $minutes_in_one_hour )
                : ( $bias + $standard_bias ) % $minutes_in_one_hour
            ) % $minutes_in_one_hour
        ),
        (
            $standard_month != 0
            ? (
                ( ( $bias + $daylight_bias ) < 0 ? ( dst_sign => q[-] ) : () ),
                dst_hours => int(
                    ( $bias + $daylight_bias ) /
                      _SECONDS_IN_ONE_MINUTE() *
                      ( ( $bias + $daylight_bias ) < 0 ? $negative_one : 1 )
                ),
                dst_minutes => (
                    (
                        ( $bias + $daylight_bias ) < 0
                        ? $minutes_in_one_hour -
                          ( ( $bias + $daylight_bias ) % $minutes_in_one_hour )
                        : ( $bias + $daylight_bias ) % $minutes_in_one_hour
                    ) % $minutes_in_one_hour
                ),
                start_month => $daylight_month,
                end_month   => $standard_month,
                start_week  => $daylight_day,
                end_week    => $standard_day,
                start_day   => $daylight_day_of_week,
                end_day     => $standard_day_of_week,
                end_hour    => $standard_hour
              )
            : ()
        ),
    };
    return $tz_definition;
}

sub _read_win32_transition_times {
    my ( $self, $timezone_specific_subkey, $timezone_specific_registry_path ) =
      @_;
    my @transition_times;
    if (
        Win32API::Registry::RegOpenKeyExW(
            $timezone_specific_subkey,
            $self->_win32_registry_encode('Dynamic DST'),
            0,
            Win32API::Registry::KEY_QUERY_VALUE(),
            my $timezone_dst_subkey
        )
      )
    {
        Win32API::Registry::RegQueryValueExW( $timezone_dst_subkey,
            $self->_win32_registry_encode('FirstEntry'),
            [], [], my $dword, [] )
          or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Dynamic DST\\FirstEntry:$EXTENDED_OS_ERROR"
          );
        my $first_entry = unpack 'I', $dword;
        Win32API::Registry::RegQueryValueExW( $timezone_dst_subkey,
            $self->_win32_registry_encode('LastEntry'),
            [], [], $dword, [] )
          or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Dynamic DST\\LastEntry:$EXTENDED_OS_ERROR"
          );
        my $last_entry = unpack 'I', $dword;
        for my $year ( $first_entry .. $last_entry ) {
            Win32API::Registry::RegQueryValueExW( $timezone_dst_subkey,
                $self->_win32_registry_encode($year),
                [], [], my $binary, [] )
              or Carp::croak(
"Failed to read LOCAL_MACHINE\\$timezone_specific_registry_path\\Dynamic DST\\$year:$EXTENDED_OS_ERROR"
              );
            my $tz_definition = $self->_unpack_win32_tzi_structure($binary);
        }
        Win32API::Registry::RegCloseKey($timezone_dst_subkey)
          or Carp::croak(
"Failed to close LOCAL_MACHINE\\$timezone_specific_registry_path\\Dynamic DST:$EXTENDED_OS_ERROR"
          );
    }
    elsif (
        Win32API::Registry::regLastError() == _WIN32_ERROR_FILE_NOT_FOUND() )
    {
    }
    else {
        Carp::croak(
"Failed to open LOCAL_MACHINE\\$timezone_specific_registry_path:$EXTENDED_OS_ERROR"
        );
    }
    return \@transition_times;
}

sub win32_mapping {
    my ($self) = @_;
    my %returned_timezones;
    if ( $OSNAME eq 'MSWin32' ) {
        my $timezone_database_registry_path =
          'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones';
        Win32API::Registry::RegOpenKeyExW(
            Win32API::Registry::HKEY_LOCAL_MACHINE(),
            $self->_win32_registry_encode($timezone_database_registry_path),
            0,
            Win32API::Registry::KEY_QUERY_VALUE() |
              Win32API::Registry::KEY_ENUMERATE_SUB_KEYS(),
            my $timezone_database_subkey,
          )
          or Carp::croak(
"Failed to open LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR"
          );
        my $enumerate_timezones = 1;
        my $timezone_index      = 0;
        my %local_windows_timezones;
        while ($enumerate_timezones) {
            if (
                Win32API::Registry::RegEnumKeyExW(
                    $timezone_database_subkey, $timezone_index, my $buffer, [],
                    [],                        [],              [],         [],
                )
              )
            {
                $local_windows_timezones{ $self->_win32_registry_decode($buffer)
                } = 1;
            }
            elsif ( Win32API::Registry::regLastError() ==
                _WIN32_ERROR_NO_MORE_ITEMS() )
            {    # ERROR_NO_MORE_TIMES from winerror.h
                $enumerate_timezones = 0;
            }
            else {
                Carp::croak(
"Failed to read from LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR"
                );
            }
            $timezone_index += 1;
        }
        Win32API::Registry::RegCloseKey($timezone_database_subkey)
          or Carp::croak(
"Failed to close LOCAL_MACHINE\\$timezone_database_registry_path:$EXTENDED_OS_ERROR"
          );
        foreach
          my $timezone ( sort { $a cmp $b } keys %olson_to_win32_timezones )
        {
            foreach
              my $win32_tz_name ( @{ $olson_to_win32_timezones{$timezone} } )
            {
                if (   ( $local_windows_timezones{$win32_tz_name} )
                    && ( !defined $returned_timezones{$timezone} ) )
                {
                    $returned_timezones{$timezone} = $win32_tz_name;
                }
            }
        }
    }
    else {
        foreach
          my $timezone ( sort { $a cmp $b } keys %olson_to_win32_timezones )
        {
            foreach
              my $win32_tz_name ( @{ $olson_to_win32_timezones{$timezone} } )
            {
                if ( !defined $returned_timezones{$timezone} ) {
                    $returned_timezones{$timezone} = $win32_tz_name;
                }
            }
        }
    }
    return %returned_timezones;
}

sub reset_cache {
    my ($self) = @_;
    if ( ref $self ) {
        foreach my $key (qw(_tzdata _zonetab_last_modified _comments _zones)) {
            $self->{$key} = {};
        }
        delete $self->{_unix_zonetab_path};
    }
    else {
        $_tzdata_cache  = {};
        $_zonetab_cache = {};
    }
    return;
}

1;
__END__
=head1 NAME

Time::Zone::Olson - Provides an Olson timezone database interface

=head1 VERSION

Version 0.41

=cut

=head1 SYNOPSIS

    use Time::Zone::Olson();

    my $time_zone = Time::Zone::Olson->new( timezone => 'Australia/Melbourne' ); # set timezone at creation time
    my $now = $time_zone->time_local($seconds, $minutes, $hours, $day, $month, $year); # convert for Australia/Melbourne time
    foreach my $area ($time_zone->areas()) {
        foreach my $location ($time_zone->locations($area)) {
            $time_zone->timezone("$area/$location");
            print scalar $time_zone->local_time($now); # output time in $area/$location local time
            warn scalar localtime($now) . " log message for sysadmin"; # but log in system local time
        }
    }

=head1 DESCRIPTION

Time::Zone::Olson is intended to provide a simple interface to the Olson database that is available on most UNIX systems.  It provides an interface to list common time zones, such as Australia/Melbourne that are stored in the zone.tab file, and localtime/Time::Local::timelocal replacements to translate times to and from the users time zone, without changing the time zone used by Perl.  This allows logging/etc to be conducted in the system's local time.

Time::Zone::Olson was designed to produce the same result as a 64 bit copy of the L<date(1)|date(1)> command.

Time::Zone::Olson will attempt to function even without an actual Olson database on Windows platforms by translating information available in the Windows registry.

=head1 SUBROUTINES/METHODS

=head2 new

Time::Zone::Olson->new() will return a new time zone object.  It accepts a hash as a parameter with an optional C<timezone> key, which contains an Olson time zone value, such as 'Australia/Melbourne'.  The hash also allows a C<directory> key, with the file system location of the Olson time zone database as a value.

Both of these parameters default to C<$ENV{TZ}> and C<$ENV{TZDIR}> respectively.

=head2 areas

This method will return a list of the areas (such as Asia, Australia, Africa, America, Europe) from the zone.tab file.  The areas will be sorted alphabetically.

=head2 locations

This method accepts a area (such as Asia, Australia, Africa, America, Europe) as a parameter and will return a list of matching locations (such as Melbourne, Perth, Hobart) from the zone.tab file.  The locations will be sorted alphabetically.

=head2 comment

This method accepts the name of time zone such as C<"Australia/Melbourne"> as a parameter and will return the matching comment from the zone.tab file.  For example, if C<"Australia/Melbourne"> was passed as a parameter, the L</comment> function would return C<"Victoria">.  For Windows platforms, it will return the contents of the C<Display> registry setting.  For example, for C<"Australia/Melbourne"> using English as a language, it would return C<"(UTC+10) Canberra, Melbourne, Sydney">.

=head2 directory

This method can be used to get or set the root directory of the Olson database, usually located at C</usr/share/zoneinfo>.

=head2 timezone

This method can be used to get or set the time zone, which will affect all future calls to L</local_time> or L</time_local>.  The parameter for this method should be in the Olson format of a time zone, such as C<"Australia/Melbourne">.

=head2 equiv

This method takes a time zone name as a parameter.  It then compares the transition times and offsets for the currently set time zone to the transition times and offsets for the specified time zone and returns true if they match exactly from the current time.  The second optional parameter can specify the start time to use when comparing the two time zones.

=head2 offset

This method can be used to get or set the offset for all L</local_time> or L</time_local> calls.  The offset should be specified in minutes from GMT.

=head2 area

This method will return the area component of the current time zone, such as Australia

=head2 location

This method will return the location component of the current time zone, such as Melbourne

=head2 local_offset

This method takes the same arguments as C<localtime> but returns the appropriate offset from GMT in minutes.  This can to used as a C<offset> parameter to a subsequent call to Time::Zone::Olson.

=head2 local_time

This method has the same signature as the 64 bit version of the C<localtime> function.  That is, it accepts up to a 64 bit signed integer as the sole argument and returns the C<(seconds, minutes, hours, day, month, year, wday, yday, isdst)> definition for the time zone for the object.  The time zone used to calculate the local time may be specified as a parameter to the L</new> method or via the L</timezone> method.

=head2 time_local

This method has the same signature as the 64 bit version of the C<Time::Local::timelocal> function.  That is, it accepts C<(seconds, minutes, hours, day, month, year, wday, yday, isdst)> as parameters in a list and returns the correct UNIX time in seconds according to the current time zone for the object.  The time zone used to calculate the local time may be specified as a parameter to the L</new> method or via the L</timezone> method. 

During a time zone change such as +11 GMT to +10 GMT, there will be two possible UNIX times that can result in the same local time.  In this case, like C<Time::Local::timelocal>, this function will return the lower of the two times.

=head2 transition_times

This method can be used to get the list of transition times for the current time zone.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 determining_path

This method can be used to determine which file system path was used to determine the current operating system timezone.  If it returns undef, then the current operating system timezone was determined by other means (such as the win32 registry, or comparing the digests of C</etc/localtime> with timezones in L</directory>).

=head2 leap_seconds

This method can be used to get the list of leap seconds for the current time zone.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 reset_cache

This method can be used to reset the cache.  This method is only intended for testing the results of Time::Zone::Olson.  In actual use, cached values are only used if the C<mtime> of the relevant files has not changed.

=head2 tz_definition

This method will return the TZ environment variable (if any) that describes a timezone after the L</transition_times> have been used.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 win32_mapping 

This method will return a hash containing the mapping between Windows time zones and Olson time zones.  This method is only intended for testing the results of Time::Zone::Olson.

=head2 win32_registry

This method will return true if the object is using the Windows registry for Olson tz calculations.  Otherwise it will return false.

=head1 DIAGNOSTICS

=over

=item C<< %s is not a TZ file >>

The designated path did not have the C<TZif> prefix at the start of the file.  Maybe either the directory or the time zone name is incorrect?

=item C<< Failed to read header from %s:%s >>

The designated file encountered an error reading either the version 1 or version 2 headers

=item C<< Failed to read entire header from %s.  %d bytes were read instead of the expected %d >>

The designated file is shorter than expected

=item C<< %s is not a time zone in the existing Olson database >>

The designated time zone could not be found on the file system.  The time zone is expected to be in the designated directory + the time zone name, for example, /usr/share/zoneinfo/Australia/Melbourne

=item C<< %s does not have a valid format for a TZ time zone >>

The designated time zone name could not be matched by the regular expression for a time zone in Time::Zone::Olson

=item C<< There are two transition times for %s in %s, which cannot be coped with at the moment.  Please file a bug with Time::Zone::Olson >>

The transition times are sorted to handle unsorted (on disk) transition times which has been found on solaris.  Please file a bug.

=item C<< Failed to close %s:%s >>

There has been a file system error while reading or closing the designated path

=item C<< Failed to open %s for reading:%s >>

There has been a file system error while opening the the designated path.  This could be permissions related, or the time zone in question doesn't exist?

=item C<< Failed to stat %s:%s >>

There has been a file system error while doing a L<stat|perlfunc/"stat"> on the designated path.  This could be permissions related, or the time zone in question doesn't exist?

=item C<< Failed to read %s from %s:%s >>

There has been a file system error while reading from the designated path.  The file could be corrupt?

=item C<< Failed to read all the %s from %s.  %d bytes were read instead of the expected %d >>

The designated file is shorter than expected.  The file could be corrupt?

=item C<< The tz definition at the end of %s could not be read in %d bytes >>

The designated file is longer than expected.  Maybe the time zone version is greater than the currently recognized 3?

=item C<< Failed to read tz definition from %s:% >>

There has been a file system error while reading from the designated path.  The file could be corrupt?

=item C<< Failed to parse the tz definition of %s from %s >>

This is probably a bug in Time::Zone::Olson in failing to parse the C<TZ> variable at the end of the file.

=item C<< Failed to open %s:%s >>

There has been an error while opening the the designated registry entry.

=item C<< Failed to read from %s:%s >>

There has been an file system error while reading from the registry.

=item C<< Failed to close %s:%s >>

There has been an error while reading or closing the designated registry entry

=back

=head1 CONFIGURATION AND ENVIRONMENT

Time::Zone::Olson requires no configuration files or environment variables.  However, it will use the values of C<$ENV{TZ}> and C<$ENV{TZDIR}> as defaults for missing parameters.

=head1 DEPENDENCIES

For environments where the unpack 'q' parameter is not supported, the L<Math::Int64|Math::Int64> module is required

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

On Windows platforms, the Olson TZ database is usually unavailable.  In an attempt to provide a workable alternative, the Windows Registry is interrogated and translated to allow Olson time zones (such as Australia/Melbourne) to be used on Windows nodes.  Therefore, the use of Time::Zone::Olson should be cross-platform compatible, but the actual results may be different, depending on the compatibility of the Windows Registry time zones and the Olson TZ database.

For perl versions less than 5.10, support for TZ environment variable parsing is not complete.  It should cover all existing cases in the Olson time zone database though.

To report a bug, or view the current list of bugs, please visit L<https://github.com/david-dick/time-zone-olson/issues>

=head1 SEE ALSO

=over

=item *
L<DateTime::TimeZone|DateTime::TimeZone>

=item *
L<DateTime::TimeZone::Tzfile|DateTime::TimeZone::Tzfile>

=item *
L<DateTime::TimeZone::Local::Win32|DateTime::TimeZone::Local::Win32>

=item *
L<Time::Local|Time::Local>

=item *
L<Time::Local::TZ|Time::Local::TZ>

=back

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
