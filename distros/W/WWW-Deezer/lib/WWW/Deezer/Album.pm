package WWW::Deezer::Album;

our $VERSION = '0.03';

use Moose;
use Moose::Util::TypeConstraints;

extends 'WWW::Deezer::Obj';

use WWW::Deezer;
use WWW::Deezer::Artist;

# http://developers.deezer.com/api/album

has 'id' => (is => 'ro', isa => 'Int');
has 'title' => (is => 'ro', isa => 'Str');
has 'link' => (is => 'rw', isa => 'Str');
has 'cover' => (is => 'ro', isa => 'Str');
has 'cover_small' => (is => 'ro', isa => 'Str');
has 'cover_medium' => (is => 'ro', isa => 'Str');
has 'cover_big' => (is => 'ro', isa => 'Str');
has 'cover_xl' => (is => 'ro', isa => 'Str');
has 'genre_id' => (is => 'rw', isa => 'Int');
has 'label' => (is => 'ro', isa => 'Str');
has 'duration' => (is => 'ro', isa => 'Int');
has 'fans' => (is => 'ro', isa => 'Int');
has 'rating' => (is => 'ro', isa => 'Int');
has 'release_date' => (is => 'rw', isa => 'Str');
has 'available' => (is => 'ro');
has 'genres' => (is => 'ro');
has 'nb_tracks' => (is => 'ro');
has 'upc' => (is => 'ro', isa => 'Str');
has 'record_type' => (is => 'ro', isa => 'Str');

has 'artist' => (
    is => 'ro', 
    isa => 'Ref', 
    weak_ref => 1
); # 2do: change Ref to Object

has 'tracks' => (is => 'ro');

around BUILDARGS => sub { # allow create Album object with single argument passed to constructor - deezer ID
    my ($orig, $class) = (shift, shift);
    my $self = {};

    if (@_ == 1 && !ref $_[0] ) {
        $self = $class->$orig( id => $_[0] );
        $self = WWW::Deezer->new->album($_[0]);
    }
    else {
        $self = $class->$orig(@_);
    }
    return $self;
};

around [qw/genre_id link release_date upc genres nb_tracks record_type/] => sub { # add here another attributes which need fetching from server
    my ($orig, $self) = (shift, shift);
    my $attr = $self->$orig(@_);
    
    unless (defined $attr) { 
        # fetch recreate album.
        my $new_obj = $self->deezer_obj->album($self->id);
        $attr = $new_obj->$orig(@_);
        $self->reinit_attr_values($new_obj);
    }
    
    return $attr;
};

sub comments {
    my $self = shift;
    return;
}

sub fans_list {
    my $self = shift;
}

1;
