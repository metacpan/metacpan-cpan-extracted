
use strict;
use warnings;

use Test::More tests => 12;
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
} 'sitemap-google.xml loaded';

is scalar @urls, 2, "all 2 URLs loaded";

is_deeply [ map { $_->loc } @urls ], [
    'http://example.com/sample1.html',
    'http://example.com/sample2.html',
], "<loc> correct for all";


is_deeply [ map { $_->lastmod } @urls ], [qw(
    2014
    2014
)], "<lastmod> correct for all";

is_deeply [ map { $_->changefreq } @urls ], [qw(
    never
    never
)], "<changefreq> correct for all";

is_deeply [ map { $_->priority } @urls ], [qw(
    0.1
    0.8
)], "<priority> correct for all";

is_deeply [ map { $_->mobile } @urls ], [
    undef,
    1
], "<mobile:mobile> correct for all";

is_deeply [ map { @{ $_->images } } @urls ], [
    WWW::Sitemap::XML::Google::Image->new(
        {
            loc => 'http://example.com/image1.jpg',
            caption => 'Caption 1',
            title => 'Title 1',
            license => 'http://www.mozilla.org/MPL/2.0/',
            geo_location => 'Town 1, Region 1',
        },
    ),
    WWW::Sitemap::XML::Google::Image->new(
        {
            loc => 'http://example.com/image2.jpg',
            caption => 'Caption 2',
            title => 'Title 2',
            license => 'http://www.mozilla.org/MPL/2.0/',
            geo_location => 'Town 2, Region 1',
        }
    ),
    WWW::Sitemap::XML::Google::Image->new(
        {
            loc => 'http://example.com/image3.jpg',
            caption => 'Caption 3',
            title => 'Title 3',
            license => 'http://www.mozilla.org/MPL/2.0/',
            geo_location => 'Town 1, Region 2',
        },
    ),
    WWW::Sitemap::XML::Google::Image->new(
        {
            loc => 'http://example.com/image4.jpg',
            caption => 'Caption 4',
            title => 'Title 4',
            license => 'http://www.mozilla.org/MPL/2.0/',
            geo_location => 'Town 2, Region 2',
        }
    ),
], "<image:image> correct for all";

is_deeply [ map { @{ $_->videos } } @urls ], [
    WWW::Sitemap::XML::Google::Video->new(
        content_loc => 'http://example.com/video1.flv',
        player => WWW::Sitemap::XML::Google::Video::Player->new(
            {
                loc => 'http://example.com/video_player.swf?video=1',
                allow_embed => "yes",
                autoplay => "ap=1",
            }
        ),
        thumbnail_loc => 'http://example.com/thumbs/1.jpg',
        title => 'Video Title 1',
        description => 'Video Description 1',
    ),
    WWW::Sitemap::XML::Google::Video->new(
        content_loc => 'http://example.com/video2.flv',
        player => WWW::Sitemap::XML::Google::Video::Player->new(
            {
                loc => 'http://example.com/video_player.swf?video=2',
                allow_embed => "yes",
                autoplay => "ap=1",
            }
        ),
        thumbnail_loc => 'http://example.com/thumbs/2.jpg',
        title => 'Video Title 2',
        description => 'Video Description 2',
    ),
], "<video:video> correct for all";


sub _read_sitemap {
    local $/;
    open SITEMAP, 't/data/sitemap-google.xml';
    my $xml =  <SITEMAP>;
    close SITEMAP;
    return $xml;
}
