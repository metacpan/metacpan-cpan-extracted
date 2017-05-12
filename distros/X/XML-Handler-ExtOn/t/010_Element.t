#use Test::More qw( no_plan);
use Test::More tests=>11;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn::TieAttrs';
    use_ok 'XML::Handler::ExtOn::Element';
    use_ok 'XML::Handler::ExtOn::Context';
}

=pod
<?xml version="1.0"?>
<Document xmlnsw="http://test.com/defaultns" xmlns:nodef='http://zag.ru' xmlns:xlink='http://www.w3.org/1999/xlink'>
    <nodef:p xlink:xtest="1" attr="1">test</nodef:p>
    <p defaulttest="1" xlink:attr="1">test</p>
</Document>

=cut

my $ns1     = new XML::Handler::ExtOn::Context::;
my $context = $ns1;
my $t1_elemnt = {
    'Prefix'     => undef,
    'LocalName'  => 'p',
    'Attributes' => {
        '{http://www.w3.org/1999/xlink}attr' => {
            'LocalName'    => 'attr',
            'Prefix'       => 'xlink',
            'Value'        => '1',
            'Name'         => 'xlink:attr',
            'NamespaceURI' => 'http://www.w3.org/1999/xlink'
        },
        '{}defaulttest' => {
            'LocalName'    => 'defaulttest',
            'Prefix'       => undef,
            'Value'        => '1',
            'Name'         => 'defaulttest',
            'NamespaceURI' => undef
        }
    },
    'Name'         => 'p',
    'NamespaceURI' => undef
};
my ( $prefix1, $uri1 ) = ( 'xlink', 'http://www.w3.org/1999/xlink' );
$ns1->declare_prefix( $prefix1, $uri1 );
$ns1->declare_prefix( 'test', 'http://www.w3.org/TR/REC-html40' );
my $element = new XML::Handler::ExtOn::Element::
  name    => "p",
  context => $context,
  sax2    => $t1_elemnt;
ok my $ref_by_pref = $element->attrs_by_prefix($prefix1),
  "get attr by prefix: $prefix1";
$ref_by_pref->{test} = 1;
ok my $ref_by_uri = $element->attrs_by_ns_uri($uri1), "get attr by uri: $uri1";

#diag Dumper($ref_by_pref, $ref_by_uri);
is_deeply $ref_by_pref, $ref_by_uri, 'check by pref and by uri';

#diag Dumper ( (tied %{$ref_by_pref} )->_orig_hash );
#test import - export
my $t2_element = {
    'Prefix'     => 'nodef',
    'LocalName'  => 'p',
    'Attributes' => {
        '{}attr' => {
            'LocalName'    => 'attr',
            'Prefix'       => undef,
            'Value'        => '1',
            'Name'         => 'attr',
            'NamespaceURI' => undef
        },
        '{http://www.w3.org/2000/xmlns/}xlink' => {
            'LocalName'    => 'xlink',
            'Prefix'       => 'xmlns',
            'Value'        => 'http://www.w3.org/1999/xlink',
            'Name'         => 'xmlns:xlink',
            'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
        },
        '{http://www.w3.org/1999/xlink}xtest' => {
            'LocalName'    => 'xtest',
            'Prefix'       => 'xlink',
            'Value'        => '1',
            'Name'         => 'xlink:xtest',
            'NamespaceURI' => 'http://www.w3.org/1999/xlink'
        },
        '{http://www.w3.org/2000/xmlns/}nodef' => {
            'LocalName'    => 'nodef',
            'Prefix'       => 'xmlns',
            'Value'        => 'http://zag.ru',
            'Name'         => 'xmlns:nodef',
            'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
        },

    },
    'Name'         => 'nodef:p',
    'NamespaceURI' => 'http://zag.ru'
};
my $context2 = new XML::Handler::ExtOn::Context::;
my $element2 = new XML::Handler::ExtOn::Element::
  context => $context2,
  sax2    => $t2_element;

ok my $by_name = $element2->attributes->by_name, 'get by_name';
isa_ok my $obj = tied %{$by_name} , 'XML::Handler::ExtOn::TieAttrsName', 'by_name';
is_deeply $by_name,
  {
    'attr'        => '1',
    'xlink:xtest' => '1',
    'xmlns:nodef' => 'http://zag.ru',
    'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
  },
  'check by name';
$by_name->{test}  = 1 ;
is_deeply $by_name,
 {
           'attr' => '1',
           'test' => 1,
           'xlink:xtest' => '1',
           'xmlns:nodef' => 'http://zag.ru',
           'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
         },
  'check create attr';
delete $by_name->{test};
is_deeply $by_name,
 {
           'attr' => '1',
           'xlink:xtest' => '1',
           'xmlns:nodef' => 'http://zag.ru',
           'xmlns:xlink' => 'http://www.w3.org/1999/xlink'
         },
  'check delete attr';

