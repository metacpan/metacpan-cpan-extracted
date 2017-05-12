package XML::Toolkit::RNG::ZeroOrMore;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'attribute_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Attribute]',
     is          => 'ro',     init_arg    => 'attributes',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_attribute => ['push'] },     description => {
        Prefix => "",
        LocalName => "attribute",
        node_type => "child",
        Name => "attribute",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
has 'choice_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Choice]',
     is          => 'ro',     init_arg    => 'choices',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_choice => ['push'] },     description => {
        Prefix => "",
        LocalName => "choice",
        node_type => "child",
        Name => "choice",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 1,
     },
);
has 'element_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Element]',
     is          => 'ro',     init_arg    => 'elements',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_element => ['push'] },     description => {
        Prefix => "",
        LocalName => "element",
        node_type => "child",
        Name => "element",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 2,
     },
);
1;

__END__
