use lib 't';
use t   '1';

$elem->tag;

reqs_are [ [ GET => '/element/123/name' ] ], '->tag';
