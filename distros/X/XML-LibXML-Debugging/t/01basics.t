use Test::More tests => 3;
BEGIN { use_ok('XML::LibXML::Debugging') };

use XML::LibXML;

my $doc  = XML::LibXML::Document->new;
my $root = $doc->createElementNS('http://www.w3.org/1999/xhtml', 'html');
$doc->setDocumentElement($root);
$root->setAttribute('xml:lang', 'en-gb-oed');

is(
	$doc->toClarkML,
	'<{http://www.w3.org/1999/xhtml}html {http://www.w3.org/XML/1998/namespace}lang="en-gb-oed" {http://www.w3.org/2000/xmlns/}xmlns="http://www.w3.org/1999/xhtml"/>',
	"toClarkML seems to be working.");

my $correct = {
          'root' => {
                      'nsuri' => 'http://www.w3.org/1999/xhtml',
                      'suffix' => 'html',
                      'qname' => 'html',
                      'children' => [],
                      'type' => 'Element',
                      'attributes' => [
                                        {
                                          'value' => 'en-gb-oed',
                                          'nsuri' => 'http://www.w3.org/XML/1998/namespace',
                                          'suffix' => 'lang',
                                          'qname' => 'xml:lang',
                                          'type' => 'Attribute',
                                          'prefix' => 'xml'
                                        },
                                        {
                                          'value' => 'http://www.w3.org/1999/xhtml',
                                          'nsuri' => 'http://www.w3.org/2000/xmlns/',
                                          'suffix' => undef,
                                          'qname' => 'xmlns',
                                          'type' => 'Namespace Declaration',
                                          'prefix' => 'xmlns'
                                        }
                                      ],
                      'prefix' => undef
                    },
          'type' => 'Document'
        };

is_deeply($doc->toDebuggingHash, $correct, "toDebuggingHash seems to work.");
