package Win32::GUI::OpenGLFrame;

# Win32::GUI::OpenGLFrame
# (c) Robert May, 2006..2009
# released under the same terms as Perl.

use 5.006;
use strict;
use warnings;

our $VERSION = "0.02";
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

use Win32::GUI qw(WS_OVERLAPPEDWINDOW WS_CHILD WS_CLIPCHILDREN WS_CLIPSIBLINGS);
our @ISA = qw(Win32::GUI::Window);

use Exporter qw(import);
our @EXPORT_OK = qw(w32gSwapBuffers);

require XSLoader;
XSLoader::load('Win32::GUI::OpenGLFrame', $XS_VERSION);

sub Win32::GUI::Window::AddOpenGLFrame {
    return Win32::GUI::OpenGLFrame->new(@_);
}

sub CS_OWNDC()           {32}
our $WINDOW_CLASS;

sub new {
    my $class = shift;
    my $parent = shift;
    my %options = @_;

    if(exists $options{-onResize}) {
        require Carp;
        Carp::Croak("-resize option is invalid");
    }
    if(exists $options{-onPaint}) {
        require Carp;
        Carp::Croak("-paint option is invalid");
    }

    my $displayfunc = delete($options{-display});
    my $initfunc = delete($options{-init});
    my $reshapefunc = delete($options{-reshape});
    my $doubleBuffer = delete($options{-doubleBuffer}) || 0;
    my $depthFlag = delete($options{-depth}) || 0;

    # Window class with CS_OWNDC, and no background brush
    $WINDOW_CLASS = Win32::GUI::Class->new(
        -name  => "Win32GUI_OpenGLFrame",
        -style => CS_OWNDC,
        -brush => 0,
    ) unless $WINDOW_CLASS;

    my $self = $class->SUPER::new(
        -parent    => $parent,
        -popstyle  => WS_OVERLAPPEDWINDOW,
        -pushstyle => WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
        -class => $WINDOW_CLASS,
        -visible => 1,
        %options,
    );

    # Set a suitable Pixel format
    my $dc = $self->_SetOpenGLPixelFormat($doubleBuffer, $depthFlag) or die "SetOpenGLPixelFormat failed: $^E";

    # Create an OpenGL rendering context for this window, and
    # activate it
    my $rc = wglCreateContext($dc) or die "wglCreateContext: $^E";
    wglMakeCurrent($dc, $rc) or die "wglMakeCurrent: $^E";

    # Store away our class instance data
    $self->ClassData( {
            dc      => $dc,           # We used a class with CS_OWNDC, so can store the DC
            rc      => $rc,
            display => $displayfunc,
            reshape => $reshapefunc,
        } );

    # Call our initialisation function
    $initfunc->($self) if $initfunc;

    # Now that we've got everything initialised, register our _paint and _resize
    # handlers.  We don't do this earlier, else they may get called before we're
    # ready to handle the events.
    $self->SetEvent("Paint", \&_paint);
    $self->SetEvent("Resize", \&_resize);
    
    # Ensure that out paint and resize (reshape) handers get called once.
    $self->_resize();
    $self->InvalidateRect(0);
    
    return $self;
}

sub DESTROY {
    my ($self) = @_;

    # my $idata = $self->ClassData();
    # Previous line shows a bug in ClassData, where _UserData() can return undef if the
    # window has been destroyed and the perlud structure de-allocated.  We do our own thing
    # here for now:
    # XXX Submit patch to Win32::GUI to fix ClassData()
    my $idata;
    if (my $tmp = $self->_UserData()) {
        $idata = $tmp->{__PACKAGE__};
    }

    if(defined $idata) {
        wglMakeCurrent();  # remove the current rendering context
        wglDeleteContext($idata->{rc});
        Win32::GUI::DC::ReleaseDC($self, $idata->{dc}); # not necessary, but good form
    }

    $self->SUPER::DESTROY(@_); # pass destruction up the chain
}

######################################################################
# Static (non-method) functions
######################################################################
sub w32gSwapBuffers
{
    my $hdc = wglGetCurrentDC();
    if($hdc) {
        glFlush(); # XXX Should we have a glFinish() here?
        return SwapBuffers($hdc);
    }

    return 0;
}

######################################################################
# internal callback functions
######################################################################
sub _paint {
    my ($self, $dc) = @_;
    $dc->Validate();

    my $idata = $self->ClassData();

    wglMakeCurrent($idata->{dc}, $idata->{rc}) or die "wglMakeCurrent: $^E";

    if ($idata->{display}) {
        $idata->{display}->($self);
        glFlush();
    }
    else {
        # default: clear all buffers, and display
        glClear();
        w32gSwapBuffers();
    }

    return 0;
}

sub _resize {
    my ($self) = @_;

    my $idata = $self->ClassData();

    wglMakeCurrent($idata->{dc}, $idata->{rc}) or die "wglMakeCurrent: $^E";

    if ($idata->{reshape}) {
        $idata->{reshape}->($self->ScaleWidth(), $self->ScaleHeight())
    }
    else {
	    # default: resize viewport to window
        glViewport(0,0,$self->ScaleWidth(),$self->ScaleHeight());
    }

    return 1;
}

1; # end of OpenGLFrame.pm
__END__

=head1 NAME

Win32::GUI::OpenGLFrame - Integrate OpenGL with Win32::GUI

=head1 SYNOPSIS

  use Win32::GUI::OpenGLFrame qw(w32gSwapBuffers);

  my $oglw = $win->AddOpenGLFrame(...);

=head1 DESCRIPTION

Win32::GUI::OpenGLFrame provides a binding between the perl OpenGL module and
Win32::GUI.  If all you want is windows with OpenGL content, the the OpenGL
module provides a binding to the Win32 glut windowing library.  This module
will be useful if the OpenGL content is a smaller part of your GUI - I.e.
you want to mix OpenGL output with other Win32 controls.

The interface should be mostly familar to anyone with Win32::GUI experience,
although it has been modified to try to make it more intuitave for those used
to programming with the glut interface.

Familarity with both Win32::GUI and the perl OpenGL bindings are assumed.

=head1 EXPORTS

The function c<w32gSwapBuffers> is exportable on request - nothing is exported by default.

=head1 AVAILABLE FUNCTIONS

=head2 w32gSwapBuffers

This function swaps the front and back buffers on a double-buffered rendering context. Acts
on the curretly active rendering context.  It does nothing (and so is safe to call) on a
single buffered rendering context.  Equivilent to the glutSwapBuffers() function.

=head1 Win32::GUI::OpenGLFrame Object

=head2 Constructor: $win->AddOpenGLFrame()

Creates a child window of c<$win> with an OpenGL rendering context associated with the window.
Most of the standard Win32::GUI::Window options are available with the following additions and
restrictions:

=over

=item Use C<-init> for OpenGL initialisation function

The C<-init> option supplies a function callback in which OpenGL initialiastion can be performed.
The OpenGL rendering context is createed and made currrent before the callback is made.  This is
typically used for initialising views, textures etc.

The Win32::GUI::OpenGLFrame object is passed as the only parameter into the C<-init> callback.

=item Use C<-reshape> rather than C<-onResize>

This corresponds to the glut resize event handler.  The OpenGL rendering context for the
window is made active before the callback is made.  The width and height of the window's
client area are provied as parameters to the callback.

If no handler is supplied, the default handler make the OpenGL viewport match the size
of the window.

It is an error to use the C<-onReszie> option.

=item Use C<-display> rather than C<-onPaint>

This corresponds to the glud display event handler.  The OpenGL rendering context for the
window is made active before the callback is made.  The Win32::GUI::OpenGLFrame object
is passed as the only parameter in the <-display> callback.

If no hander is supplied, the deafult handler clears the view.

It is an error to use the C<-onPaint> option.

=item C<-doublebuffer>

The <-doublebuffer> option is a boolean indicating whether the created rendering context
should be double buffered or not.

=item C<-depth>

The <-depth> option is a boolean indicating whether a depth buffer should be requested.  If it is
then a 32-bit depth buffer s requested.

=back

=head1 SEE ALSO

See the demos distributed with the module for further inspiration.  If you have a recent Win32::GUI installation
then try the demo browser by issuing the following command:

  C:\> win32-gui-demos

=over

=item OpenGL - L<http://www.opengl.org/>

=item Perl OpenGL (POGL) - L<http://graphcomp.com/opengl/>

=item OpenGL for Win32 - L<http://www.bribes.org/perl/wopengl.html>

=item The OpenGL Utility Toolkit (GLUT) - L<http://www.opengl.org/resources/libraries/glut/>

=item OpenGL on MSDN - L<http://msdn.microsoft.com/en-gb/library/dd374278%28VS.85%29.aspx>

=back

=head1 SUPPORT

Contact the author for support.

=head1 AUTHORS

Robert May (C<robertmay@cpan.org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006..2009 by Robert May

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
