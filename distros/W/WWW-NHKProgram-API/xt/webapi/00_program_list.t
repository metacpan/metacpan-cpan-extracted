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
    my $json = $client->list_raw({
        area    => 130,
        service => 'g1',
        date    => $date,
    });

    my $program_list;
    eval { $program_list = JSON::decode_json($json)->{list}->{g1} };
    ok !$@;
    $first_program = $program_list->[0];
    ok $first_program;
    $last_program  = $program_list->[-1];
    ok $last_program;
    $response_length = scalar @$program_list;
};

subtest 'Get response as hashref certainly' => sub {
    my $program_list = $client->list({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        date    => $date,
    });
    is scalar @$program_list, $response_length, 'check response length';

    subtest 'Check program information' => sub {
        cmp_deeply(
            $program_list->[0],
            $first_program,
        );

        cmp_deeply(
            $program_list->[-1],
            $last_program,
        );
    };
};

done_testing;

