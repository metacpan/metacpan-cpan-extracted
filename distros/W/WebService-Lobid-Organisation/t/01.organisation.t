use Test::More tests => 7;

use utf8;

use lib "../lib";

BEGIN {
use_ok( 'WebService::Lobid::Organisation' );
}

my $O = WebService::Lobid::Organisation->new(isil=>'DE-380');
is($O->api_url,'https://lobid.org/', "API-URL found");
is($O->found,'true', "ISIL found");
is($O->name,'Stadtbibliothek Köln',"Name found");
is($O->url,'http://www.stbib-koeln.de/', "URL found");
is($O->has_provides,1, "service found");

$O = WebService::Lobid::Organisation->new(isil=>'foo');
is($O->found,'false', "ISIL 'foo' not found");

