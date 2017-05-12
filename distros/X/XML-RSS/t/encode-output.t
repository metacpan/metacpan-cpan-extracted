# $Id: encode-output.t,v 1.2 2003/01/18 01:11:33 comdog Exp $
use Test::More tests => 1;

use XML::RSS;
use File::Spec;

$|++;

my $file = File::Spec->catfile(File::Spec->curdir(), "t", "data", "1.0", "rss1.0.exotic.rdf");
my $rss = XML::RSS->new(encode_output => 1);

eval {
	$rss->parsefile( $file );
};


# Test 5.
# Encode illegal characters (e.g. &) when outputting RSS
#
my $rss_str = $rss->as_string();
my $rss2 = XML::RSS->new();
eval {
	$rss2->parse( $rss_str );
};

unlike ($@, qr/invalid token/, "encode invalid characters" );
