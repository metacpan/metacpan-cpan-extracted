use strict;
use warnings;
use Test::More tests => 5;

use UUID::Object;

is( lc(uuid_nil->as_string), '00000000-0000-0000-0000-000000000000', 'uuid_nil' );

is( lc(uuid_ns_dns->as_string), '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'uuid_ns_dns' );
is( lc(uuid_ns_url->as_string), '6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'uuid_ns_url' );
is( lc(uuid_ns_oid->as_string), '6ba7b812-9dad-11d1-80b4-00c04fd430c8', 'uuid_ns_oid' );
is( lc(uuid_ns_x500->as_string), '6ba7b814-9dad-11d1-80b4-00c04fd430c8', 'uuid_ns_x500' );

