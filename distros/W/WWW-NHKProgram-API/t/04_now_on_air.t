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

my $expected = {
    'previous' => {
        'event_id' => 34863,
        'area' => {
            'name' => '東京',
            'id' => 130
        },
        'start_time' => '2014-02-05T01:25:00+09:00',
        'service' => {
            'logo_l' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x200.png',
                'height' => 200
            },
            'logo_m' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x100.png',
                'height' => 100
            },
            'logo_s' => {
                'width' => 100,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-100x50.png',
                'height' => 50
            },
            'name' => 'ＮＨＫ総合１',
            'id' => 'g1'
        },
        'end_time' => '2014-02-05T02:15:00+09:00',
        'subtitle' => '身近なモノに秘められた物語をトコトン探求！今回は腕時計。数億円の機械式腕時計から、大ヒットしたあの耐衝撃時計の開発秘話まで、小さな盤面の奥の小宇宙へとご案内。',
        'genres' => [
            '0801',
            '1015',
            '0502'
        ],
        'id' => '2014020434863',
        'title' => '好きだモノ。。。「腕時計」'
    },
    'present' => {
        'event_id' => '03350',
        'area' => {
            'name' => '東京',
            'id' => 130
        },
        'start_time' => '2014-02-05T02:15:00+09:00',
        'service' => {
            'logo_l' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x200.png',
                'height' => 200
            },
            'logo_m' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x100.png',
                'height' => 100
            },
            'logo_s' => {
                'width' => 100,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-100x50.png',
                'height' => 50
            },
            'name' => 'ＮＨＫ総合１',
            'id' => 'g1'
        },
        'end_time' => '2014-02-05T03:04:00+09:00',
        'subtitle' => '【解説】竹内元康，【アナウンサー】竹林宏　～ドイツ・クリンケシタールで収録～',
        'genres' => [
            '0106',
            '0109'
        ],
        'id' => '2014020403350',
        'title' => 'ソチオリンピック直前　ワールドカップ中継シリーズ「ジャンプ男子・団体」'
    },
    'following' => {
        'event_id' => '31349',
        'area' => {
            'name' => '東京',
            'id' => 130
        },
        'start_time' => '2014-02-05T03:04:00+09:00',
        'service' => {
            'logo_l' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x200.png',
                'height' => 200
            },
            'logo_m' => {
                'width' => 200,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-200x100.png',
                'height' => 100
            },
            'logo_s' => {
                'width' => 100,
                'url' => 'http://www.nhk.or.jp/common/img/media/gtv-100x50.png',
                'height' => 50
            },
            'name' => 'ＮＨＫ総合１',
            'id' => 'g1'
        },
        'end_time' => '2014-02-05T03:05:00+09:00',
        'subtitle' => '女子モーグル「予選」は総合テレビで２月８日（土）夜１０：５０から、「決勝」は総合テレビで２月９日（日）午前３：００ごろから中継します！ぜひご覧ください。',
        'genres' => [
            '0106',
            '0109'
        ],
        'id' => '2014020431349',
        'title' => '全力応援！ソチ五輪～上村愛子「悲願の表彰台へ」'
    }
};

subtest 'Get response as hashref certainly' => sub {
    my $now_on_air = $client->now_on_air({
        area    => 130,
        service => 'g1',
    });

    cmp_deeply($now_on_air, $expected);
};

subtest 'Get response as raw JSON certainly' => sub {
    my $json = $client->now_on_air_raw({
        area    => '東京',
        service => 'ＮＨＫ総合１',
    });

    my $now_on_air = JSON::decode_json($json)->{nowonair_list}->{g1};
    cmp_deeply($now_on_air, $expected);
};

subtest 'Error handling' => sub {
    my $data = q/{"fault":{"faultstring":"Invalid ApiKey","detail":{"errorcode":"oauth.v2.InvalidApiKey"}}}/;
    my $furl_guard = t::Util::mock_furl_response(401, $data)->();

    subtest 'Get error response as hashref certainly' => sub {
        eval { my $now_on_air = $client->now_on_air({
            area    => 130,
            service => 'g1',
        })};
        like $@, qr/\[Error\] 401 Unauthorized: Invalid ApiKey \(oauth\.v2\.InvalidApiKey\)/
    };
    subtest 'Get error response as JSON certainly' => sub {
        eval { my $now_on_air = $client->now_on_air_raw({
            area    => 130,
            service => 'g1',
        })};
        like $@, qr/$data/
    };
};

done_testing;
__DATA__
{
  "nowonair_list":{
    "g1":{
      "previous":{
        "id" : "2014020434863",
        "event_id" : "34863",
        "start_time" : "2014-02-05T01:25:00+09:00",
        "end_time" : "2014-02-05T02:15:00+09:00",
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
        "title" : "好きだモノ。。。「腕時計」",
        "subtitle" : "身近なモノに秘められた物語をトコトン探求！今回は腕時計。数億円の機械式腕時計から、大ヒットしたあの耐衝撃時計の開発秘話まで、小さな盤面の奥の小宇宙へとご案内。",
        "genres":[
          "0801",
          "1015",
          "0502"
        ]
      },
      "present":{
        "id" : "2014020403350",
        "event_id" : "03350",
        "start_time" : "2014-02-05T02:15:00+09:00",
        "end_time" : "2014-02-05T03:04:00+09:00",
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
        "title" : "ソチオリンピック直前　ワールドカップ中継シリーズ「ジャンプ男子・団体」",
        "subtitle" : "【解説】竹内元康，【アナウンサー】竹林宏　～ドイツ・クリンケシタールで収録～",
        "genres":[
          "0106",
          "0109"
        ]
      },
      "following":{
        "id" : "2014020431349",
        "event_id" : "31349",
        "start_time" : "2014-02-05T03:04:00+09:00",
        "end_time" : "2014-02-05T03:05:00+09:00",
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
        "title" : "全力応援！ソチ五輪～上村愛子「悲願の表彰台へ」",
        "subtitle" : "女子モーグル「予選」は総合テレビで２月８日（土）夜１０：５０から、「決勝」は総合テレビで２月９日（日）午前３：００ごろから中継します！ぜひご覧ください。",
        "genres":[
          "0106",
          "0109"
        ]
      }
    }
  }
}
