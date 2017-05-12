package W3C::SVG::svg;
use Moose;
use MooseX::AttributeHelpers;

has 'circle_collection' => (
     isa         => 'ArrayRef[W3C::SVG::circle]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'circle' },
     description => {
         sort_order => 0,
     },
);
has 'height' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "height",
     node_type => "attribute",
     Name => "height",
     NamespaceURI => "",
     sort_order => 1,
 },
);
has 'width' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "width",
     node_type => "attribute",
     Name => "width",
     NamespaceURI => "",
     sort_order => 2,
 },
);

no Moose;
1;
__END__
