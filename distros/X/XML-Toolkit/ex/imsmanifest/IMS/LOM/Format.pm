package IMS::LOM::Format;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'text' => (
     isa         => 'Str',
     is          => 'rw',
     traits      => [ 'XML' ],
  description => {
     sort_order => 0,
 },
);

no Moose;
1;
__END__
