use lib 't';
use t   '1';

$drv->windows;

reqs_are [ [ GET => '/window/handles' ] ], '->windows';
