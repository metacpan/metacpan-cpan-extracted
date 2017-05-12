use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/:all/;

is( scalar find_primary("America/Podunk"),
    undef, "bad find_primary() returns undef" );
is( find_cluster("America/Podunk"), undef, "bad find_cluster() returns undef" );
ok( !is_primary("America/Podunk"), "bad is_primary() is false" );

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
