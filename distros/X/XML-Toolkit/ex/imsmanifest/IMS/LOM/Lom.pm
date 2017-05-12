package IMS::LOM::Lom;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'educational_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Educational]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'educational' },
     description => {
         sort_order => 0,
     },
);
has 'general_collection' => (
     isa         => 'ArrayRef[IMS::LOM::General]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'general' },
     description => {
         sort_order => 1,
     },
);
has 'lifecycle_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Lifecycle]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'lifecycle' },
     description => {
         sort_order => 2,
     },
);
has 'rights_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Rights]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'rights' },
     description => {
         sort_order => 3,
     },
);
has 'technical_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Technical]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'technical' },
     description => {
         sort_order => 4,
     },
);

no Moose;
1;
__END__
