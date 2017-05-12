use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use WebService::Livedoor::Weather;
use t::Util;

my $obj = WebService::Livedoor::Weather->new;
my $forecastmap_data = t::Util->load_forecastmap_data();
$obj->__parse_forecastmap($forecastmap_data);

is $obj->__get_cityid('仙台'), '040010';
is $obj->__get_cityid('東京'), '130010';
is $obj->__get_cityid('横浜'), '140010';
is $obj->__get_cityid('名古屋'), '230010';
is $obj->__get_cityid('大阪'), '270000';
is $obj->__get_cityid('京都'), '260010';
is $obj->__get_cityid('新潟'), '150010';
is $obj->__get_cityid('広島'), '340010';
is $obj->__get_cityid('岡山'), '330010';
is $obj->__get_cityid('福岡'), '400010';
is $obj->__get_cityid('那覇'), '471010';
is $obj->__get_cityid('父島'), '130040';
throws_ok { $obj->__get_cityid('練馬')} qr'Invalid city name', 'Undefined city Nerima in forecastmap';

done_testing;
