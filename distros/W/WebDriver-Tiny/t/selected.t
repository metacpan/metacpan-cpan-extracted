use lib 't';
use t   '1';

$elem->selected;

reqs_are [ [ GET => '/element/123/selected' ] ], '->selected';
