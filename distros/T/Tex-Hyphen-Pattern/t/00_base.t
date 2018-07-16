#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use Test::More;

our $VERSION = 0.100;

if ( $ENV{'AUTHOR_TESTING'} ) {
    eval {
        require Test::NoWarnings;
        1;
    } or do {
        diag q{Not testing for warnings};
    };
}

BEGIN {
    use Readonly;
    Readonly my $COLLATERAL_TESTS => 4;
    ## no critic qw(ProhibitPackageVars)
    @MAIN::methods = qw(filename available);
    plan 'tests' => ( $COLLATERAL_TESTS + @MAIN::methods ) + 1;
    ## use critic
    ok( 1, q{Basic OK} );
    use_ok('TeX::Hyphen::Pattern');
}
diag("Testing TeX::Hyphen::Pattern $TeX::Hyphen::Pattern::VERSION");
my $pat = new_ok('TeX::Hyphen::Pattern');

@TeX::Hyphen::Pattern::Sub::ISA = qw(TeX::Hyphen::Pattern);
my $pat_sub = new_ok('TeX::Hyphen::Pattern::Sub');

## no critic qw(ProhibitPackageVars)
foreach my $method (@MAIN::methods) {
    can_ok( 'TeX::Hyphen::Pattern', $method );
}
## use critic

my $msg =
q{Author test. Set the environment variable AUTHOR_TESTING to enable this test.};
SKIP: {
    if ( not $ENV{'AUTHOR_TESTING'} ) {
        skip $msg, 1;
    }
}
$ENV{'AUTHOR_TESTING'} && Test::NoWarnings::had_no_warnings();
