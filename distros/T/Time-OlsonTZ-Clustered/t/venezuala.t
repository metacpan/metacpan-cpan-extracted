use 5.008001;
use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/:all/;

my $zones = primary_zones("VE");

is( $zones->[0]{description}, "Venezuela",
    "primary zone description falls back to country name" );
is( $zones->[0]{offset},        "-4.5",            "-4.5 offset" );
is( $zones->[0]{timezone_name}, "America/Caracas", "primary zone correct" );

my $raw = timezone_clusters("VE");

is( $raw->[0]{description}, '', "raw cluster description is blank" );

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
