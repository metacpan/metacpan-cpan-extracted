use strict;
use Test::More;
use WebService::PhotoZou;

unless ($ENV{PHOTOZOU_USERNAME} and $ENV{PHOTOZOU_PASSWORD}) {
    Test::More->import(skip_all => "no username and password set, skipped.");
    exit;
}

plan tests => 2;

my $api = WebService::PhotoZou->new(
    username => $ENV{PHOTOZOU_USERNAME},
    password => $ENV{PHOTOZOU_PASSWORD},
);

my $photos = $api->search_public(
    limit => 1,
);
SKIP : {
    skip 'no result.', 2 if scalar @$photos == 0;
    is scalar @$photos, 1;
    my $photo = $photos->[0];
    like $photo->{photo_id}, qr/^\d+$/;
}
