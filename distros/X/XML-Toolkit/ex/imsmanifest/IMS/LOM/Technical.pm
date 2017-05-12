package IMS::LOM::Technical;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'format_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Format]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'format' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
