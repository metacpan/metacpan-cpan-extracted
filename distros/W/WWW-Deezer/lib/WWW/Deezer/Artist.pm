package WWW::Deezer::Artist;

our $VERSION = '0.03';

use Moose;
use Moose::Util::TypeConstraints;

extends 'WWW::Deezer::Obj';

use WWW::Deezer;
use WWW::Deezer::Album;

# http://developers.deezer.com/api/artist

has 'id', is => 'ro', isa => 'Int';
has 'name', is => 'ro', isa => 'Str';
has 'link', is => 'ro', isa => 'Str';
has 'tracklist', is => 'ro', isa => 'Str';
has 'share', is => 'ro', isa => 'Url';
has 'picture', is => 'ro', isa => 'Url';
has 'picture_small', is => 'ro', isa => 'Url';
has 'picture_medium', is => 'ro', isa => 'Url';
has 'picture_big', is => 'ro', isa => 'Url';
has 'picture_xl', is => 'ro', isa => 'Url';
has 'nb_album', is => 'rw', isa => 'Int';
has 'nb_fan', is => 'rw', isa => 'Int';

has 'radio' => (
    is => 'ro',
    isa => 'JSONBoolean',
    coerce => 1
);

around BUILDARGS => sub { # allow create Artist object with single argument passed to constructor - deezer ID
    my ($orig, $class) = (shift, shift);
    my $self = {};

    if (@_ == 1 && !ref $_[0] ) {
        $self = $class->$orig( id => $_[0] );
        $self = WWW::Deezer->new->artist($_[0]);
    }
    else {
        # 2DO: deal with Bool and JSON::XS::Boolean=\1 in 'radio' argument
        $self = $class->$orig(@_);
    }
    return $self;
};

around [qw/nb_fan nb_album/] => sub { # add here another attributes which need fetching from server
    my ($orig, $self) = (shift, shift);
    my $attr = $self->$orig(@_);

    unless (defined $attr) {
        # fetch recreate artist.
        my $new_obj = $self->deezer_obj->artist($self->id);
        $attr= $new_obj->$orig(@_);
        $self->reinit_attr_values($new_obj);
    }

    return $attr;
};

sub top {
    my $self = shift;
    return;
}

sub albums {
    my $self = shift;
    return;
}   

sub comments {
    my $self = shift;
    return;
}   

sub fans {
    my $self = shift;
    return;
}   

sub related {
    my $self = shift;
    return;
}   

sub get_radio {
    my $self = shift;
    return;
}   

1;
