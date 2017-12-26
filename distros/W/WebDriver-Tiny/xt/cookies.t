use strict;
use warnings;

use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd:8080');

is_deeply $drv->cookies, {}, 'No cookies';

$drv->cookie( foo => 'bar' );
$drv->cookie( baz => 'qux', path => '/' );

my $cookie = {
    domain   => 'httpd',
    expiry   => re('^\d+'),
    httpOnly => bool(0),
    name     => 'foo',
    path     => '/',
    secure   => bool(0),
    value    => 'bar',
};

cmp_deeply $drv->cookie('foo'), $cookie, 'Cookie "foo" exists';

cmp_deeply $drv->cookies, {
    foo => $cookie,
    baz => {
        domain   => 'httpd',
        expiry   => re('^\d+'),
        httpOnly => bool(0),
        name     => 'baz',
        path     => '/',
        secure   => bool(0),
        value    => 'qux',
    },
}, 'Cookies exists';

$drv->cookie_delete('foo');

is_deeply [ keys %{ $drv->cookies } ], ['baz'], 'Only "baz" left';

$drv->cookie_delete;

is keys %{ $drv->cookies }, 0, 'No cookies left';

done_testing;
