use lib 't';
use t   '1';

$elem->attr('foo');

reqs_are [ [ GET => '/element/123/attribute/foo' ] ], '->attr("foo")';
