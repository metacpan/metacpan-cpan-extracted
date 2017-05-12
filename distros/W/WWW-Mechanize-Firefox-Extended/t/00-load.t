#!usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;
use lib 'lib';

my $module;

BEGIN {
    $module  = 'WWW::Mechanize::Firefox::Extended';
    use_ok( $module ) || print "Bail out!\n";
}

diag( sprintf "Testing %s %s, Perl %s", $module, $module->VERSION, $] );

for (sort grep /\.pm\z/, keys %INC) {
   s/\.pm\z//;
   s!/!::!g;
   eval { diag(join(' ', $_, $_->VERSION || '<unknown>')) };
}
