use strict;
use utf8;

use Text::Util::Chinese qw(extract_presuf);

use Test2::V0;

my @input = (
    '禁煙的車廂',
    '禁煙標語隨處可見',
    '我每個月都有一天禁煙',
    '禁煙之後容易餓',
    '禁煙的生活很有意義',
    '全席禁煙',
    '只有部分禁煙',
);

my $extracted = extract_presuf(
    sub { shift @input },
    sub { },
    { threshold => 2 },
);

is $extracted, { '禁煙' => 1 };

done_testing;
