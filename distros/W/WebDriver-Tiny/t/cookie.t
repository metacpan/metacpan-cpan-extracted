use lib 't';
use t   '3';

$drv->cookie('foo');

reqs_are [ [ GET => '/cookie' ] ], '->cookie("foo")';

$drv->cookie( foo => 'bar' );

reqs_are [ [ POST => '/cookie', { cookie => {qw/name foo value bar/} } ] ],
    '->cookie( foo => "bar" )';

$drv->cookie( foo => 'bar', baz => 'qux' );

reqs_are [ [ POST => '/cookie', { cookie => {qw/name foo value bar baz qux/} } ] ],
    '->cookie( foo => "bar", baz => "qux" )';
