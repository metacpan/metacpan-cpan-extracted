package IMS::LOM::Description;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'langstring_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Langstring]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'langstring' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
