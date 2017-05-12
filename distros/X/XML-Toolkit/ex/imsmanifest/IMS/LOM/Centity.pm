package IMS::LOM::Centity;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'vcard_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Vcard]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'vcard' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
