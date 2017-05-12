package IMS::LOM::General;
use Moose;
use MooseX::AttributeHelpers;
use XML::Toolkit;

has 'description_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Description]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'description' },
     description => {
         sort_order => 0,
     },
);
has 'identifier_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Identifier]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'identifier' },
     description => {
         sort_order => 1,
     },
);
has 'keyword_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Keyword]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'keyword' },
     description => {
         sort_order => 2,
     },
);
has 'language_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Language]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'language' },
     description => {
         sort_order => 3,
     },
);
has 'title_collection' => (
     isa         => 'ArrayRef[IMS::LOM::Title]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'title' },
     description => {
         sort_order => 4,
     },
);

no Moose;
1;
__END__
