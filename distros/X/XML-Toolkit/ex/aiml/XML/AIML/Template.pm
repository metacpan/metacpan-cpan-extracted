package XML::AIML::Template;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'random_collection' => (
     isa         => 'ArrayRef[XML::AIML::Random]',
     is          => 'ro',     init_arg    => 'randoms',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_random => ['push'] },     description => {
        Prefix => "",
        LocalName => "random",
        node_type => "child",
        Name => "random",
        NamespaceURI => "",
        sort_order => 0,
     },
);
has 'text' => (
     isa         => 'Str',
     is          => 'rw',   
     traits      => [ 'XML'],
     description => {
        node_type => "character",
        sort_order => 1,
     },
);
1;

__END__
