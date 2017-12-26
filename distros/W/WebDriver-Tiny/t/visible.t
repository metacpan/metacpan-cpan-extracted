use lib 't';
use t   '1';

$elem->visible;

reqs_are [ [ GET => '/element/123/displayed' ] ], '->visible';
