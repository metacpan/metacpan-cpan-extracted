package XML::Toolkit::RNG::Grammar;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'datatypeLibrary' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "datatypeLibrary",
        node_type => "attribute",
        Name => "datatypeLibrary",
        NamespaceURI => "",
        sort_order => 0,
     },
);
has 'define_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Define]',
     is          => 'ro',     init_arg    => 'defines',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_define => ['push'] },     description => {
        Prefix => "",
        LocalName => "define",
        node_type => "child",
        Name => "define",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 1,
     },
);
has 'ns' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "ns",
        node_type => "attribute",
        Name => "ns",
        NamespaceURI => "",
        sort_order => 2,
     },
);
has 'start_collection' => (
     isa         => 'ArrayRef[XML::Toolkit::RNG::Start]',
     is          => 'ro',     init_arg    => 'starts',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_start => ['push'] },     description => {
        Prefix => "",
        LocalName => "start",
        node_type => "child",
        Name => "start",
        NamespaceURI => "http://relaxng.org/ns/structure/1.0",
        sort_order => 3,
     },
);
has 'xmlns' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "xmlns",
        node_type => "attribute",
        Name => "xmlns",
        NamespaceURI => "",
        sort_order => 4,
     },
);
1;

__END__
