use lib 't';
use t   '2';

$drv->accept_alert;

reqs_are [], '->accept_alert without handlesAlerts does nothing';

$drv->[3]{handlesAlerts} = 1;

$drv->accept_alert;

reqs_are [ [ POST => '/accept_alert' ] ], '->accept_alert';
