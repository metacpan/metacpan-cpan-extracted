use lib 't';
use t   '1';

$drv->back;

reqs_are [ [ POST => '/back' ] ], '->back';
