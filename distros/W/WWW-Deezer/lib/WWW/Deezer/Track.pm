package WWW::Deezer::Track;

our $VERSION = '0.03';

use Moose;
use Moose::Util::TypeConstraints;

extends 'WWW::Deezer::Obj';

use WWW::Deezer::Album;
use WWW::Deezer::Artist;

# http://developers.deezer.com/api/track

has 'id' => ( is  => 'ro', isa => 'Int' );

has 'readable' => (
    is => 'ro',
    isa => 'JSONBoolean',
    coerce => 1
);

has 'unseen' => (
    is => 'ro',
    isa => 'JSONBoolean',
    coerce => 1
);
    
has 'title'         => ( is  => 'ro', isa => 'Str' );
has 'title_short'   => ( is  => 'ro', isa => 'Str' );
has 'title_version' => ( is  => 'ro', isa => 'Str' );
has 'isrc'          => ( is  => 'ro', isa => 'Str' );

has 'link'     => ( is  => 'ro', isa => 'Str' );
has 'share'    => ( is  => 'ro', isa => 'Str' );
has 'duration' => ( is  => 'ro', isa => 'Int' );

has 'track_position' => ( is  => 'ro', isa => 'Int' );

has 'disk_number' => ( is  => 'ro', isa => 'Int' );

has 'rank' => ( is  => 'ro', isa => 'Int' );

has 'release_date' => ( is => 'ro', isa => 'Num' );
has 'bpm'          => ( is => 'ro', isa => 'Num' );
has 'gain'         => ( is => 'ro', isa => 'Num' );

has 'explicit_lyrics' => (
    is     => 'ro',
    isa    => 'JSONBoolean',
    coerce => 1,
);

has 'preview' => ( is  => 'ro', isa => 'Str' ); # URL

has 'artist' => (
    is => 'rw', 
    isa => 'Ref',
); # 2do: change Ref to Object

has 'album' => (
    is  => 'rw',
    isa => 'Ref',
); # 2do: change Ref to Object

has 'deezer_obj' => (
    is  => 'rw',
    isa => 'Ref'
);

sub count {
    my $self = shift;
    return scalar @{$self->data};
}

sub first {
    my $self = shift;
    return $self->data->[0];
}

sub set_artist {
    my ($self, $data) = @_;
    my $artist = WWW::Deezer::Artist->new($data);
    $artist->deezer_obj($self->deezer_obj);
    $self->artist($artist);
    return $self;
}

sub set_album {
    my ($self, $data) = @_;
    my $album = WWW::Deezer::Album->new($data);
    $album->deezer_obj($self->deezer_obj);
    $self->album($album);
    return $self;
}

1;
