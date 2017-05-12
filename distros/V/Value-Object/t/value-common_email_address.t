#!/usr/bin/env perl

use Test::More tests => 7;
use Test::Exception;

use strict;
use warnings;

use Value::Object::EmailAddressCommon;

subtest "Doesn't create for invalid email addresses" => sub {
    throws_ok { Value::Object::EmailAddressCommon->new(); } qr/^Value::Object::EmailAddressCommon/, "no create undef email address";
    throws_ok { Value::Object::EmailAddressCommon->new( '' ); } qr/^Value::Object::EmailAddressCommon/, "no create empty email address";
};

subtest "Create correct object for simple email address" => sub {
    my $domain = Value::Object::EmailAddressCommon->new( 'gwadej@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddressCommon' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddressCommon matches input" );
    is( $domain->local_part,    'gwadej', "EMailAddress local part matches input" );
    isa_ok( $domain->domain, 'Value::Object::Domain' );
    is( $domain->domain->value, 'cpan.org', "EMailAddress domain matches input" );
};

{
    throws_ok { Value::Object::EmailAddressCommon->new( '"gwade@j"@cpan.org' ) }
        qr/^Value::Object::EmailAddressCommon/,
        "Invalid local part throws";
}

subtest "Create correct object with uppercased domain" => sub {
    my $domain = Value::Object::EmailAddressCommon->new( 'gwadej@CPAN.ORG' );
    isa_ok( $domain, 'Value::Object::EmailAddressCommon' );
    is( $domain->value, 'gwadej@CPAN.ORG', "EmailAddressCommon matches input" );
};

subtest "Create fine with new_canonical and simple address" => sub {
    my $domain = Value::Object::EmailAddressCommon->new_canonical( 'gwadej@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddressCommon' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddressCommon matches input" );
};

{
    throws_ok { Value::Object::EmailAddressCommon->new_canonical( '"g@wadej"@cpan.org' ); }
        qr/^Value::Object::EmailAddressCommon/,
        "Invalid local part throws on canonical";
}

subtest "Create canonicallized object from uppercased domain" => sub {
    my $domain = Value::Object::EmailAddressCommon->new_canonical( 'gwadej@CPAN.ORG' );
    isa_ok( $domain, 'Value::Object::EmailAddressCommon' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddressCommon canonicalized" );
};

