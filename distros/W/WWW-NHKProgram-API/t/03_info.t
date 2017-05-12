#!perl

use strict;
use warnings;
use utf8;
use t::Util;
use Encode qw/encode_utf8/;
use WWW::NHKProgram::API;

use Test::Deep;
use Test::More;

my $data = do { local $/; <DATA> };
my $furl_guard = t::Util::mock_furl_response(200, encode_utf8($data))->();

my $client = WWW::NHKProgram::API->new(
    api_key => '__API_KEY__',
);

my $expected_program_info = {
    'event_id' => '02027',
    'hashtags' => [],
    'program_logo' => {},
    'area' => {
        'name' => "東京",
        'id' => '130'
    },
    'start_time' => '2014-02-04T04:10:00+09:00',
    'service' => {
        'logo_l' => {
            'width' => '200',
            'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x200.png',
            'height' => '200'
        },
        'logo_m' => {
            'width' => '200',
            'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x100.png',
            'height' => '100'
        },
        'logo_s' => {
            'width' => '100',
            'url' => 'http://www.nhk.or.jp/common/img/media/gtv-100x50.png',
            'height' => '50'
        },
        'name' => "ＮＨＫ総合１",
        'id' => 'g1'
    },
    'end_time' => '2014-02-04T04:15:00+09:00',
    'subtitle' => '',
    'genres' => [
        '0207'
    ],
    'id' => '2014020402027',
    'title' => "ＮＨＫプレマップ",
    'program_url' => 'http://nhk.jp/P2539'
};

subtest 'Get response as hashref certainly' => sub {
    my $program_info = $client->info({
        area    => 130,
        service => 'g1',
        id      => '2014020402027',
    });

    cmp_deeply(
        $program_info,
        $expected_program_info,
    );
};

subtest 'Get response as raw JSON certainly' => sub {
    my $json = $client->info_raw({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        id      => '2014020402027',
    });

    my $program_info = JSON::decode_json($json)->{list}->{g1}->[0];
    cmp_deeply(
        $program_info,
        $expected_program_info,
    );
};

subtest 'Error handling' => sub {
    my $data = q/{"fault":{"faultstring":"Invalid ApiKey","detail":{"errorcode":"oauth.v2.InvalidApiKey"}}}/;
    my $furl_guard = t::Util::mock_furl_response(401, $data)->();
    subtest 'Get error response as hashref certainly' => sub {
        eval { my $program_info = $client->info({
            area    => 130,
            service => 'g1',
            id      => '2014020402027',
        }) };
        like $@, qr/\[Error\] 401 Unauthorized: Invalid ApiKey \(oauth\.v2\.InvalidApiKey\)/
    };
    subtest 'Get error response as JSON certainly' => sub {
        eval { my $program_info = $client->info_raw({
            area    => 130,
            service => 'g1',
            id      => '2014020402027',
        }) };
        like $@, qr/$data/
    };
};

done_testing;
__DATA__
{
  "list":{
    "g1":[
      {
        "id" : "2014020402027",
        "event_id" : "02027",
        "start_time" : "2014-02-04T04:10:00+09:00",
        "end_time" : "2014-02-04T04:15:00+09:00",
        "area":{
          "id" : "130",
          "name" : "東京"
        },
        "service":{
          "id" : "g1",
          "name" : "ＮＨＫ総合１",
          "logo_s":{
            "url" : "http://www.nhk.or.jp/common/img/media/gtv-100x50.png",
            "width" : "100",
            "height" : "50"
          },
          "logo_m":{
            "url" : "http://www.nhk.or.jp/common/img/media/gtv-200x100.png",
            "width" : "200",
            "height" : "100"
          },
          "logo_l":{
            "url" : "http://www.nhk.or.jp/common/img/media/gtv-200x200.png",
            "width" : "200",
            "height" : "200"
          }
        },
        "title" : "ＮＨＫプレマップ",
        "subtitle" : "",
        "genres":[
          "0207"
        ],
        "program_logo":{

        },
        "program_url" : "http://nhk.jp/P2539",
        "hashtags":[

        ]
      }
    ]
  }
}
