package XMLTK::XSPF::Playlist;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'trackList_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::TrackList]',
     is          => 'ro',     init_arg    => 'trackLists',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_trackList => ['push'] },     description => {
        Prefix => "",
        LocalName => "trackList",
        node_type => "child",
        Name => "trackList",
        NamespaceURI => "http://xspf.org/ns/0/",
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
has 'xmlns' => (
     isa         => 'Str',
     is          => 'ro',   
     traits      => [ 'XML'],
     description => {
        Prefix => "",
        LocalName => "xmlns",
        node_type => "attribute",
        Name => "xmlns",
        NamespaceURI => "",
        sort_order => 2,
     },
);
1;
__END__
