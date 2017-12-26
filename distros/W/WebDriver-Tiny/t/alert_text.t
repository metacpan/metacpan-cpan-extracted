use lib 't';
use t   '1';

$drv->alert_text;

reqs_are [ [ GET => '/alert/text' ] ], '->alert_text';
