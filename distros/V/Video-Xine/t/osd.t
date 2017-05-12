
use strict;
use warnings;

use FindBin '$Bin';

use Test::More tests => 8;

use Video::Xine;
use Video::Xine::OSD qw/:cap_constants/;

TEST: {
    my $xine = Video::Xine->new();
    my $audio_port = Video::Xine::Driver::Audio->new( $xine, 'none' );

    my $driver = make_vo($xine);

    my $stream = $xine->stream_new( $audio_port, $driver );

    my $osd = Video::Xine::OSD->new(
        stream => $stream,
        x      => 0,
        y      => 0,
        width  => 500,
        height => 100
    );

    ok(1);

    my $caps = $osd->get_capabilities();
    ( $caps & XINE_OSD_CAP_FREETYPE2 ) and diag("Has freetype2");
    ( $caps & XINE_OSD_CAP_FREETYPE2 ) and diag("Can do unscaled OSD");

    ok(1);

    $stream->open("$Bin/video_xine_test.mp4")
      or die "Couldn't open '$Bin/video_xine_test.mp4'";

    $stream->play();

    # Skip rest of tests if we can't set the font
  SKIP: {
        $osd->set_font( 'serif', 66 )
          or skip( "Unable to set font", 6 );
        ok( 1, "Set font" );
        $osd->draw_text(
            x          => 5,
            y          => 10,
            text       => "Hello there!",
            color_base => 0
        );
        ok( 1, "draw text" );
        sleep(1);
        $osd->show(0);
        ok( 1, "show" );
        sleep(2);
        $osd->hide(0);
        ok( 1, "hide" );
        sleep(2);

        $osd->clear();
        ok( 1, "clear" );
        $osd->draw_text(
            x          => 0,
            y          => 0,
            text       => q{How's it going?},
            color_base => 0
        );
        ok( 1, "draw_text 2" );
        $osd->show();
    }
}

sub make_vo {
    my ($xine) = @_;

    my $driver = make_x11_vo($xine)
      or return Video::Xine::Driver::Video->new( $xine, 'none' );

}

sub make_x11_vo {
    my ($xine) = @_;

    eval 'use X11::FullScreen;';
    if ($@) {
        warn "Couldn't load X11::FullScreen: $@";
        return;
    }

    defined( $ENV{'VIDEO_XINE_SHOW'} ) && $ENV{'VIDEO_XINE_SHOW'}
      or return;

    my $display_str = defined $ENV{'DISPLAY'} ? $ENV{'DISPLAY'} : ':0.0';

    my $display = X11::FullScreen->new($display_str)
      or do {
        warn( "X11::FullScreen does not initialize", 1 );
        return;
      };


    my $window = $display->show();
    $display->sync();
    my $x11_visual =
      Video::Xine::Util::make_x11_visual( $display,
        $display->getDefaultScreen(),
        $window, $display->getWidth(), $display->getHeight(),
        $display->getPixelAspect() );

    my $driver =
      Video::Xine::Driver::Video->new( $xine, "auto", 1, $x11_visual,
        [ $window, $display ] )
      or do {
        warn "Unable to load video driver";
        return;
      };

    return $driver;
}
