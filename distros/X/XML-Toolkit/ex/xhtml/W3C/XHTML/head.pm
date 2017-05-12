package W3C::XHTML::head;
use Moose;
use MooseX::AttributeHelpers;

has 'object_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::object]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'object' },
     description => {
         sort_order => 0,
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
         sort_order => 1,
     },
);
has 'title_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::title]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'title' },
     description => {
         sort_order => 2,
     },
);

no Moose;
1;
__END__
