#use Test::More qw( no_plan);
use Test::More tests=>5;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn::Attributes';
    use_ok 'XML::Handler::ExtOn::Context';
}
my $sax2_attr = {
    '{}attr' => {
        'LocalName'    => 'attr',
        'Prefix'       => undef,
        'Value'        => '1',
        'Name'         => 'attr',
        'NamespaceURI' => undef
    },
    '{}xmlns' => {
        'LocalName'    => 'xmlns',
        'Prefix'       => undef,
        'Value'        => 'http://test.com/defaultns',
        'Name'         => 'xmlns',
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

};
my $context1 = new XML::Handler::ExtOn::Context::;
my $elem1    = new XML::Handler::ExtOn::Attributes::
  context => $context1,
  sax2    => $sax2_attr;
#diag Dumper $elem1->_a_stack; exit;
is_deeply $elem1->_a_stack,  [
          {
            'Prefix' => 'xmlns',
            'LocalName' => 'nodef',
            'Value' => 'http://zag.ru',
            'Name' => 'xmlns:nodef',
            'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
          },
          {
            'Prefix' => undef,
            'LocalName' => 'attr',
            'Value' => '1',
            'Name' => 'attr',
            'NamespaceURI' => 'http://test.com/defaultns'
          },
          {
            'Prefix' => 'xlink',
            'LocalName' => 'xtest',
            'Value' => '1',
            'Name' => 'xlink:xtest',
            'NamespaceURI' => 'http://www.w3.org/1999/xlink'
          },
          {
            'Prefix' => undef,
            'LocalName' => 'xmlns',
            'Value' => 'http://test.com/defaultns',
            'Name' => 'xmlns',
            'NamespaceURI' => undef
          },
          {
            'Prefix' => 'xmlns',
            'LocalName' => 'xlink',
            'Value' => 'http://www.w3.org/1999/xlink',
            'Name' => 'xmlns:xlink',
            'NamespaceURI' => 'http://www.w3.org/2000/xmlns/'
          }
        ],'check a_stack';
is_deeply $context1->get_map,  {
          '' => 'http://test.com/defaultns',
          'nodef' => 'http://zag.ru',
          'xlink' => 'http://www.w3.org/1999/xlink',
          'xmlns' => 'http://www.w3.org/2000/xmlns/'
        }, 'check registered ns';

is_deeply $elem1->to_sax2, $sax2_attr, 'check export to sax2';
