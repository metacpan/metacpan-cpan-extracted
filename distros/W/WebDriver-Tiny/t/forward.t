use lib 't';
use t   '1';

$drv->forward;

reqs_are [ [ POST => '/forward' ] ], '->forward';
