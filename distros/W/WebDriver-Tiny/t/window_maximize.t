use lib 't';
use t   '2';

$drv->window_maximize;

reqs_are [ [ POST => '/window/current/maximize' ] ], '->window_maximize';

$drv->window_maximize('foo');

reqs_are [ [ POST => '/window/foo/maximize' ] ], '->window_maximize("foo")';
