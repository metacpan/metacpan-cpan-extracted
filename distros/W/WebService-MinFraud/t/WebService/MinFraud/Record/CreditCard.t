use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::CreditCard;

my %fixture = (
    brand                                => 'Visa',
    country                              => 'US',
    is_issued_in_billing_address_country => 1,
    is_prepaid                           => 1,
    is_virtual                           => 1,
    issuer                               => { name => 'Bank' },
    type                                 => 'credit',
);
my $cc = WebService::MinFraud::Record::CreditCard->new(%fixture);

is( $cc->brand,   $fixture{brand},   test_name('brand') );
is( $cc->country, $fixture{country}, test_name('country') );
is(
    $cc->is_issued_in_billing_address_country,
    $fixture{is_issued_in_billing_address_country},
    test_name('issued in billing country')
);
is( $cc->is_prepaid,   $fixture{is_prepaid},   test_name('is prepaid') );
is( $cc->is_virtual,   $fixture{is_virtual},   test_name('is virtual') );
is( $cc->issuer->name, $fixture{issuer}{name}, test_name('issuer name') );
is( $cc->type,         $fixture{type},         test_name('type') );

my $cc2 = WebService::MinFraud::Record::CreditCard->new(
    brand => 'Visa',
    type  => q{}
);
is( $cc2->type, q{}, 'credit card type empty' );

sub test_name {
    my $name = shift;
    return 'credit card ' . $name;
}

done_testing;
