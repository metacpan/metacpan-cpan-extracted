package IMS::CP::Resources;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'resource_collection' => (
     isa         => 'ArrayRef[IMS::CP::Resource]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'resource' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
