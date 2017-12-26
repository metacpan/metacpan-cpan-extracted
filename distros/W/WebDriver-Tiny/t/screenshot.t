use lib 't';
use t   '2';

$content = '{"value":""}';

$drv->screenshot;

reqs_are [ [ GET => '/screenshot' ] ], '$drv->screenshot';

$elem->screenshot;

reqs_are [ [ GET => '/element/123/screenshot' ] ], '$elem->screenshot';
