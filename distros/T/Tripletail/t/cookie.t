# -*- perl -*-
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 10;
use Tripletail qw(/dev/null);

# print $TL->newLegacySerializer->serialize({aaa => [111]}), "\n";
# h616161r79333333313333333133333331

# print $TL->newLegacySerializer->serialize({aaa => [333]}), "\n";
# h616161r79333333333333333333333333

$ENV{HTTP_COOKIE} = 'foo=h616161r79333333313333333133333331';

dies_ok { $TL->getCookie } 'calling getCookie() outside startCgi()';

$TL->startCgi(
    -main => sub {
        my $c;
        ok($c = $TL->getCookie('name'), 'getCookie');
        ok($c = $TL->getCookie, 'getCookie');

        my $form;
        ok($form = $c->get('esa'), 'get');
        ok($form = $c->get('foo'), 'get');

        is($form->get('aaa'), '111', '$form->get');

        dies_ok {$c->set('foo')} 'set die';
        dies_ok {$c->set('foo',\123)} 'set die';

        $form->set(aaa => 333);
        $c->set(foo => $form);

        my @set = $c->_makeSetCookies;
        is($set[0],
           'foo=h616161r79333333333333333333333333',
           '_makeSetCookies');

        ok($c = $TL->getCookie, 'getCookie');
    });
