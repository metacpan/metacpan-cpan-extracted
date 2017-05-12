use lib 't';
use t   '1';

$elem->enabled;

reqs_are [ [ GET => '/element/123/enabled' ] ], '->enabled';
