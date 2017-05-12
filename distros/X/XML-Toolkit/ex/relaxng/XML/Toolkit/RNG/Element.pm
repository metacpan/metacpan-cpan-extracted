package XML::Toolkit::RNG::Element;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'anyName_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::AnyName]',
     is          => 'ro',     init_arg    => 'anyNames',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_anyName => ['push'] },     description => {
        Prefix => "",
        LocalName => "anyName",
        node_type => "child",
        Name => "anyName",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
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
        sort_order => 1,
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
        sort_order => 2,
     },
);
has 'data_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Data]',
     is          => 'ro',     init_arg    => 'datas',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_data => ['push'] },     description => {
        Prefix => "",
        LocalName => "data",
        node_type => "child",
        Name => "data",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 3,
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
        sort_order => 4,
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
        sort_order => 5,
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
        sort_order => 6,
     },
);
has 'ref_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Ref]',
     is          => 'ro',     init_arg    => 'refs',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_ref => ['push'] },     description => {
        Prefix => "",
        LocalName => "ref",
        node_type => "child",
        Name => "ref",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 7,
     },
);
has 'text_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Text]',
     is          => 'ro',     init_arg    => 'texts',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_text => ['push'] },     description => {
        Prefix => "",
        LocalName => "text",
        node_type => "child",
        Name => "text",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 8,
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
        sort_order => 9,
     },
);
1;

__END__
