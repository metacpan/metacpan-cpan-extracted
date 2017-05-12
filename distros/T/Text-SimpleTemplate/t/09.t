# -*- mode: perl -*-
#
# $Id$
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 1 }

$tmpl = new Text::SimpleTemplate;
$tmpl->pack('<% $ZERO %>');
$tmpl->setq(ZERO => 0);

ok($tmpl->fill eq "0");

exit(0);
