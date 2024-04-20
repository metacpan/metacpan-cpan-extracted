#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('URI::PackageURL');
use_ok('URI::PackageURL::Util');
use_ok('URI::PackageURL::App');

done_testing();

diag("URI::PackageURL $URI::PackageURL::VERSION, Perl $], $^X");
