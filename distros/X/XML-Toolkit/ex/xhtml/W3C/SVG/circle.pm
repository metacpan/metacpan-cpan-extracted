package W3C::SVG::circle;
use Moose;
use MooseX::AttributeHelpers;

has 'cx' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "cx",
     node_type => "attribute",
     Name => "cx",
     NamespaceURI => "",
     sort_order => 0,
 },
);
has 'cy' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "cy",
     node_type => "attribute",
     Name => "cy",
     NamespaceURI => "",
     sort_order => 1,
 },
);
has 'fill' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "fill",
     node_type => "attribute",
     Name => "fill",
     NamespaceURI => "",
     sort_order => 2,
 },
);
has 'r' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "r",
     node_type => "attribute",
     Name => "r",
     NamespaceURI => "",
     sort_order => 3,
 },
);
has 'text' => (
     isa         => 'Str',
     is          => 'rw',
     traits      => [ 'XML' ],
  description => {
     sort_order => 4,
 },
);

no Moose;
1;
__END__
