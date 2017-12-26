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

my $num = re qr/^[\d.]+$/a;

my $elem = $drv->('h1');

cmp_deeply $elem->rect,
    { 'width', $num, 'height', $num, 'x', $num, 'y', $num }, 'rect';

done_testing;
