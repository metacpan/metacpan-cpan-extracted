package WWW::Discogs::Label;

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

    $self->{_name}        = $args{name}        || '';
    $self->{_contactinfo} = $args{contactinfo} || '';
    $self->{_parentLabel} = $args{parentLabel} || '';
    $self->{_releases}    = $args{releases}    || [];
    $self->{_sublabels}   = $args{sublabels}   || [];
    $self->{_params}      = $args{_params}     || {};
    $self->{_uri}         = $args{_uri}        || '';

    return $self;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

sub releases {
    my $self = shift;
    unless ($self->{_params}->{releases}) {
        carp "No releases fetched for label '" . $self->{_name} .
            "'. Call 'label' method with releases => 1 param."
    }

    return @{ $self->{_releases} };
}

sub contactinfo {
    my $self = shift;
    return $self->{_contactinfo};
}

sub sublabels {
    my $self = shift;
    return @{ $self->{_sublabels} };
}

sub parentlabel {
    my $self = shift;
    return $self->{_parentLabel};
}

1;
