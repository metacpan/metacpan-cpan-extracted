use strict;
use warnings;
use utf8;
use Test::More;

use Text::Shinobi;

is(
    Text::Shinobi::normalize('ヷヹヺヸヴ'),
    "わ\x{3099}ゑ\x{3099}を\x{3099}ゐ\x{3099}う\x{3099}",
    'va'
);

is(
    Text::Shinobi::normalize('ぁぃぅぇぉっゃゅょゎゕゖㇾㇷㇶㇸㇲㇹㇱㇼㇳㇰㇿㇻㇺㇵㇽㇴ'),
    'あいうえおつやゆよわかけレフヒヘスホシリトクロラムハルヌ',
    'to uppper'
);

done_testing();
