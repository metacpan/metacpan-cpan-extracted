use Test::More;
use strict;

unless ( $ENV{'AWS_ACCESS_KEY_ID'} && $ENV{'AWS_ACCESS_KEY_SECRET'} ){
    plan skip_all => 'AWS_ACCESS_KEY_ID and AWS_ACCESS_KEY_SECRET required for this testing';
}else{
    plan tests => 5;
}

use WebService::Simple::AWS;
my $service = WebService::Simple::AWS->new(
    base_url => 'http://webservices.amazon.com/onca/xml',
    params   => {
        Version => '2009-03-31',
        Service => 'AWSECommerceService',
        id      => $ENV{'AWS_ACCESS_KEY_ID'},
        secret  => $ENV{'AWS_ACCESS_KEY_SECRET'},
    },
);
ok( $service, 'Creating Instance' );
ok( $service->isa('WebService::Simple::AWS') , 'Is a WebService::Simple::AWS');

my $asin = '0596000278';
my $res = $service->get(
    {
        Operation     => 'ItemLookup',
        ItemId        => $asin,
        ResponseGroup => 'ItemAttributes',
    }
);

ok( $res->is_success, 'Response is success' );

my $ref = $res->parse_response();
ok( $ref, 'Parsing a response' );
is( $ref->{Items}{Item}{ASIN}, $asin, 'ASIN is currect' );
