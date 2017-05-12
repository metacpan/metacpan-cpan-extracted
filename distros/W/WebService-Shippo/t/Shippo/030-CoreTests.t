# Not the greatest tests in the world, but more like a starter 
# for 10 influenced by tests of similar calibre (where present)
# in Shippo's own APIs. I want to re-visit these after the first
# gold release to make them more extensive.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";
use TestHarness;
use WebService::Shippo;

my @objects_under_test = (
    'Address' => {
        create_default_item => \&default_address,
        class               => 'Shippo::Address',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
        more_tests => [
            testValidateAddress => sub {
                my $address   = stash->{item};
                my $object_id = $address->object_id;
                my $validated = Shippo::Address->validate( $object_id );
                ok( $validated->is_valid, __TEST__ );
            },
        ],
    },
    'CarrierAccount' => {
        create_default_item => \&default_carrier_account,
        class               => 'Shippo::CarrierAccount',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->carrier eq 'fedex';
        },
        more_tests => [
            testUpdate => sub {
                my $carrier_account = stash->{item};
                my $updated_account = Shippo::CarrierAccount->update(
                    $carrier_account->object_id,
                    active => false
                );
                is( $updated_account->active, false, __TEST__ );
                $updated_account->activate();
                is( $updated_account->active, true, __TEST__ );
                $updated_account->deactivate();
                is( $updated_account->active, false, __TEST__ );
                $updated_account->enable_test_mode();
                is( $updated_account->test, true, __TEST__ );
                $updated_account->enable_production_mode();
                is( $updated_account->test, false, __TEST__ );
            },
        ],
    },
    'CustomsItem' => {
        create_default_item => \&default_customs_item,
        class               => 'Shippo::CustomsItem',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
    },
    'CustomsDeclaration' => {
        create_default_item => \&default_customs_declaration,
        class               => 'Shippo::CustomsDeclaration',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
    },
    'Manifest' => {
        create_default_item => \&default_manifest,
        class               => 'Shippo::Manifest',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->object_status eq 'NOTRANSACTIONS';
        },
    },
    'Parcel' => {
        create_default_item => \&default_parcel,
        class               => 'Shippo::Parcel',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
    },
    'Rate' => {
        create_default_item => \&default_rate,
        class               => 'Shippo::Rate',
        skip            => [ 'testInvalidCreate', 'testFetch', 'testInvalidFetch' ],
        object_is_valid => sub {
            my ( $object ) = @_;
            return defined $object;
        },
    },
    'Shipment' => {
        create_default_item => \&default_shipment,
        class               => 'Shippo::Shipment',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
        skip       => ['testFetch'],
        more_tests => [
            testFetch => sub {
                my $object = stash->{list}{results}[0];
                my $id     = $object->{object_id};
                ok( defined( $id ), __TEST__ );
                my $item = Shippo::Shipment->fetch( $id );
                is( $object->id, $item->id, __TEST__ );
            },
            testRates => sub {
                my $rates = stash->{item}->get_shipping_rates(
                    stash->{item}->id,
                );
                ok( $rates->results, __TEST__ );
            },
            testRates => sub {
                my $rates = WebService::Shippo::Rate->get_shipping_rates(
                    stash->{item}->id, 'GBP',
                );
                ok( $rates->results, __TEST__ );
            },
        ],
    },
    'Transaction' => {
        create_default_item => \&default_transaction,
        class               => 'Shippo::Transaction',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->is_valid;
        },
    },
    'Refund' => {
        create_default_item => \&default_refund,
        class               => 'Shippo::Refund',
        object_is_valid     => sub {
            my ( $object ) = @_;
            return $object->object_status eq 'ERROR';
        },
    },
);

my @tests;

while ( @objects_under_test ) {
    my $test_group      = shift @objects_under_test;
    my $config          = shift @objects_under_test;
    my $class           = $config->{class};
    my $object_is_valid = $config->{object_is_valid};
    my $more_tests      = $config->{more_tests};
    my @skip_tests      = @{ $config->{skip} } if $config->{skip};
    push @tests, $test_group => [
        testValidCreate => sub {
            return if grep { /^testValidCreate$/ } @skip_tests;
            stash->{item} = $config->{create_default_item}->();
            my $item = stash->{item};
            ok( defined( $item ),            __TEST__ );
            ok( $object_is_valid->( $item ), __TEST__ );
        },
        testInvalidCreate => sub {
            return if grep { /^testInvalidCreate$/ } @skip_tests;
            eval { $class->create( invalid_data => 'invalid' ); };
            like( $@, qr/400 BAD REQUEST/i, __TEST__ );
        },
        testListFirstPage => sub {
            return if grep { /^testListAll$/ } @skip_tests;
            stash->{list} = $class->all( results => 3, page => 1 );
            my $list = stash->{list};
            ok( defined( $list->count ),   __TEST__ );
            ok( defined( $list->results ), __TEST__ );
        },
        testListPageSize => sub {
            return if grep { /^testListPageSize$/ } @skip_tests;
            my $page_size = 1;
            my $list = $class->all( results => $page_size, page => 1 );
            is( $list->page_size, $page_size, __TEST__ );
        },
        testFetch => sub {
            return if grep { /^testFetch$/ } @skip_tests;
            my $object = stash->{list}{results}[0];
            my $id     = $object->{object_id};
            ok( defined( $id ), __TEST__ );
            my $item = $class->fetch( $id );
            is_deeply( $object, $item, __TEST__ );
        },
        testInvalidFetch => sub {
            return if grep { /^testInvalidFetch$/ } @skip_tests;
            my $id = 'Invalid Object Identifier';
            eval { $class->fetch( $id ); };
            like( $@, qr/404 NOT FOUND/i, __TEST__ );
        },
        $more_tests ? @$more_tests : (),
    ];
} ## end while ( @objects_under_test)

sub default_address
{
    Shippo::Address->create(
        object_purpose => 'QUOTE',
        name           => 'John Smith',
        company        => 'Initech',
        street1        => 'Greene Rd.',
        street_no      => '6512',
        street2        => '',
        city           => 'Woodridge',
        state          => 'IL',
        zip            => '60517',
        country        => 'US',
        phone          => '123 353 2345',
        email          => 'jmercouris@iit.com',
        metadata       => 'Customer ID 234;234',
    );
}

sub default_carrier_account
{
    my ( $account_id ) = @_;
    $account_id = rand() unless $account_id;
    Shippo::CarrierAccount->create(
        carrier    => 'fedex',
        account_id => $account_id,
        active     => true,
        test       => true,
        parameters => { meter => '1234' },
    );
}

sub default_parcel
{
    Shippo::Parcel->create(
        length        => '5',
        width         => '5',
        height        => '5',
        distance_unit => 'cm',
        weight        => '2',
        mass_unit     => 'lb',
        template      => '',
        metadata      => 'Customer ID 123456',
    );
}

sub default_customs_item
{
    Shippo::CustomsItem->create(
        description    => 'T-Shirt',
        quantity       => '2',
        net_weight     => '400',
        mass_unit      => 'g',
        value_amount   => '20',
        value_currency => 'USD',
        tariff_number  => '',
        origin_country => 'US',
        metadata       => 'Order ID #123123',
    );
}

sub default_customs_declaration
{
    my $customs_item = default_customs_item();
    Shippo::CustomsDeclaration->create(
        exporter_reference   => '',
        importer_reference   => '',
        contents_type        => 'MERCHANDISE',
        contents_explanation => 'T-Shirt purchase',
        invoice              => '#123123',
        license              => '',
        certificate          => '',
        notes                => '',
        eel_pfc              => 'NOEEI_30_37_a',
        aes_itn              => '',
        non_delivery_option  => 'ABANDON',
        certify              => 'true',
        certify_signer       => 'Laura Behrens Wu',
        disclaimer           => '',
        incoterm             => '',
        items                => [ $customs_item->object_id ],
        metadata             => 'Order ID #123123',
    );
}

sub default_manifest
{
    my $address = default_address();
    Shippo::Manifest->create(
        provider        => 'USPS',
        submission_date => '2014-05-16T23:59:59Z',
        address_from    => $address->object_id,
    );
}

sub default_shipment
{
    my $address_from = default_address();
    my $address_to   = default_address();
    my $parcel       = default_parcel();
    Shippo::Shipment->create(
        object_purpose      => 'QUOTE',
        address_from        => $address_from->object_id,
        address_to          => $address_to->object_id,
        parcel              => $parcel->object_id,
        submission_type     => 'PICKUP',
        submission_date     => '2013-12-03T12:00:00.000Z',
        insurance_amount    => '30',
        insurance_currency  => 'USD',
        extra               => { signature_confirmation => true },
        customs_declaration => '',
        reference_1         => '',
        reference_2         => '',
        metadata            => 'Customer ID 123456',
    );
}

sub default_rate
{
    my $shipment = default_shipment();
    my $rates = WebService::Shippo::Shipment->get_shipping_rates( $shipment->id );
    return $rates;
}

sub default_transaction
{
    my $shipment = Shippo::Shipment->create(
        object_purpose => 'PURCHASE',
        address_from   => {
            object_purpose => 'PURCHASE',
            name           => 'Shawn Ippotle',
            company        => 'Shippo',
            street1        => '215 Clayton St.',
            city           => 'San Francisco',
            state          => 'CA',
            zip            => '94117',
            country        => 'US',
            phone          => '+1 555 341 9393',
            email          => 'shippotle@goshippo.com'
        },
        address_to => {
            object_purpose => 'PURCHASE',
            name           => 'Mr Hippo',
            company        => '',
            street1        => 'Broadway 1',
            street2        => '',
            city           => 'New York',
            state          => 'NY',
            zip            => '10007',
            country        => 'US',
            phone          => '+1 555 341 9393',
            email          => 'mrhippo@goshippo.com'
        },
        parcel => {
            length        => '5',
            width         => '5',
            height        => '5',
            distance_unit => 'in',
            weight        => '2',
            mass_unit     => 'lb'
        },
    );
    my $rates       = $shipment->get_shipping_rates( $shipment->id );
    my $rate        = $rates->item( 1 );
    my $transaction = Shippo::Transaction->create( rate => $rate->id );
    my $label_url1  = $transaction->get_shipping_label( $transaction->id );
    ok( $label_url1, __TEST__ );
    my $label_url2 = Shippo::Transaction->get_shipping_label( $transaction->id );
    ok( $label_url2, __TEST__ );
    is( $label_url1, $label_url2, __TEST__ );
    return $transaction;
}

sub default_refund
{
    my $refund = Shippo::Refund->create( transaction => default_transaction->id );
    return $refund;
}

SKIP: {
    skip '(no Shippo API key defined)', 1
        unless Shippo->api_key;
    TestHarness->run_tests( \@tests );
}

done_testing();
