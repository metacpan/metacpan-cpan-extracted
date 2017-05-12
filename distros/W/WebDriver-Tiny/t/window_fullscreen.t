use lib 't';
use t   '1';

$drv->window_fullscreen;

reqs_are [ [ POST => '/window/fullscreen' ] ], '->window_fullscreen';
