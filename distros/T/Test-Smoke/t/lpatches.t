#! perl -w
use strict;

# $Id$

use File::Spec::Functions;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use File::Copy;

use Test::More tests => 15;
BEGIN { 
    use_ok 'Test::Smoke::Util', qw( get_local_patches set_local_patch );
}
my $verbose = $ENV{SMOKE_VERBOSE} || 0;

ok( defined &get_local_patches, "get_local_patches() is defined" );
ok( defined &set_local_patch, "set_local_patch() is defined" );

my $plevh = 'patchlevel.h';
SKIP: {
    my $srcd = catdir( $findbin, qw( ftppub perl-current ) );
    my $src  = catfile( $srcd, $plevh );
    my $dst  = catfile( $findbin, $plevh );
    copy( $src, $dst ) or skip "Cannot copy $plevh ($!)", 2;

    my @lpatches = get_local_patches( $findbin, $verbose );

    is @lpatches, 1, "One localpatch";
    is $lpatches[0], 'DEVEL19999', "description: $lpatches[0]";


    my @descr = ( "[PATCH] fix 1", "[PATCH] fix 2" );
    ok set_local_patch( $findbin, @descr ), "set_local_patch()";

    @lpatches = get_local_patches( $findbin, $verbose );
    is @lpatches, 3, "Three local patches";
    is $lpatches[1], $descr[0], "descr: $descr[0]";
    is $lpatches[2], $descr[1], "descr: $descr[1]";

    1 while unlink $dst;
    my $plb = catfile( $findbin, 'patchlevel.bak' );
    1 while unlink $plb;
}

SKIP: {
    my $srcd = catdir( $findbin, qw( ftppub ) );
    my $src  = catfile( $srcd, 'pl_with_pn.h' );
    my $dst  = catfile( $findbin, $plevh );
    copy( $src, $dst ) or skip "Cannot copy $plevh ($!)", 2;

    my @lpatches = get_local_patches( $findbin, $verbose );

    is @lpatches, 1, "One localpatch";
    is $lpatches[0], 'DEVEL25000', "description: $lpatches[0]";


    my @descr = ( "[PATCH] fix 1", "[PATCH] fix 2" );
    ok set_local_patch( $findbin, @descr ), "set_local_patch()";

    @lpatches = get_local_patches( $findbin, $verbose );
    is @lpatches, 3, "Three local patches";
    is $lpatches[1], $descr[0], "descr: $descr[0]";
    is $lpatches[2], $descr[1], "descr: $descr[1]";

    1 while unlink $dst;
    my $plb = catfile( $findbin, 'patchlevel.bak' );
    1 while unlink $plb;
}
