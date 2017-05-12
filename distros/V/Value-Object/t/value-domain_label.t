#!/usr/bin/env perl

use Test::More tests => 9;
use Test::Exception;

use strict;
use warnings;

use Value::Object::DomainLabel;

subtest "Doesn't create for invalid domains" => sub {
    throws_ok { Value::Object::DomainLabel->new(); } qr/^Value::Object::DomainLabel/, "no create undef domain label";
    throws_ok { Value::Object::DomainLabel->new( '' ); } qr/^Value::Object::DomainLabel/, "no create empty domain label";
    throws_ok { Value::Object::DomainLabel->new( 'google.com' ); } qr/^Value::Object::DomainLabel/, "no create empty domain label";
};

{
    my $domain = Value::Object::DomainLabel->new( 'google' );
    isa_ok( $domain, 'Value::Object::DomainLabel' );
    is( $domain->value, 'google', "DomainLabel matches input" );
}

{
    my $domain = Value::Object::DomainLabel->new( 'GOOGLE' );
    isa_ok( $domain, 'Value::Object::DomainLabel' );
    is( $domain->value, 'GOOGLE', "DomainLabel matches input" );
}

{
    my $domain = Value::Object::DomainLabel->new_canonical( 'google' );
    isa_ok( $domain, 'Value::Object::DomainLabel' );
    is( $domain->value, 'google', "DomainLabel matches input" );
}

{
    my $domain = Value::Object::DomainLabel->new_canonical( 'GOOGLE' );
    isa_ok( $domain, 'Value::Object::DomainLabel' );
    is( $domain->value, 'google', "DomainLabel canonicalized" );
}

