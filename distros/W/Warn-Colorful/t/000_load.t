#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Warn::Colorful';
}

diag "Testing Warn::Colorful/$Warn::Colorful::VERSION";
