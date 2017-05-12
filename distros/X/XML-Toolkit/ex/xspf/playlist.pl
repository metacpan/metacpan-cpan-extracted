#!/usr/bin/env perl
use strict;
use 5.10.0;
use lib qw(lib);

use XMLTK::XSPF;
use aliased 'XML::Toolkit::Generator';

my $location_url =
"http://server430.files.myapp.com/e1/hq_flv/321779.flv?h=9d512f72b8b19c863bbee572ad3be219";
my $thumb_video_url =
  'http://server320.files.myapp.com/e1/preview_flv/321779.flv';
my $thumb_url =
'http://server320.files.myapp.com/e1/screenshot2/32/17/321779/321779_preview_{i}.jpg';

my $poster_img = '/static/images/poster.jpg';
my $logo_img   = '/static/images/yplogo.png';

my $doc = Playlist->new(
    version    => '1',
    trackLists => [
        TrackList->new(
            tracks => [
                Track->new(
                    albums => [ Album->new( text => 'provider' ) ],
                    titles => [ Title->new( text => 'videobox' ) ],
                    images => [ Image->new( text => $logo_img ) ],
                ),
                Track->new(
                    albums    => [ Album->new( text    => 'content' ) ],
                    images    => [ Image->new( text    => $poster_img ) ],
                    locations => [ Location->new( text => $location_url ) ],
                    metas     => [
                        Meta->new(
                            rel  => 'thumbvideo',
                            text => $thumb_video_url
                        ),
                        Meta->new(
                            rel  => 'thumb',
                            text => $thumb_url,
                        ),
                        Meta->new( rel => 'type', text => 'flv' ),
                    ]
                ),
            ],
        ),
    ],
);

my $generator =
  Generator->new( { namespace_map => { '' => 'http://xspf.org/ns/0/', } } );

$generator->render_object($doc);
say $generator->output;
