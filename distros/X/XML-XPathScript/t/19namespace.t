use strict;
use warnings;

use Test::More "no_plan";     # I, for one, don't like it when a plan
                              # comes together

use XML::XPathScript;

my $xps = XML::XPathScript->new;

my $noop_stylesheet = '<%= apply_templates() %>';
my $result = $xps->transform( <<'NAMESPACED_XML', $noop_stylesheet);
<rss xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:wp="http://wordpress.org/export/1.2/" version="2.0">
    <channel>
     <title>Geography Channel</title>
     <wp:wxr_version>1.2</wp:wxr_version>
    </channel>
</rss>
NAMESPACED_XML

my ($rss_attributes) = $result =~ m/^<rss ([^>]*)>/;
my @rss_attributes = split m/ /, $rss_attributes;
is scalar(grep { $_ eq 'version="2.0"' } @rss_attributes), 1;
is scalar(grep { $_ =~ m/^xmlns:/      } @rss_attributes), 3;
unlike $result, qr{xmlns:xmlns:};
like $result, qr{<wp:wxr_version>1.2</wp:wxr_version>};
like $result, qr{<title>Geography Channel</title>};
