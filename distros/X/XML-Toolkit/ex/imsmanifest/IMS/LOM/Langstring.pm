package IMS::LOM::Langstring;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'lang' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "xml",
     LocalName => "lang",
     node_type => "attribute",
     Name => "xml:lang",
     NamespaceURI => "http://www.w3.org/XML/1998/namespace",
     sort_order => 0,
 },
);
has 'text' => (
     isa         => 'Str',
     is          => 'rw',
     traits      => [ 'XML' ],
  description => {
     sort_order => 1,
 },
);

no Moose;
1;
__END__
