# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Data::Dumper;
BEGIN { plan tests => 19 };
use Video::OpenQuicktime;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $qt = Video::OpenQuicktime->new(-file=>"eg/sample.mov");
ok(2);

#ok $qt->init_file;
#warn "\n\n".$qt->_oqt."\n\n";


##########################
# AUDIO TESTS
##########################
ok $qt->get_audio_bits           == 16;
ok $qt->get_audio_channels       == 2;
#ok $qt->get_audio_codec          eq '';
ok $qt->get_audio_compressor     eq 'QDM2';
ok $qt->get_audio_length         == 108544;
ok $qt->get_audio_samplerate     == 22050;
ok $qt->get_audio_track_count    == 1;

##########################
# INFO TESTS
##########################

ok $qt->get_info                 eq 'Made with Quicktime for Linux';
ok $qt->get_name                 eq '';
ok $qt->get_copyright            eq '';

##########################
# VIDEO TESTS
##########################
ok $qt->get_video_compressor     eq 'SVQ1';
ok $qt->get_video_depth          == 24;
ok $qt->get_video_framerate      == 12;
ok $qt->get_video_height         == 240;
ok $qt->get_video_length         == 60;
ok $qt->get_video_track_count    == 1;
ok $qt->get_video_width          == 190;

##########################
# MISC TESTS
##########################
ok $qt->length                   == 5;

