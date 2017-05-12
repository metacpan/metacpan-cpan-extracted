package WWW::Discogs::Master;

use strict;
use warnings;
use NEXT;
use base qw ( WWW::Discogs::ReleaseBase );

sub new {
    my ($class, @args) = @_;

    my $self = {};
    bless $self, $class;
    $self->EVERY::LAST::_init(@args);

    return $self;
}

sub _init {
    my ($self, %args) = @_;

    $self->{_versions}     = $args{versions}     || [];
    $self->{_main_release} = $args{main_release} || '';

    return $self;
}

sub versions {
    my $self = shift;
    return @{ $self->{_versions} };
}

sub main_release {
    my $self = shift;
    return $self->{_main_release};
}

1;
