#use Test::More qw( no_plan);
use Test::More tests=>11;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn::TieAttrs';
    use_ok 'XML::Handler::ExtOn::Context';
    use_ok 'XML::Handler::ExtOn::Element';
}
my $t1_element = {
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

my $context1 = new XML::Handler::ExtOn::Context::;
my $element1 = new XML::Handler::ExtOn::Element::
  context => $context1,
  sax2    => $t1_element;
isa_ok $element1->attributes, 'XML::Handler::ExtOn::Attributes',
  '$element1->attributes';
my $stack = $element1->attributes->_a_stack;
is_deeply $stack,
  [
    {
        'LocalName'    => 'attr',
        'Prefix'       => 'xlink',
        'Value'        => '1',
        'Name'         => 'xlink:attr',
        'NamespaceURI' => 'http://www.w3.org/1999/xlink'
    },
    {
        'LocalName'    => 'defaulttest',
        'Prefix'       => undef,
        'Value'        => '1',
        'Name'         => 'defaulttest',
        'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
    }
  ],
  'check stack content';
my %attr_by_name = ();
my $obj = tie %attr_by_name, 'XML::Handler::ExtOn::TieAttrs', $stack,
  by       => 'Prefix',
  value    => 'xlink',
  template => {
    Value        => '',
    NamespaceURI => 'http://www.w3.org/1999/xlink',
    Name         => '',
    LocalName    => '',
    Prefix       => ''
  };

is_deeply \%attr_by_name, { 'attr' => '1' }, 'check \%attr_by_name';
$attr_by_name{attr2} = 3;
is_deeply \%attr_by_name,
  {
    'attr'  => '1',
    'attr2' => 3
  },
  'check $attr_by_name{attr2} =3';
$attr_by_name{attr3} = 3;
delete $attr_by_name{attr2};
is_deeply $obj->_orig_hash,
  [
    {
        'LocalName'    => 'attr',
        'Prefix'       => 'xlink',
        'Value'        => '1',
        'Name'         => 'xlink:attr',
        'NamespaceURI' => 'http://www.w3.org/1999/xlink'
    },
    {
        'LocalName'    => 'defaulttest',
        'Prefix'       => undef,
        'Value'        => '1',
        'Name'         => 'defaulttest',
        'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
    },
    {
        'Prefix'       => 'xlink',
        'LocalName'    => 'attr3',
        'Value'        => 3,
        'Name'         => 'xlink:attr3',
        'NamespaceURI' => 'http://www.w3.org/1999/xlink'
    }
  ],
  'check  $attr_by_name{attr3} =3;delete $attr_by_name{attr2}';

my %attr_by_name1 = ();
my $obj1 = tie %attr_by_name1, 'XML::Handler::ExtOn::TieAttrs', $stack,
  by       => 'NamespaceURI',
  value    => 'http://www.w3.org/2000/xmlns/',
  template => {
    Value        => '',
    NamespaceURI => '',
    Name         => '',
    LocalName    => '',
    Prefix       => ''
  };

@attr_by_name1{qw/ 123 124/} = ( 1, 3 );
is_deeply \%attr_by_name1,
  {
    '123'         => 1,
    '124'         => 3,
    'defaulttest' => '1'
  },
  'check @attr_by_name1{qw/ 123 124/ } = (1,3);';

%attr_by_name1 = ();
is_deeply \%attr_by_name1, {}, 'check %attr_by_name1 = ();';
is_deeply $obj->_orig_hash,
  [
    {
        'LocalName'    => 'attr',
        'Prefix'       => 'xlink',
        'Value'        => '1',
        'Name'         => 'xlink:attr',
        'NamespaceURI' => 'http://www.w3.org/1999/xlink'
    },
    {
        'Prefix'       => 'xlink',
        'LocalName'    => 'attr3',
        'Value'        => 3,
        'Name'         => 'xlink:attr3',
        'NamespaceURI' => 'http://www.w3.org/1999/xlink'
    }
  ],
  'check $obj->_orig_hash';

