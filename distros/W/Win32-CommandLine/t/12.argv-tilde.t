#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

## ToDO: compare with argv.t tests and combine as reasonable; since tests are all done at the same time, we could seperate the $ENV overrides into seperate test files

#use lib 't/lib';
use Test::More;
use Test::Differences;

#plan skip_all => 'Tilde tests are highly configuration dependent [to run: set TEST_FRAGILE]' unless $ENV{TEST_FRAGILE} or $ENV{TEST_ALL};

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; }; # runs the Test::NoWarnings test (must be AFTER any plan skip_all ...)

# if ( !$ENV{HARNESS_ACTIVE} ) {
#     # not executing under Test::Harness
#     use lib qw{ lib };      # for ease of testing from command line and testing immediacy, use the 'lib' version (so 'blib/arch' version doesn't have to be updated 1st)
#     }

use Win32::CommandLine;

sub add_test;
sub test_num;
sub do_tests;

# Tests

## accumulate tests

add_test( [ qq{$0 ~*} ], ( q{~*} ) );

if ($ENV{TEST_FRAGILE}) {
    ## ToDO: This is really not a fair test on all computers unless we make sure the specific account(s) exist and know what the expansions should be...
    ##    :: using $ENV{USERPROFILE} should be safe, but backtest on XP with early perl's before removing the TEST_FRAGILE gate
    add_test( [ qq{$0 ~} ], ( unixify($ENV{USERPROFILE}) ) );
    add_test( [ qq{$0 ~ ~$ENV{USERNAME}} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
    add_test( [ qq{$0 ~$ENV{USERNAME}/} ], ( unixify($ENV{USERPROFILE}.q{/}) ) );
    add_test( [ qq{$0 x ~$ENV{USERNAME}\\ x} ], ( 'x', unixify($ENV{USERPROFILE}.q{/}), 'x' ) );
    add_test( [ qq{$0 ~ ~}.lc($ENV{USERNAME}) ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
    if ($ENV{USERNAME} =~ /\A(.)(.*?)(.)\z/) {
        my $mixed_case_USERNAME;
        $mixed_case_USERNAME = lc($1).lc($2).uc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        $mixed_case_USERNAME = lc($1).uc($2).lc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        $mixed_case_USERNAME = lc($1).uc($2).uc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        $mixed_case_USERNAME = uc($1).lc($2).lc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        $mixed_case_USERNAME = uc($1).lc($2).uc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        $mixed_case_USERNAME = uc($1).uc($2).lc($3);
        add_test( [ qq{$0 ~ ~$mixed_case_USERNAME} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
        }
    add_test( [ qq{$0 ~ ~}.uc($ENV{USERNAME}) ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
    ##
    }

## ToDO: ~ expansion is correct; BUT $ENV override of ~ doesn't work ... should it? -- CHECK this and write a test

## TODO: check both with and without nullglob, including using %opts for argv()
add_test( [ qq{$0 foo\\bar}, { nullglob => 0 } ], ( q{foo\\bar} ) );

## do tests

# setup a known environment
$ENV{nullglob} = 0;     ## no critic ( RequireLocalizedPunctuationVars ) ## ToDO: remove/revisit

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0);

do_tests(); # test re-parsing of command_line() by argv()
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }       ## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; eval { @got = Win32::CommandLine::_argv(@args); 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }

#### SUBs

sub dosify{
    # use Win32::CommandLine::_dosify
    use Win32::CommandLine;
    return Win32::CommandLine::_dosify(@_); ## no critic ( ProtectPrivateSubs )
}

sub unixify{
    # _unixify( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
    # unixify string, returning a string which has unix correct slashes
    @_ = @_ ? @_ : $_ if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    ## no critic ( ProhibitUnusualDelimiters )

    for (@_ ? @_ : $_)
        {
        s:\\:\/:g;
        }

    return wantarray ? @_ : "@_";
}
