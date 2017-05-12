use lib 't';
use t   '1';

$drv->window_switch('foo');

reqs_are [ [ POST => '/window', { name => 'foo' } ] ], '->window_switch("foo")';
