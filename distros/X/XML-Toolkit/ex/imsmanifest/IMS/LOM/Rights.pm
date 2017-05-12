package IMS::LOM::Rights;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'copyrightandotherrestrictions_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Copyrightandotherrestrictions]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'copyrightandotherrestrictions' },
     description => {
         sort_order => 0,
     },
);
has 'cost_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Cost]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'cost' },
     description => {
         sort_order => 1,
     },
);
has 'description_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Description]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'description' },
     description => {
         sort_order => 2,
     },
);

no Moose;
1;
__END__
