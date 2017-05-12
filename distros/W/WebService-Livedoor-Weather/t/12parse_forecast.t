use strict;
use warnings;
use utf8;
use Encode;
use Test::More;
use Test::Exception;
use WebService::Livedoor::Weather;
use t::Util;

my $obj = WebService::Livedoor::Weather->new;
my $forecastmap_data = t::Util->load_forecastmap_data;
$obj->__parse_forecastmap($forecastmap_data);

my $city_id = $obj->__get_cityid('東京');
my $forecast_data = t::Util->load_forecast($city_id);
my $forecast = $obj->__parse_forecast($forecast_data);

isa_ok $forecast, 'HASH';
is_deeply [sort keys %$forecast], [
   'copyright',
   'description',
   'forecasts',
   'link',
   'location',
   'pinpointLocations',
   'publicTime',
   'title'
];

isa_ok $forecast->{copyright}, 'HASH';

isa_ok $forecast->{description}, 'HASH';
my $desc_text = '';
$desc_text .= $_ while <DATA>;
$desc_text =~ s/\n\n$//;
is $forecast->{description}{text}, $desc_text;
is $forecast->{description}{publicTime}, '2013-04-03T13:49:00+0900';

isa_ok $forecast->{forecasts}, 'ARRAY';
for my $f (@{$forecast->{forecasts}}) {
    isa_ok $f, 'HASH';
    is_deeply [sort keys %$f], [qw[date dateLabel image telop temperature]];
}

is_deeply [ map { $_->{dateLabel} } @{ $forecast->{forecasts} } ],
  [ '今日', '明日', '明後日' ];

is $forecast->{link}, 'http://weather.livedoor.com/area/forecast/130010';

isa_ok $forecast->{location}, 'HASH';
is_deeply $forecast->{location}, {
    city       => "東京",
    area       => "関東",
    prefecture => "東京都",
};

isa_ok $forecast->{pinpointLocations}, 'ARRAY';
is scalar @{$forecast->{pinpointLocations}}, 53;
for my $p (@{$forecast->{pinpointLocations}}) {
    isa_ok $p, 'HASH';
    is_deeply [sort keys %$p], ['link','name'];
}

is $forecast->{publicTime}, '2013-04-03T11:00:00+0900';

is $forecast->{title}, '東京都 東京 の天気';

done_testing;

__DATA__
 関東の東海上には前線を伴った低気圧があって、発達しながら北東に進ん
でいます。

【関東甲信地方】
 現在、関東甲信地方は、全般に雨または曇りとなっています。

 今日は、前線を伴った低気圧が東海上を発達しながら北東に進むでしょう
。また、上空を寒気を伴った気圧の谷が通過する見込みです。
 このため、関東甲信地方は、現在雨となっているところも夕方には曇りと
なる見込みです。関東地方や伊豆諸島では、夕方にかけて大気の状態が不安
定となり、雷を伴う所があるでしょう。

 明日は、はじめ冬型の気圧配置となりますが、日本海から高気圧が張り出
して次第に緩むでしょう。一方、関東の南には弱い気圧の谷となる見込みで
す。
 このため、関東甲信地方は、晴れる所が多いですが、関東南部を中心に午
後は次第に雲が広がるでしょう。長野県や関東地方北部の山沿いでは、はじ
め曇りで雨や雪の降る所があるでしょう。

 関東近海は、今日は大しけとなる所があるでしょう。船舶は高波に厳重に
警戒してください。明日も波が高いでしょう。

【東京地方】
 今日は、雨で夕方から曇りでしょう。昼過ぎにかけては雷雨となる所があ
るでしょう。
 明日は、晴れで昼前から時々曇りでしょう。

