# -*- mode: perl -*-
#
# $Id$
#

use Test;
use Text::SimpleTemplate;

BEGIN { plan tests => 1 }

$tmpl = new Text::SimpleTemplate;
$tmpl->pack(q{
<% my $text; for (0..9) { $text .= $_; } "<%$text"; %>
});
ok($tmpl->fill, "\n<%0123456789\n");

exit(0);
