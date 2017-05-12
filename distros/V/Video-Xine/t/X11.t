use strict;
use warnings;

use FindBin '$Bin';
use Test::More tests => 1;

use Video::Xine;
use Video::Xine::Driver::Video ':constants';
use Video::Xine::Util 'make_x11_fs_visual';
if ($@) { skip_all(); }

my $xine = Video::Xine->new(config_file => "$Bin/test_config");


SKIP: {
  eval { require X11::FullScreen; };

  skip("X11::FullScreen module required for X11 tests", 1) if $@;

  if (! $ENV{'DISPLAY'}) {
    skip("Skipping X11 tests. Set DISPLAY to enable.", 1);
  }

  my $display_str = $ENV{'DISPLAY'};

  my $display = X11::FullScreen->new($display_str);
  
  $display->show();
  $display->sync();
  my $x11_visual = make_x11_fs_visual($display);
  my $driver = Video::Xine::Driver::Video->new($xine,"auto", XINE_VISUAL_TYPE_X11, $x11_visual)
    or skip("Couldn't load video driver", 1);
  my $audio_driver = Video::Xine::Driver::Audio->new($xine, 'none')
    or skip "Unable to load audio driver", 1;
  my $stream = $xine->stream_new($audio_driver, $driver);
  
  $stream->open("$Bin/video_xine_test.mp4")
    or die "Couldn't open '$Bin/video_xine_test.mp4'";
  $stream->play( 0 , 10000);
  sleep(5);

  ok(1);
}
