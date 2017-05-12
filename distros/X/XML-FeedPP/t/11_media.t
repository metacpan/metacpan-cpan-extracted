# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 37;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
    my $ftitle = "Title of the site";
    my $fdesc  = "Description of the site";
    my $link1  = "http://www.perl.org/";
# ----------------------------------------------------------------
    my $xmlns_media = 'http://search.yahoo.com/mrss/';
    my $media_content_url      = "http://www.kawa.net/xp/images/xp-title-512.gif";
    my $media_content_type     = "image/gif";
    my $media_content_width    = 512;
    my $media_content_height   = 96;
    my $media_title_value      = "media title";
    my $media_text_value       = "media value";
    my $media_text_type        = "html";
    my $media_thumbnail_url    = "http://www.kawa.net/xp/images/xp-title-256.gif";
    my $media_thumbnail_width  = 256;
    my $media_thumbnail_height = 48;
    my $media_credit_value     = "credit value";
    my $media_credit_scheme    = "urn:kawanet:tags";
# ----------------------------------------------------------------
    my $media_hash = {
        'media:content@url'      => $media_content_url,
        'media:content@type'     => $media_content_type,
        'media:content@width'    => $media_content_width,
        'media:content@height'   => $media_content_height,
        'media:title'            => $media_title_value,
        'media:text'             => $media_text_value,
        'media:text@type'        => $media_text_type,
        'media:thumbnail@url'    => $media_thumbnail_url,
        'media:thumbnail@width'  => $media_thumbnail_width,
        'media:thumbnail@height' => $media_thumbnail_height,
        'media:credit@scheme'    => $media_credit_scheme,
        'media:credit'           => $media_credit_value,
    };
# ----------------------------------------------------------------
{
    my $feed1 = XML::FeedPP::RSS->new();
    $feed1->title( $ftitle );
    $feed1->xmlns( 'xmlns:media' => $xmlns_media );
    is( $feed1->xmlns('xmlns:media'), $xmlns_media, '1. xmlns:media' );

    my $item1 = $feed1->add_item( $link1 );
    $item1->set( %$media_hash );

    foreach my $key ( sort keys %$media_hash ) {
        is( $item1->get($key), $media_hash->{$key}, '1. '.$key );
    }

    my $source1 = $feed1->to_string();
    my $feed2 = XML::FeedPP::RDF->new();
    $feed2->merge( $source1 );

    my $item2 = $feed2->get_item(0);
    foreach my $key ( sort keys %$media_hash ) {
        is( $item2->get($key), $media_hash->{$key}, '2.'.$key );
    }
}
# ----------------------------------------------------------------
{
    my $feed = XML::FeedPP::RSS->new();
    $feed->xmlns('xmlns:media' => 'http://search.yahoo.com/mrss/');
    my $item = $feed->add_item('http://www.example.com/index.html');
    $item->set('media:content@url'    => 'http://www.example.com/image.jpg');
    $item->set('media:content@type'   => 'image/jpeg');
    $item->set('media:content@width'  => 640);
    $item->set('media:content@height' => 480);

    my $source3 = $feed->to_string();
    my $feed3 = XML::FeedPP->new($source3);
    is($feed3->xmlns('xmlns:media'), $xmlns_media, '3. xmlns:media');

    my $item3 = $feed3->get_item(0);
    is($item3->link, 'http://www.example.com/index.html', '3. link');
    is($item3->get('media:content@url'), 'http://www.example.com/image.jpg', '3. media:content@url');
    is($item3->get('media:content@type'), 'image/jpeg', '3. media:content@type');
    is($item3->get('media:content@width'), '640', '3. media:content@width');
    is($item3->get('media:content@height'), '480', '3. media:content@height');
}
# ----------------------------------------------------------------
{
    # SEE http://video.search.yahoo.com/mrss
    my $source4 = <<EOT;
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"
xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule">
<channel>
<title>My Movie Review Site</title>
<link>http://www.foo.com</link>
<description>I review movies.</description>
    <item>
        <title>Movie Title: Is this a good movie?</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/trailer.mov" 
        fileSize="12216320" type="video/quicktime" expression="sample"/>
        <creativeCommons:license>
        http://www.creativecommons.org/licenses/by-nc/1.0
        </creativeCommons:license>
        <media:rating>nonadult</media:rating>
    </item>
</channel>
</rss>
EOT
    my $feed4 = XML::FeedPP->new($source4);
    is($feed4->xmlns('xmlns:media'), $xmlns_media, '4. xmlns:media');

    my $item4 = $feed4->get_item(0);
    is($item4->link, 'http://www.foo.com/item1.htm', '4. link');
    is($item4->get('media:content@url'), 'http://www.foo.com/trailer.mov', '4. media:content@url');
    is($item4->get('media:content@fileSize'), '12216320', '4. media:content@fileSize');
    is($item4->get('media:content@type'), 'video/quicktime', '4. media:content@type');
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
