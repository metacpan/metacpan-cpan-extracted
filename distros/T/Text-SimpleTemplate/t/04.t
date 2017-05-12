# -*- mode: perl -*-
#
# $Id: 04.t,v 1.1 1999/10/24 13:30:25 tai Exp $
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 2 }

$tmpl = new Text::SimpleTemplate;
$tmpl->setq("TEXT", "hello, world");

$tmpl->pack(<<'EOF');
<% $TEXT %>
EOF

ok("hello, world\n", $tmpl->fill);

$tmpl->pack(<<'EOF');
<%
$text = <<EOT;
$TEXT
EOT
%>
EOF

ok("hello, world\n\n", $tmpl->fill);

exit(0);
