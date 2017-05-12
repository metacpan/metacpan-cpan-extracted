use strict;
use warnings;
use Test::More tests => 14;
use WWW::MySociety::Gaze;

ok my $gaze = WWW::MySociety::Gaze->new, 'new';
isa_ok $gaze, 'WWW::MySociety::Gaze';

{
    ok my $country = $gaze->get_country_from_ip( '192.5.6.30' ),
      'got country code';
    like $country, qr{^[A-Z]+$}, 'country code looks OK';
}

{
    my @countries = $gaze->get_find_places_countries;
    ok @countries > 30, 'got some countries';
    my @nice = grep { qr{^[A-Z]+$} } @countries;
    is_deeply \@nice, \@countries, 'all valid ISO codes';
}

{
    my @places = $gaze->find_places(
        country => 'GB',
        query   => 'Newcastle upon Tyne'
    );
    ok @places > 3, 'got some places';
    like $places[0]->{Name}, qr{^Newcastle}, 'first name matches';
}

{
    my $density
      = $gaze->get_population_density( 54.9880556, -1.6194444 );

    # Should be OK until Newcastle disappears under water or becomes
    # uncomfortably crowded.
    ok $density > 100 && $density < 1_000_000, 'density looks OK';
}

{
    my $radius = $gaze->get_radius_containing_population(
        lat    => 54.9880556,
        lon    => -1.6194444,
        number => 10_000
    );

    ok $radius > 10 && $radius < 1_000_000, 'radius looks OK';
}

{
    my @bb = $gaze->get_country_bounding_coords( 'GB' );

    ok @bb == 4, 'correct number of elements';
    ok $bb[0] > $bb[1], 'latitude order correct';
    ok $bb[2] > $bb[3], 'longitude order correct';
}

{
    my @places = $gaze->get_places_near(
        lat      => 54.9880556,
        lon      => -1.6194444,
        distance => 20,
        number   => 1000
    );

    ok @places > 10, 'got some places';
}
