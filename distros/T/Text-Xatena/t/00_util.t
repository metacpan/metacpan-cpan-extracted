use strict;
use Test::More tests => 5;

use Text::Xatena::Util;

is escape_html("'"), "&#39;";
is escape_html('"'), "&#34;";
is escape_html('<'), "&lt;";
is escape_html('>'), "&gt;";
is escape_html('&'), "&amp;";

