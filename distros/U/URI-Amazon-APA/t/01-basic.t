#!perl -T
use strict;
use warnings;
use URI::Amazon::APA;
use Test::More tests => 1;

# http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html

my $u = URI::Amazon::APA->new('http://webservices.amazon.com/onca/xml');
$u->query(
    'AWSAccessKeyId=00000000000000000000&ItemId=0679722769&Operation=I'
    . 'temLookup&ResponseGroup=ItemAttributes%2COffers%2CImages%2CReview'
    . 's&Service=AWSECommerceService&Timestamp=2009-01-01T12%3A00%3A00Z&'
    . 'Version=2009-01-06' );
$u->sign(
    key    => '00000000000000000000',
    secret => '1234567890',
);
#warn $u;
#is ($u->signature, 'Nace/U3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg=');
is ($u->signature, 'Nace+U3Az4OhN7tISqgs1vdLBHBEijWcBeCqL5xN9xg=');
