package IMS::LOM::Date;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'datetime_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Datetime]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'datetime' },
     description => {
         sort_order => 0,
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
         sort_order => 1,
     },
);

no Moose;
1;
__END__
