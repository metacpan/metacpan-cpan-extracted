use strict;
use Test::More tests => 5;
use WebService::MerriamWebster;
# TODO
# I have test it use my own api key.
# it seems hard to test in this situation.
# there is a small test file in examples dir
is(WebService::MerriamWebster::_subdir("bixgrat"), 'bix', 'bix');
is(WebService::MerriamWebster::_subdir("gggrat"), 'gg', 'gg');
is(WebService::MerriamWebster::_subdir("1grat"), '1', 'begin with number');
is(WebService::MerriamWebster::_subdir("1"), '1', 'only number');
is(WebService::MerriamWebster::_subdir("grat"), 'g', 'default');



