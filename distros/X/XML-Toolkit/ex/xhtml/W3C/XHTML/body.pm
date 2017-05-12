package W3C::XHTML::body;
use Moose;
use MooseX::AttributeHelpers;

has 'h3_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::h3]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'h3' },
     description => {
         sort_order => 0,
     },
);
has 'p_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::p]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'p' },
     description => {
         sort_order => 1,
     },
);

no Moose;
1;
__END__
