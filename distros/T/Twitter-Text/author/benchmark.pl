use strict;
use warnings;
use utf8;
use Benchmark ':all';
use Twitter::Text;

timethis(1000000, sub {
    extract_hashtags_with_indices('#foooooooooo #世界のみんなへ届けたい aaaaa');
});

timethis(1000000, sub {
    extract_mentions_or_lists_with_indices('@foooo @foooooo @foooo @foofooo @fofofff');
});
