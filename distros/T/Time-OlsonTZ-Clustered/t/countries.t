use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/:all/;

my @country_codes = qw( AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB
  BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BW BY BZ CA CC CD CF CG CH CI CK
  CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ
  FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HN HR
  HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY
  KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ
  MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG
  PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK
  SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW
  TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW);

cmp_deeply( [ country_codes() ], \@country_codes, "country code list correct" );

is( country_name("xx"), '', "bad country_name() returns empty string" );

is_deeply( primary_zones("xx"), [], "bad primary_zones() returns empty array" );
is_deeply( timezone_clusters("xx"), [], "bad primary_zones() returns empty array" );

done_testing;
#
# This file is part of Time-OlsonTZ-Clustered
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
