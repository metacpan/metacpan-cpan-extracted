use lib 't';
use t   '1';

$drv->window;

reqs_are [ [ GET => '/window' ] ], '->window';
