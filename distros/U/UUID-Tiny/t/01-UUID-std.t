#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use IO::File;
use MIME::Base64;

use UUID::Tiny qw(:std);

#
# Pre-defined UUIDs ...

ok( equal_uuids(UUID_NIL,     '00000000-0000-0000-0000-000000000000'), 'NIL'  );
ok( equal_uuids(UUID_NS_DNS,  '6ba7b810-9dad-11d1-80b4-00c04fd430c8'), 'DNS'  );
ok( equal_uuids(UUID_NS_URL,  '6ba7b811-9dad-11d1-80b4-00c04fd430c8'), 'URL'  );
ok( equal_uuids(UUID_NS_OID,  '6ba7b812-9dad-11d1-80b4-00c04fd430c8'), 'OID'  );
ok( equal_uuids(UUID_NS_X500, '6ba7b814-9dad-11d1-80b4-00c04fd430c8'), 'X500' );

#
# is_uuid_string() ...
#
ok( is_uuid_string(uuid_to_string(UUID_NIL)), 'is_uuid_string($UUID_NIL)' );
ok( is_uuid_string(uuid_to_string(UUID_NS_URL)),
    'is_uuid_string() with URL UUID'
);
ok( 
    !is_uuid_string('6ba7b810-9dad-11d1-80b4-00c04fd430'),
    'is_uuid_string() with truncated UUID-string'
);

#
# uuid_to_string() and string_to_uuid() ...
#
is(
    uuid_to_string(UUID_NIL),
    '00000000-0000-0000-0000-000000000000',
    'uuid_to_string(UUID_NIL)',
);
is(
    uuid_to_string(UUID_NS_DNS),
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    'uuid_to_string(UUID_NS_DNS)',
);
is(
    uuid_to_string(uuid_to_string(UUID_NS_URL)),
    uuid_to_string(UUID_NS_URL),
    'uuid_to_string with UUID string returns UUID string'
);
is(
    string_to_uuid(UUID_NS_OID),
    UUID_NS_OID,
    'string_to_uuid of UUID return UUID'
);

my $hex_uuid = uuid_to_string(UUID_NS_URL);
$hex_uuid =~ tr/-//;
is(
    string_to_uuid($hex_uuid),
    UUID_NS_URL,
    'string_to_uuid of hex string'
);

my $base64_uuid = encode_base64(UUID_NS_URL);
is(
    string_to_uuid($base64_uuid),
    UUID_NS_URL,
    'string_to_uuid of Base64 string'
);

is(
    string_to_uuid( 'urn:uuid:' . uuid_to_string(UUID_NS_DNS) ),
    UUID_NS_DNS,
    'string_to_uuid with URN string representation'
);

is(
    string_to_uuid( 'uuid:' . uuid_to_string(UUID_NS_DNS) ),
    UUID_NS_DNS,
    'string_to_uuid with shortened URN string representation'
);

is(
    string_to_uuid( 'URN:UUID:' . uc(uuid_to_string(UUID_NS_DNS)) ),
    UUID_NS_DNS,
    'string_to_uuid with all-uppercase URN string representation'
);

eval{ string_to_uuid( 'This is nonsense!' ) };
like( $@, qr/is no UUID string/, 'string_to_uuid with invalid string' );


#
# Create v3 (MD5) UUIDs ...
#
is(
    create_uuid_as_string( UUID_MD5, UUID_NS_DNS, 'python.org' ),
    '6fa459ea-ee8a-3ca4-894e-db77e160355e',
    'v3 UUID with DNS und python.org'
);
is(
    create_uuid_as_string( UUID_V3, UUID_NS_DNS, 'www.doughellmann.com' ),
    'bcd02e22-68f0-3046-a512-327cca9def8f',
    'v3 UUID test with www.doughellmann.com and DNS Namespace UUID'
);

my $test_data = do {
    local $/;
    open my $fh, '<', 't/data/test.jpg' or croak "Open failed!";
    <$fh>;
};

my $fh;
open $fh, '<', 't/data/test.jpg' or croak "Open failed!";
is(
    create_uuid_as_string( UUID_MD5, $fh ),
    create_uuid_as_string( UUID_V3, $test_data ),
    'V3 UUID from GLOB'
);
undef $fh;

$fh = new IO::File 't/data/test.jpg' or croak 'IO::File failed.';
is(
    create_uuid_as_string( UUID_MD5, $fh ),
    create_uuid_as_string( UUID_V3, $test_data ),
    'V3 UUID from IO::File'
);
undef $fh;

#
# Create v5 UUIDs ...
#
if (!UUID_SHA1_AVAIL) {
    diag('No SHA1 available, skipping UUID_SHA1 tests ...');
}
else {
    is(
        create_uuid_as_string( UUID_SHA1, UUID_NS_DNS, 'python.org' ),
        '886313e1-3b8a-5372-9b90-0c9aee199e5d',
        'v5 UUID with DNS und python.org'
    );
    is(
        create_uuid_as_string( UUID_V5, UUID_NS_DNS, 'www.doughellmann.com' ),
        'e3329b12-30b7-57c4-8117-c2cd34a87ce9',
        'v5 UUID test with www.doughellmann.com and DNS Namespace UUID'
    );

    open $fh, '<', 't/data/test.jpg' or croak "Open failed!";
    is(
        create_uuid_as_string( UUID_SHA1, $fh ),
        create_uuid_as_string( UUID_V5, $test_data ),
        'V5 UUID from GLOB'
    );
    undef $fh;

    $fh = new IO::File 't/data/test.jpg' or croak 'IO::File failed.';
    is(
        create_uuid_as_string( UUID_SHA1, $fh ),
        create_uuid_as_string( UUID_V5, $test_data ),
        'V5 UUID from IO::File'
    );
    undef $fh;

    is(
        create_uuid(UUID_SHA1, 'Ein Test-String.'),
        create_uuid(UUID_V5, UUID_NIL, 'Ein Test-String.'),
        'create_uuid without NS UUID'
    );
}

#
# is_v1_uuid() and is_v5_uuid() ...
#
ok( version_of_uuid(UUID_NS_URL) == 1, 'is_v1_uuid with UUID' );
ok(
    version_of_uuid(string_to_uuid(UUID_NS_URL)) == 1,
    'is_v1_uuid with UUID string'
);
ok(
    version_of_uuid(
        string_to_uuid('e3329b12-30b7-57c4-8117-c2cd34a87ce9')) == 5,
    'is_v5_uuid with UUID'
);
ok(
    version_of_uuid('e3329b12-30b7-57c4-8117-c2cd34a87ce9') == 5,
    'is_v5_uuid with UUID string'
);

#
# Generate v1mc UUIDs ...
#
my $now = time();
my $v1_uuid = create_uuid();
#diag uuid_to_string($v1_uuid);
ok( version_of_uuid($v1_uuid) == 1, 'create_uuid creates v1 UUID' );

# Check time_of_uuid() ...
my $uuid_time = int(time_of_uuid($v1_uuid));
ok( ($uuid_time == $now) || ($uuid_time == $now + 1), 'check time of UUID' );
is( time_of_uuid(UUID_NIL), undef, 'time_of_uuid($UUID_NIL) is undef' );
is(
    time_of_uuid($v1_uuid),
    time_of_uuid(uuid_to_string($v1_uuid)),
    'time_of_uuid with UUID and UUID string'
);

# Check clk_seq_of_uuid() ...
ok( defined clk_seq_of_uuid($v1_uuid), 'clk_seq_of_uuid works as expected' );
ok( !defined clk_seq_of_uuid(UUID_NIL), 'clk_seq_of_uuid of UUID NIL undef');
is(
    clk_seq_of_uuid($v1_uuid),
    clk_seq_of_uuid(uuid_to_string($v1_uuid)),
    'clk_seq_of_uuid with UUID and UUID string'
);

# Check equal_uuids() ...
ok( equal_uuids($v1_uuid, uuid_to_string($v1_uuid)), 'equal_uuids()' );
ok( !equal_uuids(uuid_to_string($v1_uuid), UUID_NS_URL), '!equal_uuids()' );

# Check if time advances as expected ...
sleep 1;
ok( $now < time_of_uuid(create_uuid()), 'check if time advances ...');

# Check for uniqueness of consecutive UUIDs ...
my %uuid;
my $prev_uuid;
for (my $i = 0; $i < 10000; $i++) {
    my $act_uuid = create_uuid();
    if (!exists $uuid{$act_uuid}) {
        $uuid{$act_uuid} = 1;
        if (defined $prev_uuid) {
            ok(
                (
                    (time_of_uuid($prev_uuid) < time_of_uuid($act_uuid))
                        && (clk_seq_of_uuid($prev_uuid)
                            == clk_seq_of_uuid($act_uuid))
                ) || (
                    (time_of_uuid($prev_uuid) >= time_of_uuid($act_uuid))
                        && (clk_seq_of_uuid($prev_uuid)
                            != clk_seq_of_uuid($act_uuid))
                ),
                'time advances or clk_seq is different'
            );
        }
        $prev_uuid = $act_uuid;
    }
    else {
        fail('Consecutive v1 UUIDs are not unique!');
    }
}


#
# Generate v4 UUIDs ...
#
my $v4_uuid = create_uuid(UUID_RANDOM);
#diag uuid_to_string($v4_uuid);
ok( version_of_uuid($v4_uuid) == 4, 'create_uuid creates v4 UUID' );

# Check for uniqueness of random UUIDs ...
my $not_unique = 0;
for (my $i = 0; $i < 100000; $i++) {
    my $act_uuid = create_uuid(UUID_V4);
    if (!exists $uuid{$act_uuid}) {
        $uuid{$act_uuid} = 1;
    }
    else {
        $not_unique = 1;
        last;
    }
}

ok( !$not_unique, '100.000 V4 UUIDs are unique!' ); 


