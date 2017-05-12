use strict;
use warnings;
use List::Util qw(first);
use DateTime;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";
use Webservice::OVH;

my $csv_file = $ARGV[0];
die "The script expects a filepath to a csv file as first argument" unless $csv_file;

sub load_csv {

    my ($file) = @_;

    my $domain_list = {};

    open( my $fh, '<:encoding(UTF-8)', $file ) or die "Could not open file '$file' $!";

    while ( my $row = <$fh> ) {

        $row =~ s/\r\n//g;
        my @row = split( ',', $row );
        my $object = { area => $row[0], domain => $row[1], status => $row[2], auth => $row[3] };
        $domain_list->{ $row[1] } = $object;
    }

    close $fh;

    return $domain_list;
}

my $api = Webservice::OVH->new_from_json("../credentials.json");

my $domains = load_csv($csv_file);

my $cart = $api->order->new_cart( ovh_subsidiary => 'DE' );

foreach my $domain ( keys %$domains ) {

    if ( $domains->{$domain}{status} eq 'connect' && $domains->{$domain}{auth} ) {

        my $offers = $cart->offers_domain_transfer( $domains->{$domain}{domain} );

        my @offer     = grep { $_->{offer} eq 'gold' } @$offers;
        my $offer_id  = $offer[0]->{offerId};
        my $orderable = $offer[0]->{orderable};

        print STDERR $orderable;

        print STDERR $domain . "\n";
        $cart->add_transfer( $domains->{$domain}{domain}, offer_id => $offer_id, auth_info => $domains->{$domain}{auth} );
    }
}

my $checkout = $cart->info_checkout;

my $details = $checkout->{details};

print STDERR "Beschreibung,Domain,Anzahl,Preis (ohne Steuer)\n";

foreach my $detail (@$details) {

    print STDERR sprintf( "%s,%s,%s,%s\n", $detail->{description}, $detail->{domain}, $detail->{quantity}, $detail->{totalPrice}{text} );
}

print STDERR sprintf( "%s,%s,%s,%s,%s,%s\n", "", "", "", $checkout->{prices}{withoutTax}{text}, $checkout->{prices}{tax}{text}, $checkout->{prices}{withTax}{text} );

my $order = $cart->checkout;

my $means = $order->available_registered_payment_mean;

$order->pay_with_registered_payment_mean('fidelityAccount');

