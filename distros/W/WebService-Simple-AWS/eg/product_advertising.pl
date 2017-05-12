use strict;
use warnings;
use WebService::Simple::AWS;

my $service = WebService::Simple::AWS->new(
    base_url => 'http://webservices.amazon.com/onca/xml',
    params   => {
        Version => '2009-03-31',
        Service => 'AWSECommerceService',
        id      => $ENV{'AWS_ACCESS_KEY_ID'},
        secret  => $ENV{'AWS_ACCESS_KEY_SECRET'},
    },
    debug => 1,
);

my $res = $service->get(
    {
        Operation     => 'ItemLookup',
        ItemId        => '0596000278', # Larry's book
        ResponseGroup => 'ItemAttributes',
    }
);
my $ref = $res->parse_response();
print "$ref->{Items}{Item}{ItemAttributes}{Title}\n";
#xxx
