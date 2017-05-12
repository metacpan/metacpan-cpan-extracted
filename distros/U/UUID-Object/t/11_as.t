use strict;
use warnings;
use Test::More tests => 21;

use UUID::Object;

my $class = 'UUID::Object';

my $u;

# as_*()
$u = $class->create_from_string('6ba7b810-9dad-11d1-80b4-00c04fd430c8');

is( $u->as_binary, "\x6b\xa7\xb8\x10\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8", 'as_binary' );

is( lc($u->as_hex), "6ba7b8109dad11d180b400c04fd430c8", 'as_hex' );

is( lc($u->as_string), "6ba7b810-9dad-11d1-80b4-00c04fd430c8", 'as_string' );

is( $u->as_base64, "a6e4EJ2tEdGAtADAT9QwyA==", 'as_base64' );

# create_from_*()
$u = $class->create_from_binary("\x6b\xa7\xb8\x11\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8");
is( lc($u->as_string), "6ba7b811-9dad-11d1-80b4-00c04fd430c8", 'create_from_binary' );

$u = $class->create_from_hex("6ba7b8119dad11d180b400c04fd430c8");
is( lc($u->as_string), "6ba7b811-9dad-11d1-80b4-00c04fd430c8", 'create_from_hex' );

$u = $class->create_from_base64("a6e4EZ2tEdGAtADAT9QwyA==");
is( lc($u->as_string), "6ba7b811-9dad-11d1-80b4-00c04fd430c8", 'create_from_base64' );

# assign_with_*()
$u = $class->create_nil();
$u = $u->assign_with_object($class->create_from_string("6ba7b812-9dad-11d1-80b4-00c04fd430c8"));
is( lc($u->as_string), "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 'assign_with_object' );

$u = $class->create_nil();
$u = $u->assign_with_binary("\x6b\xa7\xb8\x12\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8");
is( lc($u->as_string), "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 'assign_with_binary' );

$u = $class->create_nil();
$u = $u->assign_with_hex("6ba7b8129dad11d180b400c04fd430c8");
is( lc($u->as_string), "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 'assign_with_hex' );

$u = $class->create_nil();
$u = $u->assign_with_string('6ba7b812-9dad-11d1-80b4-00c04fd430c8');
is( lc($u->as_string), "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 'assign_with_string' );

$u = $class->create_nil();
$u = $u->assign_with_base64("a6e4Ep2tEdGAtADAT9QwyA==");
is( lc($u->as_string), "6ba7b812-9dad-11d1-80b4-00c04fd430c8", 'assign_with_base64' );

# handy create()
$u = $class->create("\x6b\xa7\xb8\x13\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8");
is( lc($u->as_string), "6ba7b813-9dad-11d1-80b4-00c04fd430c8", 'handy create(binary)' );

$u = $class->create("6ba7b8139dad11d180b400c04fd430c8");
is( lc($u->as_string), "6ba7b813-9dad-11d1-80b4-00c04fd430c8", 'handy create(hex)' );

$u = $class->create('6ba7b813-9dad-11d1-80b4-00c04fd430c8');
is( lc($u->as_string), "6ba7b813-9dad-11d1-80b4-00c04fd430c8", 'handy create(string)' );

$u = $class->create("a6e4E52tEdGAtADAT9QwyA==");
is( lc($u->as_string), "6ba7b813-9dad-11d1-80b4-00c04fd430c8", 'handy create(base64)' );

# handy assign()
$u = $class->create_nil();
$u = $u->assign_with_object($class->create_from_string("6ba7b814-9dad-11d1-80b4-00c04fd430c8"));
is( lc($u->as_string), "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 'handy assign(object)' );

$u = $class->create_nil();
$u = $u->assign("\x6b\xa7\xb8\x14\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8");
is( lc($u->as_string), "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 'handy assign(binary)' );

$u = $class->create_nil();
$u = $u->assign(uc "6ba7b8149dad11d180b400c04fd430c8");
is( lc($u->as_string), "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 'handy assign(hex)' );

$u = $class->create_nil();
$u = $u->assign(uc '6ba7b814-9dad-11d1-80b4-00c04fd430c8');
is( lc($u->as_string), "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 'handy assign(string)' );

$u = $class->create_nil();
$u = $u->assign("a6e4FJ2tEdGAtADAT9QwyA==");
is( lc($u->as_string), "6ba7b814-9dad-11d1-80b4-00c04fd430c8", 'handy assign(basse64)' );
