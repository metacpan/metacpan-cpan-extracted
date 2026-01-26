#!perl -T

use strict;
use warnings;

use Test::More;

my @CLASSES = qw(
    URI::PackageURL
    URI::PackageURL::App
    URI::PackageURL::Type
    URI::PackageURL::Util

    URI::VersionRange
    URI::VersionRange::App
    URI::VersionRange::Constraint
    URI::VersionRange::Version
);

use_ok($_) for @CLASSES;

done_testing();

diag("URI::PackageURL $URI::PackageURL::VERSION, Perl $], $^X");
