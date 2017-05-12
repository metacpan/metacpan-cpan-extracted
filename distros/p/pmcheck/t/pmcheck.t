#!/usr/bin/env perl

######################################################################
## Pragmas

use strict;
use utf8;
use warnings;

######################################################################
## Required Libraries

use File::Spec::Functions;
use FindBin qw( $Bin );
use Test::Differences;
use Test::More tests => 6;

######################################################################
## Constants

my $MODULE = catfile( $Bin, &updir, 'lib', 'App', 'pmcheck.pm' );

########################################
# Global variables

our ( %provided, %required );   ## no critic (Variables::ProhibitPackageVars)

######################################################################
## Tests

require_ok( catfile( $Bin, &updir, 'script', 'pmcheck' ) );

##############################
# sub first_line

is( first_line( catfile( $Bin, 'perlcriticrc' ) ), "severity = 3\n", 'first_line' );

##############################
# sub modules_used

eq_or_diff [ modules_used(\q{}) ], [], 'modules_used none';

eq_or_diff [ sort( modules_used($MODULE) ) ], [qw( strict utf8 version warnings )], 'modules_used';

##############################
# sub provided

{
    no warnings 'once';
    $File::Find::name = q{};
}
$_ = $MODULE;
provided();
eq_or_diff [ sort keys %provided ], [qw( App::pmcheck )], 'provided';

##############################
# sub required

$_ = catfile( $Bin, 'pmcheck.t' );
required();
eq_or_diff [ sort keys %required ], [qw( Test::Differences )], 'required';

exit;
