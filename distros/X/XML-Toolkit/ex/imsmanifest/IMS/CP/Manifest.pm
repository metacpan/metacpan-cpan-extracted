package IMS::CP::Manifest;
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
has 'imsmd' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "xmlns",
     LocalName => "imsmd",
     node_type => "attribute",
     Name => "xmlns:imsmd",
     NamespaceURI => "http://www.w3.org/2000/xmlns/",
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
has 'organizations_collection' => (
     isa         => 'ArrayRef[IMS::CP::Organizations]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'organizations' },
     description => {
         sort_order => 3,
     },
);
has 'resources_collection' => (
     isa         => 'ArrayRef[IMS::CP::Resources]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'resources' },
     description => {
         sort_order => 4,
     },
);
has 'schemaLocation' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "xsi",
     LocalName => "schemaLocation",
     node_type => "attribute",
     Name => "xsi:schemaLocation",
     NamespaceURI => "http://www.w3.org/2001/XMLSchema-instance",
     sort_order => 5,
 },
);
has 'version' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "version",
     node_type => "attribute",
     Name => "version",
     NamespaceURI => "",
     sort_order => 6,
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
     sort_order => 7,
 },
);
has 'xsi' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "xmlns",
     LocalName => "xsi",
     node_type => "attribute",
     Name => "xmlns:xsi",
     NamespaceURI => "http://www.w3.org/2000/xmlns/",
     sort_order => 8,
 },
);

no Moose;
1;
__END__
