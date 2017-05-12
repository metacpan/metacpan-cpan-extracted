package WebService::Yahoo::BOSS::Response::PlaceFinder;

=head1 NAME

WebService::Yahoo::BOSS::Response::PlaceFinder

=cut

use Moo;

use Carp qw(croak);

has [ qw(
    quality
    latitude
    longitude
    offsetlat
    offsetlon
    radius
    name
    line1
    line2
    line3
    line4
    house
    street
    xstreet
    unittype
    unit
    postal
    neighborhood
    city
    county
    state
    country
    countrycode
    statecode
    countycode
    uzip
    hash
    woeid
    woetype
) ] => ( is => 'rw' );


sub parse {
    my ($class, $bossresponse) = @_;

    my $data = $bossresponse->{placefinder}
        or croak "bossresponse doesn't contain a 'placefinder' data: @{[ keys %$bossresponse ]}";

    return {
        start        => $data->{start},
        count        => $data->{count},
        results      => [ map { $class->new($_) } @{ $data->{results} } ]
    };
}


1;
