
use strict;
use warnings;
use Test::More;

eval { require Types::Serialiser };
plan skip_all => "Types::Serialiser needed for this test" if $@;
use Types::Bool qw(true false is_bool);

plan tests => 22;

ok( is_bool(true),  'true is_bool()' );
ok( is_bool(false), 'false is_bool()' );

ok( !is_bool(undef), 'undef not is_bool()' );
ok( !is_bool(''),    '"" not is_bool()' );
ok( !is_bool(0),     '0 not is_bool()' );

ok( !is_bool(1), '1 not is_bool()' );

ok( !is_bool( \0 ), '\0 not is_bool()' );
ok( !is_bool( \1 ), '\1 not is_bool()' );

ok( !is_bool('true'),  '"true" not is_bool()' );
ok( !is_bool('false'), '"false" not is_bool()' );

ok( !is_bool('Types::Bool'),       '"Types::Bool" not is_bool()' );
ok( !is_bool('JSON::PP::Boolean'), '"JSON::PP::Boolean" not is_bool()' );

ok( !is_bool( [] ), '[] not is_bool()' );
ok( !is_bool( {} ), '{} not is_bool()' );

ok( is_bool( do { bless \( my $dummy = 0 ), 'Types::Bool' } ), 'bless \0, "Types::Bool" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 0 ), 'JSON::PP::Boolean' } ), 'bless \0, "JSON::PP::Boolean" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Types::Bool' } ), 'bless \1, "Types::Bool" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'JSON::PP::Boolean' } ), 'bless \1, "JSON::PP::Boolean" is_bool()' );

package Bool2;
our @ISA = qw(Types::Bool);

package Bool3;
our @ISA = qw(JSON::PP::Boolean);

package main;

ok( is_bool( do { bless \( my $dummy = 0 ), 'Bool2' } ), 'bless \0, "Bool2" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 0 ), 'Bool3' } ), 'bless \0, "Bool3" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Bool2' } ), 'bless \1, "Bool2" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Bool3' } ), 'bless \1, "Bool3" is_bool()' );
