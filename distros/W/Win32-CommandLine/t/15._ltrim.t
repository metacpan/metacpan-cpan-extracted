#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

# use lib "t/lib";
use Test::More;
use Test::Differences;

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; }; # (should be AFTER any plan skip_all ...)

# use lib qw{ lib blib/lib blib/arch };

use Win32::CommandLine;

local $| = 1;     # autoflush for warnings to be in sequence with regular output

sub add_test;
sub test_num;
sub do_tests;

# Tests

## accumulate tests

add_test( [ qq{} ], [ qq{} ] );
add_test( [ qq{ testing} ], [ qw( testing ) ] );
add_test( [ qq{ testing}, qq{\tTAB-test} ], [ 'testing', 'TAB-test' ] );
add_test( [ qq{ testing}, { trim_re => '[\st]+'} ], [ 'esting'] );
#add_test( [ qq{ }, { trim_re => '[\st]+'} ], [ qq() ] );
#add_test( [ qq{ testing}, qq{\tTAB-test}, { trim_re => '(?i:[\stes]+)'}], [ 'ing', 'AB-test' ] );

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0);

do_tests(); # test _ltrim()

##
my @tests;
sub add_test { push @tests, \@_; return; }
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $arg_ref = shift @{$t}; my @arg = @{$arg_ref}; my @exp_ref = @{$t}; my @got = Win32::CommandLine::_ltrim(@arg); my $opt_ref; $opt_ref = pop @{$arg_ref} if ( @{$arg_ref} && (ref($arg_ref->[-1]) eq 'HASH')); eq_or_diff \@got, @exp_ref, "testing _ltrim parse: `".join(",",@{$arg_ref}).($opt_ref ? ' {'.join(",",map { "$_ => ".$opt_ref->{$_}} keys %{$opt_ref}).'}': '')."`"; } return; }
