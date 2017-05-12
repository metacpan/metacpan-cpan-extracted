package WWW::Discogs::HasMedia;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, @args) = @_;

    croak "Can't create abstract object WWW::Discogs::HasMedia"
        if $class eq __PACKAGE__;
}

sub _init {
    my ($self, %args) = @_;

    $self->{_images} = $args{images} || [];
    $self->{_videos} = $args{videos} || [];

    return $self;
}

sub images {
    my ($self, %args) = @_;
    my $image_type = $args{type};

    if ($image_type) {
        return grep { $_->{type} =~ /^${image_type}$/i } @{ $self->{_images} };
    }

    return @{ $self->{_images} };
}

sub videos {
    my $self = shift;
    return @{ $self->{_videos} };
}

1;
