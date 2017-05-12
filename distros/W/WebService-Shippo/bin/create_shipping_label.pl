use strict;
use LWP::UserAgent;
use WebService::Shippo;

# If it hasn't already done outside of the script, you
# must set your API key...
Shippo->api_key( 'PASTE YOUR PRIVATE AUTH TOKEN HERE' )
    unless Shippo->api_key;

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
        }
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
        label_file_type => 'PNG',
    }
);

# Get the shipping label...
my $label_url
    = Shippo::Transaction->get_shipping_label( $transaction->object_id );
my $browser = LWP::UserAgent->new;
$browser->get( $label_url, ':content_file' => './sample.png' );

# Refresh and view the transaction object...
print "Transaction:\n", $transaction;
