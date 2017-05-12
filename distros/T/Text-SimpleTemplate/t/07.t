# -*- mode: perl -*-
#
# $Id: 07.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 1 }

$tmpl = new Text::SimpleTemplate;
$tmpl->pack(<<'EOF');
<% my $text; for (0..9) { $text .= $_; } $text; %>
EOF

ok("0123456789\n", $tmpl->fill);

exit(0);
