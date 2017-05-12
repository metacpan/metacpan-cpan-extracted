#!perl

use strict;
use warnings;
use utf8;
use Time::Piece;
use JSON ();
use WWW::NHKProgram::API;

use Test::Deep;
use Test::More;

my $api_key = $ENV{NHK_PROGRAM_API_KEY};
plan skip_all => "API_KEY is not given." unless $api_key;

my $client = WWW::NHKProgram::API->new(
    api_key => $api_key,
);

my $t = localtime;
my $id = $t->ymd('') . '00000';

subtest 'Get response as hashref certainly' => sub {
    eval {
        my $program_info = $client->info({
            area    => 130,
            service => 'g1',
            id      => $id,
        });
    };
    ok !$@;
};

subtest 'Get response as raw JSON certainly' => sub {
    eval {
        my $json = $client->info_raw({
            area    => '東京',
            service => 'ＮＨＫ総合１',
            id      => $id,
        });
    };
    ok !$@;
};

done_testing;
