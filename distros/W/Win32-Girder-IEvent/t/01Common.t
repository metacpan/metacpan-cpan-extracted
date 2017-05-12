use strict;
use Test;

BEGIN { plan tests => 5 };

use Win32::Girder::IEvent::Common qw(
        hash_password
        $def_pass
        $def_port
        $def_host
);

ok(1); # If we made it this far, we're ok.
ok($def_pass,"NewDefPWD");
ok($def_port,1024);
ok($def_host,'localhost');
ok('894fef51aebc1c838c374276527e8286', hash_password('12ab','NewDefPWD'));

