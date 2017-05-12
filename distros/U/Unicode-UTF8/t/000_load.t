#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Unicode::UTF8');
}

diag("Unicode::UTF8 $Unicode::UTF8::VERSION, Perl $], $^X");

