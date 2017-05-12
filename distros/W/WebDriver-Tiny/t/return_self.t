use lib 't';
use t scalar(
    @::methods = qw/
        accept_alert
        back
        base_url
        cookie_delete
        dismiss_alert
        forward
        get
        refresh
        window_close
        window_maximize
        window_switch
    /
) + 4;

is $drv->$_('foo'), $drv, "->$_ should return \$self" for @::methods;

is $drv->$_( 1, 1 ), $drv, "->$_ should return \$self"
    for qw/cookie storage window_position window_size/;
