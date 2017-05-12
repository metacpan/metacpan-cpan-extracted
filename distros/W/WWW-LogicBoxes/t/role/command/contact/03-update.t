#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes qw( create_api );

use WWW::LogicBoxes::Role::Command::Contact;

use Readonly;
Readonly my $UPDATE_CONTACT_OBSOLETE => $WWW::LogicBoxes::Role::Command::Contact::UPDATE_CONTACT_OBSOLETE;

my $logic_boxes = create_api();

subtest 'Updating a Contact Is Now Obsolete' => sub {
    my $updated_contact = WWW::LogicBoxes::Contact->new(
        id           => 42,
        name         => 'Nico Habermann',
        company      => 'Free University of Amsterdam',
        email        => 'test-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com',
        address1     => 'Computer Science Building',
        city         => 'Amsterdam',
        state        => 'North Holland',
        country      => 'NL',
        zipcode      => '78713',
        phone_number => '+31205989898 ',
        customer_id  => 2600,
    );

    throws_ok {
        $logic_boxes->update_contact( contact => $updated_contact );
    } qr/\Q$UPDATE_CONTACT_OBSOLETE/, 'Throws on trying to update contact';
};

done_testing;
