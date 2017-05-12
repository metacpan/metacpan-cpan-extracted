package XML::Toolkit::RNG::Ref;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

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
        sort_order => 0,
     },
);
1;

__END__
