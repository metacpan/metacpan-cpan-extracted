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

$drv->window_rect( 640, 480 );

is_deeply $drv->window_rect, { qw/width 640 height 480 x 0 y 0/ },
    'window_size( 640, 480 )';

$drv->window_rect( 800, 600, 10, 20 );

is_deeply $drv->window_rect, { qw/width 800 height 600 x 10 y 20/ },
    'window_rect( 800, 600, 10, 20 )';

$drv->window_maximize;

is_deeply $drv->window_rect, { qw/width 1366 height 768 x 10 y 20/ },
    'window_maximize';

is_deeply $drv->windows, [ $drv->window ], 'windows & window';

$drv->window_switch( $drv->window );

#$drv->window_minimize;

#is_deeply $drv->window_rect, { qw/width 1366 height 768 x 10 y 20/ },
#    'window_minimize';

done_testing;
