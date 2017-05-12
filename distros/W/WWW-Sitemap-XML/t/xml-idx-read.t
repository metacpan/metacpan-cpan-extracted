
use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('WWW::SitemapIndex::XML') };

my $o;

lives_ok {
    $o = WWW::SitemapIndex::XML->new();
} 'test object created';

my @sitemaps;
lives_ok {
    @sitemaps = $o->read( string => _read_sitemapindex() );
} 'sitemapindex.xml loaded';

is scalar @sitemaps, 9, "all 9 sitemaps loaded";

is_deeply [ map { $_->loc } @sitemaps ], [
    'http://www.mywebsite.com/sitemap1.xml?param1=value1&param2=value2',
    'http://www.mywebsite.com/sitemap2.xml',
    'http://www.mywebsite.com/sitemap3.xml?name=Alex%20J.%20G.%20Burzy%C5%84ski',
    'http://www.mywebsite.com/sitemap4.xml',
    'http://www.mywebsite.com/sitemap5.xml?param3=value3#fragment',
    'http://www.mywebsite.com/sitemap6.xml',
    'http://www.mywebsite.com/sitemap7.xml',
    'http://www.mywebsite.com/sitemap8.xml',
    'http://www.mywebsite.com/sitemap9.xml',
], "<loc> correct for all";


is_deeply [ map { $_->lastmod } @sitemaps ], [qw(
    2010-11-19T19:05:01+00:00
    2010-11-19T13:05:01+00:00
    2010-11-19T16:05:01
    2010-11-19T06:05
    2010-11-19T18:05:01.12-05:00
    2010-11-19T13:05:01+01:00
    2010-11-19T16:05:01.45Z
    2010
    2010-11-19
)], "<lastmod> correct for all";


sub _read_sitemapindex {
    local $/;
    open SITEMAP, 't/data/sitemapindex.xml';
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}
