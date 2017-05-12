use lib 't';
use t   '3';

$drv->cookie_delete;

reqs_are [ [ DELETE => '/cookie' ] ], '->cookie_delete';

$drv->cookie_delete('foo');

reqs_are [ [ DELETE => '/cookie/foo' ] ], '->cookie_delete("foo")';

$drv->cookie_delete(qw/foo bar/);

reqs_are [ [ DELETE => '/cookie/foo' ], [ DELETE => '/cookie/bar' ]  ],
    '->cookie_delete( "foo", "bar" )';
