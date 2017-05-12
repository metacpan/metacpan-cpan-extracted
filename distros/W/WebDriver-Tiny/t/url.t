use lib 't';
use t   '1';

$drv->url;

reqs_are [ [ GET => '/url' ] ], '->url';
