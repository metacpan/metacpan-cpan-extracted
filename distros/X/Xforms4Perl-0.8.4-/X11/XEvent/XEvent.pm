#    XEvent.pm - An extension to PERL to access XEvent structures.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package X11::XEvent;

require Exporter;
require DynaLoader;
require AutoLoader;

=head1 NAME

XEvent - package to access XEvent structure fields

=head1 SYNOPSIS

	use <a package that returns XEvents>;
	use X11::XEvent;

	$xevent = function_that_returns_xevent(its, parms);
	$type = $xevent->type;    

	# Any XEvent field can be read like this.

=head1 DESCRIPTION

This class/package provides an extension to perl that allows
Perl programs read-only access to the XEvent structure. So.
how do they get hold of an XEvent to read? Well, they use ANOTHER
Perl extension that blesses pointers to XEvents into the XEvent
class. Such an extension would do that by supplying a TYPEMAP as
follows:

     XEvent *    T_PTROBJ

and then returning XEvent pointers from appropriate function calls.

An extension that does this is the X11::Xforms extension. So, using these
two extensions the perl programmer can do some pretty powerful
XWindows application programming.

So whats in this package. Well, quite simply, every method in this
package is named after a field in the XEvent structure. Now, anyone
who has seen that structure knows that it is, in fact, a union of
a bunch of other structures, the only common field of which is the
first field, the type field.

However, this package is written so that you don't have to know the
REAL structure of the event you are interested in, you just have to
know the name of the field you are after. ALL XEvent fields are
catered for, even the wierd vector ones. ALL are returned as perl
scalars of various intuitively obvious types.

There is one special function that might interest some of you. The
all_fields function returns the values of all fields in the XEvent
as a perl list.

=cut

@ISA = qw(Exporter DynaLoader);

$X11::XEvent::VERSION = '0.7';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

	AnyModifier
	Button1
	Button1Mask
	Button1MotionMask
	Button2
	Button2Mask
	Button2MotionMask
	Button3
	Button3Mask
	Button3MotionMask
	Button4
	Button4Mask
	Button4MotionMask
	Button5
	Button5Mask
	Button5MotionMask
	ButtonMotionMask
	ButtonPress
	ButtonPressMask
	ButtonRelease
	ButtonReleaseMask
	CirculateNotify
	CirculateRequest
	ClientMessage
	ColormapChangeMask
	ColormapNotify
	ConfigureNotify
	ConfigureRequest
	ControlMapIndex
	ControlMask
	CreateNotify
	DestroyNotify
	EnterNotify
	EnterWindowMask
	Expose
	ExposureMask
	FocusChangeMask
	FocusIn
	FocusOut
	GraphicsExpose
	GravityNotify
	KeyPress
	KeyPressMask
	KeyRelease
	KeyReleaseMask
	KeymapNotify
	KeymapStateMask
	LASTEvent
	LeaveNotify
	LeaveWindowMask
	LockMapIndex
	LockMask
	MapNotify
	MapRequest
	MappingNotify
	Mod1MapIndex
	Mod1Mask
	Mod2MapIndex
	Mod2Mask
	Mod3MapIndex
	Mod3Mask
	Mod4MapIndex
	Mod4Mask
	Mod5MapIndex
	Mod5Mask
	MotionNotify
	NoEventMask
	NoExpose
	OwnerGrabButtonMask
	PointerMotionHintMask
	PointerMotionMask
	PropertyChangeMask
	PropertyNotify
	ReparentNotify
	ResizeRedirectMask
	ResizeRequest
	SelectionClear
	SelectionNotify
	SelectionRequest
	ShiftMapIndex
	ShiftMask
	StructureNotifyMask
	SubstructureNotifyMask
	SubstructureRedirectMask
	UnmapNotify
	VisibilityChangeMask
	VisibilityNotify
	XKeycodeToKeysym
	
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
            ($pack,$file,$line) = caller;
            die "Your vendor has not defined XEventPtr macro $constname, used at $file on $line.";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}


bootstrap X11::XEvent;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
