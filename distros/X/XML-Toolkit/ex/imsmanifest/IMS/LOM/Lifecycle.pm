package IMS::LOM::Lifecycle;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'contribute_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Contribute]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'contribute' },
     description => {
         sort_order => 0,
     },
);
has 'status_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Status]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'status' },
     description => {
         sort_order => 1,
     },
);
has 'version_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Version]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'version' },
     description => {
         sort_order => 2,
     },
);

no Moose;
1;
__END__
