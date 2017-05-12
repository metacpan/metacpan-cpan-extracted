package W3C::MathML::math;
use Moose;
use MooseX::AttributeHelpers;

has 'mfrac_collection' => (
     isa         => 'ArrayRef[W3C::MathML::mfrac]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'mfrac' },
     description => {
         sort_order => 0,
     },
);
has 'xmlns' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "xmlns",
     node_type => "attribute",
     Name => "xmlns",
     NamespaceURI => "",
     sort_order => 1,
 },
);

no Moose;
1;
__END__
