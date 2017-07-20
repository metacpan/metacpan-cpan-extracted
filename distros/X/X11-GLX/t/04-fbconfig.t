#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util 'looks_like_number';
use X11::GLX::FBConfig;

plan skip_all => "No X11 Server available"
	unless defined $ENV{DISPLAY};

my $dpy= X11::Xlib->new;
X11::GLX::glXQueryVersion($dpy, my ($major, $minor));

note "GLX Version $major.$minor";
plan skip_all => "FBConfig requires GLX 1.3"
	unless ($major * 100 + $minor) >= 103;

my @fbc= X11::GLX::glXGetFBConfigs($dpy, $dpy->default_screen);
ok( @fbc > 0, 'glXGetFBConfig' );

is( $fbc[0]->display, $dpy, 'display' );

# Find one with a visual_id
my ($fbc)= grep { $_->visual_id } @fbc;
ok( $fbc, 'found fbconfig with visual_id' );

ok( (my $vis= $fbc->visual_info), 'visual_info' );
is( $vis && $vis->display, $dpy, 'visual_info->display' );

for (qw(
  xid
  buffer_size
  level
  doublebuffer
  stereo
  aux_buffers
  red_size
  green_size
  blue_size
  alpha_size
  depth_size
  stencil_size
  accum_red_size
  accum_green_size
  accum_blue_size
  accum_alpha_size
  render_type
  drawable_type
  x_renderable
  visual_id
  x_visual_type
  config_caveat
  transparent_type
  transparent_index_value
  transparent_red_value
  transparent_green_value
  transparent_blue_value
  transparent_alpha_value
  max_pbuffer_width
  max_pbuffer_height
  max_pbuffer_pixels
)) {
	my $v;
	ok( looks_like_number($v= $fbc->$_), $_ )
		and note "$_ is $v";
}

done_testing;
