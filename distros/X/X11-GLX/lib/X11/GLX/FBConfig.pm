package X11::GLX::FBConfig;
$X11::GLX::FBConfig::VERSION = '0.03';
use strict;
use warnings;
use X11::GLX;
require Scalar::Util;
use parent 'X11::Xlib::Opaque';

# ABSTRACT: Framebuffer config


sub visual_info {
	my $self= shift;
	X11::GLX::glXGetVisualFromFBConfig($self->display, $self);
}

sub xid          { shift->get_attr(X11::GLX::GLX_FBCONFIG_ID()) }
sub buffer_size  { shift->get_attr(X11::GLX::GLX_BUFFER_SIZE()) }
sub level        { shift->get_attr(X11::GLX::GLX_LEVEL())       }
sub doublebuffer { shift->get_attr(X11::GLX::GLX_DOUBLEBUFFER()) }
sub stereo       { shift->get_attr(X11::GLX::GLX_STEREO())       }
sub aux_buffers  { shift->get_attr(X11::GLX::GLX_AUX_BUFFERS())  }
sub red_size     { shift->get_attr(X11::GLX::GLX_RED_SIZE())     }
sub green_size   { shift->get_attr(X11::GLX::GLX_GREEN_SIZE())   }
sub blue_size    { shift->get_attr(X11::GLX::GLX_BLUE_SIZE())    }
sub alpha_size   { shift->get_attr(X11::GLX::GLX_ALPHA_SIZE())   }
sub depth_size   { shift->get_attr(X11::GLX::GLX_DEPTH_SIZE())   }
sub stencil_size { shift->get_attr(X11::GLX::GLX_STENCIL_SIZE()) }
sub accum_red_size   { shift->get_attr(X11::GLX::GLX_ACCUM_RED_SIZE())   }
sub accum_green_size { shift->get_attr(X11::GLX::GLX_ACCUM_GREEN_SIZE()) }
sub accum_blue_size  { shift->get_attr(X11::GLX::GLX_ACCUM_BLUE_SIZE())  }
sub accum_alpha_size { shift->get_attr(X11::GLX::GLX_ACCUM_ALPHA_SIZE()) }
sub render_type      { shift->get_attr(X11::GLX::GLX_RENDER_TYPE()) }
sub drawable_type    { shift->get_attr(X11::GLX::GLX_DRAWABLE_TYPE()) }
sub x_renderable     { shift->get_attr(X11::GLX::GLX_X_RENDERABLE()) }
sub visual_id        { shift->get_attr(X11::GLX::GLX_VISUAL_ID()) }
sub x_visual_type    { shift->get_attr(X11::GLX::GLX_X_VISUAL_TYPE()) }
sub config_caveat    { shift->get_attr(X11::GLX::GLX_CONFIG_CAVEAT()) }
sub transparent_type { shift->get_attr(X11::GLX::GLX_TRANSPARENT_TYPE()) }
sub transparent_index_value { shift->get_attr(X11::GLX::GLX_TRANSPARENT_INDEX_VALUE()) }
sub transparent_red_value   { shift->get_attr(X11::GLX::GLX_TRANSPARENT_RED_VALUE()) }
sub transparent_green_value { shift->get_attr(X11::GLX::GLX_TRANSPARENT_GREEN_VALUE()) }
sub transparent_blue_value  { shift->get_attr(X11::GLX::GLX_TRANSPARENT_BLUE_VALUE()) }
sub transparent_alpha_value { shift->get_attr(X11::GLX::GLX_TRANSPARENT_ALPHA_VALUE()) }
sub max_pbuffer_width       { shift->get_attr(X11::GLX::GLX_MAX_PBUFFER_WIDTH()) }
sub max_pbuffer_height      { shift->get_attr(X11::GLX::GLX_MAX_PBUFFER_HEIGHT()) }
sub max_pbuffer_pixels      { shift->get_attr(X11::GLX::GLX_MAX_PBUFFER_PIXELS()) }


sub get_attr {
	my ($self, $attr_id)= @_;
	$attr_id= X11::GLX->$attr_id unless Scalar::Util::looks_like_number($attr_id);
	my $ret= X11::GLX::glXGetFBConfigAttrib($self->display, $self, $attr_id, my $out);
	die "No such GLXFBConfig attribute $attr_id" 
		if $ret == X11::GLX::GLX_BAD_ATTRIBUTE();
	return undef unless !$ret;
	return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX::FBConfig - Framebuffer config

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is a view of an opaque struct allocated by OpenGL which describes
a framebuffer format.  This is similar to an X11 Visual, but has more
attributes specific to OpenGL.

=head1 ATTRIBUTES

=head2 display

Returns reference to the X11::Xlib instance this object was created from.
(this object wraps a pointer whose scope seems to be the life of the X11
 connection)  Note that this FBConfig holds a strong reference to the
connection, so the connection won't go out of scope as long as you hold
onto this object.

=head2 visual_info

Returns an L<XVisualInfo|X11::Xlib::XVisualInfo> for the FBConfig.

=head2 xid

Returns the X11 ID for this FBConfig.

=head2 buffer_size
=head2 level
=head2 doublebuffer
=head2 stereo
=head2 aux_buffers
=head2 red_size
=head2 green_size
=head2 blue_size
=head2 alpha_size
=head2 depth_size
=head2 stencil_size
=head2 accum_red_size
=head2 accum_green_size
=head2 accum_blue_size
=head2 accum_alpha_size
=head2 render_type
=head2 drawable_type
=head2 x_renderable
=head2 visual_id
=head2 x_visual_type
=head2 config_caveat
=head2 transparent_type
=head2 transparent_index_value
=head2 transparent_red_value
=head2 transparent_green_value
=head2 transparent_blue_value
=head2 transparent_alpha_value
=head2 max_pbuffer_width
=head2 max_pbuffer_height
=head2 max_pbuffer_pixels

=head1 METHODS

=head2 get_attr

  use X11::GLX ':constants';
  my $val= $fbconfig->get_attr($GLX_CONSTANT);

Retrieve a GLX constant.  Dies if C<$GLX_CONSTANT> is not a valid
attriute (according to GLX return value).  Also dies if this FBConfig
doesn't have an associated display or if the display has been closed.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
