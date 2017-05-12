use strict;
use warnings;

use FindBin '$Bin';
use Test::More tests => 1;
use Video::Xine;
use Video::Xine::Stream ':status_constants';
use Video::Xine::Event ':type_constants';

our $DEBUG = 1;

SKIP: {

    my $xine = Video::Xine->new( config_file => "$Bin/test_config" );

    my $vo = Video::Xine::Driver::Video->new( $xine, 'none' )
      or skip( "Unable to load 'none' video driver", 1 );

    my $ao = Video::Xine::Driver::Audio->new( $xine, 'none' )
      or skip q{Could not load audio driver 'none'}, 1;

    my $stream = $xine->stream_new( $ao, $vo );

    my $queue = Video::Xine::Event::Queue->new($stream);

    $stream->open("$Bin/video_xine_test.mp4")
      or die "Couldn't open '$Bin/video_xine_test.mp4'";

    $stream->play( 0, int( .7 * 65535 ) );

  PLAY: for ( ; ; ) {
        my $event = $queue->wait_event();
        print "Event: ", $event->get_type(), "\n"
          if $DEBUG;
        $event->get_type() == XINE_EVENT_UI_PLAYBACK_FINISHED and last PLAY;
    }

    ok(1);

}

