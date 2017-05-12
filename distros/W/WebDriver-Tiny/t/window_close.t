use lib 't';
use t   '1';

$drv->window_close;

reqs_are [ [ DELETE => '/window' ] ], '->window_close';
