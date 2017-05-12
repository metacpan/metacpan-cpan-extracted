use lib 't';
use t   '1';

$drv->cookies;

reqs_are [ [ GET => '/cookie' ] ], '->cookies';
