#! /usr/bin/perl -w
use strict;
use Data::Dumper;

# $Id: smoke.t 1191 2008-08-08 23:30:46Z abeltje $
use File::Spec::Functions;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use File::Copy;

use Test::More tests => 8;
use_ok( 'Test::Smoke' );
use_ok ('Test::Smoke::Util', qw( get_local_patches ));

my $verbose = $ENV{SMOKE_VERBOSE} || 0;

my @patchlevels = (
#    [
#        patch level,
#        patch description,
#        string in report
#    ],
     [
         "20000",
         "",
         "   20000   ",
     ],
     [
         "2af192eebde5f7a93e229dfc3196f62ee4cbcd2e",
         "blead-47-2af192ee",
         "blead-47-2af192ee",
     ],
     [
         "a1248f17ffcfa8fe0e91df962317b46b81fc0ce5",
         "v5.11.1-205-ga1248f1",
         "v5.11.1-205-ga1248f1",
     ],
);


for my $p (@patchlevels) {
    # test set_smoke_patchlevel

    my $plevh = 'patchlevel.h';

    my $srcd = catdir( $findbin, qw( ftppub perl-current ) );
    my $src  = catfile( $srcd, $plevh );
    my $dst  = catfile( $findbin, $plevh );
    copy( $src, $dst ) or die "Cannot copy $plevh ($!)", 2;

    my @lpatches = get_local_patches( $findbin, $verbose );
    my $count_before = @lpatches;

    Test::Smoke::set_smoke_patchlevel($findbin, $p->[0], $verbose);
    my @lpatches2 = get_local_patches( $findbin, $verbose );
    is(scalar @lpatches2, $count_before + 1, "smoke id added in patchlevel.h");

    Test::Smoke::set_smoke_patchlevel($findbin, $p->[0], $verbose);
    my @lpatches3 = get_local_patches( $findbin, $verbose );
    is(scalar @lpatches3, $count_before + 1, "smoke id only one time added in patchlevel.h");

    1 while unlink $dst;
    my $plb = catfile( $findbin, 'patchlevel.bak' );
    1 while unlink $plb;
}

