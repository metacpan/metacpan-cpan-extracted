#!perl -w

use strict;
use XML::Feed;
use Test::More tests => 2;


my $html = <<'EOD';
<html>
<head>
	<title>No Entries</title>
</head>
<body>
<p>No entries</p>
</body>
</html>
EOD
ok(my $feed = XML::Feed->parse(\$html), "Parsed the HTML");
is(scalar($feed->entries), 0,           "Got 0 entries");

