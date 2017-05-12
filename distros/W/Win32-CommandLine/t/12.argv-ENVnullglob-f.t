#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

#use lib 't/lib';
use Test::More;
use Test::Differences;
my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

if ( !$ENV{HARNESS_ACTIVE} ) {
	# not executing under Test::Harness
	use lib qw{ lib };		# for ease of testing from command line and testing immediacy, use the 'lib' version (so 'blib/arch' version doesn't have to be updated 1st)
	}

use Win32::CommandLine;

sub add_test;
sub test_num;
sub do_tests;

# setup a known environment
$ENV{nullglob} = 0;  	## no critic ( RequireLocalizedPunctuationVars ) ## ToDO: remove/revisit

# Tests

## accumulate tests

add_test( [ qq{$0} ], qw( ) );

add_test( [ qq{ $0} ], qw( ) );

add_test( [ qq{$0 } ], qw( ) );

add_test( [ qq{ $0 } ], qw( ) );

add_test( [ qq{ a } ], qw( ) );

add_test( [ qq{ a b c } ], qw( ) );

add_test( [ qq{ a 'b' c } ], qw( ) );

add_test( [ qq{$0 a '' } ], ( qq{a}, qq{} ) );

add_test( [ qq{$0 a b c} ], qw( a b c ) );

add_test( [ qq{$0 "a b" c} ], ( "a b", "c" ) );

add_test( [ qq{$0 'a b' c'' } ], ( "a b", "c" ) );

add_test( [ qq{$0 "a b" c"" } ], ( "a b", "c" ) );

add_test( [ qq{$0 "a b" c""d } ], ( "a b", "cd" ) );

add_test( [ qq{$0 'a b" c'} ], ( qq{a b" c} ) );	##"

add_test( [ qq{$0 'a bb" c'} ], ( qq{a bb" c} ) );	##"

add_test( [ qq{$0 \$'test'} ], ( qq{test} ) );

add_test( [ qq{$0 \$'\\x34\\x34'} ], ( qq{44} ) );

add_test( [ qq{$0 '\\x34\\x34'} ], ( qq{\\x34\\x34} ) );

add_test( [ qq{$0 \*.t} ], ( q{*.t} ) );

#add_test( [ qq{$0 '*.t} ], ( q{*.t} ) );   # exception: unbalanced quotes

add_test( [ qq{$0 a b c \*.t} ], ( qw{a b c}, q{*.t} ) );

add_test( [ qq{$0 a b c t/\*.t} ], ( qw{a b c}, glob('t/*.t') ) );

add_test( [ qq{$0 a t/\*.t b} ], ( "a", glob('t/*.t'), "b" ) );

add_test( [ qq{$0 t/\"*".t} ], ( q{t/*.t} ) );	##"

add_test( [ qq{$0 t/\'*'.t} ], ( q{t/*.t} ) );

add_test( [ qq{$0 t/{0}\*.t} ], ( glob('t/{0}*.t') ) );

add_test( [ qq{$0 t/{0,}\*.t} ], ( glob('t/{0,}*.t') ) );

add_test( [ qq{$0 t/{0,p}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{0,p}*.t') ) );

add_test( [ qq{$0 t/\{0,t,p\}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{0,t,p}*.t') ) );

add_test( [ qq{$0 t/\{t,p,0\}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{t,p,0}*.t') ) );

add_test( [ qq{$0 t/\*} ], ( glob('t/*') ) );

add_test( [ qq{$0 '\\\\'} ], ( '\\\\' ) );

add_test( [ qq{$0 'a\\a' '\\a\\x\\'} ], ( 'a\\a', '\\a\\x\\' ) );

add_test( [ qq{$0 '/a\a'} ], ( qq{/a\a} ) );

add_test( [ qq{$0 '//foo\\bar'} ], ( q{//foo\\bar} ) );

add_test( [ qq{$0 '/a\a' /foo\\\\bar} ], ( qq{/a\a}, q{/foo\\\\bar} ) );

add_test( [ qq{$0 1 't\\glob-file.tests'/*} ], ( 1, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 2 't\\glob-file.tests'\\*} ], ( 2, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 3 't\\glob-file.tests/'*} ], ( 3, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 4 't\\glob-file.tests\\'*} ], ( 4, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 5 't\\glob-file.tests\\*'} ], ( 5, q{t\\glob-file.tests\\*} ) );

add_test( [ qq{$0 t ""} ], ( q{t}, q{} ) );

add_test( [ qq{$0 t 0} ], ( q{t}, q{0} ) );

add_test( [ qq{$0 t 0""} ], ( q{t}, q{0} ) );

add_test( [ qq{$0 't\\glob-file.tests\\'*x} ], ( q{t\\glob-file.tests\\*x} ) );
#

if ($ENV{TEST_FRAGILE}) {
	## ToDO: This is really not a fair test on all computers unless we make sure the specific account(s) exist and know what the expansions should be...
	##    :: using $ENV{USERPROFILE} should be safe, but backtest on XP with early perl's before removing the TEST_FRAGILE gate
	add_test( [ qq{$0 ~*} ], ( q{~*} ) );
	add_test( [ qq{$0 ~} ], ( unixify($ENV{USERPROFILE}) ) );
	add_test( [ qq{$0 ~ ~$ENV{USERNAME}} ], ( unixify($ENV{USERPROFILE}), unixify($ENV{USERPROFILE}) ) );
	add_test( [ qq{$0 ~$ENV{USERNAME}/} ], ( unixify($ENV{USERPROFILE}.q{/}) ) );
	add_test( [ qq{$0 x ~$ENV{USERNAME}\\ x} ], ( 'x', unixify($ENV{USERPROFILE}.q{/}), 'x' ) );
	##
	}

# rule tests
# non-globbed tokens should stay the same
add_test( [ qq{$0 1 foo\\bar} ], ( 1, q{foo\\bar} ) );
add_test( [ qq{$0 2 \\foo/bar} ], ( 2, q{\\foo/bar} ) );
add_test( [ qq{$0 1 't\\glob-file.tests\\'*} ], ( 1, glob('t/glob-file.tests/*') ) );

# dosify
add_test( [ qq{$0 foo\\bar} ], ( q{foo\\bar} ) );



## TODO: check both with and without nullglob, including using %opts for argv()
add_test( [ qq{$0 foo\\bar}, { nullglob => 0 } ], ( q{foo\\bar} ) );

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0);

do_tests(); # test re-parsing of command_line() by argv()
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }		## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; eval { @got = Win32::CommandLine::_argv(@args); 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }

#### SUBs

sub dosify{
	# use Win32::CommandLine::_dosify
	use Win32::CommandLine;
	return Win32::CommandLine::_dosify(@_);	## no critic ( ProtectPrivateSubs )
}

sub unixify{
	# _unixify( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
	# unixify string, returning a string which has unix correct slashes
	@_ = @_ ? @_ : $_ if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	## no critic ( ProhibitUnusualDelimiters )

	for (@_ ? @_ : $_)
		{
		s:\\:\/:g;
		}

	return wantarray ? @_ : "@_";
}
