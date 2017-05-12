use strict;
use warnings;
use Test::More;
use WWW::Shorten 'Google';

is(makeashorterlink('http://search.cpan.org/'), 'http://goo.gl/YC9r');

done_testing;

