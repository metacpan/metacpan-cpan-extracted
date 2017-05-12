use strict;
use Test::More;
use WebService::PhotoZou;

unless ($ENV{PHOTOZOU_USERNAME} and $ENV{PHOTOZOU_PASSWORD}) {
    Test::More->import(skip_all => "no username and password set, skipped.");
    exit;
}

plan tests => 3;

my $api = WebService::PhotoZou->new(
    username => $ENV{PHOTOZOU_USERNAME},
    password => $ENV{PHOTOZOU_PASSWORD},
);

my $name = 'WebService::PhotoZou';
my $album_id = $api->photo_add_album(
    name      => $name,
    perm_type => 'deny'
) or die $api->errormsg;
like $album_id, qr/^\d+$/;

sleep 1;

my $albums = $api->photo_album or die $api->errormsg;
my ($album) = grep { $_->{album_id} eq $album_id } @$albums;
is $album->{name}, $name;

sleep 1;

my $photo_id = $api->photo_add(
    photo    => 't/test.jpg',
    album_id => $album_id,
);
like $photo_id, qr/^\d+$/;
