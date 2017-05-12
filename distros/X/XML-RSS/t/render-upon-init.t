use strict;
use warnings;

use Test::More tests => 3;

use XML::RSS;

{
my $rss = XML::RSS->new( version => '0.9' );
# TEST
like( $rss->as_string,
	qr|<rdf:RDF[\d\D]+xmlns="http://my.netscape.com/rdf/simple/0.9/"[^>]*>|,
	"rdf tag for version 0.9" );

$rss = XML::RSS->new( version => '0.91' );
# TEST
like( $rss->as_string, qr/<rss version="0.91">/,
	"rss tag for version 0.91" );

$rss = XML::RSS->new( version => '1.0' );

# TEST
like( $rss->as_string,
	qr|<rdf:RDF[\d\D]+xmlns="http://purl.org/rss/1.0/"[^>]*>|,
	"rdf tag for version 1.0" );
}

