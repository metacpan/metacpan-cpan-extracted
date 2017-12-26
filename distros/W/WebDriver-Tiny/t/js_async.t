use lib 't';
use t   '1';

$drv->js_async('foo');

reqs_are [ [ POST => '/execute/async', { args => [], script => 'foo' } ] ],
    '->js_async("foo")';
