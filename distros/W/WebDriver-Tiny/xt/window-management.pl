use strict;
use warnings;

my $int = re qr/^\d+$/;
my $js  = <<'JS';
    return [
        window.outerWidth  || window.innerWidth,
        window.outerHeight || window.innerHeight,
    ];
JS

sub {
    my $drv = shift;

    $drv->window_size( 640, 480 );

    is_deeply $drv->js($js), [ 640, 480 ], 'window_size( 640, 480 )';

    is_deeply [ $drv->window_size ], [ 640, 480 ], 'window_size';

    $drv->window_size( 800, 600 );

    is_deeply $drv->js($js), [ 800, 600 ], 'window_size( 800, 600 )';

    is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

    $drv->window_maximize;

    cmp_deeply [ $drv->window_size ], [ $int, $int ], 'window_maximize';

    $drv->window_size( current => 800, 600 );

    is_deeply [ $drv->window_size ], [ 800, 600 ], 'window_size';

    $drv->window_maximize('current');

    cmp_deeply [ $drv->window_size ], [ $int, $int ],
        'window_maximize("current")';
};
