package WWW::Discogs::Release;

use strict;
use warnings;
use NEXT;
use base qw( WWW::Discogs::ReleaseBase );

sub new {
    my ($class, @args) = @_;

    my $self = {};
    bless $self, $class;
    $self->EVERY::LAST::_init(@args);

    return $self;
}

sub _init {
    my ($self, %args) = @_;

    $self->{_title}        = $args{title}              || '';
    $self->{_released}     = $args{released}           || '';
    $self->{_released_fmt} = $args{released_formatted} || '';
    $self->{_country}      = $args{country}            || '';
    $self->{_status}       = $args{status}             || '';
    $self->{_master_id}    = $args{master_id}          || '';
    $self->{_formats}      = $args{formats}            || [];
    $self->{_labels}       = $args{labels}             || [];

    return $self;
}

sub title {
    my $self = shift;
    return $self->{_title};
}

sub released {
    my $self = shift;
    return $self->{_released};
}

sub released_formatted {
    my $self = shift;
    return $self->{_released_fmt};
}

sub labels {
    my $self = shift;
    return @{ $self->{_labels} };
}

sub country {
    my $self = shift;
    return $self->{_country};
}

sub formats {
    my $self = shift;
    return @{ $self->{_formats} };
}

sub status {
    my $self = shift;
    return $self->{_status};
}

sub master_id {
    my $self = shift;
    return $self->{_master_id};
}

1;
