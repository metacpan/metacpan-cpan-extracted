package IMS::LOM::Learningresourcetype;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'source_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Source]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'source' },
     description => {
         sort_order => 0,
     },
);
has 'value_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Value]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'value' },
     description => {
         sort_order => 1,
     },
);

no Moose;
1;
__END__
