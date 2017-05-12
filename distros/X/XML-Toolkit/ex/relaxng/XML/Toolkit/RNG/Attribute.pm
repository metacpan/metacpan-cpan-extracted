package XML::Toolkit::RNG::Attribute;
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
1;

__END__
