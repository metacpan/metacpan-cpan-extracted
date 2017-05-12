#!perl

use strict;
use warnings;
use utf8;
use JSON ();
use Time::Piece;
use WWW::NHKProgram::API;

use Test::Deep;
use Test::More;

my $api_key = $ENV{NHK_PROGRAM_API_KEY};
plan skip_all => "API_KEY is not given." unless $api_key;

my $client = WWW::NHKProgram::API->new(
    api_key => $api_key,
);

my $t    = localtime;
my $date = $t->ymd;

my $first_program;
my $last_program;
my $response_length;
subtest 'Get response as raw JSON certainly' => sub {
    my $json = $client->genre_raw({
        area    => 130,
        service => 'g1',
        genre   => '0000',
        date    => $date,
    });

    my $genre_list;
    eval { $genre_list = JSON::decode_json($json)->{list}->{g1} };
    ok !$@;
    $first_program = $genre_list->[0];
    ok $first_program;
    $last_program = $genre_list->[-1];
    ok $last_program;
    $response_length = scalar @$genre_list
};

subtest 'Get response as hashref certainly' => sub {
    my $genre_list = $client->genre({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        genre   => '定時・総合',
        date    => $date,
    });
    is scalar @$genre_list, $response_length, 'check response length';

    subtest 'Check program information' => sub {
        cmp_deeply(
            $genre_list->[0],
            $first_program,
        );

        cmp_deeply(
            $genre_list->[-1],
            $last_program,
        );
    };
};

done_testing;

