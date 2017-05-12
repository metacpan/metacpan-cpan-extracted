use lib 't';
use t   '1';

$drv->js_phantom('foo');

reqs_are [ [ POST => '/phantom/execute', { args => [], script => 'foo' } ] ],
    '->js_phantom("foo")';
