package XML::AIML::Aiml;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'category_collection' => (
     isa         => 'ArrayRef[XML::AIML::Category]',
     is          => 'ro',     init_arg    => 'categorys',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_category => ['push'] },     description => {
        Prefix => "",
        LocalName => "category",
        node_type => "child",
        Name => "category",
        NamespaceURI => "",
        sort_order => 0,
     },
);
has 'version' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "version",
        node_type => "attribute",
        Name => "version",
        NamespaceURI => "",
        sort_order => 1,
     },
);
1;

__END__
