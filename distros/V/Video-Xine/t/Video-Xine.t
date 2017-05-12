#########################

use strict;
use warnings;
use FindBin '$Bin';
use Test::More tests => 13;
BEGIN { use_ok('Video::Xine') };
use Video::Xine::Stream qw/:status_constants/;

#########################

my $version = Video::Xine->get_version();
like($version, qr/^\d+\.\d+\.\d+$/, 'Version is about right');
diag("Xine-lib version: $version");

my $rc = Video::Xine->check_version(1,1,0);
ok($rc, "check version");

my $xine = Video::Xine->new()
  or die "Couldn't initialize xine";
if (defined $ENV{'XINE_ENGINE_PARAM_VERBOSITY'}) {
  $xine->set_param(XINE_ENGINE_PARAM_VERBOSITY, $ENV{'XINE_ENGINE_PARAM_VERBOSITY'});
}
my $null_audio;

SKIP: {

if ($ENV{'VIDEO_XINE_SHOW'}) {
  $null_audio = Video::Xine::Driver::Audio->new($xine);
}
else {
  $null_audio = Video::Xine::Driver::Audio->new($xine, 'none')
    or skip "Couldn't open 'none' driver", 10;
}
ok(1);

# Get length and do a quick status check
TEST1: {
  my $stream  = $xine->stream_new($null_audio);
  is($stream->get_status(), XINE_STATUS_IDLE);
  $stream->open("$Bin/video_xine_test.mp4")
    or die "Couldn't open '$Bin/video_xine_test.mp4'";
  my ($pos_pct, $pos_time, $length_time) = $stream->get_pos_length();
  is($pos_pct, 0);
  is($pos_time, 0);
  is($length_time, 10010);
  $stream->play();
  is($stream->get_status(), XINE_STATUS_PLAY);
  $stream->stop();
  is($stream->get_status(), XINE_STATUS_STOP);
  $stream->close();
  is($stream->get_status(), XINE_STATUS_IDLE);
}

TEST2: {
  my $stream = $xine->stream_new($null_audio);
  $stream->open("$Bin/test.ogg")
    or die "Couldn't open '$Bin/test.ogg'";
  $stream->play()
	or die "Couldn't play '$Bin/test.ogg'";
  while ($stream->get_status() == XINE_STATUS_PLAY) {
    sleep 1;
  }
  $stream->close();
  ok(1);
}

TODO: {
  local $TODO = 1;
  my $stream = $xine->stream_new($null_audio);
  $stream->open("/dev/null");
  is($stream->get_error(), XINE_ERROR_NO_INPUT_PLUGIN);
}

}
