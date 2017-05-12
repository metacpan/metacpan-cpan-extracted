use lib 't';
use t   '1';

$content = '{"value":""}';

$drv->screenshot;

reqs_are [ [ GET => '/screenshot' ] ], '->screenshot';
