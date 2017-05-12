package IMS::LOM::Educational;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'learningresourcetype_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Learningresourcetype]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'learningresourcetype' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
