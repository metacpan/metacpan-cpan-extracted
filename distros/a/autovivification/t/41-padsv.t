#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

my $buf = "abc\ndef\n";
open my $x, '<', \$buf;

# Do this one first so that the check functions are set up for the second
my $res = eval 'no autovivification; <$x>';
is $@,   '',      'padsv 1: no error';
is $res, "abc\n", 'padsv 1: correct returned value';

$res = eval '<$x>';
is $@,   '',      'padsv 2: no error';
is $res, "def\n", 'padsv 2: correct returned value';
