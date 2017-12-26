use lib 't';
use t   '1';

$drv->alert_dismiss;

reqs_are [ [ POST => '/alert/dismiss' ] ], '->alert_dismiss';
