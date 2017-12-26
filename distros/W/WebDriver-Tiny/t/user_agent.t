use lib 't';
use t   '1';

$drv->user_agent;

reqs_are [ [
    POST => '/execute/sync',
    { args => [], script => 'return window.navigator.userAgent' },
] ], '->user_agent';
