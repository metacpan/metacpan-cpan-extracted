use lib 't';
use t   '1';

$drv->title;

reqs_are [ [ GET => '/title' ] ], '->title';
