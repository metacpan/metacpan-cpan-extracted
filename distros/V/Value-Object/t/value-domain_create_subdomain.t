#!/usr/bin/env perl

use Test::More tests => 3;
use Test::Exception;

use strict;
use warnings;

use Value::Object::Domain;
use Value::Object::DomainLabel;

my $domain = Value::Object::Domain->new( 'example.com' );

subtest "Input validation" => sub {
    throws_ok { $domain->make_subdomain() } qr/Domain: undefined/, "Don't create if label undefined";
    throws_ok { $domain->make_subdomain( 'www' ) } qr/Domain: Not/, "Don't create if label is scalar";
    throws_ok { $domain->make_subdomain( [] ) } qr/Domain: Not/, "Don't create if label is wrong reference type";
};

subtest "Add a subdomain" => sub {
    my $label = Value::Object::DomainLabel->new( 'www' );
    my $subdom = $domain->make_subdomain( $label );
    isa_ok( $subdom, 'Value::Object::Domain' );
    is( $subdom->value, 'www.example.com', 'Correct subdomain' );
    is( $domain->value, 'example.com', 'Original not changed' );
};

subtest "Add a subdomain non-canonical" => sub {
    my $label = Value::Object::DomainLabel->new( 'WWW' );
    my $subdom = $domain->make_subdomain( $label );
    isa_ok( $subdom, 'Value::Object::Domain' );
    is( $subdom->value, 'WWW.example.com', 'Correct subdomain' );
    is( $domain->value, 'example.com', 'Original not changed' );
};
