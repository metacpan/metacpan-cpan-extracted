package IMS::LOM::Contribute;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'centity_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Centity]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'centity' },
     description => {
         sort_order => 0,
     },
);
has 'date_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Date]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'date' },
     description => {
         sort_order => 1,
     },
);
has 'role_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Role]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'role' },
     description => {
         sort_order => 2,
     },
);

no Moose;
1;
__END__
