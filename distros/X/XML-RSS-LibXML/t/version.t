# $Id: version.t,v 1.2 2004/04/21 02:44:40 kellan Exp $

use Test::More tests => 6;

$|++;

use XML::RSS::LibXML;

{
my $rss = XML::RSS::LibXML->new( version => '0.9' );
# TEST
isa_ok( $rss, 'XML::RSS::LibXML' );
make_rss( $rss );
# TEST
like( $rss->as_string, 
	qr|<rdf:RDF[\d\D]+xmlns="http://my.netscape.com/rdf/simple/0.9/"[^>]*>|,
	"rdf tag for version 0.9" );

$rss = XML::RSS::LibXML->new( version => '0.91' );
# TEST
isa_ok( $rss, 'XML::RSS::LibXML' );
make_rss( $rss );
# TEST
like( $rss->as_string, qr/<rss version="0.91">/,
	"rss tag for version 0.91" );

$rss = XML::RSS::LibXML->new( version => '1.0' );
# TEST
isa_ok( $rss, 'XML::RSS::LibXML' );

make_rss( $rss );

# TEST
like( $rss->as_string, 
	qr|<rdf:RDF[\d\D]+xmlns="http://purl.org/rss/1.0/"[^>]*>|,
	"rdf tag for version 1.0" );
}

sub make_rss
{
    my $rss = shift;

    $rss->channel(
        title => 'Test RSS',
        link  => 'http://www.example.com',
        );
        
}

