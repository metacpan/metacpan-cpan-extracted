use strict;
use warnings;

use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd');

is $drv->js('return "foo"'), 'foo', q/js('return "foo"')/;

is $drv->js_async('arguments[0]("bar")'), 'bar',
    q/js_async('arguments[0]("bar")')/;

done_testing;
