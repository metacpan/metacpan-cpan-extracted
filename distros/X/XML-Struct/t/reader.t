use strict;
use Test::More;
use XML::Struct qw(readXML);

my ($data, $reader, $stream);

$stream = XML::LibXML::Reader->new( string => "<root> </root>" );
$reader = XML::Struct::Reader->new;
is_deeply $reader->read( $stream ), [ 'root', {}, [] ], 'skip whitespace';

$stream = XML::LibXML::Reader->new( string => "<root> </root>" );
$reader = XML::Struct::Reader->new( whitespace => 1 );
is_deeply $reader->read( $stream ), [ 'root' => { }, [' '] ], 'whitespace';

my $xml = <<'XML';
<root x:a="A" b="B" xmlns:x="http://example.org/">
  <x:foo>t&#x65;xt</x:foo>
  <bar key="value">
    text
    <doz/><![CDATA[xx]]></bar>
</root>
XML

$data = readXML($xml);

is_deeply $data, [
      'root', {
        'b' => 'B',
        'xmlns:x' => 'http://example.org/',
        'x:a' => 'A'
      }, [
        [
          'x:foo', { },
          [ 'text' ]
        ],
        [
          'bar', { 'key' => 'value' },
          [
            "\n    text\n    ",
            [ 'doz', {}, [] ],
            "xx"
          ]
        ]
      ]
    ], 'readXML';

$data = readXML( $xml, ns => 'strip' );
is_deeply $data->[1], { a => 'A', b => 'B' }, 'strip attribute namespaces';
is_deeply $data->[2]->[0]->[0], 'foo', 'strip element namespaces';

eval { readXML( $xml, ns => 'disallow' ) };
like $@, qr{namespaces not allowed (at line \d+ )?at t/reader\.t}, 'disallow namespaces';

$data = readXML( '<x xmlns="http://example.org/"/>', ns => 'strip' );
is_deeply $data, ['x',{},[]], 'strip default namespace declaration';

eval { readXML( '<x xmlns="http://example.org/"/>', ns => 'disallow' ) };
like $@, qr{namespaces not allowed}, 'disallow namespaces attributes';

is_deeply readXML( 't/nested.xml', attributes => 0, ns => 'disallow' ), 
    [ nested => [
      [ items => [ [ a => ["X"] ] ] ],
      [ "foo" => [ [ "bar" ] ] ],
      [ items => [
        [ "b" ],
        [ a => ["Y"] ], 
      ] ]
    ] ], 'without attributes';

$xml = <<'XML';
<!DOCTYPE doc [
    <!ELEMENT doc EMPTY>
    <!ATTLIST doc attr CDATA "42">
]><doc/>
XML

# FIXME: current reader does not respect DTD
$xml = '<doc attr="42"/>';

is_deeply readXML( $xml, simple => 1 ),
    { attr => 42 }, 'mixed attributes';
is_deeply readXML( $xml, simple => 1, root => 1 ),
    { doc => { attr => 42 } }, 'mixed attributes';

is_deeply readXML( 't/flat.xml', simple => 1, root => 1, attributes => 0 ),
    { doc => { id => [1,2,4], xx => 3 } }, 
    'simple with root and without attributes';

my @nodes = readXML( 't/flat.xml', path => '/doc/id', simple => 1, root => 'xx' );
is_deeply \@nodes, [ { xx => 1 }, { xx => 2 }, { xx => 4 } ], 'list of nodes';

my $first = readXML( 't/flat.xml', path => '/doc/id', simple => 1, root => 'xx' );
is_deeply $first, { xx => 1 }, 'first of a list of nodes';

@nodes = ();
$reader = XML::Struct::Reader->new( from => 't/flat.xml', simple => 1, root => 'n' );
push @nodes, $_ while $_ = $reader->readNext('/*/id');
is_deeply \@nodes, [ { n => 1 }, { n => 2 }, { n => 4 } ], 'read simple as loop';

# read from DOM
my $dom = XML::LibXML->load_xml( string => "<root><element/></root>" );
is_deeply readXML($dom), 
    [ root => { }, [ [ element => { }, [ ] ] ] ], 
    'read from XML::LibXML::Document';

is_deeply readXML($dom, simple => 1, root => 1),
    { root => { element => {} } },
    'empty tags in simple format'; 

is_deeply readXML($dom->documentElement),
    [ root => { }, [ [ element => { }, [ ] ] ] ], 
    'read from XML::LibXML::Element';

$dom = XML::LibXML->load_xml( string => "<root/>" );
is_deeply readXML( $dom, simple => 1, root => 1 ),
    { root => {} },
    'empty tag as root';

done_testing;
