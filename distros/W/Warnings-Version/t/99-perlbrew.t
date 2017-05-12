#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use Warnings::Version 'all';

use Test::More ( $ENV{ALLBREWS} ? '' : ( skip_all =>
        "Author test that requires special setup ($^X)" ) );

my $prefix = dirname $0;
my $name   = "Warnings/Version.pm";
my $inc    = $INC{$name}; $inc =~ s/\Q$name\E$//;

delete $ENV{ALLBREWS};
foreach my $test ( glob("$prefix/*.t") ) {
    ok( system('allbrews', "-I$inc", $test) == 0,
        "Testing $test on all perls via perlbrew" );
}

done_testing;
