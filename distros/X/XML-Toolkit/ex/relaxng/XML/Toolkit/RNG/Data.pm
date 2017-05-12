package XML::Toolkit::RNG::Data;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'type' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "type",
        node_type => "attribute",
        Name => "type",
        NamespaceURI => "",
        sort_order => 0,
     },
);
1;

__END__
