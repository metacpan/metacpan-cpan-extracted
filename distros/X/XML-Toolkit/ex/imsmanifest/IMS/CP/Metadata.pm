package IMS::CP::Metadata;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'lom_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Lom]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'lom' },
     description => {
         sort_order => 0,
     },
);
has 'schema_collection' => (
     isa         => 'ArrayRef[IMS::CP::Schema]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'schema' },
     description => {
         sort_order => 1,
     },
);
has 'schemaversion_collection' => (
     isa         => 'ArrayRef[IMS::CP::Schemaversion]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'schemaversion' },
     description => {
         sort_order => 2,
     },
);

no Moose;
1;
__END__
