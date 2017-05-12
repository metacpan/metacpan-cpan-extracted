package IMS::CP::Organizations;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'default' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "default",
     node_type => "attribute",
     Name => "default",
     NamespaceURI => "",
     sort_order => 0,
 },
);
has 'organization_collection' => (
     isa         => 'ArrayRef[IMS::CP::Organization]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'organization' },
     description => {
         sort_order => 1,
     },
);

no Moose;
1;
__END__
