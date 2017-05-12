use strict;
use utf8;
use warnings;

sub {
    my $drv = shift;

    $drv->js('window.alert("💩")');

    is $drv->alert_text, $drv->capabilities->{handlesAlerts} ? '💩' : undef,
        'alert_text';

    $drv->dismiss_alert;
}
