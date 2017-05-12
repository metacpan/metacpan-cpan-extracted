use strict;
use warnings;
use Test::More;
use WWW::Shorten 'Google';

is(makealongerlink('http://goo.gl/YC9r'), 'http://search.cpan.org/');
is(makealongerlink('YC9r'), 'http://search.cpan.org/');

done_testing;
