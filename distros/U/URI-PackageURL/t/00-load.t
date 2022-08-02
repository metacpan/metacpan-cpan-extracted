#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('URI::PackageURL');

done_testing();

diag("URI::PackageURL $URI::PackageURL::VERSION, Perl $], $^X");
