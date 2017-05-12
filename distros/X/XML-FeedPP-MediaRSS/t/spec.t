use warnings;
use strict;

use Test::More tests => 5;
use Test::Deep;
use XML::FeedPP;
use XML::FeedPP::MediaRSS;

sub spec_ok {
    my ($xml, $expected, $note) = @_;
    my $feed  = XML::FeedPP->new($xml, -type => 'string', use_ixhash => 1);
    my $media = XML::FeedPP::MediaRSS->new($feed);
    my @got   = map { $media->for_item($_) } ($feed->get_item);
    cmp_deeply(\@got, noclass($expected), $note);
}

{
    my $xml = <<'XML';
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
XML
    my $expected = [
        {
            url        => 'http://www.foo.com/trailer.mov',
            fileSize   => 12216320,
            type       => 'video/quicktime',
            expression => 'sample',
            rating     => {
                simple => 'nonadult',
            },
        }
    ];
    spec_ok(
        $xml, $expected, 
        'A movie review with a trailer, using a Creative Commons license.'
    );
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"
xmlns:dcterms="http://purl.org/dc/terms/">
<channel>
<title>Music Videos 101</title>
<link>http://www.foo.com</link>
<description>Discussions of great videos</description>
    <item>
        <title>The latest video from an artist</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/movie.mov" fileSize="12216320" 
        type="video/quicktime" expression="full">
        <media:player url="http://www.foo.com/player?id=1111" 
        height="200" width="400"/>
        <media:hash algo="md5">dfdec888b72151965a34b4b59031290a</media:hash>
        <media:credit role="producer">producer's name</media:credit>
        <media:credit role="artist">artist's name</media:credit>
        <media:category scheme="http://blah.com/scheme">music/artist 
        name/album/song</media:category>
        <media:text type="plain">
        Oh, say, can you see, by the dawn's early light
        </media:text>
        <media:rating>nonadult</media:rating>
        <dcterms:valid>
            start=2002-10-13T09:00+01:00;
            end=2002-10-17T17:00+01:00;
            scheme=W3C-DTF
        </dcterms:valid>
        </media:content>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            category => {
                'http://blah.com/scheme' => 
                    re(qr{music/\s*artist\s*name/\s*album/\s*song})
            },
            credit => {
                'urn:ebu' => {
                    artist   => [q"artist's name"],
                    producer => [q"producer's name"]
                }
            },
            expression => 'full',
            fileSize => 12216320,
            hash => {
                algorithm => 'md5',
                checksum  => 'dfdec888b72151965a34b4b59031290a'
            },
            player => {
                url    => 'http://www.foo.com/player?id=1111',
                width  => 400,
                height => 200,
            },
            rating => {
                simple => 'nonadult'
            },
            text => {
                text => re(
                    qr"^\s*Oh, say, can you see, by the dawn's early light\s*$",
                ),
                type => 'plain'
            },
            type => 'video/quicktime',
            url => 'http://www.foo.com/movie.mov'
        }
    ];
    spec_ok($xml, $expected, 'A music video with a link to a player window, and additional metadata about the video, including expiration date.');
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
<title>Song Site</title>
<link>http://www.foo.com</link>
<description>Discussion on different songs</description>
    <item>
        <title>These songs make me think about blah</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/band1-song1.mp3" 
        fileSize="1000" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band1</media:credit>
        <media:category>music/band1/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
        <media:content url="http://www.foo.com/band2-song1.mp3" 
        fileSize="2000" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band2</media:credit>
        <media:category>music/band2/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
        <media:content url="http://www.foo.com/band3-song1.mp3" 
        fileSize="1500" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band3</media:credit>
        <media:category>music/band3/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            category => {
                'none' => 'music/band1/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band1'
                    ]
                }
            },
            expression => 'full',
            fileSize => 1000,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band1-song1.mp3'
        },
        {
            category => {
                'none' => 'music/band2/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band2'
                    ]
                }
            },
            expression => 'full',
            fileSize => 2000,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band2-song1.mp3'
        },
        {
            category => {
                'none' => 'music/band3/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band3'
                    ]
                }
            },
            expression => 'full',
            fileSize => 1500,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band3-song1.mp3'
        },
    ];
    spec_ok($xml, $expected, 
        'Several different songs that relate to the same topic.');
}

{
    my $xml = <<'XML';

<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
<title>Song Site</title>
<link>http://www.foo.com</link>
<description>Songs galore at different bitrates</description>
    <item>
        <title>Cool song by an artist</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:group>
            <media:content url="http://www.foo.com/song64kbps.mp3" 
            fileSize="1000" bitrate="64" type="audio/mpeg" 
            isDefault="true" expression="full"/>
            <media:content url="http://www.foo.com/song128kbps.mp3" 
            fileSize="2000" bitrate="128" type="audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song256kbps.mp3" 
            fileSize="4000" bitrate="256" type="audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song512kbps.mp3.torrent" 
            fileSize="8000" type="application/x-bittorrent;enclosed=audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song.wav" 
            fileSize="16000" type="audio/x-wav" expression="full"/>
            <media:credit role="musician">band member 1</media:credit>
            <media:credit role="musician">band member 2</media:credit>
            <media:category>music/artist name/album/song</media:category>
            <media:rating>nonadult</media:rating>
        </media:group>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            url        => 'http://www.foo.com/song64kbps.mp3',
            fileSize   => 1000,
            bitrate    => 64,
            type       => 'audio/mpeg',
            expression => 'full',
            isDefault  => 1,
            credit     => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song128kbps.mp3',
            fileSize   => 2000,
            bitrate    => 128,
            type       => 'audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song256kbps.mp3',
            fileSize   => 4000,
            bitrate    => 256,
            type       => 'audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song512kbps.mp3.torrent',
            fileSize   => 8000,
            type       => 'application/x-bittorrent;enclosed=audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song.wav',
            fileSize   => 16000,
            type       => 'audio/x-wav',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        }
    ];
    spec_ok($xml, $expected, 'Same song with multiple files at different bitrates and encodings.  (Bittorrent example as well)');
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
<title>Song Site</title>
<description>mRSS example with new fields added in v1.5.0</description>

	<item>
                <link>http://www.foo.com</link>
                <pubDate>Mon, 27 Aug 2001 16:08:56 PST</pubDate>
                <media:content url="http://www.foo.com/video.mov" fileSize="2000" bitrate="128" type="video/quicktime" expression="full"/>
                <media:community>
                    <media:starRating average="3.5" count="20" min="1" max="10"/>
                    <media:statistics views="5" favorites="5"/>
                    <media:tags>news: 5, abc:3</media:tags>
                </media:community>
                <media:comments>
                    <media:comment>comment1</media:comment>
                    <media:comment>comment2</media:comment>
                </media:comments>
                <media:embed url="http://www.foo.com/player.swf" width="512" height="323" >
                    <media:param name="type">application/x-shockwave-flash</media:param>
                    <media:param name="width">512</media:param>
                    <media:param name="height">323</media:param>
                    <media:param name="allowFullScreen">true</media:param>
                    <media:param name="flashVars">id=12345&vid=678912i&lang=en-us&intl=us&thumbUrl=http://www.foo.com/thumbnail.jpg</media:param>
                </media:embed>
                <media:responses>
                  <media:response>www.response1.com</media:response>
                  <media:response>www.response2.com</media:response>
                </media:responses>
                <media:backLinks>
                  <media:backLink>www.backLink1.com</media:backLink>
                  <media:backLink>www.backLink2.com</media:backLink>
                </media:backLinks>
                <media:status state="active"/>
                <media:price type="rent" price="19.99" currency="EUR" />
                <media:license type="text/html" href="http://www.licensehost.com/license"> Sample license for a video </media:license>
                <media:subTitle type="application/smil" lang="en-us"  href="http://www.foo.org/subtitle.smil"  />
                <media:peerLink type="application/x-bittorrent " href="http://www.foo.org/sampleFile.torrent"  />
                <media:location description="My house" start="00:01" end="01:00">
                   <georss:where>
                       <gml:Point>
                         <gml:pos>35.669998 139.770004</gml:pos>
                       </gml:Point>
                   </georss:where>
                </media:location>
                <media:restriction type="sharing" relationship="deny" />
                <media:scenes>
                    <media:scene>
                        <sceneTitle>sceneTitle1</sceneTitle>
                        <sceneDescription>sceneDesc1</sceneDescription>
                        <sceneStartTime>00:15</sceneStartTime>
                        <sceneEndTime>00:45</sceneEndTime>
                    </media:scene>
                </media:scenes>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            url        => 'http://www.foo.com/video.mov',
            fileSize   => 2000,
            bitrate    => 128,
            type       => 'video/quicktime',
            expression => 'full',
            community  => {
                starRating => {
                    average => 3.5,
                    count   => 20,
                    min     => 1,
                    max     => 10,
                },
                statistics => {
                    views     => 5,
                    favorites => 5,
                },
                tags => {
                    news => 5,
                    abc  => 3,
                }
            },
            comments => [
                'comment1',
                'comment2',
            ],
            embed => {
                type            => 'application/x-shockwave-flash',
                width           => 512,
                height          => 323,
                allowFullScreen => 'true',
                flashVars       => 'id=12345&vid=678912i&lang=en-us&intl=us&thumbUrl=http://www.foo.com/thumbnail.jpg',
            },
            responses => [
                'www.response1.com',
                'www.response2.com',
            ],
            backLinks => [
                'www.backLink1.com',
                'www.backLink2.com',
            ],
            status => { state => 'active' },
            price => [
                { price => 19.99, type => 'rent', currency => 'EUR' }
            ],
            license => {
                type => 'text/html',
                href => 'http://www.licensehost.com/license',
                name => ' Sample license for a video ',
            },
            subTitle => {
                'en-us' => {
                    type => 'application/smil',
                    href => 'http://www.foo.org/subtitle.smil',
                }
            },
            peerLink => {
                type => 'application/x-bittorrent ',
                href => 'http://www.foo.org/sampleFile.torrent',
            },
            restriction => {
                allow => bool(0),
                type  => 'sharing',
                list  => 'none',
            },
            scenes => [
                {
                    title       => 'sceneTitle1',
                    description => 'sceneDesc1',
                    start_time  => '00:15',
                    end_time    => '00:45',
                }
            ],
        }
    ];
    spec_ok($xml, $expected, 'Example using all the new elements added mRSS version 1.5.0.');
}
