package W3C::XHTML::script;
use Moose;
use MooseX::AttributeHelpers;

has 'src' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "src",
     node_type => "attribute",
     Name => "src",
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
has 'type' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "type",
     node_type => "attribute",
     Name => "type",
     NamespaceURI => "",
     sort_order => 2,
 },
);

no Moose;
1;
__END__
