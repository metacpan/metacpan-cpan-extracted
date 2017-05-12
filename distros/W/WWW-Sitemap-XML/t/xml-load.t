
use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('WWW::Sitemap::XML') };

my $o;

lives_ok {
    $o = WWW::Sitemap::XML->new();
} 'test object created';

lives_ok {
    $o->load( string => _read_sitemap() );
} 'sitemap.xml loaded';

is scalar $o->urls, 9, "all 9 URLs loaded";

is_deeply [ map { $_->loc } $o->urls ], [
'http://www.mywebsite.com/32.html?param1=value1&param2=value2',
'http://www.mywebsite.com/2.html',
'http://www.mywebsite.com/friendly_url.html?name=Alex%20J.%20G.%20Burzy%C5%84ski',
'http://www.mywebsite.com/31.html',
'http://www.mywebsite.com/index.html?param3=value3#fragment',
'http://www.mywebsite.com/21.html',
'http://www.mywebsite.com/3.html',
'http://www.mywebsite.com/22.html',
'http://www.mywebsite.com/1.html',
], "urls added in correct order";


sub _read_sitemap {
    local $/;
    open SITEMAP, 't/data/sitemap.xml';
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}
