#! /usr/bin/perl -w
use strict;

# $Id$

use File::Spec::Functions;
use Cwd;

use Test::More;

BEGIN {
    plan $^O eq 'VMS'
        ? ( tests    => 16 )
        : ( skip_all => "This ($^O) is not VMS!" );

    use_ok( 'Test::Smoke::Util', 'set_vms_rooted_logical' );
}

ok defined &set_vms_rooted_logical, "set_vms_rooted_logical() imported";

my $logical = sprintf 'TS_TMPRL%02d', rand( 100 );
my $cwd = cwd();

{
    ok Test::Smoke::Util::set_vms_rooted_logical( $logical ),
       "no errors in set_vms_rooted_logical( $logical )";

    my $show_logical = `SHOW LOGICAL $logical`;
    like $show_logical, qq[/^\\s*"$logical" = /m], "$logical does exist";
    like $show_logical, qq[/\\(LNM\\\$JOB_/], "It's in the Job table";

    my( $rlpath ) = $show_logical =~ m| = ._?:(\[.*?\])|;
    my( $wdpath ) = $cwd          =~ m| = ._?:(\[.*?\])|;

    is $rlpath, $wdpath, "dirtree looks right";

    # DEASSIGN the logical
    ok !system( "DEASSIGN/JOB $logical" ), "DEASSIGN/JOB $logical";
}

{
    ok Test::Smoke::Util::set_vms_rooted_logical( $logical, curdir() ),
       "no errors in set_vms_rooted_logical( $logical, '[.]' )";

    my $show_logical = `SHOW LOGICAL $logical`;
    like $show_logical, qq[/^\\s*"$logical" = /m], "$logical does exist";
    like $show_logical, qq[/\\(LNM\\\$JOB_/], "It's in the Job table";

    my( $rlpath ) = $show_logical =~ m| = ._?:(\[.*?\])|;
    my( $wdpath ) = $cwd          =~ m| = ._?:(\[.*?\])|;

    is $rlpath, $wdpath, "dirtree looks right";

    # DEASSIGN the logical
    ok !system( "DEASSIGN/JOB $logical" ), "DEASSIGN/JOB $logical";
}

{
    my $tdir = catdir( $cwd, 't' );
    ok Test::Smoke::Util::set_vms_rooted_logical( $logical ),
       "no errors in set_vms_rooted_logical( $logical, '$tdir' )";

    my $show_logical = `SHOW LOGICAL $logical`;
    like $show_logical, qq[/^\\s*"$logical" = /m], "$logical does exist";
    like $show_logical, qq[/\\(LNM\\\$JOB_/], "It's in the Job table";

    my( $rlpath ) = $show_logical =~ m| = ._?:(\[.*?\])|;
    my( $wdpath ) = $tdir         =~ m| = ._?:(\[.*?\])|;

    is $rlpath, $wdpath, "dirtree looks right";

    # DEASSIGN the logical
    ok !system( "DEASSIGN/JOB $logical" ), "DEASSIGN/JOB $logical";
}
