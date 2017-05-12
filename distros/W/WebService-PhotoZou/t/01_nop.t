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

# test
is $api->nop, 'ok';
