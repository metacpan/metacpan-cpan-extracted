#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use IO::File;
use MIME::Base64;

use UUID::Tiny;

# As of 1.02, tests only the existance of the old "legacy" interface ...
my @legacy = qw(
    UUID_NIL
    UUID_NS_DNS UUID_NS_URL UUID_NS_OID UUID_NS_X500
    UUID_V1
    UUID_V3
    UUID_V4
    UUID_V5
    UUID_SHA1_AVAIL
    create_UUID create_UUID_as_string
    is_UUID_string
    UUID_to_string string_to_UUID
    version_of_UUID time_of_UUID clk_seq_of_UUID
    equal_UUIDs
);
my @not_legacy = qw(
    UUID_TIME
    UUID_MD5
    UUID_RANDOM
    UUID_SHA1
    create_uuid create_uuid_as_string
    is_uuid_string
    uuid_to_string string_to_uuid
    version_of_uuid time_of_uuid clk_seq_of_uuid
    equal_uuids
);

no warnings;

foreach my $legacy_symbol (@legacy) {
    ok( exists $main::{$legacy_symbol}, "$legacy_symbol available" );
}

foreach my $not_legacy_symbol (@not_legacy) {
    ok( !exists $main::{$not_legacy_symbol}, "$not_legacy_symbol unavailable" );
}

my $test = create_UUID(UUID_V1);
$test = create_UUID(UUID_V4);

