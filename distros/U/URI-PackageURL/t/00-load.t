#!perl -T

use strict;
use warnings;

use Test::More;

my @CLASSES = qw(
    URI::PackageURL
    URI::PackageURL::Util
    URI::PackageURL::App

    URI::VersionRange
    URI::VersionRange::Constraint
    URI::VersionRange::Version
    URI::VersionRange::App
);

use_ok($_) for @CLASSES;

done_testing();

diag("URI::PackageURL $URI::PackageURL::VERSION, Perl $], $^X");
