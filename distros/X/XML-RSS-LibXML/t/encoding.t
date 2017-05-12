# $Id: encoding.t,v 1.2 2004/04/21 02:44:40 kellan Exp $

use Test::More tests => 18;

$|++;

use XML::RSS::LibXML;

my @versions = qw( 0.9 0.91 1.0 );

foreach my $version ( @versions )
	{
	# default
	my $rss = XML::RSS::LibXML->new( version => $version );
	isa_ok( $rss, 'XML::RSS::LibXML' );
	make_rss( $rss );
	like( $rss->as_string, qr/^<\?xml version="1.0" encoding="UTF-8"\?>/,
		"Default encoding for version $version" );
		
	# UTF-8
	$rss = XML::RSS::LibXML->new( version => $version,
		encoding => 'UTF-8' );
	isa_ok( $rss, 'XML::RSS::LibXML' );
	make_rss( $rss );
	like( $rss->as_string, qr/^<\?xml version="1.0" encoding="UTF-8"\?>/,
		"Default encoding for version $version" );
	
	# home brew
    # XXX - XML::LibXML is picky about the encoding, so we can't
    # just use 'Fooey'. Instead we use some commonly found encoding
	$rss = XML::RSS::LibXML->new( version => $version,
		encoding => 'EUC-JP' );
	isa_ok( $rss, 'XML::RSS::LibXML' );
	make_rss( $rss );
	like( $rss->as_string, qr/^<\?xml version="1.0" encoding="EUC-JP"\?>/,
		"Default encoding for version $version" );
	}
	
sub make_rss
	{
	my $rss = shift;
	
	$rss->channel(
		title => 'Test RSS',
		link  => 'http://www.example.com',
		);
		
	}
