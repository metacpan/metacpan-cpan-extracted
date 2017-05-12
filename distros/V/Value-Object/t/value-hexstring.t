#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;

use strict;
use warnings;

use Value::Object::HexString;

subtest "Doesn't create for invalid hexstrings" => sub {
    throws_ok { Value::Object::HexString->new(); } qr/^Value::Object::HexString/, 'no create undef hexstring';
    throws_ok { Value::Object::HexString->new( '' ); } qr/^Value::Object::HexString/, 'no create empty hexstring';
    throws_ok { Value::Object::HexString->new( 'fred' ); } qr/^Value::Object::HexString/, 'Invalid character';
};

subtest 'All digits hexstring' => sub {
    my $domain = Value::Object::HexString->new( '12345678' );
    isa_ok( $domain, 'Value::Object::HexString' );
    is( $domain->value, '12345678', 'HexString matches input' );
};

subtest 'All lowercase hexstring' => sub {
    my $domain = Value::Object::HexString->new( 'deadbeef' );
    isa_ok( $domain, 'Value::Object::HexString' );
    is( $domain->value, 'deadbeef', 'HexString matches input' );
};

subtest 'All uppercase hexstring' => sub {
    my $domain = Value::Object::HexString->new( 'DEADBEEF' );
    isa_ok( $domain, 'Value::Object::HexString' );
    is( $domain->value, 'DEADBEEF', 'HexString uppercase matches input' );
};

subtest 'new_canonical canonicalizes the string' => sub {
    my $domain = Value::Object::HexString->new_canonical( 'DEADBEEF' );
    isa_ok( $domain, 'Value::Object::HexString' );
    is( $domain->value, 'deadbeef', 'Canonical HexString matches is lowercased' );
};
