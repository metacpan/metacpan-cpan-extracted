use strict;
use warnings;
use Test::More;
use WWW::Shorten 'Flickr';

is(makeashorterlink('http://www.flickr.com/photos/poppen/3902877433/'), 'http://flic.kr/p/6WTgue');
is(makeashorterlink('3902877433'), 'http://flic.kr/p/6WTgue');
is(makeashorterlink('http://flic.kr/p/6WTgue'), undef);

done_testing;

