use lib 't';
use t   '2';

$drv->html;

reqs_are [ [ GET => '/source' ] ], '$drv->html';

$elem->html;

reqs_are [ [
    POST => '/execute/sync',
    {   args   => [ { ELEMENT => 123 } ],
        script => 'return arguments[0].outerHTML',
    },
] ], '$elem->html';
