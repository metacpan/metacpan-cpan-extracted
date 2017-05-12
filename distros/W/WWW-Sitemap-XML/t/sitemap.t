
use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('WWW::SitemapIndex::XML::Sitemap') }


my $o;

my @valid = (
    {
        loc => 'http://www.mywebsite.com/sitemap1.xml.gz',
    },
    {
        loc => 'http://www.mywebsite.com/sitemap1.xml.gz?source=google',
        lastmod => time(),
    }
);
my @invalid = (
    {},
    {
        loc => 'http://mywebsite.com/sitemap1.xml.gz',
        lastmod => 'now',
    },
);

for my $args ( @valid ) {
    lives_ok {
        $o = WWW::SitemapIndex::XML::Sitemap->new(%$args);
    } 'object created with valid args';
    isa_ok($o->as_xml, 'XML::LibXML::Element');
}

for my $args ( @invalid ) {
    dies_ok {
        $o = WWW::SitemapIndex::XML::Sitemap->new(%$args);
    } 'object not created with invalid args';
}

