use strict;
use Test::More;
use WebService::PhotoZou;

unless ($ENV{PHOTOZOU_USERNAME} and $ENV{PHOTOZOU_PASSWORD}) {
    Test::More->import(skip_all => "no username and password set, skipped.");
    exit;
}

plan tests => 1;

my $api = WebService::PhotoZou->new(
    username => $ENV{PHOTOZOU_USERNAME},
    password => $ENV{PHOTOZOU_PASSWORD},
);

my $groups = $api->user_group;
SKIP : {
    skip 'no group.', 1 if scalar @$groups == 0;
    my $group = $groups->[0];
    like $group->{group_id}, qr/^\d+$/;
}
