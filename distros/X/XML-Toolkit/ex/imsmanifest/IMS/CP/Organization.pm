package IMS::CP::Organization;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'identifier' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "identifier",
     node_type => "attribute",
     Name => "identifier",
     NamespaceURI => "",
     sort_order => 0,
 },
);
has 'item_collection' => (
     isa         => 'ArrayRef[IMS::CP::Item]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'item' },
     description => {
         sort_order => 1,
     },
);
has 'metadata_collection' => (
     isa         => 'ArrayRef[IMS::CP::Metadata]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'metadata' },
     description => {
         sort_order => 2,
     },
);
has 'title_collection' => (
     isa         => 'ArrayRef[IMS::CP::Title]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'title' },
     description => {
         sort_order => 3,
     },
);

no Moose;
1;
__END__
