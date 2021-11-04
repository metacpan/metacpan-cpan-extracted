#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use X11::Xlib;
use POSIX;
use X11::GLX ':all';
use Try::Tiny;

plan skip_all => "No X11 Server available"
	unless defined $ENV{DISPLAY};

# In order to test shared context, the server must support the extension
# and the server must have enabled indirect rendering, which is no longer
# enabled by default in some distros.

my $dpy= X11::Xlib->new;

glXQueryVersion($dpy, my ($major, $minor));
note "GLX Version $major.$minor";

my $ext= glXQueryExtensionsString($dpy);
note "GLX Extensions: $ext";

plan skip_all => 'GLX_EXT_import_context is not supported'
	unless $ext =~ /\bGLX_EXT_import_context\b/;

my ($vis, $cx);
try {
	# Need to trap errors, else program exits
	$dpy->on_error(sub {
		my ($d, $e)= @_;
		diag "X11 error: $e during ".(!defined $vis? 'glXChooseVisual':'glXCreateContext');
		print STDOUT "1..0 # SKIP Import context testing requires X Server that allows indirect contexts\n";
		POSIX::_exit(0);
	});
	$vis= glXChooseVisual($dpy);
	note "Visual=$vis";
	$cx= glXCreateContext($dpy, $vis, undef, 0);
	note "Context=$cx";
	$dpy->flush_sync; # make sure we get any errors from the above
};
plan skip_all => "Import context testing requires X Server that allows indirect contexts"
	unless defined $cx;

# Now we actually start testing, because the rest should succeed.
# Need to declare number of tests because of hacky child process Test::More
# behavior below.
plan tests => 5;

ok( my $pix= $dpy->new_pixmap($dpy->screen, 50, 50, $vis->depth), 'XCreatePixmap' );
$dpy->flush_sync;

ok( my $glpix= glXCreateGLXPixmap($dpy, $vis, $pix), 'XCreateGLXPixmap' );
$dpy->flush_sync;

ok( glXMakeCurrent($dpy, $glpix, $cx), 'glXMakeCurrent' );
$dpy->flush_sync;

ok( my $cx_id= glXGetContextIDEXT($cx), 'glXGetContextIDEXT' );
$dpy->flush_sync;

# Can't get Test::Builder to play nicely with child proc...
# Hacky workaround is to have child process emit TAP of a subtest, so this whole
# thing counts as one test.
# TODO: consider moving entire project to Test2 framework, which supposedly
# can handle this.
defined ( my $pid= fork() ) or die "fork: $!";
if (!$pid) {
	exec($^X, '-e', <<'END', $cx_id) or die "Exec perl -e failed: $!";
	use strict;
	use warnings;
	use X11::Xlib;
	use X11::GLX ':all';
	sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }
	
	my $n= 0;
	my $indent= "    ";
	sub note($) { print "$indent# $_[0]\n"; }
	sub ok { my ($bool, $msg)= @_; print($indent.($bool? "ok ":"not ok ").++$n." - $msg\n"); }
	sub is {
		my ($val, $expect, $msg)= @_; print($indent.($val eq $expect? "ok ":"not ok ").++$n." - $msg\n");
		if ($val ne $expect) { note "'$val' is not '$expect'"; }
	}
	sub isa_ok { my ($obj, $cls, $msg)= @_; print($indent.(ref($obj)->isa($cls)? "ok ":"not ok ").++$n." - $msg is a $cls\n"); }
	
	my $cx_id= 0 + $ARGV[0];
	note "Connecting to shared context ID $cx_id";
	ok( my $dpy2= X11::Xlib->new, "new X11::Xlib" );
	ok( my $remote_cx= glXImportContextEXT($dpy2, $cx_id), 'glXImportContextEXT' );
	isa_ok( $remote_cx, 'X11::GLX::Context::Imported', 'remote_cx' );
	isa_ok( $remote_cx, 'X11::GLX::Context', 'remote_cx' );
	is( glXQueryContextInfoEXT($dpy2, $remote_cx, GLX_VISUAL_ID_EXT, my $vis2), 0, 'glXQueryContextInfoEXT' );
	ok( $vis2, 'got a visual' ) or diag explain $vis2;
	$vis2= $vis2? $dpy2->visual_info($vis2) : glXChooseVisual($dpy2);
	ok( my $cx2= glXCreateContext($dpy2, $vis2, $remote_cx, 0), 'child glXCreateContext' );
	is( err{ glXFreeContextEXT($dpy2, $remote_cx); }, '', 'glXFreeContextEXT' );
	is( err{ glXDestroyContext($dpy2, $cx2); }, '', 'glXDestroyContext' );
	
	print "${indent}1..9\n";
END
}
wait;
is( $?, 0, "Child exited cleanly" );

glXDestroyContext($dpy, $cx);
Test::More->builder->no_ending(1); # Test::Builder child and parent argue about how many tests were run

