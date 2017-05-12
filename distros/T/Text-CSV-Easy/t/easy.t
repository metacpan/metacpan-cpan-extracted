#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Test::Deep;
use Test::More;

use Text::CSV::Easy qw(csv_build csv_parse);

note( "Using " . Text::CSV::Easy::module() );
is( csv_build(qw(one two)), q{"one","two"}, 'csv_build is properly installed' );
cmp_deeply( [ csv_parse(q{"one","two"}) ], [qw(one two)], 'csv_parse is properly installed' );

done_testing();
