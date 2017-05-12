use strict;
use feature 'say';
use HTTP::Tiny;

my $xml = '<RateV4Request USERID="563THEGA4590" PASSWORD="415FT08PY842"><Revision>2</Revision><Package ID="AC92D646-75D8-11E5-B1F9-E7A2AA3E4BB4"><Service>all</Service><ZipOrigination>53716</ZipOrigination><ZipDestination>32309</ZipDestination><Pounds>1</Pounds><Ounces>0</Ounces><Container></Container><Size>Regular</Size><Width>6</Width><Length>12</Length><Height>12</Height><Girth>69</Girth><Machinable>False</Machinable></Package></RateV4Request>';


my $http = HTTP::Tiny->new;
my $uri = 'http://production.shippingapis.com/ShippingAPI.dll';
#$uri = 'http://testing.shippingapis.com/ShippingAPItest.dll';
my $response = $http->post_form($uri, {
    API     => 'RateV4',
    XML     => $xml,
    }, {
    headers => {
        Content_Type        => 'application/x-www-form-urlencoded',
    },
});

say $response->{content};
