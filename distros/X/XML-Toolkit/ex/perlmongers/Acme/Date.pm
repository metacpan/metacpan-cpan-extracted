package Acme::Date;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'text' => (
    isa         => 'Str',
    is          => 'rw',
    traits      => ['XML'],
    description => {
        node_type  => "character",
        sort_order => 0,
    },
);
has 'type' => (
    isa         => 'Str',
    is          => 'ro',
    traits      => ['XML'],
    description => {
        LocalName    => "type",
        Prefix       => "",
        node_type    => "attribute",
        Name         => "type",
        NamespaceURI => "",
        sort_order   => 1,
    },
);
1;

__END__
