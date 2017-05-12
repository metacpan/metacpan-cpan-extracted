use lib 't';
use t   '7';

is $drv->base_url, '';

is $drv->base_url('foo'), $drv;

is $drv->base_url, 'foo';

is $drv->base_url(undef), $drv;

is $drv->base_url, '';

is $drv->base_url('dickköpfig'), $drv;

is $drv->base_url, 'dickköpfig';
