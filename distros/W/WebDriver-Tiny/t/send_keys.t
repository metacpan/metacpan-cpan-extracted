use lib 't';
use t   '1';
use utf8;

$elem->send_keys('perl☃');

reqs_are [ [ POST => '/element/123/value', { text => 'perl☃' } ] ],
    '->send_keys("perl")';
