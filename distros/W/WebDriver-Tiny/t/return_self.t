use lib 't';
use t   '17';

is $drv->$_, $drv, "drv->$_ should return \$self" for qw/
    alert_accept
    alert_dismiss
    back
    cookie_delete
    forward
    refresh
    window_close
    window_maximize
/;

is $drv->$_('foo'), $drv, "drv->$_('foo') should return \$self" for qw/
    base_url
    cookie_delete
    get
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
