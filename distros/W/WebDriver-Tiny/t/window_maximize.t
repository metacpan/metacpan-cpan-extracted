use lib 't';
use t   '1';

$drv->window_maximize;

reqs_are [ [ POST => '/window/maximize' ] ], '->window_maximize';
