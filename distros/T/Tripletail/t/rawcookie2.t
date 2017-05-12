#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use Tripletail '/dev/null';

$ENV{HTTP_COOKIE} = 'foo=bar; aaa=bbb';

$TL->startCgi(
    -main => sub {
        # foo1=zzzzzz...
        # ^-+-^
        #   `-[5 octets]
        my $c;
        ok($c = $TL->getRawCookie, 'getRawCookie');
        ok($c->set(foo1 => 'z' x (4096 - 5 + 1)), 'set');
        dies_ok {$c->_makeSetCookies} 'over';

        $TL->print('dummy string to avoid the \"no contents\" error.');
    });
