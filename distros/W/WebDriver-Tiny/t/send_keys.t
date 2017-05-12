use lib 't';
use t   '1';
use utf8;

$elem->send_keys('perl☃');

reqs_are [ [ POST => '/element/123/value', { value => [qw/p e r l ☃/] } ] ],
    '->send_keys("perl")';
