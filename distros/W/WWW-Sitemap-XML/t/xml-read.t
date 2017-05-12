
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('WWW::Sitemap::XML') };

my $o;

lives_ok {
    $o = WWW::Sitemap::XML->new();
} 'test object created';

my @urls;
lives_ok {
    @urls = $o->read( string => _read_sitemap() );
} 'sitemap.xml loaded';

is scalar @urls, 9, "all 9 URLs loaded";

is_deeply [ map { $_->loc } @urls ], [
    'http://www.mywebsite.com/32.html?param1=value1&param2=value2',
    'http://www.mywebsite.com/2.html',
    'http://www.mywebsite.com/friendly_url.html?name=Alex%20J.%20G.%20Burzy%C5%84ski',
    'http://www.mywebsite.com/31.html',
    'http://www.mywebsite.com/index.html?param3=value3#fragment',
    'http://www.mywebsite.com/21.html',
    'http://www.mywebsite.com/3.html',
    'http://www.mywebsite.com/22.html',
    'http://www.mywebsite.com/1.html',
], "<loc> correct for all";


is_deeply [ map { $_->lastmod } @urls ], [qw(
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

is_deeply [ map { $_->changefreq } @urls ], [qw(
    weekly
    daily
    weekly
    daily
    always
    weekly
    always
    never
    monthly
)], "<changefreq> correct for all";

is_deeply [ map { $_->priority } @urls ], [qw(
    0.5
    0.3
    0.7
    0.1
    1.0
    0.6
    0.5
    0.1
    0.2
)], "<priority> correct for all";


sub _read_sitemap {
    local $/;
    open SITEMAP, 't/data/sitemap.xml';
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}
