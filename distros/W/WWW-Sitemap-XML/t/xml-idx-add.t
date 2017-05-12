
use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;
use Test::NoWarnings;
use URI;

BEGIN { use_ok('WWW::SitemapIndex::XML') };

my $o;

lives_ok {
    $o = WWW::SitemapIndex::XML->new();
} 'test object created';

{
    package Test::WWW::SitemapIndex::XML::NotImplements;
    use Moose;

    has 'loc' => (
        is => 'rw',
        isa => 'Str',
    );
}

{
    package Test::WWW::SitemapIndex::XML::DoesImplements;
    use Moose;

    has [qw( loc lastmod as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    with 'WWW::SitemapIndex::XML::Sitemap::Interface';
}

my %valid = (
    url_only => [
        'http://mywebsite.com:81/sitemap1.xml.gz',
    ],
    loc_only => [
        loc => 'http://mywebsite.com:81/sitemap2.xml.gz?a=1&b=2',
    ],
    loc_only_hashref => [
        {
            loc => 'http://mywebsite.com:81/sitemap3.xml.gz?a=1&b=2',
        }
    ],
    all_values => [
        loc => 'http://mywebsite.com:81/sitemap4.xml.gz?a=1&b=2',
        lastmod => time(),
    ],
    all_values_hashref => [
        {
            loc => 'http://mywebsite.com:81/sitemap5.xml.gz?a=1&b=2',
            lastmod => time(),
        }
    ],
    www_sitemap_xml_url => [
        WWW::SitemapIndex::XML::Sitemap->new(
            loc => URI->new('http://mywebsite.com:81/sitemap6.xml.gz?a=1&b=2'),
            lastmod => time(),
        ),
    ],
    other_class => [
        Test::WWW::SitemapIndex::XML::DoesImplements->new(
            loc => 'http://mywebsite.com:81/sitemap7.xml.gz?a=1&b=2',
            lastmod => '2010',
            as_xml => '<sitemap><loc>http://mywebsite.com:81/sitemap7.xml.gz</loc></sitemap>',
        ),
    ],
);

my $count = $o->sitemaps;
for my $test ( keys %valid ) {
    lives_ok {
        $o->add( @{ $valid{$test} } );
    } "add works for $test";

    is scalar $o->sitemaps, ++$count,
        "...and one sitemap has been added";

    lives_ok {
        $o->as_xml;
    } "...and as_xml works";
}

my %invalid = (
    'different_proto' => [
        loc => 'https://mywebsite.com:81/sitemap.xml.gz',
    ],
    'different_port' => [
        loc => 'http://mywebsite.com/sitemap.xml.gz',
    ],
    'different_host' => [
        loc => 'http://subdomain.mywebsite.com:81/sitemap.xml.gz',
    ],
    'too_long' => [
        loc => 'http://subdomain.mywebsite.com:81/'. ( 'a' x 2040),
    ],
    'no_scheme' => [
        loc => 'subdomain.mywebsite.com/sitemap.xml.gz',
    ],
    'wrong_object' => [
        Test::WWW::SitemapIndex::XML::NotImplements->new(
            loc => 'http://mywebsite.com:81/sitemap.xml.gz',
        )
    ],
);

for my $test ( keys %invalid ) {
    dies_ok {
        $o->add( @{ $invalid{$test} } );
    } "add does not work for $test";
}

SKIP: {
    skip "long running tests", 1
        unless $ENV{RELEASE_TESTING};

    for ( scalar($o->sitemaps) + 1 .. 50_000) {
        $o->add( loc => "http://mywebsite.com:81/sitemap-$_.xml" );
    }

    dies_ok {
        $o->add( loc => "http://mywebsite.com:81/sitemap-50001.xml" );
    } "sitemap cannot cointain more then 50 000 sitemaps";
};


