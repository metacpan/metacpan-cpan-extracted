#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use UnixODBC::BridgeServer ok(1);
use UnixODBC::RSS ok(2);
use UnixODBC::DriverConf ok(3);
exit;
__END__


