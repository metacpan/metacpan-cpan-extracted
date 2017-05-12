use Test::More tests => 4;
use XML::RSS;
use File::Spec;

$|++;

my $file = File::Spec->catfile(File::Spec->curdir(), "t", "data", "1.0", "rss1.0.exotic.rdf");
my $rss = XML::RSS->new(encode_output => 1);

eval {
	$rss->parsefile( $file );
};



# Test 1.
# Support for feeds that use a default namespace other then RSS
#

unlike ($@, qr/invalid version/, "non-default namespace" );

# Test 2.
# Make sure modules are parsed and loaded
#
my $namespaces = {
	'rss' => 'http://purl.org/rss/1.0/',
	'dc' => 'http://purl.org/dc/elements/1.1/',
    'annotate' => 'http://purl.org/rss/1.0/modules/annotate/',
    'cp' => 'http://my.theinfo.org/changed/1.0/rss/',
    'admin' => 'http://webns.net/mvcb/',
	'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	'#default' => 'http://www.w3.org/1999/xhtml'
};

ok ( eq_hash( $rss->{namespaces}, $namespaces ),
	"modules and namespaces" );

# Test 3.
# Make sure modules that use rdf:resource are being properly parsed
# in channel element
#
ok ($rss->{'channel'}->{'http://webns.net/mvcb/'}->{'errorReportsTo'} eq
	'mailto:admin@example.org',
	'parse rdf:resource on channel' );

# Test 4.
# rdf:resrouce properly parsed in item
#
ok ($rss->{'items'}->[0]->{'http://my.theinfo.org/changed/1.0/rss/'}->{'server'} eq
	"http://example.org/changedPage",
	'parse rdf:resource on item' );


