package XML::AIML::Li;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'srai_collection' => (
     isa         => 'ArrayRef[XML::AIML::Srai]',
     is          => 'ro',     init_arg    => 'srais',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_srai => ['push'] },     description => {
        Prefix => "",
        LocalName => "srai",
        node_type => "child",
        Name => "srai",
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
