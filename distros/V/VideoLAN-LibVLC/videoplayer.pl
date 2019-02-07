#! /usr/bin/env perl
use strict;
use warnings;
use OpenGL::Sandbox qw( :all glBindTexture glEnable GL_TEXTURE_2D
	-V1 plot_st_xyz GL_RGB GL_RGBA GL_QUADS GL_TRIANGLES );
use VideoLAN::LibVLC;
use AnyEvent;
use Log::Any '$log';
use Log::Any::Adapter Daemontools => -init => { env => 1 };

my $vlc= VideoLAN::LibVLC->new;
$vlc->log(sub { print "$_[0]{message}\n" });
my $listen_vlc= AE::io $vlc->callback_fh, 0, sub { $vlc->callback_dispatch };

my $next_pic_id= 1;
my $cur_pic;
my $pic_texture;
my $exit_cv= AE::cv;
my $main_event;
my $player= $vlc->new_media_player;
#$player->trace_pictures(1);
my $init_cv= AE::cv {
	my $format= $_[0]->recv;
	$log->info("Make Context");
	make_context(width => $format->{width}, height => $format->{height});
	glEnable(GL_TEXTURE_2D);
	$log->info("New texture");
	$pic_texture= new_texture('pic', width => $format->{width}, height => $format->{height});
	$log->info("Load empty");
	$pic_texture->load({ format => GL_RGBA, data => undef });
	$log->info("Warn GL Errors");
	warn_gl_errors;
	$log->info("Setup idle event");
	$main_event= AE::idle sub {
		if (!$player->is_playing) {
			$exit_cv->send(0);
		}
		#$log->info("Render picture $cur_pic");
		if ($cur_pic) {
			$pic_texture->load({ format => GL_RGBA, data => $cur_pic->plane(0) });
			plot_st_xyz(GL_QUADS,
				(0,1, -1,-1,0), (1,1, 1,-1,0), (1,0,  1, 1,0), (0,0, -1,1,0),
			);
			next_frame;
		}
	};
};

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
		$player->queue_picture($cur_pic) if $cur_pic;
		$cur_pic= $_[1]{picture};
	},
);
$player->media(shift);
$player->play;

exit $exit_cv->recv;
