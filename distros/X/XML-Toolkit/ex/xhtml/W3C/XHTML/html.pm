package W3C::XHTML::html;
use Moose;
use MooseX::AttributeHelpers;

has 'body_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::body]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'body' },
     description => {
         sort_order => 0,
     },
);
has 'head_collection' => (
     isa         => 'ArrayRef[W3C::XHTML::head]',
     is          => 'ro',
     traits      => [ 'XML' ],
      metaclass   => 'Collection::Array',
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     provides    => { push => 'head' },
     description => {
         sort_order => 1,
     },
);
has 'svg' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "xmlns",
     LocalName => "svg",
     node_type => "attribute",
     Name => "xmlns:svg",
     NamespaceURI => "http://www.w3.org/2000/xmlns/",
     sort_order => 2,
 },
);
has 'xmlns' => (
     isa         => 'Str',
     is          => 'ro',
     traits      => [ 'XML' ],
  description => {
     Prefix => "",
     LocalName => "xmlns",
     node_type => "attribute",
     Name => "xmlns",
     NamespaceURI => "",
     sort_order => 3,
 },
);

no Moose;
1;
__END__
