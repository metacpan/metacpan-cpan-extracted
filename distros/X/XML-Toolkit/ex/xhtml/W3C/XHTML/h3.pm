package W3C::XHTML::h3;
use Moose;
use MooseX::AttributeHelpers;

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
