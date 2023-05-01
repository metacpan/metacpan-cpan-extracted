#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$

use File::Spec::Functions;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use File::Copy;

my $verbose = exists $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;
my $showcfg = 0;

use Test::More tests => 691;

use_ok 'Test::Smoke::Reporter';

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


my $config_sh = catfile( $findbin, 'config.sh' );

for my $p (@patchlevels) {
    create_config_sh( $config_sh, version => '5.6.1' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc='ccache gcc'
=
-Uuseperlio
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $timer = time - 300;
    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at @{ [$timer] }
Smoking patch $patch


Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc' -Uuseperlio
------------------------------------------------------------------------------
PERLIO = stdio  u=3.96  s=0.66  cu=298.11  cs=21.18  scripts=731  tests=75945
All tests successful.
Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc' -Uuseperlio -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio  u=4.43  s=0.76  cu=324.65  cs=21.58  scripts=731  tests=75945
All tests successful.
Finished smoking $patch
Stopped smoke at @{ [$timer += 100] }
EORESULTS

    is( $reporter->{_rpt}{started}, $timer - 300, "Start time" );
    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );
    my $cfgarg = "-Dcc='ccache gcc' -Uuseperlio";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports ok" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{stdio}, "O",
        "'$cfgarg -DDEBUGGING' reports ok" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc='ccache gcc'
----------- ---------------------------------------------------------
O O         -Uuseperlio
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'PASS', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}

for my $p (@patchlevels) {
    create_config_sh( $config_sh, version => '5.8.3' );
    my $reporter = Test::Smoke::Reporter->new(
        ddir    => $findbin,
        v       => $verbose, 
        outfile => '',
        showcfg => $showcfg,
        cfg     => \( my $bcfg = <<__EOCFG__ ),
-Dcc='ccache gcc'
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $timer = time - 1000;
    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at @{ [$timer] }
Smoking patch $patch

MANIFEST did not declare t/perl

Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc'
------------------------------------------------------------------------------
TSTENV = stdio  u=3.93  s=0.60  cu=262.21  cs=27.41  scripts=764  tests=76593

    ../lib/Benchmark.t............FAILED 193

TSTENV = perlio u=3.66  s=0.50  cu=233.24  cs=24.79  scripts=764  tests=76593
All tests successful.
TSTENV = locale:nl_NL.utf8      u=3.90  s=0.54  cu=256.36  cs=26.99  scripts=763  tests=7658

    ../lib/Benchmark.t............FAILED 193

Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc' -DDEBUGGING
------------------------------------------------------------------------------
TSTENV = stdio  u=3.98  s=0.60  cu=276.95  cs=27.43  scripts=764  tests=76593

    ../lib/Benchmark.t............FAILED 193

TSTENV = perlio u=3.66  s=0.57  cu=262.38  cs=25.93  scripts=764  tests=76593
All tests successful.
TSTENV = locale:nl_NL.utf8      u=4.15  s=0.62  cu=269.53  cs=27.02  scripts=763  tests=7658
7

    ../lib/Benchmark.t............FAILED 193

Finished smoking $patch
Stopped smoke at @{ [$timer += 100] }
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my $cfgarg = "-Dcc='ccache gcc'";
    {   local $" = "', '";
        my @bldenv = sort keys %{ $reporter->{_rpt}{$cfgarg}{N} };
        is_deeply( \@bldenv, [qw( locale:nl_NL.utf8 perlio stdio )],
                   "Buildenvironments '@bldenv'" );
    }

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, 'F',
        "'$cfgarg' (stdio) reports failure" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{stdio}, 'F',
        "'$cfgarg -DDEBUGGING' (stdio) reports failure" );

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, 'O',
        "'$cfgarg' (perlio) reports OK" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{perlio}, 'O',
        "'$cfgarg -DDEBUGGING' (perlio) reports OK" );

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{'locale:nl_NL.utf8'}, 'F',
        "'$cfgarg' (utf8) reports failure" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{'locale:nl_NL.utf8'}, 'F',
        "'$cfgarg -DDEBUGGING' (utf8) reports Failure" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc='ccache gcc'
----------- ---------------------------------------------------------
F O F F O F 
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    if ( $showcfg ) {
         like $reporter->report, "/Build configurations:\n$bcfg=/", 
              "has the configurations";
    } else {
         unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
                "hasn't the configurations";
    }

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}

for my $p (@patchlevels) {
    create_config_sh( $config_sh, version => '5.9.0' );
    my $reporter = Test::Smoke::Reporter->new(
        ddir    => $findbin,
        v       => $verbose, 
        outfile => '',
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Smoking patch $patch
Stopped smoke at 1073290464
Started smoke at 1073290464

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio  u=0.05  s=0  cu=0.26  cs=0  scripts=4  tests=107
All tests successful.
PERLIO = perlio u=0.03  s=0.01  cu=0.24  cs=0.04  scripts=4  tests=107
All tests successful.
Stopped smoke at 1073290465
Started smoke at 1073290465

Configuration: -Dusedevel -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio  u=0.04  s=0.01  cu=0.26  cs=0.02  scripts=3  tests=106

    ../t/smoke/die.t........................FAILED ??
    ../t/smoke/many.t.......................FAILED 2-6 8-12 14-18 20-24 26-30 32
                                         36 38-42 44-48 50-54 56-60 62
                                         66 68-72 74-78 80-84 86-90 92
                                         96 98-100

PERLIO = perlio u=0.05  s=0.01  cu=0.25  cs=0.02  scripts=3  tests=106

    ../t/smoke/die.t........................FAILED ??
    ../t/smoke/many.t.......................FAILED 2-6 8-12 14-18 20-24 26-30 32
                                         36 38-42 44-48 50-54 56-60 62
                                         66 68-72 74-78 80-84 86-90 92
                                         96 98-100

Stopped smoke at 1073290467
Finished smoking $patch
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my $cfgarg = "";
    {   local $" = "', '";
        my @bldenv = sort keys %{ $reporter->{_rpt}{$cfgarg}{summary}{N} };
        is_deeply( \@bldenv, [qw( perlio stdio )],
                   "Buildenvironments '@bldenv'" );
        @bldenv = sort @{ $reporter->{_tstenv} };
        is_deeply( \@bldenv, [qw( perlio stdio )],
                   "Buildenvironments '@bldenv'" );
    }

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, 'O',
        "'$cfgarg' (stdio) reports OK" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{stdio}, 'F',
        "'$cfgarg -DDEBUGGING' (stdio) reports failure" );

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, 'O',
        "'$cfgarg' (perlio) reports OK" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{D}{perlio}, 'F',
        "'$cfgarg -DDEBUGGING' (perlio) reports Failure" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) none
----------- ---------------------------------------------------------
O O F F     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    like $reporter->report, qq@/^
         Failures: \\s+ \\(common-args\\) \\s+ none \\n
         \\[stdio\\/perlio\\] \\s* -DDEBUGGING
    /xm@, "Failures:";
}

unlink $config_sh;

for my $p (@patchlevels) {
    # This test is just to test 'PASS' (and not PASS-so-far)
    #    create_config_sh( $config_sh, version => '5.00504' );
    my $reporter = Test::Smoke::Reporter->new( 
        ddir    => $findbin,
        v       => $verbose, 
        outfile => '',
        is56x   => 1,
    );
    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");

    isa_ok $reporter, 'Test::Smoke::Reporter';
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1073864611
Smoking patch $patch
Stopped smoke at 1073864615
Started smoke at 1073864615

Configuration: -Dusedevel -Dcc='ccache egcc' -Uuseperlio
------------------------------------------------------------------------------

Compiler info: ccache egcc version 3.2
TSTENV = stdio  u=8.42  s=2.10  cu=476.05  cs=61.49  scripts=776  tests=78557
All tests successful.
Stopped smoke at 1073866466
Started smoke at 1073866466

Configuration: -Dusedevel -Dcc='ccache egcc' -Uuseperlio -DDEBUGGING
------------------------------------------------------------------------------

Compiler info: ccache egcc version 3.2
TSTENV = stdio  u=9.84  s=2.03  cu=523.95  cs=61.85  scripts=776  tests=78557
All tests successful.
Finished smoking $patch
Stopped smoke at 1073869001
EORESULTS

    chomp( my $summary = $reporter->summary );
    is $summary, 'PASS', $summary;
    is $reporter->ccinfo, "ccache egcc version 3.2", "ccinfo()";
    like $reporter->report, "/^Summary: PASS\n/m", "Summary from report";

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc='ccache egcc'
----------- ---------------------------------------------------------
O O         -Uuseperlio
__EOM__

}

for my $p (@patchlevels) {
    # Test a bug reported by Merijn
    # the c's were reported for locale: only

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    my $ddir = catfile( $findbin, 'ftppub' );
    make_test_file($patch, $ddir, "bugtst01.out", "bugtst01.tmp");

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => $ddir,
        is56x      => 0,
        defaultenv => 0,
        locale     => 'EN_US.UTF-8',
        outfile    => 'bugtst01.tmp',
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=gcc
=

-Duselongdouble
-Duse564bitint
__EOCFG__
    ), "new()" );
    isa_ok $reporter, 'Test::Smoke::Reporter';
    is $reporter->ccinfo, "? unknown cc version ", "ccinfo(bugstst01)";

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    ok( (defined $reporter->{_rpt}{running}),
        "Smoke still running" );
    isnt( $reporter->{_rpt}{finished}, "Finished",
        "Smoke not finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    my $r = is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=gcc
----------- ---------------------------------------------------------
F F F F F F 
c - - c - - -Duselongdouble
F F F - - - -Duse64bitint
__EOM__

    $r or diag $reporter->smoke_matrix, $reporter->bldenv_legend;

    if ( $showcfg ) {
         like $reporter->report, "/Build configurations:\n$bcfg=/", 
              "has the configurations";
    } else {
         unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
                "hasn't the configurations";
    }

    unlink catfile( $ddir, "bugtst01.tmp" ) or die "Failed to unlink temp file: $!";
}

for my $p (@patchlevels) {
    # report from cygwin

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    my $ddir = catfile( $findbin, 'ftppub' );
    make_test_file($patch, $ddir, "bugtst02.out", "bugtst02.tmp");

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => $ddir,
        is56x      => 0,
        defaultenv => 0,
        outfile    => 'bugtst02.tmp',
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),

-Duseithreads
=

-Duse64bitint
__EOCFG__
    ), "new reporter for bugtst02.out" );
    isa_ok $reporter, 'Test::Smoke::Reporter';
    is $reporter->ccinfo, "gcc version 3.3.1 (cygming special)", 
       "ccinfo(bugstst02)";

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    my $r = is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix 2";
$p->[2]  Configuration (common) none
----------- ---------------------------------------------------------
F F M -     
F F M -     -Duse64bitint
F F M -     -Duseithreads
F F M -     -Duseithreads -Duse64bitint
__EOM__

    $r or diag $reporter->smoke_matrix, $reporter->bldenv_legend;

    if ( $showcfg ) {
         like $reporter->report, "/Build configurations:\n$bcfg=/", 
              "has the configurations";
    } else {
         unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
                "hasn't the configurations";
    }

    unlink catfile( $ddir, "bugtst02.tmp" ) or die "Failed to unlink temp file: $!";
}

for my $p (@patchlevels) {
    # report from Win32

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    my $ddir = catfile( $findbin, 'ftppub' );
    make_test_file($patch, $ddir, "bugtst03.out", "bugtst03.tmp");

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => catdir( $findbin, 'ftppub' ),
        is56x      => 0,
        defaultenv => 1,
        is_win32   => 1,
        outfile    => 'bugtst03.tmp',
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<'__EOCFG__' ),
-DINST_TOP=$(INST_DRV)\Smoke\doesntexist
=

-Duseithreads
=

-Duselargefiles
=

-Dusemymalloc
=

-Accflags='-DPERL_COPY_ON_WRITE'
=

-DDEBUGGING
__EOCFG__
    ), "new reporter for bugtst03.out" );
    isa_ok $reporter, 'Test::Smoke::Reporter';
    is $reporter->ccinfo, "cl version 12.00.8804",
       "ccinfo(bugstst03)";

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    my $r = is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix 3";
$p->[2]  Configuration (common) -DINST_TOP=\$(INST_DRV)\\Smoke\\doesntexist
----------- ---------------------------------------------------------
O O         
F F         -Accflags='-DPERL_COPY_ON_WRITE'
O O         -Dusemymalloc
F F         -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
O O         -Duselargefiles
F F         -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
O O         -Duselargefiles -Dusemymalloc
F F         -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
X O         -Duseithreads
F F         -Duseithreads -Accflags='-DPERL_COPY_ON_WRITE'
O O         -Duseithreads -Dusemymalloc
F F         -Duseithreads -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
X O         -Duseithreads -Duselargefiles
F F         -Duseithreads -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
X O         -Duseithreads -Duselargefiles -Dusemymalloc
F F         -Duseithreads -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
__EOM__

    $r or diag $reporter->smoke_matrix, $reporter->bldenv_legend;

    if ( $showcfg ) {
         like $reporter->report, "/Build configurations:\n$bcfg=/", 
              "has the configurations";
    } else {
         unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
                "hasn't the configurations";
    }
    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures(bugtst03)";
[default] -Accflags='-DPERL_COPY_ON_WRITE'
[default] -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
[default] -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
[default] -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 10 12 14 16-18
    op/magic.t..............................FAILED 37-53
    op/tie.t................................FAILED 22

[default] -DDEBUGGING -Accflags='-DPERL_COPY_ON_WRITE'
[default] -DDEBUGGING -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 9-20
    op/magic.t..............................FAILED 37-53
    op/tie.t................................FAILED 22

[default] -DDEBUGGING -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
[default] -DDEBUGGING -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 9-20
    ../lib/DBM_Filter/t/utf8.t..............FAILED 13 19
    op/magic.t..............................FAILED 37-53
    op/tie.t................................FAILED 22

[default] -Duseithreads
Inconsistent test results (between TEST and harness):
    ../ext/threads/t/thread.t...............FAILED test 25

[default] -Duseithreads -Accflags='-DPERL_COPY_ON_WRITE'
[default] -Duseithreads -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 18-20

[default] -DDEBUGGING -Duseithreads -Accflags='-DPERL_COPY_ON_WRITE'
[default] -DDEBUGGING -Duseithreads -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
[default] -DDEBUGGING -Duseithreads -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
[default] -DDEBUGGING -Duseithreads -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 9-20

[default] -Duseithreads -Duselargefiles
[default] -Duseithreads -Duselargefiles -Dusemymalloc
Inconsistent test results (between TEST and harness):
    ../ext/threads/t/problems.t.............dubious

[default] -Duseithreads -Duselargefiles -Accflags='-DPERL_COPY_ON_WRITE'
[default] -Duseithreads -Duselargefiles -Dusemymalloc -Accflags='-DPERL_COPY_ON_WRITE'
    ../ext/Cwd/t/cwd.t......................FAILED 18-20
Inconsistent test results (between TEST and harness):
    ../ext/threads/shared/t/sv_simple.t.....dubious
__EOFAIL__

    unlink catfile( $ddir, "bugtst03.tmp" ) or die "Failed to unlink temp file: $!";
}

for my $p (@patchlevels) {
    # Failed tests (bad plan) + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
../t/op/test1.t.............................................PASSED
    2
../t/op/test1.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.
../t/op/test2.t.............................................PASSED
    2
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.

TSTENV = perlio 
../t/op/test1.t.............................................PASSED
    2
../t/op/test1.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.
../t/op/test2.t.............................................PASSED
    2
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
../t/op/test1.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 5 tests but ran 2.
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports pass" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "O",
        "'$cfgarg' reports pass" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
O O - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'PASS', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    ok (! @f_lines, "No failures");

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed tests + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
../t/op/test1.t.............................................FAILED
    1
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
../t/op/test1.t.............................................FAILED
    1
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
../t/op/test1.t.............................................FAILED
    1
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.37  s=0.00  cu=3.34  cs=0.10  scripts=5  tests=13349

    ../t/op/test1.t.............................................FAILED
        1
    ../t/op/test1.t.............................................PASSED
        2

TSTENV = perlio u=0.15  s=0.02  cu=3.02  cs=0.11  scripts=5  tests=13349

    ../t/op/test1.t.............................................FAILED
        1
    ../t/op/test1.t.............................................PASSED
        2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
    ../t/op/test1.t.............................................FAILED
        1
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
    ../t/op/test1.t.............................................PASSED
        2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Inconsistent result + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.32  s=0.02  cu=3.32  cs=0.14  scripts=5  tests=13349

    ../t/op/test1.t.............................................PASSED
        2
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1

TSTENV = perlio u=0.10  s=0.00  cu=2.99  cs=0.12  scripts=5  tests=13349

    ../t/op/test1.t.............................................PASSED
        2
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "X",
        "'$cfgarg' reports inconsistent" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "X",
        "'$cfgarg' reports inconsistent" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
X X - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(X)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
    ../t/op/test1.t.............................................PASSED
        2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Inconsistent result + Failed test + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.26  s=0.00  cu=3.32  cs=0.12  scripts=5  tests=13349

    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................FAILED
        1
    ../t/op/test2.t.............................................PASSED
        2
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1

TSTENV = perlio u=0.09  s=0.00  cu=3.01  cs=0.12  scripts=5  tests=13349

    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................FAILED
        1
    ../t/op/test2.t.............................................PASSED
        2
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
    ../t/op/test2.t.............................................FAILED
        1
Inconsistent test results (between TEST and harness):
    ../t/op/test1.t.........................FAILED at test 1
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................PASSED
        2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed test + Bad Plan + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
../t/op/test1.t.............................................FAILED
    1
../t/op/test1.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test2.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 70 tests but ran 64.
../t/op/test3.t.............................................FAILED
    1-2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test4.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
../t/op/test4.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test5.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
../t/op/test5.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test5.t.............................................FAILED
    Bad plan.  You planned 75 tests but ran 64.

TSTENV = perlio 
../t/op/test1.t.............................................FAILED
    1
../t/op/test1.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test2.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 70 tests but ran 64.
../t/op/test3.t.............................................FAILED
    1-2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test4.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
../t/op/test4.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test5.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
../t/op/test5.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test5.t.............................................FAILED
    Bad plan.  You planned 75 tests but ran 64.

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );



    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
../t/op/test1.t.............................................FAILED
    1
../t/op/test2.t.............................................FAILED
    Bad plan.  You planned 70 tests but ran 64.
../t/op/test3.t.............................................FAILED
    1-2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test4.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
../t/op/test5.t.............................................FAILED
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
    25, 27, 29, 31, 33, 35, 37, 39, 41, 43
    45, 47, 49, 51, 53, 55, 57, 59, 61, 63
    Bad plan.  You planned 75 tests but ran 64.
__EOFAIL__

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
../t/op/test1.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test2.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test4.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
../t/op/test5.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    24, 26, 28, 30, 32, 34, 36, 38, 40, 42
    44, 46, 48, 50, 52, 54, 56, 58, 60, 62
    64
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Passed TODO test (different configuration)
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc -Duseithreads
------------------------------------------------------------------------------
TSTENV = stdio  
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports pass" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "O",
        "'$cfgarg' reports pass" );
    my $cfgarg2 = "-Dcc=/opt/perl/ccache/gcc -Duseithreads";
    is( $reporter->{_rpt}{$cfgarg2}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports pass" );
    is( $reporter->{_rpt}{$cfgarg2}{summary}{N}{perlio}, "O",
        "'$cfgarg' reports pass" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );
    use Data::Dumper;


    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
O O - -     
O O - -     -Duseithreads
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'PASS', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    ok (! @f_lines, "No failures");

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
[stdio/perlio] -Duseithreads
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}

for my $p (@patchlevels) {
    # Passed TODO test (different configuration)
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
All tests successful.
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2


Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc -Duseithreads
------------------------------------------------------------------------------
TSTENV = stdio  
All tests successful.
../t/op/test1.t.............................................PASSED
    3
../t/op/test2.t.............................................PASSED
    2

TSTENV = perlio 
All tests successful.
../t/op/test1.t.............................................PASSED
    4
../t/op/test2.t.............................................PASSED
    2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports pass" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "O",
        "'$cfgarg' reports pass" );
    my $cfgarg2 = "-Dcc=/opt/perl/ccache/gcc -Duseithreads";
    is( $reporter->{_rpt}{$cfgarg2}{summary}{N}{stdio}, "O",
        "'$cfgarg' reports pass" );
    is( $reporter->{_rpt}{$cfgarg2}{summary}{N}{perlio}, "O",
        "'$cfgarg' reports pass" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );
    use Data::Dumper;


    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
O O - -     
O O - -     -Duseithreads
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'PASS', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    ok (! @f_lines, "No failures");

    my @t_lines = split /\n/, $reporter->todo_passed;
    is_deeply \@t_lines, [split /\n/, <<'__EOTODO__'], "Passed Todo tests";
[stdio/perlio] 
../t/op/test1.t.............................................PASSED
    2
../t/op/test2.t.............................................PASSED
    2

[stdio] -Duseithreads
../t/op/test1.t.............................................PASSED
    3
../t/op/test2.t.............................................PASSED
    2

[perlio] -Duseithreads
../t/op/test1.t.............................................PASSED
    4
../t/op/test2.t.............................................PASSED
    2
__EOTODO__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.37  s=0.00  cu=3.34  cs=0.10  scripts=5  tests=13349

    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
 
TSTENV = perlio u=0.15  s=0.02  cu=3.02  cs=0.11  scripts=5  tests=13349

    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
__EOFAIL__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.37  s=0.00  cu=3.34  cs=0.10  scripts=5  tests=13349

    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
    ../t/porting/diag.t.........................................FAILED
        No plan found in TAP output
 
TSTENV = perlio u=0.15  s=0.02  cu=3.02  cs=0.11  scripts=5  tests=13349

    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
    ../t/porting/diag.t.........................................FAILED
        No plan found in TAP output

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
        No plan found in TAP output
__EOFAIL__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}


for my $p (@patchlevels) {
    # Failed + Passed TODO test
    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose, 
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1258883807
Smoking patch $patch

Stopped smoke at 1258883808
Started smoke at 1258883808

Configuration: -Dusedevel -Dcc=/opt/perl/ccache/gcc
------------------------------------------------------------------------------
TSTENV = stdio  u=0.37  s=0.00  cu=3.34  cs=0.10  scripts=5  tests=13349

    ../t/porting/diag.t.........................................??????
 
TSTENV = perlio u=0.15  s=0.02  cu=3.02  cs=0.11  scripts=5  tests=13349

    ../t/porting/diag.t.........................................??????

Finished smoking $patch
Stopped smoke at 1258883821
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0], 
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    my $cfgarg = "-Dcc=/opt/perl/ccache/gcc";
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @r_lines = split /\n/, $reporter->smoke_matrix;
    is_deeply \@r_lines, [split /\n/, <<__EOM__], "Matrix";
$p->[2]  Configuration (common) -Dcc=/opt/perl/ccache/gcc
----------- ---------------------------------------------------------
F F - -     
__EOM__

    chomp( my $summary = $reporter->summary );
    is $summary, 'FAIL(F)', $summary;
    unlike $reporter->report, "/Build configurations:\n$bcfg=/", 
            "hasn't the configurations";


    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines, [split /\n/, <<'__EOFAIL__'], "Failures";
[stdio/perlio] 
    ../t/porting/diag.t.........................................??????
__EOFAIL__

#    diag Dumper $reporter->{_counters};
#    diag $reporter->report;
}

{ # Test the grepccmsg() feature
    my $testdir = catdir $findbin, 'perl-current';
    mkpath $testdir;
    copy( catfile( $findbin, 'gccmsg.out'), catfile( $testdir, 'mktest.out' ) );

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => $testdir,
        is56x      => 0,
        defaultenv => 0,
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<'__EOCFG__' )), "init for grepccmsg() ");
==
-Duseithreads
==
__EOCFG__

    my @ccmsg = split /\n/, <<'EOCCMSG';
Compiler messages(gcc):
regcomp.c: In function `S_make_trie':
regcomp.c:905: warning: `scan' might be used uninitialized in this function
regcomp.c: In function `S_study_chunk':
regcomp.c:1618: warning: comparison is always false due to limited range of data type
pp_sys.c:311: warning: `S_emulate_eaccess' defined but not used
byterun.c: In function `byterun':
byterun.c:906: warning: comparison is always false due to limited range of data type
DProf.xs:140: warning: =unused= attribute ignored
re_comp.c: In function `S_study_chunk':
re_comp.c:1618: warning: comparison is always false due to limited range of data type
EOCCMSG
    s/=unused=/\x{2018}unused\x{2019}/ for @ccmsg;

    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";

    # `stupid emacs
    ok my $ccmsg = $reporter->ccmessages, "Got compiler messages";
    for my $line ( @ccmsg ) {
        like $ccmsg, "/\Q$line\E/ms", "$line";
    }
    rmtree $testdir, $verbose;
}

{ # Test the registered_patches() feature
    my $testdir = catdir $findbin, 'perl-current';
    mkpath $testdir;
    copy( catfile( $findbin, 'gccmsg.out'), catfile( $testdir, 'mktest.out' ) );
    my $plhsrc = catdir( $findbin, qw( ftppub perl-current ) );
    copy( catfile( $plhsrc, 'patchlevel.h' ),
          catfile( $testdir, 'patchlevel.h' ) );
    require Test::Smoke::Util;
    Test::Smoke::Util::set_local_patch( $testdir, "[PATCH] Just testing" );

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => $testdir,
        is56x      => 0,
        defaultenv => 0,
        lfile      => catfile( $findbin, 'gccmsg.log' ),
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<'__EOCFG__' )), "init for get_local_patches() ");
==
-Duseithreads
==
__EOCFG__

    my $lp_list = $reporter->registered_patches;
    like $lp_list, "/\Q[PATCH] Just testing\E/", "Found the patch";

    my $rpt = $reporter->report;
    like $rpt, "/\\nLocally\\ applied\\ patches:\\n
                 \\ \\ \\ \\ DEVEL19999\\n
                 \\ \\ \\ \\ \\[PATCH\\]\\ Just\\ testing/x",
         "Found patches section";

    unlike $rpt, "/^Tests skipped on user request:\n/m",
         "Report does not contain user_skipped_tests()";

    rmtree $testdir, $verbose;
}

{ # Test the user_skipped_tests() feature
    my $testdir = catdir $findbin, 'perl-current';
    mkpath $testdir;
    copy( catfile( $findbin, 'gccmsg.out'), catfile( $testdir, 'mktest.out' ) );
    my $plhsrc = catdir( $findbin, qw( ftppub perl-current ) );
    copy( catfile( $plhsrc, 'patchlevel.h' ),
          catfile( $testdir, 'patchlevel.h' ) );

    my $skip_tests = catfile $findbin, 'tests.skip';
    put_file( (my $no_tests = <<__EOSKIP__), $skip_tests );
lib/Benchmark.t 
__EOSKIP__

    ok( my $reporter = Test::Smoke::Reporter->new(
        ddir       => $testdir,
        is56x      => 0,
        defaultenv => 0,
        lfile      => catfile( $findbin, 'gccmsg.log' ),
        skip_tests => $skip_tests,
        v          => $verbose,
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<'__EOCFG__' )), "init for get_local_patches() ");
==
-Duseithreads
==
__EOCFG__

    $no_tests = join "\n", map "    $_" => split /\n/, $no_tests;
    my $st_list = $reporter->user_skipped_tests;
    is $st_list, "\nTests skipped on user request:\n$no_tests",
       "user_skipped_tests()";

    my $rpt = $reporter->report;
    like $rpt, "/^Tests skipped on user request:\n$no_tests/m",
         "Report contains user_skipped_tests()";

    rmtree $testdir, $verbose;
    1 while unlink $skip_tests;
}

{
    my $bcfg = "";
    my $plhsrc = catdir( $findbin, qw( ftppub perl-current ) );
    copy( catfile( $plhsrc, 'patchlevel.h' ),
          catfile( $findbin, 'patchlevel.h' ) );
    my $report = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        outfile    => 'multilocale.out',
        verbose    => $verbose,
        defaultenv => 0,
        cfg        => \$bcfg,
    );
    isa_ok $report, 'Test::Smoke::Reporter';

    is $report->bldenv_legend, <<__EOL__, "legend ok";
| | | | | | | +- LC_ALL = nl_NL.UTF-8 -DDEBUGGING
| | | | | | +--- LC_ALL = be_BY.UTF-8 -DDEBUGGING
| | | | | +----- PERLIO = perlio -DDEBUGGING
| | | | +------- PERLIO = stdio  -DDEBUGGING
| | | +--------- LC_ALL = nl_NL.UTF-8
| | +----------- LC_ALL = be_BY.UTF-8
| +------------- PERLIO = perlio
+--------------- PERLIO = stdio 
__EOL__

    1 while unlink catfile( $findbin, 'patchlevel.h' );
}

{
    my $bcfg = <<__EOC__;

-Duse64bit
-Duselongdouble
-Dusemorebits
=

-Duseithreads
=
/-DDEBUGGING/

-DDEBUGGING
__EOC__
    my $plhsrc = catdir($findbin, qw( ftppub perl-current ));
    copy(catfile($plhsrc, 'patchlevel.h'), catfile($findbin, 'patchlevel.h'));
    my $report = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        outfile    => 'pc09.out',
        verbose    => $verbose,
        defaultenv => 0,
        cfg        => \$bcfg,
    );
    isa_ok $report, 'Test::Smoke::Reporter';

    is $report->bldenv_legend, <<__EOL__, "legend ok";
| | | | | +- LC_ALL = en_US.utf8 -DDEBUGGING
| | | | +--- PERLIO = perlio -DDEBUGGING
| | | +----- PERLIO = stdio  -DDEBUGGING
| | +------- LC_ALL = en_US.utf8
| +--------- PERLIO = perlio
+----------- PERLIO = stdio 
__EOL__

    1 while unlink catfile($findbin, 'patchlevel.h');
}

{    # Test write to file
    create_config_sh($config_sh, version => '5.6.1');

    my $reporter = Test::Smoke::Reporter->new(
        ddir      => $findbin,
        v         => $verbose,
        outfile   => '',
        showcfg   => $showcfg,
        user_note => 'This is user info',
        cfg       => \(my $bcfg = <<__EOCFG__ ),
-Dcc='ccache gcc'
=
-Uuseperlio
__EOCFG__
    );
    isa_ok($reporter, 'Test::Smoke::Reporter');

    my $timer = time - 300;
    $reporter->read_parse(\(my $result = <<EORESULTS));
Started smoke at @{ [$timer] }
Smoking patch 22000


Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc' -Uuseperlio
------------------------------------------------------------------------------
PERLIO = stdio  u=3.96  s=0.66  cu=298.11  cs=21.18  scripts=731  tests=75945
All tests successful.
Stopped smoke at @{ [$timer += 100] }
Started smoke at @{ [$timer] }

Configuration: -Dusedevel -Dcc='ccache gcc' -Uuseperlio -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio  u=4.43  s=0.76  cu=324.65  cs=21.58  scripts=731  tests=75945
All tests successful.
Finished smoking 22000
Stopped smoke at @{ [$timer += 100] }
EORESULTS

    my $report_string = $reporter->report;

    like($report_string, qr{\nThis is user info\n}, 'Has user info');
    my $file = catfile($findbin, "report.tmp");
    if (-e $file) {
        die "$file already exists?";
    }
    $reporter->write_to_file($file);

    if (-e $file) {
        ok(1, "file exists");

        open my $in, "<", $file or die "Can't read file: $!";
        my $in_string = "";
        while (<$in>) {
            $in_string .= $_;
        }
        # Prevent false negatives:
        # < tux: Intel(R) Xeon(R) CPU E3-1245 V2 @ 3.40GHz (GenuineIntel 3740MHz) (x86_64/8 cpu[32 cores])
        # > tux: Intel(R) Xeon(R) CPU E3-1245 V2 @ 3.40GHz (GenuineIntel 3774MHz) (x86_64/8 cpu[32 cores])
        unless ($in_string eq $report_string) {
            s{GenuineIntel [0-9]+[MG]Hz}{GenuineIntel 9999MHz} for $in_string, $report_string;
        }
        is($in_string, $report_string, "file is the same as the report");
        close $in;
        unlink $file or die "Can't unlink file: $!";
    }
    else {
        ok(0, "file exists");
        ok(0, "file is the same as the report");
    }
    unlink $config_sh;
}

{
    note("rt.cpan.org 125932");

    create_config_sh( $config_sh, version => '5.11.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
        showcfg    => $showcfg,
        cfg        => \( my $bcfg = <<__EOCFG__ ),
-Dcc=/opt/perl/ccache/gcc
__EOCFG__
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    my $p = [
        'd3bb03e0842cd3214922ab134a48314ee3fe2077',
        'v5.29.1-31-gd3bb03e084',
        '',
    ];
    my $patch = $p->[0] . ($p->[1] ? " $p->[1]" : "");
    my $cfgarg = q|-Duseithreads -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing" -Dcc="clang -Qunused-arguments" -Duse64bitint|;
    $reporter->read_parse( \(my $result = <<EORESULTS) );
Started smoke at 1532483322
Smoking patch $p->[0] $p->[1]
Smoking branch smoke-me/khw-sisyphus
Stopped smoke at 1532483323
Started smoke at 1532483323

Configuration: -Dusedevel $cfgarg
------------------------------------------------------------------------------

Compiler info: clang -Qunused-arguments version 4.2.1 Compatible FreeBSD Clang 6.0.0 (tags/RELEASE_600/final 326565)
TSTENV = stdio	Files=2662, Tests=1183093, 280 wallclock secs (78.77 usr  9.51 sys + 597.30 cusr 55.12 csys = 740.70 CPU)

../lib/locale.t.............................................FAILED
    436-437, 441, 444, 458

TSTENV = perlio	Files=2662, Tests=1182934, 265 wallclock secs (81.45 usr 11.89 sys + 547.26 cusr 57.26 csys = 697.85 CPU)

../lib/locale.t.............................................FAILED
    436-437, 441, 444, 458

Stopped smoke at 1532484119
Finished smoking $p->[0] $p->[1] smoke-me/khw-sisyphus
EORESULTS

    is( $reporter->{_rpt}{patch}, $p->[0],
        "Changenumber $reporter->{_rpt}{patch}" );
    is( $reporter->{_rpt}{patchdescr}, $p->[1] || $p->[0],
        "Changedescr $reporter->{_rpt}{patchdescr}" );

    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{stdio}, "F",
        "'$cfgarg' reports fail" );
    is( $reporter->{_rpt}{$cfgarg}{summary}{N}{perlio}, "F",
        "'$cfgarg' reports fail" );
    ok( (not defined $reporter->{_rpt}{running}),
        "Smoke not running" );
    is( $reporter->{_rpt}{finished}, "Finished",
        "Smoke finished" );

    my @f_lines = split /\n/, $reporter->failures;
    is_deeply \@f_lines,
        [split /\n/, <<'__EOFAIL__'], "Multiple unit tests and sequences of unit tests identified as failures";
[stdio/perlio] -Duseithreads -Duse64bitint
../lib/locale.t.............................................FAILED
    436-437, 441, 444, 458
__EOFAIL__

    unlink $config_sh;
}

########## SUBROUTINES ##########

sub create_config_sh {
    my ($file, %cfg) = @_;

    my $cfg_sh = "# This is a testfile config.sh\n";
    $cfg_sh .= "# created by $0\n";

    $cfg_sh .= join "", map "$_='$cfg{$_}'\n" => keys %cfg;

    put_file($cfg_sh, $file);
}

sub make_test_file {
    my ($patch, $ddir, $in_file, $out_file) = @_;

    open my $in, "<", catfile($ddir, $in_file)
        or die "Failed to open input file: $!";
    open my $out, ">", catfile($ddir, $out_file)
        or die "Failed to create temp file: $!";
    while (<$in>) {
        s/__PATCHLEVEL__/$patch/g;
        print $out $_;
    }
    close $in;
    close $out;
}
