package W3C::XHTML::object;
use Moose;
use MooseX::AttributeHelpers;

has 'classid' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "classid",
     node_type => "attribute",
     Name => "classid",
     NamespaceURI => "",
     sort_order => 0,
 },
);
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
     sort_order => 1,
 },
);

no Moose;
1;
__END__
