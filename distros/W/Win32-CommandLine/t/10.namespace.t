#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

# check expected namespace information

use lib 't/lib';
use Test::More;
use Test::Differences;
my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

#plan tests => 2 + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => 2 + ($haveTestNoWarnings ? 1 : 0);

use lib qw{ blib\arch };		# XS module => must rebuild new .DLL before testing

use Win32::CommandLine;

eq_or_diff (\@Win32::CommandLine::EXPORT, [ ], '@EXPORT is empty');
eq_or_diff ([ sort (@Win32::CommandLine::EXPORT_OK) ], [ sort qw{ command_line argv parse } ], '@EXPORT_OK has expected values');
