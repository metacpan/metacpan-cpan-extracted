#!perl -w   -- -*- tab-width: 4; mode: perl -*-     ## no critic ( RequireTidyCode RequireVersionVar )
## no critic ( Capitalization )

use strict;
use warnings;
use English qw/ -no_match_vars /;   # enable long form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars ProhibitPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

use Test::More;

# # configure 'lib' for command line testing, when needed
# if ( !$ENV{HARNESS_ACTIVE} ) {
#     # not executing under Test::Harness (eg, executing directly from command line)
#     use lib qw{ blib/arch };   # only needed for dynamic module loads (eg, compiled XS) [ removable if no XS ]
#     use lib qw{ lib };         # use 'lib' content (so 'blib/arch' version doesn't always have to be built/updated 1st)
#     }

#

plan tests => 3 + ($haveTestNoWarnings ? 1 : 0);

#
{; ## no critic ( ProhibitBuiltinHomonyms ProhibitSubroutinePrototypes RequireArgUnpacking )
sub say  (@) { return print @_, "\n" }          # ( @:MSGS ) => $:success
sub sayf (@) { return say sprintf shift, @_ }   # ( @:MSGS ) => $:success
}
#

# Tests

require_ok('Win32::CommandLine');
Win32::CommandLine->import( qw( command_line ) );

my $zero = quotemeta $PROGRAM_NAME;
my $string = command_line();
() = say "command_line = $string";
ok($string =~ /.*perl.*$zero.*/msx, "command_line() [$string] for $PROGRAM_NAME returned {matches /.*perl.*\$PROGRAM_NAME.*/}");

my @argv2 = Win32::CommandLine::argv();
() = say "ARGV[$#ARGV] = {".join(q/:/,@ARGV).q/}/;
() = say "argv2[$#argv2] = {".join(q/:/,@argv2).q/}/;
ok($#argv2 < 0, 'successful command_line() reparse; ARGV has no args');
