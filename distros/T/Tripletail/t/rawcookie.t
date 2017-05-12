# -*- perl -*-
use Test::More tests => 17;
use Test::Exception;
use strict;
use warnings;
use Tripletail qw(/dev/null);

$ENV{HTTP_COOKIE} = 'foo=bar; aaa="bbb"';

dies_ok { $TL->getRawCookie } 'calling getRawCookie() outside startCgi()';

$TL->startCgi(
    -main => sub {

        my $c;
        ok($c = $TL->getRawCookie, 'getRawCookie');

        dies_ok {$c->get} 'get undef';
        dies_ok {$c->get(\123)} 'get ref';
        is($c->get('foo'), 'bar', 'get');
        is($c->get('aaa'), 'bbb', 'get');

        dies_ok {$c->set} 'set undef';
        dies_ok {$c->set(\123)} 'set ref';
        dies_ok {$c->set(foo => \123)} 'set ref';
        ok($c->set(foo => 'baz'), 'set');
        is($c->get('foo'), 'baz', 'get after set');

        dies_ok {$c->delete} 'delete undef';
        dies_ok {$c->delete(\123)} 'delete ref';
        ok($c->delete('foo'), 'delete');
        is $c->get('foo'), undef, 'delete then get';

        like(($c->_makeSetCookies)[0], qr/^foo=;/, '_makeSetCookies');

        ok($c->clear, 'clear');
    });
