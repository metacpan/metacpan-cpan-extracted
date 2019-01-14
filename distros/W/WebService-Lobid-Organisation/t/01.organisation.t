use Test::More tests =>   8;

use utf8;


BEGIN {
    use_ok('WebService::Lobid::Organisation');
}

my $O = WebService::Lobid::Organisation->new( isil => 'DE-380' );

if ( $O->use_ssl eq 'true' ) {
    is( $O->api_url, 'https://lobid.org/', "API-URL found (https)" );
}
else {
    is( $O->api_url, 'http://lobid.org/', "API-URL found (http)" );
}

is( $O->api_status,   'ok',                         "API is reachable" );
is( $O->found,        'true',                       "ISIL found" );
is( $O->name,         'Stadtbibliothek Köln',      "Name found" );
is( $O->url,          'http://www.stbib-koeln.de/', "URL found" );
is( $O->has_provides, 1,                            "service found" );

$O = WebService::Lobid::Organisation->new( isil => 'foo' );
is( $O->found, 'false', "ISIL 'foo' not found" );

