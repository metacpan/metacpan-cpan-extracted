use lib 't';
use t   '1';

$elem->css('foo');

reqs_are [ [ GET => '/element/123/css/foo' ] ], '->css("foo")';
