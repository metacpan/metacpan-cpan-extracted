#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );
use Test::WWW::eNom::Domain qw( create_domain create_transfer $UNREGISTERED_DOMAIN );

subtest 'Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->get_transfer_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/No transfer found for specified domain name/, 'Throws on unregistered domain';
};


subtest 'Domain Registered ( Never a Transfer )' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    throws_ok {
        $api->get_transfer_by_name( $domain->name );
    } qr/No transfer found for specified domain name/, 'Throws on domain registration';
};

subtest 'Transfer' => sub {
    my $api = create_api();
    my $transfer = create_transfer();

    my $transfers;
    lives_ok {
        $transfers = $api->get_transfer_by_name( $transfer->name );
    } 'Lives through retrieving transfer';

    cmp_ok( scalar @{ $transfers }, '==', 1, 'Correct number of transfer records' );
    isa_ok( $transfers->[0], 'WWW::eNom::DomainTransfer' );
    is_deeply( $transfers->[0], $transfer, 'Correct transfer information' );
};

# The response on this is the same 'No transfer found for...' error but finding
# a domain I can use here that will never have an actual transfer for it
# is problematic.
#subtest 'Domain Registered To Someone Else' => sub {
done_testing;
