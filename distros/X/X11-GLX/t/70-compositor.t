#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => "Work in Progress"; }
use Try::Tiny;
use X11::Xlib ':all';
use X11::GLX ':all';
use X11::GLX::DWIM;
use FindBin;
use lib "$FindBin::Bin/lib";
use OpenGL qw( :glconstants :glfunctions );
use OpenGL::Model::Cube;
use X11::SandboxServer;
use Log::Any::Adapter 'TAP';

plan skip_all => 'Xcomposite client lib is not available'
    unless X11::Xlib->can('XCompositeVersion');

my $x= try { X11::SandboxServer->new(title => $FindBin::Script) };
plan skip_all => 'Need Xephyr to run compositor tests'
    unless defined $x;

my $client= $x->connection;
plan skip_all => 'Xcomposite not supported by server'
    unless $client->XCompositeQueryVersion;

my $ext= glXQueryExtensionsString($client);
plan skip_all => 'GLX_EXT_texture_from_pixmap not supported by server'
	unless $ext =~ /GLX_EXT_texture_from_pixmap/;

sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $client->flush_sync; $ret= $@; } $ret }

my ($root, $overlay, $region);
note "local Xc ver = ".X11::Xlib::XCompositeVersion." server Xc ver = ".join('.', $client->XCompositeQueryVersion);
is( err{ $root= $client->root_window }, '', 'get root window' );
note "root = ".$root->summarize;
is( err{ $client->XCompositeRedirectSubwindows($root, CompositeRedirectAutomatic) }, '', 'XCompositeRedirectSubwindows' );
is( err{ $root->event_mask_include(SubstructureNotifyMask) }, '', 'listen SubstructureNotifyMask' );
is( err{ $overlay= $client->XCompositeGetOverlayWindow($root) }, '', 'XCompositeGetOverlayWindow' );
note "overlay = ".$overlay->summarize;

#sub nullify_window_region
{
	my $rgn= $client->XFixesCreateRegion([ { x => 100, y => 100, width => 150, height => 150 } ]);
	$overlay->set_bounding_region($rgn);
	$overlay->set_input_region($rgn);
}

my @glx_fbconfig= (
	GLX_RENDER_TYPE, GLX_RGBA_BIT,
	GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
	GLX_DOUBLEBUFFER, 1,
	GLX_RED_SIZE, 8,
	GLX_GREEN_SIZE, 8,
	GLX_BLUE_SIZE, 8,
	GLX_ALPHA_SIZE, 8,
	GLX_DEPTH_SIZE, 16,
);
my $dwim= X11::GLX::DWIM->new(
	display => $client,
	fbconfig => \@glx_fbconfig,
	target => { window => { x => 290, y => 90, width => 32, height => 32, parent => $overlay } },
	gl_projection => {}
);
#$client->XReparentWindow($dwim->target, $overlay, 0, 0);
$dwim->target->event_mask_include(ExposureMask);
$dwim->target->set_bounding_region();
#$dwim->target->show;

my $client2;
if ($ENV{TEST_APP}) {
	local $ENV{DISPLAY}= $x->display_string;
	open $client2, '-|', "$ENV{TEST_APP} 2>&1" or die "open pipe from '$ENV{TEST_APP}': $!";
} else {
	note "client2 connecting to ".$x->display_string;
	$client2= X11::Xlib->new(connect => $x->display_string);
	note "new window 50x50";
	my $w= $client2->new_window(x => 10, y => 10, width => 50, height => 50, background_pixel => 0x77777777);
	$w->autofree(0);
	$w->show;
	$client2->flush;
}

my $cube_dlist;
sub cube {
	if ($cube_dlist) {
		glCallList($cube_dlist);
	} else {
		$cube_dlist= glGenLists(1);
		glNewList($cube_dlist, GL_COMPILE_AND_EXECUTE);
		OpenGL::Model::Cube->draw;
		glEndList();
	}
}

my $r= 0;
my $start= time;
while (time - $start < 10) {
	my $e= $client->wait_event(timeout => 1);
	if ($e) {
		note 'event '.$e->summarize;
		if ($e->type == CreateNotify) {
			my $w= $client->get_cached_window($e->window);
			next if $w == $overlay;
			note "Window created: ".$w->summarize.sprintf(' (%X)', $w->xid);
		}
		elsif ($e->type == MapNotify) {
			my $w= $client->get_cached_window($e->window);
			next if $w == $overlay;
			note "Window mapped: ".$w->summarize.sprintf(' (%X)', $w->xid);
			$w->event_mask_include(ExposureMask);
		}
	} else {
		note int(time - $start);
		glClearColor(.5, 1, .5, .5);
	glClearDepth(1);
	glColor4d(1,1,1,1);
	glDepthFunc(GL_LEQUAL);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
	glShadeModel(GL_SMOOTH);
	glEnable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		$dwim->begin_frame;
		glLoadIdentity();
		glTranslated(0,0,-3);
		glDisable(GL_TEXTURE_2D);
		glRotated($r*3, 1, 1.5, 1);
		$r++;
		cube();
		$dwim->end_frame;
	}
}
undef $client2;
undef $client;

done_testing;
