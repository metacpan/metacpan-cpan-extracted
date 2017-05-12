use strict;
use LWP::UserAgent;
use WebService::Shippo;

# If it hasn't already done outside of the script, you
# must set your API key...
Shippo->api_key( 'PASTE YOUR PRIVATE AUTH TOKEN HERE' )
    unless Shippo->api_key;

my $customs_item = {
    description    => 'T-Shirt',
    quantity       => '2',
    net_weight     => '1',
    mass_unit      => 'lb',
    value_amount   => '20',
    value_currency => 'USD',
    origin_country => 'US'
};

my $customs_declaration = Shippo::CustomsDeclaration->create(
    contents_type        => 'MERCHANDISE',
    contents_explanation => 'T-Shirt purchase',
    non_delivery_option  => 'RETURN',
    certify              => true,
    certify_signer       => 'Mr. Hippo',
    items                => [$customs_item]
);

print "Customs declaration:\n", $customs_declaration;

# Create a Shipment object...
my $shipment = Shippo::Shipment->create(
    {   object_purpose => 'PURCHASE',
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
            name           => 'George Hippo',
            company        => 'BBC',
            street1        => 'BBC Broadcasting House',
            street2        => 'Portland Place',
            city           => 'London',
            state          => '',
            zip            => 'W1A 1AA',
            country        => 'GB',
            phone          => '+44 370 123 5813',
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
        customs_declaration => $customs_declaration,
    }
);

print "Shipment details:\n", $shipment;

# Retrieve shipping rates...
my $rates = Shippo::Shipment->get_shipping_rates( $shipment->object_id );

print "Shipping rates:\n", $rates;

# Get the preferred rate from your list of rates...
my $rate = $rates->item( 2 );

# Purchase the desired rate...
my $transaction = Shippo::Transaction->create(
    {   rate            => $rate->object_id,
        label_file_type => 'PDF',
    }
);

# Get the shipping label...
my $label_url = Shippo::Transaction->get_shipping_label( $transaction->object_id );
my $browser = LWP::UserAgent->new;
$browser->get( $label_url, ':content_file' => './int_sample.pdf' );

# Refresh and view the transaction object...
print "Transaction:\n", $transaction->refresh;
