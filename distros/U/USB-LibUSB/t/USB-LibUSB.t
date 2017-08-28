#!perl -T

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 3;
BEGIN {use_ok('USB::LibUSB')};

my $version_hash = libusb_get_version();

is(ref $version_hash, 'HASH', "version hash");
diag("libusb_version: ", Dumper($version_hash));
is($version_hash->{major}, 1, "major version number is 1");
