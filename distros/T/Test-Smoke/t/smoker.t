#! /usr/bin/perl -w
use strict;
use Data::Dumper;

# $Id$
use File::Spec::Functions qw( :DEFAULT devnull abs2rel rel2abs );
use Cwd;

use lib 't';
use TestLib;

use Test::More tests => 76;
use_ok( 'Test::Smoke::Smoker' );

my $debug   = exists $ENV{SMOKE_DEBUG} && $ENV{SMOKE_DEBUG};
my $verbose = exists $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;

local *LOG;
open LOG, "> " . devnull();

{
    my %config = (
        v => $verbose,
        ddir => 'perl-current',
        defaultenv => 1,
        testmake   => 'make',
    );

    my $smoker = Test::Smoke::Smoker->new( \*LOG, %config );
    isa_ok( $smoker, 'Test::Smoke::Smoker' );

    my $ref = mkargs( \%config, 
                      Test::Smoke::Smoker->config( 'all_defaults' ) );
    $ref->{logfh} = \*LOG;

    is_deeply( $smoker, $ref, "Check arguments" );   

    close LOG;
}

{
    my @nok = (
        '../ext/Cwd/t/Cwd.....................FAILED at test 10',
        'op/magic.............................FAILED at test 37',
        '../t/op/die..........................FAILED at test 22',
        'ext/IPC/SysV/t/ipcsysv...............FAILED at test 1',

    );

    my $smoker = Test::Smoke::Smoker->new( \*LOG,
        v => 0,
        ddir => cwd(),
    );

    my %tests = $smoker->_transform_testnames( @nok );
    my %raw = (
        'ext/Cwd/t/Cwd.t'          => 'FAILED at test 10',
        't/op/magic.t'             => 'FAILED at test 37',
        't/op/die.t'               => 'FAILED at test 22',
        'ext/IPC/SysV/t/ipcsysv.t' => 'FAILED at test 1',
    );
    my %expect;
    my $test_base = catdir( cwd, 't' );
    foreach my $test ( keys %raw ) {
        my $test_path = $smoker->_normalize_testname( $test );

        $expect{ $test_path } = $raw{ $test };
    }
    is_deeply \%tests, \%expect, "transform testnames" or diag Dumper \%tests;

    $debug and diag Dumper { tests => \%tests, expect => \%expect };
    close LOG;
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness_test = split /\n/, <<'EOHO';
Failed Test          Stat Wstat Total Fail  Failed  List of Failed
-------------------------------------------------------------------------------
../lib/Math/Trig.t    255 65280    29   12  41.38%  24-29
../lib/Net/hostent.t    6  1536     7   11 157.14%  2-7
../lib/Time/Local.t               135    1   0.74%  133
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? $1 : ''
    } @harness_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness pre 2.60 output";
    ../lib/Math/Trig.t......................FAILED 24-29
    ../lib/Net/hostent.t....................FAILED 2-7
    ../lib/Time/Local.t.....................FAILED 133
EOOUT
    is keys %inconsistent, 0, "No inconsistent test results"
        or diag Dumper \%inconsistent;
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness_test = split /\n/, <<'EOHO';
Failed Test  Stat Wstat Total Fail  Failed  List of Failed
-------------------------------------------------------------------------------
smoke/die.t   255 65280    ??   ??       %  ??
smoke/many.t   83 21248   100   83  83.00%  2-6 8-12 14-18 20-24 26-30 32-36
                                            38-42 44-48 50-54 56-60 62-66 68-72
                                            74-78 80-84 86-90 92-96 98-100
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? $1 : ''
    } @harness_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness pre 2.60 output";
    smoke/die.t.............................FAILED ??
    smoke/many.t............................FAILED 2-6 8-12 14-18 20-24 26-30 32-36
                                                   38-42 44-48 50-54 56-60 62-66 68-72
                                                   74-78 80-84 86-90 92-96 98-100
EOOUT
    is keys %inconsistent, 0, "No inconsistent test results";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness_test = split /\n/, <<'EOHO';
Failed Test        Stat Wstat Total Fail  List of Failed
-------------------------------------------------------------------------------
../t/op/utftaint.t    2   512    88    4  87-88
Failed 1/1 test scripts. 2/88 subtests failed.
Files=1, Tests=88,  1 wallclock secs ( 0.10 cusr +  0.02 csys =  0.12 CPU)
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? $1 : ''
    } @harness_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness_test );

    is $harness_out,
       "    ../t/op/utftaint.t......................FAILED 87-88\n",
       "Catch Test::Harness 2.60 output";
    is keys %inconsistent, 0, "No inconsistent test results";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness_test = split /\n/, <<'EOHO';
Failed Test  Stat Wstat Total Fail  List of Failed
-------------------------------------------------------------------------------
smoke/die.t   255 65280    ??   ??  ??
smoke/many.t   83 21248   100   83  2-6 8-12 14-18 20-24 26-30 32-36 38-42 44-
                                    48 50-54 56-60 62-66 68-72 74-78 80-84 86-
                                    90 92-96 98-100
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? $1 : ''
    } @harness_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness 2.60 output";
    smoke/die.t.............................FAILED ??
    smoke/many.t............................FAILED 2-6 8-12 14-18 20-24 26-30 32-36 38-42 44-
                                                   48 50-54 56-60 62-66 68-72 74-78 80-84 86-
                                                   90 92-96 98-100
EOOUT

    is keys %inconsistent, 0, "No inconsistent test results";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness_test = split /\n/, <<'EOHO';
Failed Test  Stat Wstat Total Fail  List of Failed
-------------------------------------------------------------------------------
smoke/die.t   255 65280    ??   ??  ??
smoke/many.t   83 21248   100   83  2-6 8-12 14-18 20-24 26-30 32-36 38-42 44-
                                    48 50-54 56-60 62-66 68-72 74-78 80-84 86-
                                    90 92-96 98-100
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? $1 : ''
    } @harness_test;
    $inconsistent{ '../t/op/utftaint.t' } = 1;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness 2.60 output";
    smoke/die.t.............................FAILED ??
    smoke/many.t............................FAILED 2-6 8-12 14-18 20-24 26-30 32-36 38-42 44-
                                                   48 50-54 56-60 62-66 68-72 74-78 80-84 86-
                                                   90 92-96 98-100
EOOUT

    is keys %inconsistent, 1, "One inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
Failed 2/2 test programs. 83/100 subtests failed.
../t/smoke/die....... Dubious, test returned 255 (wstat 65280, 0xff00)
 No subtests run 
../t/smoke/many...... Dubious, test returned 83 (wstat 21248, 0x5300)
 Failed 83/100 subtests 

Test Summary Report
-------------------
smoke/die.t (Wstat: 65280 Tests: 0 Failed: 0)
  Non-zero exit status: 255
  Parse errors: No plan found in TAP output
smoke/many.t (Wstat: 21248 Tests: 100 Failed: 83)
  Failed test number(s):  2-6, 8-12, 14-18, 20-24, 26-30, 32-36, 38-42
                44-48, 50-54, 56-60, 62-66, 68-72, 74-78
                80-84, 86-90, 92-96, 98-100
  Non-zero exit status: 83
Files=2, Tests=100,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.06 cusr  0.01 csys =  0.11 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;
    $inconsistent{ '../t/op/utftaint.t' } = 1;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness 3+ output";
    ../t/smoke/die.t............................................FAILED
        Non-zero exit status: 255
    ../t/smoke/die.t............................................FAILED
        No plan found in TAP output
    ../t/smoke/many.t...........................................FAILED
        2-6, 8-12, 14-18, 20-24, 26-30, 32-36, 38-42
        44-48, 50-54, 56-60, 62-66, 68-72, 74-78
        80-84, 86-90, 92-96, 98-100
    ../t/smoke/many.t...........................................FAILED
        Non-zero exit status: 83
EOOUT

    is keys %inconsistent, 1, "One inconsistent test result"
        or diag Dumper \%inconsistent;
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
Failed 2/2 test programs. 83/100 subtests failed.
../t/smoke/die....... Dubious, test returned 255 (wstat 65280, 0xff00)
 No subtests run 
../t/smoke/many...... Dubious, test returned 83 (wstat 21248, 0x5300)
 Failed 83/100 subtests 

Test Summary Report
-------------------
smoke/die (Wstat: 65280 Tests: 0 Failed: 0)
  Non-zero exit status: 255
  Parse errors: No plan found in TAP output
smoke/many (Wstat: 21248 Tests: 100 Failed: 83)
  Failed test number(s):  2-6, 8-12, 14-18, 20-24, 26-30, 32-36, 38-42
                44-48, 50-54, 56-60, 62-66, 68-72, 74-78
                80-84, 86-90, 92-96, 98-100
  Non-zero exit status: 83
Files=2, Tests=100,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.06 cusr  0.01 csys =  0.11 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;
    $inconsistent{ '../t/op/utftaint.t' } = 1;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $harness_out, <<EOOUT, "Catch Test::Harness 3.13 output";
    ../t/smoke/die.t............................................FAILED
        Non-zero exit status: 255
    ../t/smoke/die.t............................................FAILED
        No plan found in TAP output
    ../t/smoke/many.t...........................................FAILED
        2-6, 8-12, 14-18, 20-24, 26-30, 32-36, 38-42
        44-48, 50-54, 56-60, 62-66, 68-72, 74-78
        80-84, 86-90, 92-96, 98-100
    ../t/smoke/many.t...........................................FAILED
        Non-zero exit status: 83
EOOUT

    is keys %inconsistent, 1, "One inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
op/test1.t .. # Looks like you planned 5 tests but ran 2.
op/test1.t .. Failed 3/5 subtests
        (1 TODO test unexpectedly succeeded)
op/test2.t .. # Looks like you planned 5 tests but ran 2.
op/test2.t .. Failed 3/5 subtests
        (1 TODO test unexpectedly succeeded)

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
  Parse errors: Bad plan.  You planned 5 tests but ran 2.
op/test2.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
  Parse errors: Bad plan.  You planned 5 tests but ran 2.
Files=2, Tests=4,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test1.t.............................................FAILED
        Bad plan.  You planned 5 tests but ran 2.
    ../t/op/test2.t.............................................PASSED
        2
    ../t/op/test2.t.............................................FAILED
        Bad plan.  You planned 5 tests but ran 2.
EOOUT
    is keys %inconsistent, 0, "No inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
op/test1.t .. ok
op/test2.t .. ok
All tests successful.

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
op/test2.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
Files=2, Tests=4,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: PASS
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, 1, "Test detected as passed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................PASSED
        2
EOOUT
    # The inconsitent hash should not be updated: harness only detected passedd todo tests
    is keys %inconsistent, 2, "Two inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
op/test1.t .. # Failed at op/test1.t line 13
op/test1.t .. Failed 1/2 subtests
        (1 TODO test unexpectedly succeeded)
op/test2.t .. ok

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 1)
  Failed test:  1
  TODO passed:   2
op/test2.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
Files=2, Tests=4,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................FAILED
        1
    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................PASSED
        2
EOOUT
    # ../t/op/test2.t did not fail under harness; it should still be in the %inconsitent hash
    is keys %inconsistent, 1, "One inconsistent test result";
}


{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
Extending failures with harness:
        op/test1.t
op/test1.t .. ok
All tests successful.

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
Files=1, Tests=2,  0 wallclock secs ( 0.01 usr +  0.00 sys =  0.01 CPU)
Result: PASS
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;
    $inconsistent{'../t/op/test1.t'} = 1; # detected in make test as failed

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, 1, "Test detected as passed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................PASSED
        2
EOOUT
    # ../t/op/test1.t did not fail under harness; it should still be in the %inconsitent hash
    is keys %inconsistent, 1, "One inconsistent test result";
}


{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
Extending failures with harness:
        op/test1.t
op/test1.t .. # Failed at op/test1.t line 12
op/test1.t .. Failed 1/2 subtests
        (1 TODO test unexpectedly succeeded)

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 1)
  Failed test:  1
  TODO passed:   2
Files=1, Tests=2,  0 wallclock secs ( 0.01 usr +  0.00 sys =  0.01 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................FAILED
        1
    ../t/op/test1.t.............................................PASSED
        2
EOOUT
    is keys %inconsistent, 0, "No inconsistent test result";
}


{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
Extending failures with harness:
        op/test1.t
        op/test2.t
op/test1.t .. ok
op/test2.t .. # Failed at op/test2.t line 13
op/test2.t .. Failed 1/2 subtests
        (1 TODO test unexpectedly succeeded)

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 2 Failed: 0)
  TODO passed:   2
op/test2.t (Wstat: 0 Tests: 2 Failed: 1)
  Failed test:  1
  TODO passed:   2
Files=2, Tests=4,  0 wallclock secs ( 0.00 usr  0.01 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;
    $inconsistent{'../t/op/test1.t'} = 1; # detected in make test as failed

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
    ../t/op/test1.t.............................................PASSED
        2
    ../t/op/test2.t.............................................FAILED
        1
    ../t/op/test2.t.............................................PASSED
        2
EOOUT
    # ../t/op/test1.t did not fail under harness; it should still be in the %inconsitent hash
    is keys %inconsistent, 1, "One inconsistent test result";
}


{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
op/test1.t .. # Failed at op/test1.t line 12
op/test1.t .. Failed 1/64 subtests
        (32 TODO tests unexpectedly succeeded)
op/test2.t .. # Looks like you planned 70 tests but ran 64.
op/test2.t .. Failed 6/70 subtests
        (32 TODO tests unexpectedly succeeded)
op/test3.t .. # Failed at op/test3.t line 12
# Failed at op/test3.t line 17
# Failed at op/test3.t line 23
# Failed at op/test3.t line 29
# Failed at op/test3.t line 35
# Failed at op/test3.t line 41
# Failed at op/test3.t line 47
# Failed at op/test3.t line 53
# Failed at op/test3.t line 59
# Failed at op/test3.t line 65
# Failed at op/test3.t line 71
# Failed at op/test3.t line 77
# Failed at op/test3.t line 83
# Failed at op/test3.t line 89
# Failed at op/test3.t line 95
# Failed at op/test3.t line 101
# Failed at op/test3.t line 107
# Failed at op/test3.t line 113
# Failed at op/test3.t line 119
# Failed at op/test3.t line 125
# Failed at op/test3.t line 131
# Failed at op/test3.t line 137
# Failed at op/test3.t line 143
# Failed at op/test3.t line 149
# Failed at op/test3.t line 155
# Failed at op/test3.t line 161
# Failed at op/test3.t line 167
# Failed at op/test3.t line 173
# Failed at op/test3.t line 179
# Failed at op/test3.t line 185
# Failed at op/test3.t line 191
# Failed at op/test3.t line 197
# Failed at op/test3.t line 203
op/test3.t .. Failed 33/64 subtests
op/test4.t .. # Failed at op/test4.t line 12
# Failed at op/test4.t line 20
# Failed at op/test4.t line 26
# Failed at op/test4.t line 32
# Failed at op/test4.t line 38
# Failed at op/test4.t line 44
# Failed at op/test4.t line 50
# Failed at op/test4.t line 56
# Failed at op/test4.t line 62
# Failed at op/test4.t line 68
# Failed at op/test4.t line 74
# Failed at op/test4.t line 80
# Failed at op/test4.t line 86
# Failed at op/test4.t line 92
# Failed at op/test4.t line 98
# Failed at op/test4.t line 104
# Failed at op/test4.t line 110
# Failed at op/test4.t line 116
# Failed at op/test4.t line 122
# Failed at op/test4.t line 128
# Failed at op/test4.t line 134
# Failed at op/test4.t line 140
# Failed at op/test4.t line 146
# Failed at op/test4.t line 152
# Failed at op/test4.t line 158
# Failed at op/test4.t line 164
# Failed at op/test4.t line 170
# Failed at op/test4.t line 176
# Failed at op/test4.t line 182
# Failed at op/test4.t line 188
# Failed at op/test4.t line 194
# Failed at op/test4.t line 200
op/test4.t .. Failed 32/64 subtests
        (32 TODO tests unexpectedly succeeded)
op/test5.t .. # Failed at op/test5.t line 12
# Failed at op/test5.t line 20
# Failed at op/test5.t line 26
# Failed at op/test5.t line 32
# Failed at op/test5.t line 38
# Failed at op/test5.t line 44
# Failed at op/test5.t line 50
# Failed at op/test5.t line 56
# Failed at op/test5.t line 62
# Failed at op/test5.t line 68
# Failed at op/test5.t line 74
# Failed at op/test5.t line 80
# Failed at op/test5.t line 86
# Failed at op/test5.t line 92
# Failed at op/test5.t line 98
# Failed at op/test5.t line 104
# Failed at op/test5.t line 110
# Failed at op/test5.t line 116
# Failed at op/test5.t line 122
# Failed at op/test5.t line 128
# Failed at op/test5.t line 134
# Failed at op/test5.t line 140
# Failed at op/test5.t line 146
# Failed at op/test5.t line 152
# Failed at op/test5.t line 158
# Failed at op/test5.t line 164
# Failed at op/test5.t line 170
# Failed at op/test5.t line 176
# Failed at op/test5.t line 182
# Failed at op/test5.t line 188
# Failed at op/test5.t line 194
# Failed at op/test5.t line 200
# Looks like you planned 75 tests but ran 64.
op/test5.t .. Failed 43/75 subtests
        (32 TODO tests unexpectedly succeeded)

Test Summary Report
-------------------
op/test1.t (Wstat: 0 Tests: 64 Failed: 1)
  Failed test:  1
  TODO passed:   2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                24, 26, 28, 30, 32, 34, 36, 38, 40, 42
                44, 46, 48, 50, 52, 54, 56, 58, 60, 62
                64
op/test2.t (Wstat: 0 Tests: 64 Failed: 0)
  TODO passed:   2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                24, 26, 28, 30, 32, 34, 36, 38, 40, 42
                44, 46, 48, 50, 52, 54, 56, 58, 60, 62
                64
  Parse errors: Bad plan.  You planned 70 tests but ran 64.
op/test3.t (Wstat: 0 Tests: 64 Failed: 33)
  Failed tests:  1-2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                24, 26, 28, 30, 32, 34, 36, 38, 40, 42
                44, 46, 48, 50, 52, 54, 56, 58, 60, 62
                64
op/test4.t (Wstat: 0 Tests: 64 Failed: 32)
  Failed tests:  1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
                25, 27, 29, 31, 33, 35, 37, 39, 41, 43
                45, 47, 49, 51, 53, 55, 57, 59, 61, 63
  TODO passed:   2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                24, 26, 28, 30, 32, 34, 36, 38, 40, 42
                44, 46, 48, 50, 52, 54, 56, 58, 60, 62
                64
op/test5.t (Wstat: 0 Tests: 64 Failed: 32)
  Failed tests:  1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
                25, 27, 29, 31, 33, 35, 37, 39, 41, 43
                45, 47, 49, 51, 53, 55, 57, 59, 61, 63
  TODO passed:   2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
                24, 26, 28, 30, 32, 34, 36, 38, 40, 42
                44, 46, 48, 50, 52, 54, 56, 58, 60, 62
                64
  Parse errors: Bad plan.  You planned 75 tests but ran 64.
Files=5, Tests=320,  0 wallclock secs ( 0.05 usr  0.00 sys +  0.04 cusr  0.00 csys =  0.09 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (with TODO Passed)";
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
EOOUT
    is keys %inconsistent, 0, "No inconsistent test result";
}


{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
some_error at porting/diag.t line 11.
porting/diag.t .. skipped: (no reason given)

Test Summary Report
-------------------
porting/diag.t (Wstat: 512 Tests: 0 Failed: 0)
  Non-zero exit status: 2
Files=1, Tests=0,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (Non-zero exit status)";
    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
EOOUT
    is keys %inconsistent, 0, "No inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
some_error at porting/diag.t line 11.
porting/diag.t .. skipped: (no reason given)

Test Summary Report
-------------------
porting/diag.t (Wstat: 512 Tests: 0 Failed: 0)
  Non-zero exit status: 2
  Parse errors: No plan found in TAP output
Files=1, Tests=0,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (Non-zero exit status)";
    ../t/porting/diag.t.........................................FAILED
        Non-zero exit status: 2
    ../t/porting/diag.t.........................................FAILED
        No plan found in TAP output
EOOUT
    is keys %inconsistent, 0, "No inconsistent test result";
}

{
    my $smoker = Test::Smoke::Smoker->new( \*LOG, v => $verbose );
    isa_ok $smoker, 'Test::Smoke::Smoker';
    my @harness3_test = split m/\n/, <<'EOHO';
some_error at porting/diag.t line 11.
porting/diag.t .. skipped: (no reason given)

Test Summary Report
-------------------
porting/diag.t (Wstat: 512 Tests: 0 Failed: 0)
  unknown_harness_output_which_is_not_parseable
Files=1, Tests=0,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: FAIL
EOHO

    my %inconsistent = map +( $_ => 1 ) => grep length $_ => map {
        m/(\S+\.t)\s+/ ? "../t/$1" : ''
    } @harness3_test;

    my $all_ok;
    my $harness_out = $smoker->_parse_harness_output( \%inconsistent, $all_ok,
                                                      @harness3_test );

    is $all_ok, undef, "Test detected as failed";
    is $harness_out, <<EOOUT, "Catch Test::Harness 3 output (unknown output)";
    ../t/porting/diag.t.........................................??????
EOOUT
    is keys %inconsistent, 1, "One inconsistent test result";
}


{ # test the set_skip_tests(), unset_skip_tests()
    my $src = catdir qw/ t ftppub perl-current /;
    my $dst = catdir qw/ t perl-current /;
    require_ok "Test::Smoke::Syncer";
    my $syncer = Test::Smoke::Syncer->new( copy => {
        v    => $verbose,
        cdir => $src,
        ddir => $dst,
    } );
    isa_ok $syncer, 'Test::Smoke::Syncer::Copy';
    my $patch = $syncer->sync;
    is $patch, '37800ef622734ef3d18eddf53581505ff036f4b6', "Patchlevel: $patch";

    my $skip_tests = catfile 't', 'MANIFEST.NOTEST';
    my %config = (
        v          => $verbose,
        ddir       => $dst,
        defaultenv => 1,
        testmake   => 'make',
        skip_tests => $skip_tests,
    );

    my $smoker = Test::Smoke::Smoker->new( \*LOG, %config );
    isa_ok( $smoker, 'Test::Smoke::Smoker' );

SKIP: {
    local *NOTESTS;
    open NOTESTS, "> $skip_tests" or skip "Cannot create($skip_tests): $!", 7;
    my @notest = qw{ t/op/skip.t lib/t/skip.t ext/t/skip.t cpan/t/skip.t dist/t/skip.t};
    print NOTESTS "$_\n" for @notest;
    close NOTESTS;

    ok -f $skip_tests, "skip_tests file exists";

    my $skip_test = catfile( $dst, 't', 'op', 'skip.t' );
    $smoker->set_skip_tests;
    ok -f catfile( $dst, 'MANIFEST.ORG'), "MANIFEST was copied";

    my $skip = qq[print "1..0 # SKIP Disabled by Test::Smoke];
    ok get_file($skip_test) =~ /^\Q$skip\E/,
       "t/op/skip.t had skip code added";

    my @libext = grep m{^(?:lib|ext|cpan|dist)/} => @notest;
    my $manifest = catfile $dst, 'MANIFEST';
    my $manifiles = get_file( $manifest );

    my $ok = 1;
    $ok &&= ! grep $manifiles =~ /^\Q$_\E/m => @libext;
    ok $ok, "files removed from MANIFEST";

    $smoker->unset_skip_tests();

    ok ! -f catfile( $dst, 'MANIFEST.ORG'), "MANIFEST.ORG was removed";

    ok get_file($skip_test) !~ /^\Q$skip\E/,
       "t/op/skip.t had skip code removed again";

    my $files = get_file( $manifest );

    $ok = 1;
    $ok &&= grep $files =~ /^\Q$_\E/m => @libext;
    ok $ok, "files back in MANIFEST";

    1 while unlink $skip_tests;    
}
    rmtree $dst, $verbose;
}

sub mkargs {
    my( $set, $default ) = @_;

    my %mkargs = map {

        my $value = exists $set->{ $_ } 
            ? $set->{ $_ } : Test::Smoke::Smoker->config( $_ );
        ( $_ => $value )
    } keys %$default;

    return \%mkargs;
}
