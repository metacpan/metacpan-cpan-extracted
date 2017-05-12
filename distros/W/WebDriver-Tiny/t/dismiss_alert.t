use lib 't';
use t   '2';

$drv->dismiss_alert;

reqs_are [], '->dismiss_alert without handlesAlerts does nothing';

$drv->[3]{handlesAlerts} = 1;

$drv->dismiss_alert;

reqs_are [ [ POST => '/dismiss_alert' ] ], '->dismiss_alert';
