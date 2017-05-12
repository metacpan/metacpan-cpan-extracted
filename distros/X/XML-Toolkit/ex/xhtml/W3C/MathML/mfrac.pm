package W3C::MathML::mfrac;
use Moose;
use MooseX::AttributeHelpers;

has 'mi_collection' => (
     isa         => 'ArrayRef[W3C::MathML::mi]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'mi' },
     description => {
         sort_order => 0,
     },
);

no Moose;
1;
__END__
