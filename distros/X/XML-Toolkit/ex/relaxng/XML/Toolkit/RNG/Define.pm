package XML::Toolkit::RNG::Define;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

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
        sort_order => 0,
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
        sort_order => 1,
     },
);
has 'interleave_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Interleave]',
     is          => 'ro',     init_arg    => 'interleaves',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_interleave => ['push'] },     description => {
        Prefix => "",
        LocalName => "interleave",
        node_type => "child",
        Name => "interleave",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 2,
     },
);
has 'name' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "name",
        node_type => "attribute",
        Name => "name",
        NamespaceURI => "",
        sort_order => 3,
     },
);
has 'optional_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Optional]',
     is          => 'ro',     init_arg    => 'optionals',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_optional => ['push'] },     description => {
        Prefix => "",
        LocalName => "optional",
        node_type => "child",
        Name => "optional",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 4,
     },
);
has 'zeroOrMore_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::ZeroOrMore]',
     is          => 'ro',     init_arg    => 'zeroOrMores',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_zeroOrMore => ['push'] },     description => {
        Prefix => "",
        LocalName => "zeroOrMore",
        node_type => "child",
        Name => "zeroOrMore",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 5,
     },
);
1;

__END__
