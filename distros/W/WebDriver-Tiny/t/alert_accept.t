use lib 't';
use t   '1';

$drv->alert_accept;

reqs_are [ [ POST => '/alert/accept' ] ], '->alert_accept';
