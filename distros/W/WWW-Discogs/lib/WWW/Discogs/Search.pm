package WWW::Discogs::Search;

use strict;
use warnings;

sub new {
    my ($class, @args) = @_;

    my $self = {};
    bless $self, $class;
    $self->_init(@args);

    return $self;
}

sub _init {
    my ($self, %args) = @_;

    $self->{_exactresults}                 = $args{exactresults}                || [];
    $self->{_searchresults}->{_results}    = $args{searchresults}->{results}    || [];
    $self->{_searchresults}->{_numresults} = $args{searchresults}->{numResults} || '';
    $self->{_searchresults}->{_start}      = $args{searchresults}->{start}      || '';
    $self->{_searchresults}->{_end}        = $args{searchresults}->{end}        || '';
    $self->{_params}                       = $args{_params}                     || {};
    $self->{_uri}                          = $args{_uri}                        || '';

    return $self;
}

sub exactresults {
    my $self = shift;
    return @{ $self->{_exactresults} };
}

sub searchresults {
    my $self = shift;
    return @{ $self->{_searchresults}->{_results} };
}

sub numresults {
    my $self = shift;
    return $self->{_searchresults}->{_numresults};
}

sub pages {
    my $self = shift;
    if (!$self->numresults) {
        return 0;
    }
    return int($self->numresults / 20) + 1;
}

sub query {
    my $self = shift;
    return $self->{_params}->{q};
}

sub type {
    my $self = shift;
    return $self->{_params}->{type};
}

sub page {
    my $self = shift;
    return $self->{_params}->{page};
}

1;
