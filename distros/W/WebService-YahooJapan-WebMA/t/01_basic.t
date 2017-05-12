use strict;
use utf8;
use Test::More;
use WebService::YahooJapan::WebMA;

unless ($ENV{YJ_APPID}) {
    Test::More->import(skip_all => "no appid set, skipped.");
    exit;
}

plan tests => 6;

my $api = WebService::YahooJapan::WebMA->new(
    appid => $ENV{YJ_APPID},
);

my $result = $api->parse(sentence => '庭には二羽ニワトリがいる。')
    or die $api->error;
ok $result;

my $ma_result = $result->{ma_result};
is $ma_result->{total_count}   , 9, 'total_count';
is $ma_result->{filtered_count}, 9, 'filtered_count';

my $words = $ma_result->{word_list};
is scalar @$words, 9, 'word_list';

my ($sentence, $reading);
for my $word (@$words) {
    $sentence .= $word->{surface};
    $reading  .= $word->{reading};
}
is $sentence, '庭には二羽ニワトリがいる。', 'sentence';
is $reading,  'にわには2わにわとりがいる。', 'reading';

