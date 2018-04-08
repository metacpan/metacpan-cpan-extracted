use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use UUID::URandom qw/create_uuid create_uuid_hex create_uuid_string/;

my $uuid_version = 4;

# structural test
my $uuid1 = create_uuid();
my $binary = unpack( "B*", $uuid1 );
ok( defined $uuid1, "Created a UUID" );
is( length $uuid1, 16, "UUID is 16 byte string" );
is( substr( $binary, 64, 2 ), "10", "variant field correct" );
is(
    substr( $binary, 48, 4 ),
    substr( unpack( "B8", chr( substr( $uuid_version, 0, 1 ) ) ), 4, 4 ),
    "version field correct"
);

# uniqueness test
my %uuids;
my $count = 10000;
$uuids{ create_uuid() } = undef for 1 .. $count;
is( scalar keys %uuids, $count, "Generated $count unique UUIDs" );

# output tests
my $h = "[0-9a-f]"; # lc, not [[:xdigit:]]

my $hex = create_uuid_hex();
is( length $hex, 32, "create_uuid_hex length correct" );
like( $hex, qr/\A${h}{32}\z/, "create_uuid_hex format correct" );

my $str = create_uuid_string();
is( length $str, 36, "create_uuid_string length correct" );
like(
    $str,
    qr/\A${h}{8}-${h}{4}-${h}{4}-${h}{4}-${h}{12}\z/,
    "create_uuid_string format correct"
);

done_testing;
#
# This file is part of UUID-URandom
#
# This software is Copyright (c) 2018 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
