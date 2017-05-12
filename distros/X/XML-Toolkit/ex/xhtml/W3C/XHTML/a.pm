package W3C::XHTML::a;
use Moose;
use MooseX::AttributeHelpers;

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
