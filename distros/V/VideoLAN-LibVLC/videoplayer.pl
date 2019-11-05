#! /usr/bin/env perl
#
# This is an example of how to make a video player that processes video frames
# via the callbacks, instead of using VLC's own output plugins.  It renders
# via OpenGL textures, using OpenGL::Sandbox which needs to be installed
# separately and isn't otherwise required for VideoLAN::LibVLC.

use strict;
use warnings;
use OpenGL::Sandbox qw( :all glBindTexture glEnable GL_TEXTURE_2D
	-V1 plot_st_xyz GL_RGB GL_RGBA GL_QUADS GL_TRIANGLES );
use VideoLAN::LibVLC;
use AnyEvent;
use Log::Any '$log';
use Log::Any::Adapter Daemontools => -init => { env => 1 };

# This part initializes libvlc, and then initializes an AnyEvent listener to watch
# for callback data coming from libvlc's thread.  After this, libvlc callbacks will
# just magically happen any time we are blocking on an AnyEvent call.
# Also route libvlc logging into Log::Any.

my $vlc= VideoLAN::LibVLC->new;
$vlc->log($log);
my $listen_vlc= AE::io $vlc->callback_fh, 0, sub { $vlc->callback_dispatch };

# This sets up a Player object where
#   * the 'format' callback forces RGBA frames and then kicks off the rest of the initialization
#   * the 'lock' callback queues empty picture buffers until there are 8 available
#   * the 'display' callback saves a reference to the new video frame, and recycles the previous

my $next_pic_id= 1;
my $cur_pic;
my $pic_texture;
my $init_cv= AE::cv;
my $render_event;
my $exit_cv= AE::cv;

my $player= $vlc->new_media_player;
#$player->trace_pictures(1);
$player->set_video_callbacks(
	format => sub {
		my ($p, $event)= @_;
		# force RGBA for now
		$event->{chroma}= 'RGBA';
		$event->{pitch}= [$event->{width} * 4, 0, 0];
		$event->{lines}= [$event->{height}, 0, 0];
		$log->info("Set video format");
		$p->set_video_format(%$event, alloc_count => 8);
		$log->info("Trigger init_cv");
		$init_cv->send($p->video_format);
	},
	lock => sub{
		my ($p, $event)= @_;
		$p->queue_new_picture(id => ++$next_pic_id) while $p->queued_picture_count < 8
	},
	display => sub {
		my ($p, $event)= @_;
		$p->queue_picture($cur_pic) if $cur_pic;
		$cur_pic= $event->{picture};
	},
);

# Tell the player to play the media file (or URL) listed on the command line.
# The callbacks will not begin until we tell AnyEvent to wait for something.

$player->media(shift);
$player->play;

# Wait for the initialization event (format callback),
# and find out what size the video format is.
my $format= $init_cv->recv;

# This creates an OpenGL context via whatever module is available.  See OpenGL::Sandbox docs.
$log->info("Make Context");
make_context(width => $format->{width}, height => $format->{height});
glEnable(GL_TEXTURE_2D);

# Create an empty texture and initialize the video memory storage for it.
$log->info("New texture");
$pic_texture= new_texture('pic', width => $format->{width}, height => $format->{height});
$log->info("Load empty");
$pic_texture->load({ format => GL_RGBA, data => undef });

$log->info("Warn GL Errors");
warn_gl_errors;

# For the rest of the program, any time AnyEvent is done dispatching all events,
# run this event, which loads the current picture into the texture then renders
# the texture to the screen.
 
$log->info("Setup idle event");
$render_event= AE::idle sub {
	# When the video playback ends, signal the end of the program
	if (!$player->is_playing) {
		$exit_cv->send(0);
	}
	#$log->info("Render picture $cur_pic");
	if ($cur_pic) {
		# This is sloppy - the picture might already be loaded into the texture if
		# the OpenGL frame rate is faster than the video playback frame rate.
		$pic_texture->load({ format => GL_RGBA, data => $cur_pic->plane(0) });
		# This is shorthand for specifying the texture and vertex coordinates
		# of the 4 corners of a rectangle.  See OpenGL::Sandbox::V1
		plot_st_xyz(GL_QUADS,
			(0,1, -1,-1,0), (1,1, 1,-1,0), (1,0,  1, 1,0), (0,0, -1,1,0),
		);
		next_frame;
	}
};

exit $exit_cv->recv;
