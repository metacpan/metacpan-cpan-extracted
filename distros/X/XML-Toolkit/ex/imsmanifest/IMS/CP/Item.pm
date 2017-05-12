package IMS::CP::Item;
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
has 'identifierref' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "identifierref",
     node_type => "attribute",
     Name => "identifierref",
     NamespaceURI => "",
     sort_order => 1,
 },
);
has 'isvisible' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "isvisible",
     node_type => "attribute",
     Name => "isvisible",
     NamespaceURI => "",
     sort_order => 2,
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
         sort_order => 3,
     },
);
has 'parameters' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "parameters",
     node_type => "attribute",
     Name => "parameters",
     NamespaceURI => "",
     sort_order => 4,
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
         sort_order => 5,
     },
);

no Moose;
1;
__END__
