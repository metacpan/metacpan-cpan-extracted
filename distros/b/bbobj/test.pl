## $Id: test.pl,v 1.1.1.1 2002/07/14 05:57:43 dshanks Exp $

use Test;
BEGIN { plan tests => 3 };
use BigBrother::Object;
ok(1); # It seems the Object module loaded
use BigBrother::Object::Config;
ok(1); # And the config file made it as well
use BigBrother::Object::Downtime;
ok(1); # Again, if we got this far ...
