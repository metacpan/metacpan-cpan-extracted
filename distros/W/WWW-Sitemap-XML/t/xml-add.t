
use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;
use Test::NoWarnings;
use URI;

BEGIN { use_ok('WWW::Sitemap::XML') };

my $o;

lives_ok {
    $o = WWW::Sitemap::XML->new();
} 'test object created';

{
    package Test::WWW::Sitemap::XML::NotImplements;
    use Moose;

    has 'loc' => (
        is => 'rw',
        isa => 'Str',
    );
}

{
    package Test::WWW::Sitemap::XML::DoesImplements;
    use Moose;

    has [qw( loc lastmod changefreq priority as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    has [qw( images videos )] => (
        is => 'rw',
        isa => 'ArrayRef',
    );

    has [qw( mobile )] => (
        is => 'rw',
        isa => 'Bool',
    );

    with 'WWW::Sitemap::XML::URL::Interface';
}


my %valid = (
    url_only => [
        'http://mywebsite.com:81/page.html',
    ],
    loc_only => [
        loc => 'http://mywebsite.com:81/pageA.html?a=1&b=2',
    ],
    loc_only_hashref => [
        {
            loc => 'http://mywebsite.com:81/pageB.html?a=1&b=2',
        }
    ],
    all_values => [
        loc => 'http://mywebsite.com:81/pageC.html?a=1&b=2',
        lastmod => time(),
        changefreq => 'daily',
        priority => 0.3,
    ],
    all_values_hashref => [
        {
            loc => 'http://mywebsite.com:81/pageD.html?a=1&b=2',
            lastmod => time(), changefreq => 'daily',
            priority => 0.3,
        }
    ],
    www_sitemap_xml_url => [
        WWW::Sitemap::XML::URL->new(
            loc => URI->new('http://mywebsite.com:81/pageE.html?a=1&b=2'),
            lastmod => time(),
            changefreq => 'daily',
            priority => 0.3,
        ),
    ],
    other_class => [
        Test::WWW::Sitemap::XML::DoesImplements->new(
            loc => 'http://mywebsite.com:81/pageE.html?a=1&b=2',
            lastmod => '2010',
            changefreq => 'never',
            priority => 0.3,
            as_xml => '<url><loc>http://mywebsite.com:81/</loc></url>',
        ),
    ],
);

my $count = $o->urls;
for my $test ( keys %valid ) {
    lives_ok {
        $o->add( @{ $valid{$test} } );
    } "add works for $test";

    is scalar $o->urls, ++$count,
        "...and one url has been added";

    lives_ok {
        $o->as_xml;
    } "...and as_xml works";
}

my %invalid = (
    'different_proto' => [
        loc => 'https://mywebsite.com:81',
    ],
    'different_port' => [
        loc => 'http://mywebsite.com',
    ],
    'different_host' => [
        loc => 'http://subdomain.mywebsite.com:81',
    ],
    'too_long' => [
        loc => 'http://subdomain.mywebsite.com:81/'. ( 'a' x 2040),
    ],
    'no_scheme' => [
        loc => 'subdomain.mywebsite.com/file.html',
    ],
    'wrong_object' => [
        Test::WWW::Sitemap::XML::NotImplements->new(
            loc => 'http://mywebsite.com:81',
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

    for ( scalar($o->urls) + 1 .. 50_000) {
        $o->add( loc => "http://mywebsite.com:81/page-no-$_.html" );
    }

    dies_ok {
        $o->add( loc => "http://mywebsite.com:81/page-no-50001.html" );
    } "sitemap cannot cointain more then 50 000 URLs";
};


