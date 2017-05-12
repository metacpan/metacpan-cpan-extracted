use lib 't';
use t   '1';

$drv->js('foo');

reqs_are [ [ POST => '/execute', { args => [], script => 'foo' } ] ],
    '->js("foo")';
