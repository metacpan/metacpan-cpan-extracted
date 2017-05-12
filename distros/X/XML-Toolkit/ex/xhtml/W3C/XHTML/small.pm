package W3C::XHTML::small;
use Moose;
use MooseX::AttributeHelpers;

has 'a_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::a]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'a' },
     description => {
         sort_order => 0,
     },
);
has 'br_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::br]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'br' },
     description => {
         sort_order => 1,
     },
);
has 'script_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::script]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'script' },
     description => {
         sort_order => 2,
     },
);
has 'span_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::span]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'span' },
     description => {
         sort_order => 3,
     },
);

no Moose;
1;
__END__
