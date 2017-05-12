#!perl -T

use Test::More tests => 2;

use WWW::Shorten 'PunyURL';

eval { &makeashorterlink() };
ok( $@, 'makeashorterlink fails with no args' );
eval { &makealongerlink() };
ok( $@, 'makealongerlink fails with no args ' );
