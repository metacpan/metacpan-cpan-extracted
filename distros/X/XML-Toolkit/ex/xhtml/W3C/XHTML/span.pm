package W3C::XHTML::span;
use Moose;
use MooseX::AttributeHelpers;

has 'id' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "id",
     node_type => "attribute",
     Name => "id",
     NamespaceURI => "",
     sort_order => 0,
 },
);

no Moose;
1;
__END__
