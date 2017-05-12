package IMS::CP::File;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'href' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "href",
     node_type => "attribute",
     Name => "href",
     NamespaceURI => "",
     sort_order => 0,
 },
);

no Moose;
1;
__END__
