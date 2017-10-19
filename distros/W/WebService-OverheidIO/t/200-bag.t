use strict;
use warnings;

use Test::Deep;
use Test::More;

use IO::All;
use Sub::Override;
use WebService::OverheidIO::BAG;

{

    my $model = WebService::OverheidIO::BAG->new(
        key => 'very key'
    );
    isa_ok($model, "WebService::OverheidIO::BAG");

    my $answer = io->catfile('t/data/search_bag.json')->slurp;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
        my $self = shift;
        return HTTP::Response->new(200, undef, undef, $answer);
        },
    );

    $answer = $model->search("foo");

    my $address = $answer->{_embedded}{adres}[0];

    my $expected_data = {
        openbareruimtenaam   => "Muiderstraat",
        huisnummer           => 1,
        huisnummertoevoeging => '',
        huisletter           => '',
        postcode             => "1011PZ",
        woonplaatsnaam       => 'Amsterdam',
        url                  => '1011pz-muiderstraat-1',
        _links => { self => { href => "/api/bag/1011pz-muiderstraat-1" } },
    };

    cmp_deeply($address, $expected_data, "Muiderstraat found");
}

done_testing;

__END__

