use lib 't';
use t   '1';

$drv->refresh;

reqs_are [ [ POST => '/refresh' ] ], '->refresh';
