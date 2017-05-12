#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

my $logic_boxes = create_api();
my $customer    = create_customer();

subtest 'Delete Contact That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->delete_contact_by_id( 999999999 );
    } qr/You are not allowed to perform this action/, 'Throws deleting contact that does not exist';
};

subtest 'Delete Contact That is In Use On a Domain' => sub {
    my $contact = create_contact( customer_id => $customer->id );
    my $domain  = create_domain(
        customer_id           => $customer->id,
        registrant_contact_id => $contact->id,
        admin_contact_id      => $contact->id,
        technical_contact_id  => $contact->id,
        billing_contact_id    => $contact->id,
    );

    throws_ok {
        $logic_boxes->delete_contact_by_id( $contact->id );
    } qr/Cannot Delete Contact/, 'Throws deleting contact that is in use';
};

subtest 'Delete Contact' => sub {
    my $contact = create_contact( customer_id => $customer->id );

    lives_ok{
        $logic_boxes->delete_contact_by_id( $contact->id );
    } 'Lives through deleting contact';

    my $retrieved_contact = $logic_boxes->get_contact_by_id( $contact->id );

    ok( !defined $retrieved_contact, 'Contact was deleted' );
};

done_testing;
