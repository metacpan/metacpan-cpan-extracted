package XMLTK::XSPF::Meta;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'rel' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "rel",
        node_type => "attribute",
        Name => "rel",
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
