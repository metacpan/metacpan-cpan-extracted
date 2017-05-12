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

my $expected_first_program = {
    'event_id' => '33918',
    'area' => {
        'name' => "東京",
        'id' => '130'
    },
    'start_time' => '2014-02-04T04:30:00+09:00',
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
    'end_time' => '2014-02-04T05:00:00+09:00',
    'subtitle' => "▽ニュース　▽地域の課題や話題のリポート　▽日本と世界の気象情報",
    'genres' => [
        '0000',
        '0001',
        '0002'
    ],
    'id' => '2014020433918',
    'title' => "ＮＨＫニュース　おはよう日本"
};
my $expected_last_program = {
    'event_id' => '34402',
    'area' => {
        'name' => "東京",
        'id' => '130'
    },
    'start_time' => '2014-02-05T00:00:00+09:00',
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
    'end_time' => '2014-02-05T00:10:00+09:00',
    'subtitle' => "反政府デモが続くタイ。２日に行われた総選挙も、野党民主党などの反発は強く混乱が収まる気配はない。日本はどう関わっていけばよいのか、過度期にあるタイの行方を探る。",
    'genres' => [
        '0006',
        '0000',
        '0800'
    ],
    'id' => '2014020434402',
    'title' => "時論公論「タイの行方は　懸念される政治空白」二村伸解説委員"
};

subtest 'Get response as hashref certainly' => sub {
    my $genre_list = $client->genre({
        area    => 130,
        service => 'g1',
        genre   => '0000',
        date    => '2014-02-04',
    });

    subtest 'Check program information' => sub {
        my $first_program = $genre_list->[0];
        cmp_deeply(
            $first_program,
            $expected_first_program,
        );

        my $last_program = $genre_list->[-1];
        cmp_deeply(
            $last_program,
            $expected_last_program,
        );
    };
};

subtest 'Get response as raw JSON certainly' => sub {
    my $json = $client->genre_raw({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        genre   => '0000',
        date    => '2014-02-04',
    });
    my $genre_list = JSON::decode_json($json)->{list}->{g1};

    subtest 'Check program information' => sub {
        my $first_program = $genre_list->[0];
        cmp_deeply(
            $first_program,
            $expected_first_program,
        );

        my $last_program = $genre_list->[-1];
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
        eval { my $genre_list = $client->genre({
            area    => 130,
            service => 'g1',
            genre   => '0000',
            date    => '2014-02-04',
        }) };
        like $@, qr/\[Error\] 401 Unauthorized: Invalid ApiKey \(oauth\.v2\.InvalidApiKey\)/
    };
    subtest 'Get error response as JSON certainly' => sub {
        eval { my $genre_list = $client->genre_raw({
            area    => 130,
            service => 'g1',
            genre   => '0000',
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
        "id" : "2014020433918",
        "event_id" : "33918",
        "start_time" : "2014-02-04T04:30:00+09:00",
        "end_time" : "2014-02-04T05:00:00+09:00",
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
        "title" : "ＮＨＫニュース　おはよう日本",
        "subtitle" : "▽ニュース　▽地域の課題や話題のリポート　▽日本と世界の気象情報",
        "genres":[
          "0000",
          "0001",
          "0002"
        ]
      },
      {
        "id" : "2014020434402",
        "event_id" : "34402",
        "start_time" : "2014-02-05T00:00:00+09:00",
        "end_time" : "2014-02-05T00:10:00+09:00",
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
        "title" : "時論公論「タイの行方は　懸念される政治空白」二村伸解説委員",
        "subtitle" : "反政府デモが続くタイ。２日に行われた総選挙も、野党民主党などの反発は強く混乱が収まる気配はない。日本はどう関わっていけばよいのか、過度期にあるタイの行方を探る。",
        "genres":[
          "0006",
          "0000",
          "0800"
        ]
      }
    ]
  }
}
