
use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('WWW::SitemapIndex::XML') };

my $o;

lives_ok {
    $o = WWW::SitemapIndex::XML->new();
} 'test object created';

lives_ok {
    $o->load(string =>  _read_sitemapindex() );
} 'sitemapindex.xml loaded';

is scalar $o->sitemaps, 9, "all 9 sitemaps loaded";

is_deeply [ map { $_->loc} $o->sitemaps ], [
'http://www.mywebsite.com/sitemap1.xml?param1=value1&param2=value2',
'http://www.mywebsite.com/sitemap2.xml',
'http://www.mywebsite.com/sitemap3.xml?name=Alex%20J.%20G.%20Burzy%C5%84ski',
'http://www.mywebsite.com/sitemap4.xml',
'http://www.mywebsite.com/sitemap5.xml?param3=value3#fragment',
'http://www.mywebsite.com/sitemap6.xml',
'http://www.mywebsite.com/sitemap7.xml',
'http://www.mywebsite.com/sitemap8.xml',
'http://www.mywebsite.com/sitemap9.xml',
], "sitemaps added in correct order";


my $xml = $o->as_xml;
isa_ok $o->as_xml, 'XML::LibXML::Document';
is @{[ $xml->getElementsByTagName('sitemap') ]}, 9, "all 9 sitemaps in xml output";


sub _read_sitemapindex {
    local $/;
    open SITEMAP, 't/data/sitemapindex.xml';
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}
