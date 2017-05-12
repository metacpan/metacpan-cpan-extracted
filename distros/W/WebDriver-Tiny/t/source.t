use lib 't';
use t   '1';

$drv->source;

reqs_are [ [ GET => '/source' ] ], '->source';
