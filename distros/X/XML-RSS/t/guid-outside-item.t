# This is to test the following bug:
# https://github.com/shlomif/perl-XML-RSS/issues/24

use strict;
use warnings;

use Test::More tests => 1;

use XML::RSS ();

{
    my $rss_text = <<"EOF";
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
xmlns:podcast="https://podcastindex.org/namespace/1.0"
>
<channel>
    <podcast:guid>11111111-1111-1111-1111-111111111111</podcast:guid>
    </channel>
    </rss>
EOF

    my $xml = XML::RSS->new(version => "2.0");

    $xml->parse($rss_text);

    # TEST
    pass("guid not inside an item element")
}
