package X11::GLX::DWIM;
$X11::GLX::DWIM::VERSION = '0.05';
use Moo 2;
use X11::GLX;
use Carp;
use Log::Any '$log';

# ABSTRACT: Do What I Mean, with OpenGL on X11


has display => ( is => 'lazy' );

sub _build_display {
	my $self= shift;
	$log->trace('Connecting to display server');
	return X11::Xlib->new;
}

has screen  => ( is => 'lazy' );

sub _build_screen { shift->display->screen }


has _glx_version => ( is => 'lazy' );
sub _build__glx_version {
	X11::GLX::glXQueryVersion(shift->display, my $major, my $minor);
	$log->tracef('GLX Version %d.%d', $major, $minor)
		if $log->is_trace;
	return [ $major, $minor ];
}
sub glx_version { join ".", @{ shift->_glx_version } }
sub glx_version_bcd { my $v= shift->_glx_version; $v->[0] * 100 + $v->[1] }


has glx_extensions => ( is => 'lazy' );

sub _build_glx_extensions {
	X11::GLX::glXQueryExtensionsString(shift->display);
}


has _fbconfig_args    => ( is => 'ro', init_arg => 'fbconfig' );
has fbconfig          => ( is => 'lazy', init_arg => undef );
has _visual_info_args => ( is => 'ro', init_arg => 'visual_info' );
has visual_info       => ( is => 'lazy', init_arg => undef );

sub _build_fbconfig {
	my $self= shift;
	# Need GLX 1.3 in order to do FBConfigs
	return undef unless $self->glx_version_bcd >= 103 && X11::GLX->can('glXChooseFBConfig');
	
	my $arg= $self->_fbconfig_args;
	if (!$arg) {
		if (defined $self->_visual_info_args) {
			croak("TODO: convert visual_info args to fbconfig");
		} else {
			$arg= [
				X11::GLX::GLX_DOUBLEBUFFER => 1,
				X11::GLX::GLX_RED_SIZE => 8,
				X11::GLX::GLX_GREEN_SIZE => 8,
				X11::GLX::GLX_BLUE_SIZE => 8,
#				X11::GLX::GLX_ALPHA_SIZE => 8,
			];
		}
	}
	
	return $arg if ref($arg) && ref($arg)->isa('X11::GLX::FBConfig');
	
	# ChooseFBConfig returns multiple options.  Try to find one with a std X11
	# visual, and if the user asked for alpha then prefer one that can do XRender
	# with an alpha channel.
	$log->tracef('Calling glXChooseFBConfig');
	my @fbc= X11::GLX::glXChooseFBConfig($self->display, $self->screen->screen_number, $arg);
	$log->tracef(" found %d matching fbconfigs", scalar @fbc);
	
	my @fbc_with_visual= grep { $_->visual_id } @fbc;
	$log->tracef(" %d of which have an X11 Visual", scalar @fbc_with_visual);
	
	# Does the user want a drawable with alpha?
	my $ret;
	my $want_alpha= 0;
	for (0..$#$arg) {
		if ($arg->[$_] == X11::GLX::GLX_ALPHA_SIZE && $_ < $#$arg && $arg->[$_+1] > 0) {
			$want_alpha= 1;
		}
	}
	# If XRender extension is available on both client and server, check picture format for alpha mask
	if ($want_alpha and X11::Xlib->can('XRenderFindVisualFormat') and $self->display->XRenderQueryVersion()) {
		$log->tracef("Calling XRenderFindVisualFormat for %d configs", scalar @fbc_with_visual);
		my @fbc_xrender_alpha= grep {
			my $fmt= $self->display->XRenderFindVisualFormat($_->visual_info->visual);
			$fmt && $fmt->direct_alphaMask
		} @fbc_with_visual;
		
		$log->tracef(" %d have XRender picture formats with alpha channel", scalar @fbc_xrender_alpha);
		$ret= $fbc_xrender_alpha[0] if @fbc_xrender_alpha;
	}
	$ret||= $fbc_with_visual[0] if @fbc_with_visual;
	$ret||= $fbc[0] if @fbc;
	defined $ret or croak "No matching FBConfig available on server";
	
	$log->tracef('Chose GLXFBConfig %d; dbl-buf=%d %dbpp r=%d g=%d b=%d a=%d',
		$ret->xid, $ret->doublebuffer, $ret->buffer_size,
		$ret->red_size, $ret->green_size, $ret->blue_size, $ret->alpha_size)
		if $log->is_trace;
	return $ret;
}

sub _build_visual_info {
	my $self= shift;
	# If GLX version is >= 1.3, use fbconfig instead
	if ($self->glx_version_bcd >= 103 && X11::GLX->can('glXChooseFBConfig')) {
		my $vis= $self->fbconfig->visual_info;
		$log->tracef('Using visual %d (0x%X) from FBConfig', $vis->visualid, $vis->visualid)
			if $log->is_trace;
		return $vis;
	}
	
	my $arg= $self->_visual_info_args;
	$log->tracef('Calling glXChooseVisual with %s options', $arg? 'custom':'default');
	my $vis_info= !$arg? X11::GLX::glXChooseVisual($self->display, $self->screen->screen_number)
		: ref $arg eq 'ARRAY'? X11::GLX::glXChooseVisual($self->display, $self->screen->screen_number, $arg)
		: ref($arg)->isa('X11::Xlib::Visual')? $self->display->visual_info($arg)
		: croak "Can't convert $arg to XVisualInfo";
	$log->tracef('Chose visual %d (0x%X)', $vis_info->visualid, $vis_info->visualid)
		if $log->is_trace;
	return $vis_info;
}


has colormap => ( is => 'lazy' );
sub _build_colormap {
	my $self= shift;
	my $vis= $self->visual_info->visual;
	$log->tracef("Creating colormap for visual %s", $vis->id)
		if $log->is_trace;
	$self->display->new_colormap($self->screen->root_window, $vis);
}


has _glx_context_args => ( is => 'ro', init_arg => 'glx_context' );
has glx_context => ( is => 'rw', init_arg => undef, lazy => 1, builder => 1, clearer => 1, predicate => 1 );

before 'clear_glx_context' => sub {
	my $self= shift;
	if ($self->has_glx_context) {
		$self->clear_target;
		$log->trace('destroying old GLX context');
		X11::GLX::glXDestroyContext($self->display, $self->glx_context);
	}
};

before 'glx_context' => sub {
	if (@_ > 1) {
		my $self= $_[0];
		$_[1] or croak "Use clear_glx_context instead of setting a false value"; 
		$self->clear_glx_context if $self->has_glx_context;
		$_[1]= $self->_build_glx_context($_[1]);
	}
};

sub _build_glx_context {
	my ($self, $args)= @_;
	$args ||= $self->_glx_context_args || { direct => 1 };
	return $args if ref($args)->isa('X11::GLX::Context');
	ref($args) eq 'HASH' or croak "Don't know how to use $args as a glx_context";
	my $direct= $args->{direct};
	my $shared= $args->{shared};
	my $fbc= $self->fbconfig;
	my $vis= $self->visual_info;
	
	# Determine default $direct based on $shared.
	if (!defined $shared) {
		$direct= 1 unless defined $direct;
	}
	# IF $shared is an XID, then import it as a context so we can use it
	elsif (!ref $shared || ref($shared)->isa('X11::Xlib::XID')) {
		my $id= !ref($shared)? $shared : $shared->xid;
		$direct= 0 unless defined $direct;
		
		$log->trace("Importing GLX context id=$id") if $log->is_trace;
		$shared= X11::GLX::glXImportContextEXT($self->display, $id)
			or die "Can't import remote GLX context '$id'";
		# destructor takes care of cleaning up $shared
	}
	elsif (ref($shared)->isa('X11::GLX::Context')) {
		$direct= 0 unless defined $direct;
	}
	else {
		croak "Don't know how to share GLX context with $shared";
	}
	
	if ($fbc) {
		$log->tracef("Calling glXCreateNewContext config=%s render_type=GLX_RGBA_TYPE shared=%s direct=%s",
			$fbc, $shared, $direct)
			if $log->is_trace;
		return X11::GLX::glXCreateNewContext($self->display, $fbc, X11::GLX::GLX_RGBA_TYPE, $shared, $direct);
	} else {
		$log->tracef("Calling glXCreateContext visual=%s shared=%s direct=%s",
			$vis, $shared, $direct)
			if $log->is_trace;
		return X11::GLX::glXCreateContext($self->display, $vis, $shared, $direct);
	}
}


has _target_args => ( is => 'rw', init_arg => 'target' );
has target => ( is => 'rw', init_arg => undef, clearer => 1, predicate => 1, reader => '_get_target', writer => '_set_target' );

before clear_target => sub {
	if ($_[0]->has_target) {
		$log->trace("Un-setting GLX target with glXMakeCurrent(0, undef)");
		X11::GLX::glXMakeCurrent($_[0]->display)
			or croak "Can't un-set GLX target";
	}
};

sub target {
	my $self= shift;
	if (@_ || !$self->has_target) {
		if (@_ && !defined $_[0]) {
			croak("Call clear_target instead of setting to undef");
		}
		my $target= $self->_inflate_target(@_? $_[0] : $self->_target_args);
		if ($target->isa('X11::Xlib::Window')) {
			# Enable listening to MapNotify events if weren't already selected
			my $evmask= $target->event_mask;
			my $changed;
			unless ($evmask & X11::Xlib::StructureNotifyMask) {
				$changed= 1;
				$target->event_mask($evmask | X11::Xlib::StructureNotifyMask);
			}
			$log->trace('Calling XMapWindow');
			$target->show;
			# wait for window to be mapped
			$self->display->wait_event(window => $target->xid, event_type => X11::Xlib::MapNotify, timeout => 5, loop => 1)
				or $log->warn("didn't get MapNotify event?");
			# Restore previous event mask
			$target->event_mask($evmask) if $changed;
		}
		$log->trace('Calling glXMakeCurrent');
		X11::GLX::glXMakeCurrent($self->display, $target->xid, $self->glx_context)
			or croak "Can't set target to $target, glXMakeCurrent failed";
		$self->_set_target($target);
		$self->apply_gl_projection if $self->gl_projection;
	}
	return $self->_get_target;
}

sub _inflate_target {
	my ($self, $arg)= @_;
	$arg ||= { window => 1 };
	$log->tracef("Creating target for %s", $arg);
	return !ref $arg? $self->display->get_cached_xobj($arg)
		: ref($arg)->isa('X11::Xlib::XID')? $arg
		: ref($arg) eq 'HASH'? (
			$arg->{window}? $self->create_render_window($arg->{window})
			: $arg->{pixmap}? $self->create_render_pixmap($arg->{pixmap})
			: croak "Expected target->{window} or target->{pixmap}"
		)
		: croak "Don't know how to set $arg as the GL rendering target";
}


has gl_clear_bits     => ( is => 'rw', lazy => 1, builder => 1 );
# Defaults in XS:
#sub _build_gl_clear_bits {
#	return OpenGL::GL_COLOR_BUFFER_BIT()|OpenGL::GL_DEPTH_BUFFER_BIT();
#}


has gl_projection     => ( is => 'rw', trigger => \&_changed_gl_projection );
sub _changed_gl_projection {
	my ($self, $newval)= @_;
	$self->apply_gl_projection if $newval && $self->has_target;
}


sub create_render_window {
	my $self= shift;
	my %args= @_ == 1 && ref($_[0]) eq 'HASH'? %{ $_[0] }
		: (1&@_) == 0? @_
		: @_ == 1 && $_[0] eq '1'? ()
		: croak "Can't construct window from (".join(',', @_).')';
	$args{x} ||= 0;
	$args{y} ||= 0;
	if (!$args{width} || !$args{height}) {
		# Default to fullscreen dimensions. TODO: use xrandr instead of static screen dims
		$args{width} ||= $self->screen->width  - $args{x};
		$args{height} ||= $self->screen->height - $args{y};
	}
	$args{class}= X11::Xlib::InputOutput unless defined $args{class};
	$args{visual} ||= $self->visual_info->visual;
	$args{colormap} ||= $self->colormap;
	$args{parent} ||= $self->screen->root_window;
	$args{depth} ||= $self->visual_info->depth;
	$args{min_width} ||= $args{width};
	$args{min_height} ||= $args{height};
	$args{border_pixel} ||= 0; # this seems to make the difference between succeeding and failing on 32bpp visuals??
	$args{border_width} ||= 0;
	$args{background_pixmap} ||= 0;
	$log->tracef("create window: %s", { map { $_ => "$args{$_}" } keys %args })
		if $log->is_trace;
	return $self->display->new_window(%args);
}


sub create_render_pixmap {
	my $self= shift;
	my %args= @_ == 1 && ref($_[0]) eq 'HASH'? %{ $_[0] } : @_;
	$args{width} && $args{height}
		or croak "require 'width' and 'height'";
	$args{depth} ||= $self->visual_info->depth;
	$log->tracef("create X pixmap: %s", \%args);
	my $x_pixmap= $self->display->new_pixmap($self->screen, $args{width}, $args{height}, $args{depth});
	$log->tracef("create GLX pixmap: %s %s", $self->visual_info, $x_pixmap) if $log->is_trace;
	my $glx_pixmap_xid= X11::GLX::glXCreateGLXPixmap($self->display, $self->visual_info, $x_pixmap);
	return $self->display->get_cached_xobj($glx_pixmap_xid, 'X11::GLX::Pixmap',
		width    => $args{width},
		height   => $args{height},
		x_pixmap => $x_pixmap,
		autofree => 1
	);
}


sub begin_frame {
	my $self= shift;
	$self->target; # trigger lazy-build, connect, display window, etc
	$log->trace('Calling glClear');
	# export glClear ourselves to avoid depending on OpenGL module
	X11::GLX::DWIM::_glClear($self->gl_clear_bits);
}


sub end_frame {
	my $self= shift;
	$log->trace('Calling glXSwapBuffers');
	X11::GLX::glXSwapBuffers($self->display, $self->target);
	my $e= $self->get_gl_errors;
	$log->error("OpenGL error bits: ", join(', ', values %$e))
		if $e;
	return !$e;
}


sub swap_buffers {
	my $self= shift;
	$log->trace('Calling glXSwapBuffers');
	X11::GLX::glXSwapBuffers($self->display, $self->target);
}


my %_gl_err_msg= (
	map { eval { X11::GLX->can($_)->() => $_ } } qw(
		GL_INVALID_ENUM
		GL_INVALID_VALUE
		GL_INVALID_OPERATION
		GL_INVALID_FRAMEBUFFER_OPERATION
		GL_OUT_OF_MEMORY
		GL_STACK_OVERFLOW
		GL_STACK_UNDERFLOW
		GL_TABLE_TOO_LARGE
	)
);

sub get_gl_errors {
	my $self= shift;
	my (%errors, $e);
	$errors{$e}= $_gl_err_msg{$e} || "(unrecognized) ".$e
		# export glGetError ourselves to avoid depending on OpenGL module
		while (($e= X11::GLX::DWIM::_glGetError()));
	return (keys %errors)? \%errors : undef;
}


sub apply_gl_projection {
	my $self= shift;
	my %args= !@_? %{ $self->gl_projection || {} }
		: @_ == 1 && ref($_[0]) eq 'HASH'? %{ $_[0] }
		: @_;
	my ($ortho, $l, $r, $t, $b, $near, $far, $x, $y, $z, $aspect, $mirror_x, $mirror_y)
		= delete @args{qw/ ortho left right top bottom near far x y z aspect mirror_x mirror_y /};
	croak "Unexpected arguments to apply_gl_projection"
		if keys %args;
	my $have_w= defined $l && defined $r;
	my $have_h= defined $t && defined $b;
	unless ($have_h && $have_w) {
		if (!$aspect or $aspect eq 'auto') {
			my ($w, $h)= $self->target->get_w_h;
			my $screen= $self->screen;
			$aspect= ($screen->width_mm / $screen->width * $w)
			       / ($screen->height_mm / $screen->height * $h);
		}
		if (!$have_w) {
			if (!$have_h) {
				$t= (defined $b? -$b : 1) unless defined $t;
				$b= -$t unless defined $b;
			}
			my $w= ($t - $b) * $aspect;
			$r= (defined $l? $l + $w : $w / 2) unless defined $r;
			$l= $r - $w unless defined $l;
		}
		else {
			my $h= ($r - $l) / $aspect;
			$t= (defined $b? $b + $h : $h / 2) unless defined $t;
			$b= $t - $h unless defined $b;
		}
	}
	($l, $r)= ($r, $l) if $mirror_x;
	($t, $b)= ($b, $t) if $mirror_y;
	$near= 1 unless defined $near;
	$far= 1000 unless defined $far;
	defined $_ or $_= 0
		for ($x, $y, $z);
	
	# If Z is specified, then the left/right/top/bottom are interpreted to be the
	# edges of the screen at this position.  Only matters for Frustum.
	if ($z && !$ortho) {
		my $scale= 1.0/$z;
		$l *= $scale;
		$r *= $scale;
		$t *= $scale;
		$b *= $scale;
	}
	
	$log->tracef('Setting projection matrix: l=%.4lf r=%.4lf b=%.4lf t=%.4lf near=%.4lf far=%.4lf; translate %.4lf,%.4lf,%.4lf',
		$l, $r, $b, $t, $near, $far, -$x, -$y, -$z);
	X11::GLX::DWIM::_set_projection_matrix(
		$ortho? 0 : 1, $l, $r, $b, $t, $near, $far,
		$x, $y, $z, $mirror_x? 1: 0, $mirror_y? 1 : 0
	);
	# XS Performs this, but without needing to load classic OpenGL perl module.
	#OpenGL::glMatrixMode(OpenGL::GL_PROJECTION());
	#OpenGL::glLoadIdentity();
	#
	#$ortho? OpenGL::glOrtho($l, $r, $b, $t, $near, $far)
	#      : OpenGL::glFrustum($l, $r, $b, $t, $near, $far);
	#
	#OpenGL::glTranslated(-$x, -$y, -$z)
	#	if $x or $y or $z;
	#
	## If mirror is in effect, need to tell OpenGL which way the camera is
	#OpenGL::glFrontFace(!$mirror_x eq !$mirror_y? OpenGL::GL_CCW() : OpenGL::GL_CW());
	#OpenGL::glMatrixMode(OpenGL::GL_MODELVIEW());
}

sub DESTROY {
	my $self= shift;
	# Release resources in opposite order they were allocated.
	# un-set target first so that it doesn't happen after the connection is already closed
	$self->clear_target;
	$self->clear_glx_context;
	# everything else can be freed in whichever order, and ->display will
	# be freed last since visuals and fbconfigs hold a strong reference to it.
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX::DWIM - Do What I Mean, with OpenGL on X11

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $glx= X11::GLX::DWIM->new( \%options );
  while (1) {
    $glx->begin_frame();
    my_custom_opengl_rendering();
    $glx->end_frame();
  }
  
  # defaults above:
  #   Connect to default X11 Display
  #   32-bit RGBA visual, double buffered
  #   rendering to full-screen window.  Direct-render if supported.
  #   begin_frame calls glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
  #   end_frame calls glXSwapBuffers and reports any glError

=head1 DESCRIPTION

This module wraps all of the relevant L<X11::Xlib> and L<X11::GLX> function
calls needed to create the most common types of rendering target for OpenGL.

=head1 ATTRIBUTES

=head2 display

Instance of L<X11::Xlib::Display>.  Lazy-built from C<$DISPLAY> environment
var, or connects to localhost.

=head2 screen

Instance of L<X11::Xlib::Screen>.  Defaults to the default screen of the display.

=head2 glx_version

The GLX version number.  Read-only, lazy-built from L</display>.

=head2 glx_version_bcd

The GLX version in C<major * 100 + minor> binary-coded-decimal format.
Useful for comparing version numbers without worrying about floating
point rounding errors.

=head2 glx_extensions

The list of extensions supported by this implementation of GLX.
Read-only, lazy-built from L</display>.

=head2 fbconfig

  X11::GLX::DWIM->new( fbconfig => $fbconfig )
  X11::GLX::DWIM->new( fbconfig => \@glx_fbconfig_flags )

Lazy-built, read-only.  Instance of L<X11::Xlib::FBConfig>.
Can be initialized with an arrayref of parameters (integer codes) to pass to
L<glXChooseFBConfig|X11::GLX/glXChooseFBConfig>.

Will be C<undef> unless GLX version is 1.3 or higher, since FBConfig was not
introduced until this version.

=head2 visual_info

  X11::GLX::DWIM->new( visual_info => $vis )
  X11::GLX::DWIM->new( visual_info => \@glx_vis_flags )
  X11::GLX::DWIM->new( visual_info => \%visual_info_fields )

Lazy-built, read-only.  Instance of L<X11::Xlib::XVisualInfo>.
Can be initialized with an arrayref of parameters (integer codes) to pass to
L<glXChooseVisual|X11::GLX/glXChooseVisual>, or with a hashref of fields to
pass to the constructor of C<XVisualInfo>.

If you have GLX 1.3 or higher, any initializer for this attribute will instead be
converted to the appropriate L<glXChooseFBConfig|X11::GLX/glXChooseFBConfig>
arguments and the resulting visual_info will come from C<< ->fbconfig->visual_info >>.

=head2 colormap

Lazy-built, read-only.  Instance of L<X11::Xlib::Colormap>.  Defaults to a new
colormap compatible with L</visual_info>.

=head2 glx_context

An instance of L<X11::GLX::Context>.  You can also initialize it with a hash
of arguments for the call to L<glXCreateContext|X11::GLX/glXCreateContext>
or L<glXCreateNewContext|X11::GLX/glXCreateNewContext>.  (the latter is used
if GLX version is >= 1.3)

  $glx->glx_context({
    direct => $bool,            # for direct rendering ("DRI")
    shared => $context_or_xid,  # X11::GLX::Context, or the X11 ID of an indirect context
  });

If already initialized, this will destroy any previous context.

If your server supports it, and your context is indirect, you can discover the
X11 ID for a GLX context with:

  my $xid= $glx->glx_context->id

and then use that ID for the C<shared> option when creating later GL contexts
in other processes.  See L<X11::GLX/Shared GL Contexts>.

=head2 has_glx_context

Returns whether glx_context has been initialized.

=head2 clear_glx_context

Destroy the current GLX context, also clearing the L</target>.

=head2 target

Pixmap or Window which OpenGL should render to. (C<glXMakeCurrent>).
You can set this to an existing XID of a window or GLX pixmap,
an object representing one (L<X11::Xlib::Window>, etc), or a hashref
specifying parameters to either L</create_render_window>
or L</create_render_pixmap>.  If lazy-built with no initializer, it defaults
to a full-screen window.

  $glx->target( $xid );                # existing window or GLX pixmap
  $glx->target({ window => \%args });  # shortcut for create_render_window()
  $glx->target({ pixmap => \%args });  # shortcut for create_render_pixmap()
  $glx->target;                        # defaults to full-screen window

=head2 has_target

Returns true if the target has been initialized.  Use this to prevent
triggering a lazy-build of the initial target.

=head2 clear_target

Use this to un-set the target.

=head2 gl_clear_bits

The bits passed to C<glClear> in the convenience function L</begin_frame>.

Defaults to GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT

=head2 gl_projection

If you're still rockin' the old-school OpenGL 1.4 matrix system, you can use
this attribute to set up a quick projection matrix.  If the GLX context target
is initialized, setting this attribute will immediately change the GL
projection matrix.  Otherwise these settings are used as the default once that
happens.

See L</apply_gl_projection>

=head1 METHODS

=head2 create_render_window

  $glx->target( $glx->create_render_window( \%args ) );

Create a window suitable for use as an OpenGL rendering target.
C<%args> can be:

  x        - default 0
  y        - default 0
  width    - default to screen width
  height   - default to screen height
  class    - default to InputOutput
  ...

There are dozens of other parameters you can specify.
See L<X11::Xlib::Display/new_window>.

=head2 create_render_pixmap

  $glx->target( $glx->create_render_pixmap( \%args ) );

Create a pixmap suitable for use as an OpenGL rendering target.
C<%args> can be:

  width - required
  height - required
  depth  - defaults to depth of your visual

=head2 begin_frame

Convenience method; initializes rendering target if it wasn't already done,
then clears the GL buffers.

=head2 end_frame

Convenience method; calls glXSwapBuffers and then logs any glGetError
bits that were set, via L<Log::Any>

=head2 swap_buffers

Call glXSwapBuffers

=head2 get_gl_errors

Convenience method to call glGetError repeatedly and build a
hash of the symbolic names of the error constants.

=head2 apply_gl_projection

For old-school OpenGL (i.e. non-shader), this sets up a simple perspective
projection matrix.

  $glx->apply_gl_projection(
    ortho => $bool,
    left => ..., right => ..., top => ..., bottom => ...,
    near => ..., far => ..., z => ...,
    aspect => ..., mirror_x => $bool, mirror_y => $bool,
  );

If C<ortho> is true, it calls C<glOrtho>, else C<glFrustum>.
The C<left>, C<right>, C<top>, C<bottom>, C<near>, C<far> parameters are as
documented for these functions, B<but> if you request a Frustum and specify a
non-zero C<z> then it scales the parameters so that a vertex C<($left,$top,$z)>
displays at the upper-left corner of the screen.  (normally the upper left
would be C<($left,$top,$near)>)  This allows you to separate the near clipping
plane from the plane you use to scale your coordinates.

If you specify C<x>, C<y>, or C<z>, it calls C<glTranslated(-x,-y,-z)> after
the C<glFrustum> or C<glOrtho>.

If you specify C<aspect> and omit one or more of C<left>, C<right>, C<bottom>,
C<top>, then it calculates the missing dimension by this aspect ratio.
If C<aspect> is the string 'auto', it will calculate the missing dimension
based on the combination of the window aspect ratio in pixels times the pixel
physical aspect ratio in millimeters (as reported by X11) to give you a square
coordinate system.  If both dimensions are missing, top defaults to C<-bottom>,
or C<1>, and the rest is calculated from that.

If you specify C<mirror_x> or C<mirror_y>, it will flip the coordinate system
so that C<+x> is leftward or C<+y> is downward.  (remember, GL coordinates have
C<+y> upward by default).  This will also call C<glFrontFace> to match, so
mirrored X or Y is C<GL_CW> (clockwise) and neither mirrored or both mirrored
is the default C<GL_CCW> (counter clockwise).

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
