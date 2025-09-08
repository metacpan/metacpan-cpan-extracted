#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('Version::libversion::PP');
done_testing();

diag("Version::libversion::PP $Version::libversion::PP::VERSION, Perl $], $^X");

