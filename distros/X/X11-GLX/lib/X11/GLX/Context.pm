package X11::GLX::Context;
$X11::GLX::Context::VERSION = '0.03';
use strict;
use warnings;
use X11::GLX;
use parent 'X11::Xlib::Opaque';

# ABSTRACT: Opaque wrapper for GLXContext pointer


# display comes from parent class

sub autofree { $_[0]{autofree}= $_[1] if @_ > 1; $_[0]{autofree} }

sub imported { 0 }

# id comes from XS

sub DESTROY {
	my $self= shift;
	unless ($self->_already_freed) {
		X11::GLX::glXDestroyContext($self->display, $self)
			if $self->autofree;
		X11::GLX::glXFreeContextEXT($self->display, $self)
			if $self->imported;
	}
}

@X11::GLX::Context::Imported::ISA= ( __PACKAGE__ );
sub X11::GLX::Context::Imported::imported { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX::Context - Opaque wrapper for GLXContext pointer

=head1 VERSION

version 0.03

=head1 DESCRIPTION

GLXContext is an opaque object used by the GLX API to reference the collection
of state used for OpenGL rendering, usually by one thread onto one X11 window.

The only method you can call on this object is "xid", since that is the only
GLX function that doesn't also require a handle to the display.

See L<X11::GLX::DWIM> for a convenient object-oriented interface to GLX that
performs the things you probably want it to do.

=head1 ATTRIBUTES

=head2 display

X11 connection this Context was created from.

=head2 autofree

Whether to automatically call L<glXDestroyContext|X11::GLX/glXDestroyContext>
when this object goes out of scope.

=head2 imported

Read-only.  Always False in base class.  Overridden in subclass ::Imported to be True.

=head2 id

The X11 ID of the GLX context.  This is not available unless you have the
GLX_EXT_import_context extension.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
