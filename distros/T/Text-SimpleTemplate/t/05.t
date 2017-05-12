# -*- mode: perl -*-
#
# $Id: 05.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 1 }

open(FILE, $0);

$tmpl = new Text::SimpleTemplate;
$buff = join("", <FILE>);
ok($tmpl->load($0)->fill, $buff);

exit(0);
