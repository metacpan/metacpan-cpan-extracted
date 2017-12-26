use lib 't';
use t   '16';

is $drv->$_('foo'), $drv, "drv->$_('foo') should return \$self" for qw/
    alert_accept
    alert_dismiss
    back
    base_url
    cookie_delete
    forward
    get
    refresh
    window_close
    window_maximize
    window_switch
/;

is $drv->$_( 1, 1 ), $drv, "drv->$_( 1, 1 ) should return \$self" for qw/
    cookie
    window_rect
/;

is $elem->$_, $elem, "elem->$_ should return \$self" for qw/
    clear
    click
    tap
/;
