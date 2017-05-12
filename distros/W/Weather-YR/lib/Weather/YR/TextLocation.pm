package Weather::YR::TextLocation;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Base';

use Mojo::URL;

has 'lang' => ( isa => 'Str', is => 'rw', default => 'nb' );

has 'url' => ( isa => 'Mojo::URL', is => 'ro', lazy_build => 1 );

sub _build_url {
    my $self = shift;

    my $url = $self->service_url;
    $url->path ( '/weatherapi/textlocation/1.0/' );
    $url->query( latitude => $self->lat, longitude => $self->lon, language => $self->lang );

    return $url;
}

__PACKAGE__->meta->make_immutable;

1;
