package XML::Toolkit::RNG::Interleave;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'group_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Group]',
     is          => 'ro',     init_arg    => 'groups',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_group => ['push'] },     description => {
        Prefix => "",
        LocalName => "group",
        node_type => "child",
        Name => "group",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 0,
     },
);
has 'oneOrMore_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::OneOrMore]',
     is          => 'ro',     init_arg    => 'oneOrMores',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_oneOrMore => ['push'] },     description => {
        Prefix => "",
        LocalName => "oneOrMore",
        node_type => "child",
        Name => "oneOrMore",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 1,
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
        sort_order => 2,
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
        sort_order => 3,
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
        sort_order => 4,
     },
);
1;

__END__
