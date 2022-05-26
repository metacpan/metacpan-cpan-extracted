#! perl -I. -w
use t::Test::abeltje;

$ENV{RELEASE_TESTING} = 1;
use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok();

abeltje_done_testing();
