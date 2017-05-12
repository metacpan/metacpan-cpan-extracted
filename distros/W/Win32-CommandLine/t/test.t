#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More tests => 3;

# Tests

require_ok('Win32::CommandLine');
Win32::CommandLine->import( qw( command_line ) );

my $string = command_line();
print "string = $string\n";
ok($string =~ /perl/, "command_line() returned {matches /perl/}");

my @argv2 = Win32::CommandLine::argv();
print "ARGV[$#ARGV] = {".join(':',@ARGV)."}\n";
print "argv2[$#argv2] = {".join(':',@argv2)."}\n";
ok($#argv2 < 0, "has no args");
