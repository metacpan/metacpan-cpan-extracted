#!/usr/bin/env perl

use Test::More tests => 7;
use Test::Exception;

use strict;
use warnings;

use Value::Object::EmailAddress;

subtest "Doesn't create for invalid domains" => sub {
    throws_ok { Value::Object::EmailAddress->new(); } qr/^Value::Object::EmailAddress/, "no create undef domain";
    throws_ok { Value::Object::EmailAddress->new( '' ); } qr/^Value::Object::EmailAddress/, "no create empty domain";
};

subtest "Create correct object for simple email address" => sub {
    my $domain = Value::Object::EmailAddress->new( 'gwadej@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddress matches input" );
    is( $domain->local_part,    'gwadej', "EMailAddress local part matches input" );
    isa_ok( $domain->domain, 'Value::Object::Domain' );
    is( $domain->domain->value, 'cpan.org', "EMailAddress domain matches input" );
};

subtest "Create correct object with quoted local part" => sub {
    my $domain = Value::Object::EmailAddress->new( '"gwade@j"@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, '"gwade@j"@cpan.org', "EmailAddress matches input" );
    is( $domain->local_part,    '"gwade@j"', "EMailAddress local part matches input" );
    isa_ok( $domain->domain, 'Value::Object::Domain' );
    is( $domain->domain->value, 'cpan.org', "EMailAddress domain matches input" );
};

subtest "Create correct object with uppercased domain" => sub {
    my $domain = Value::Object::EmailAddress->new( 'gwadej@CPAN.ORG' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, 'gwadej@CPAN.ORG', "EmailAddress matches input" );
};

subtest "Create fine with new_canonical and simple address" => sub {
    my $domain = Value::Object::EmailAddress->new_canonical( 'gwadej@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddress matches input" );
};

subtest "new_canonical creates correct object with quoted local part" => sub {
    my $domain = Value::Object::EmailAddress->new_canonical( '"g@wadej"@cpan.org' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, '"g@wadej"@cpan.org', "EmailAddress matches input" );
};

subtest "Create canonicallized object from uppercased domain" => sub {
    my $domain = Value::Object::EmailAddress->new_canonical( 'gwadej@CPAN.ORG' );
    isa_ok( $domain, 'Value::Object::EmailAddress' );
    is( $domain->value, 'gwadej@cpan.org', "EmailAddress canonicalized" );
};

