#!perl

use strict;
use warnings;
use utf8;
use t::Util;
use Encode qw/encode_utf8/;
use WWW::NHKProgram::API;

use Test::More;
use Test::Deep;

my $data = do { local $/; <DATA> };
my $furl_guard = t::Util::mock_furl_response(200, encode_utf8($data))->();

my $client = WWW::NHKProgram::API->new(
    api_key => '__API_KEY__',
);

my $expected_first_program = {
    'event_id' => '02027',
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
    'title' => "ＮＨＫプレマップ"
};
my $expected_last_program = {
    'event_id' => '02041',
    'area' => {
        'name' => "東京",
        'id' => '130'
    },
    'start_time' => '2014-02-05T04:10:00+09:00',
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
    'end_time' => '2014-02-05T04:15:00+09:00',
    'subtitle' => '',
    'genres' => [
        '0207'
    ],
    'id' => '2014020402041',
    'title' => "ＮＨＫプレマップ"
};

subtest 'Get response as hashref certainly' => sub {
    my $program_list = $client->list({
        area    => 130,
        service => 'g1',
        date    => '2014-02-04',
    });

    subtest 'Check program information' => sub {
        my $first_program = $program_list->[0];
        cmp_deeply(
            $first_program,
            $expected_first_program,
        );

        my $last_program = $program_list->[-1];
        cmp_deeply(
            $last_program,
            $expected_last_program,
        );
    };
};

subtest 'Get response as raw JSON certainly' => sub {
    my $json = $client->list_raw({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        date    => '2014-02-04',
    });

    my $program_list = JSON::decode_json($json)->{list}->{g1};

    subtest 'Check program information' => sub {
        my $first_program = $program_list->[0];
        cmp_deeply(
            $first_program,
            $expected_first_program,
        );

        my $last_program = $program_list->[-1];
        cmp_deeply(
            $last_program,
            $expected_last_program,
        );
    };
};

subtest 'Error handling' => sub {
    my $data = q/{"fault":{"faultstring":"Invalid ApiKey","detail":{"errorcode":"oauth.v2.InvalidApiKey"}}}/;
    my $furl_guard = t::Util::mock_furl_response(401, $data)->();
    subtest 'Get error response as hashref certainly' => sub {
        eval { my $program_list = $client->list({
            area    => 130,
            service => 'g1',
            date    => '2014-02-04',
        }) };
        like $@, qr/\[Error\] 401 Unauthorized: Invalid ApiKey \(oauth\.v2\.InvalidApiKey\)/
    };
    subtest 'Get error response as JSON certainly' => sub {
        eval { my $program_list = $client->list_raw({
            area    => 130,
            service => 'g1',
            date    => '2014-02-04',
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
        ]
      },
      {
        "id" : "2014020402041",
        "event_id" : "02041",
        "start_time" : "2014-02-05T04:10:00+09:00",
        "end_time" : "2014-02-05T04:15:00+09:00",
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
        ]
      }
    ]
  }
}
