use strict;
use warnings;

use Test::More tests => 40;
use Test::Exception;
use Test::NoWarnings;
use URI;

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

{

    package Test::WWW::Sitemap::XML::Types;
    use Moose;
    use WWW::Sitemap::XML::Types qw( SitemapURL SitemapIndexSitemap Location ChangeFreq Priority ArrayRefOfImageObjects ArrayRefOfVideoObjects );

    has 'sitemap' => (
        is => 'rw',
        isa => SitemapIndexSitemap,
    );

    has 'url' => (
        is => 'rw',
        isa => SitemapURL,
    );

    has 'loc' => (
        is => 'rw',
        isa => Location,
        coerce => 1,
    );

    has 'changefreq' => (
        is => 'rw',
        isa => ChangeFreq,
    );

    has 'priority' => (
        is => 'rw',
        isa => Priority,
    );

    has 'images' => (
        is => 'rw',
        isa => ArrayRefOfImageObjects,
    );

    has 'videos' => (
        is => 'rw',
        isa => ArrayRefOfVideoObjects,
    );

}

my $o;

lives_ok {
    $o = Test::WWW::Sitemap::XML::Types->new();
} 'test object created';

my $implements = Test::WWW::Sitemap::XML::DoesImplements->new();
my $doesnt_implement = Test::WWW::Sitemap::XML::NotImplements->new();

my $idx_implements = Test::WWW::SitemapIndex::XML::DoesImplements->new();
my $idx_doesnt_implement = Test::WWW::SitemapIndex::XML::NotImplements->new();

lives_ok {
    $o->url( $implements );
} "SitemapURL accepts object implementing WWW::Sitemap::XML::URL::Interface";

dies_ok {
    $o->url( $doesnt_implement );
} "SitemapURL rejects object not implementing WWW::Sitemap::XML::URL::Interface";

lives_ok {
    $o->sitemap( $idx_implements );
} "SitemapIndexSitemap accepts object implementing WWW::SitemapIndex::XML::Sitemap::Interface";

dies_ok {
    $o->sitemap( $idx_doesnt_implement );
} "SitemapIndexSitemap rejects object not implementing WWW::SitemapIndex::XML::Sitemap::Interface";

my @valid_locs = (
    "http://mywebsite.com/",
    "http://mywebsite.com:8080/",
    "https://mywebsite.com/",
    "https://mywebsite.com:443/",
    "gopher://mywebsite.com/#fragment",
    URI->new("http://mywebsite.com/"),
);
my @invalid_locs = (
    "mywebsite.com",
    "gopher://#fragment",
    [qw( mywebsite1.com mywebsite2.com)],
);

for my $valid_loc ( @valid_locs ) {
    lives_ok {
        $o->loc($valid_loc);
    } "$valid_loc is a valid Location";
}

for my $invalid_loc ( @invalid_locs ) {
    dies_ok {
        $o->loc($invalid_loc);
    } "$invalid_loc is not a valid Location";
}


for my $valid_changefreq ( qw( always hourly daily weekly monthly yearly never ) ) {
    lives_ok {
        $o->changefreq( $valid_changefreq );
    } "$valid_changefreq is a valid ChangeFreq";
}

for my $invalid_cf ( qw( nightly fortnight ) ) {
    eval {
        $o->changefreq( $invalid_cf );
    };
    my $e = $@;
    isa_ok($e, 'Moose::Exception');
    is($e->attribute_name, 'changefreq', '...and exception thrown for changefreq');
}

for ( 0 .. 10 ) {
    my $p = sprintf("%.1f", $_/10);
    lives_ok {
        $o->priority( $p );
    } "$p is a valid Priority";
}
for my $p (qw( -1 2 10 )) {
    throws_ok {
        $o->priority( $p );
    } qr/Valid priority ranges from 0.0 to 1.0/, "$p is not a valid Priority";
}
