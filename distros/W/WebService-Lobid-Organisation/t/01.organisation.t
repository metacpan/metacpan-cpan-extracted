use Test::More tests => 9;

use utf8;

BEGIN {
use_ok( 'WebService::Lobid::Organisation' );
}

my $O = WebService::Lobid::Organisation->new(isil=>'DE-380');

is($O->api_url,'http://lobid.org/', "API-URL found");
is($O->found,'true', "ISIL found");
is($O->name,'Stadtbibliothek Köln',"Name found");
is($O->url,'http://www.stbib-koeln.de/', "URL found");
isa_ok($O->url,"URI","url");
is($O->wikipedia,'http://de.wikipedia.org/wiki/Stadtbibliothek_K%C3%B6ln',"Wikipedia Page found");
isa_ok($O->wikipedia,"URI","wikipedia page");
$O = WebService::Lobid::Organisation->new(isil=>'foo');
is($O->found,'false', "ISIL 'foo' not found");

