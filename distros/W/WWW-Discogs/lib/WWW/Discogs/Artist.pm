package WWW::Discogs::Artist;

use strict;
use warnings;
use NEXT;
use base qw( WWW::Discogs::HasMedia );
use Carp;

sub new {
    my ($class, @args) = @_;

    my $self = {};
    bless $self, $class;
    $self->EVERY::LAST::_init(@args);

    return $self;
}

sub _init {
    my ($self, %args) = @_;

    $self->{_name}           = $args{name}           || '';
    $self->{_realname}       = $args{realname}       || '';
    $self->{_profile}        = $args{profile}        || '';
    $self->{_aliases}        = $args{aliases}        || [];
    $self->{_namevariations} = $args{namevariations} || [];
    $self->{_urls}           = $args{urls}           || [];
    $self->{_releases}       = $args{releases}       || [];
    $self->{_params}         = $args{_params}        || {};
    $self->{_uri}            = $args{_uri}           || '';

    return $self;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

sub realname {
    my $self = shift;
    return $self->{_realname};
}

sub aliases {
    my $self = shift;
    return @{ $self->{_aliases} };
}

sub namevariations {
    my $self = shift;
    return @{ $self->{_namevariations} };
}

sub profile {
    my $self = shift;
    return $self->{_profile};
}

sub urls {
    my $self = shift;
    return @{ $self->{_urls} };
}

sub releases {
    my $self = shift;
    unless ($self->{_params}->{releases}) {
        carp "No releases fetched for artist '" . $self->{_name} .
            "'. Call 'artist' method with releases => 1 param."
    }

    return @{ $self->{_releases} };
}

1;

__END__
