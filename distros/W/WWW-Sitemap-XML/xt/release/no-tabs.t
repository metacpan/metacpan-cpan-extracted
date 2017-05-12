use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/Sitemap/XML.pm',
    'lib/WWW/Sitemap/XML/Google/Image.pm',
    'lib/WWW/Sitemap/XML/Google/Image/Interface.pm',
    'lib/WWW/Sitemap/XML/Google/Video.pm',
    'lib/WWW/Sitemap/XML/Google/Video/Interface.pm',
    'lib/WWW/Sitemap/XML/Google/Video/Player.pm',
    'lib/WWW/Sitemap/XML/Google/Video/Player/Interface.pm',
    'lib/WWW/Sitemap/XML/Types.pm',
    'lib/WWW/Sitemap/XML/URL.pm',
    'lib/WWW/Sitemap/XML/URL/Interface.pm',
    'lib/WWW/SitemapIndex/XML.pm',
    'lib/WWW/SitemapIndex/XML/Sitemap.pm',
    'lib/WWW/SitemapIndex/XML/Sitemap/Interface.pm'
);

notabs_ok($_) foreach @files;
done_testing;
