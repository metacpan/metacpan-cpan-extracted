use lib 't';
use t   '1';

$elem->rect;

reqs_are [ [ GET => '/element/123/rect' ] ], '->rect';
