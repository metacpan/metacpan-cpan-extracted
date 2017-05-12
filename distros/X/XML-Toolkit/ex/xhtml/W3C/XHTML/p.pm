package W3C::XHTML::p;
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
has 'math_collection' => (
     isa         => 'ArrayRef[W3C::MathML::math]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'math' },
     description => {
         sort_order => 2,
     },
);
has 'small_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::small]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'small' },
     description => {
         sort_order => 3,
     },
);
has 'svg_collection' => (
     isa         => 'ArrayRef[W3C::SVG::svg]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'svg' },
     description => {
         sort_order => 4,
     },
);
has 'text' => (
     isa         => 'Str',
     is          => 'rw',
     traits      => [ 'XML' ],
  description => {
     sort_order => 5,
 },
);

no Moose;
1;
__END__
