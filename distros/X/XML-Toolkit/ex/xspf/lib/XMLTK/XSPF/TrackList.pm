package XMLTK::XSPF::TrackList;
use Moose;
use namespace::autoclean;
use XML::Toolkit;

has 'track_collection' => (
     isa         => 'ArrayRef[XMLTK::XSPF::Track]',
     is          => 'ro',     init_arg    => 'tracks',
     traits      => [qw(XML Array)],
     lazy        => 1,
     auto_deref  => 1,
     default     => sub { [] },
     handles    => { add_track => ['push'] },     description => {
        Prefix => "",
        LocalName => "track",
        node_type => "child",
        Name => "track",
        NamespaceURI => "http://xspf.org/ns/0/",
        sort_order => 0,
     },
);
1;
__END__
