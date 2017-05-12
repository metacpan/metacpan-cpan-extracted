package XMLTK::XSPF::Track;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'album_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Album]',
     is          => 'ro',     init_arg    => 'albums',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_album => ['push'] },     description => {
        Prefix => "",
        LocalName => "album",
        node_type => "child",
        Name => "album",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 0,
     },
);
has 'image_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Image]',
     is          => 'ro',     init_arg    => 'images',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_image => ['push'] },     description => {
        Prefix => "",
        LocalName => "image",
        node_type => "child",
        Name => "image",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 1,
     },
);
has 'location_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Location]',
     is          => 'ro',     init_arg    => 'locations',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_location => ['push'] },     description => {
        Prefix => "",
        LocalName => "location",
        node_type => "child",
        Name => "location",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 2,
     },
);
has 'meta_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Meta]',
     is          => 'ro',     init_arg    => 'metas',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_meta => ['push'] },     description => {
        Prefix => "",
        LocalName => "meta",
        node_type => "child",
        Name => "meta",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 3,
     },
);
has 'title_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Title]',
     is          => 'ro',     init_arg    => 'titles',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_title => ['push'] },     description => {
        Prefix => "",
        LocalName => "title",
        node_type => "child",
        Name => "title",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 4,
     },
);
1;
__END__
