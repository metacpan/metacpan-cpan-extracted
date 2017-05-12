package XML::Toolkit::RNG::Group;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

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
        sort_order => 0,
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
        sort_order => 1,
     },
);
1;

__END__
