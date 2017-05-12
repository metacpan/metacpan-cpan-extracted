#! perl

use strict;
use warnings;
use Text::Autoformat qw/ autoformat /;
use Test::More 0.88 tests => 1;

my $input           = '';
my $expected_output = '';
my $output          = autoformat($input);

ok(defined($output) && $output eq $expected_output,
   "Empty string input should result in empty string output");

