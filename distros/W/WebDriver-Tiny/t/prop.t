use lib 't';
use t   '1';

$elem->prop('foo');

reqs_are [ [ GET => '/element/123/property/foo' ] ], '->prop("foo")';
