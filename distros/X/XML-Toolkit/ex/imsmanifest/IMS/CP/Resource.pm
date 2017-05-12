package IMS::CP::Resource;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'file_collection' => (
     isa         => 'ArrayRef[IMS::CP::File]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'file' },
     description => {
         sort_order => 0,
     },
);
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
     sort_order => 1,
 },
);
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
     sort_order => 2,
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
         sort_order => 3,
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
     sort_order => 4,
 },
);

no Moose;
1;
__END__
