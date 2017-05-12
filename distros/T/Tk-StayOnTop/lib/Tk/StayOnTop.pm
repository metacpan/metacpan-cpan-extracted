package Tk::StayOnTop;

our $VERSION = 0.12;

#==============================================================================#

=head1 NAME

Tk::StayOnTop - Keep your window in the foreground

=head1 SYNOPSIS

        use Tk::StayOnTop;
        $toplevel->stayOnTop;
        $toplevel->dontStayOnTop;

=head1 DESCRIPTION

Adds methods to the Tk::Toplevel base class so that a window can stay on top
off all other windows.

=head2 METHODS

=over 4

=cut

#==============================================================================#

package Tk::Toplevel;

use strict;
use warnings;
use Switch;
use Carp;

my ($method,$win32_winpos,$repeat_id); # Globals

## We have various ways to do this - we have to guess which is best
use constant METHOD_SIMPLE  => 1; # Pure Tk - Visibility event/Timer
use constant METHOD_ATTRIB  => 2; # Use the new -topmost => 1 attib (Win32)
use constant METHOD_WINAPI  => 3; # Win32 API calls
use constant METHOD_WMSTATE => 4; # Use Magic X WM calls (Gnome, maybe KDE etc)


#==============================================================================#
# Guess which method to use. This gets called after the window has been created
# because we may need to ask the window manager questions about it.
# $method is stored as a global which may be a bad thing - but let's see who
# complains.
#

sub get_method {
	my ($obj) = @_;

	if ($^O =~ /Win32/) {

		return METHOD_ATTRIB if $Tk::VERSION >= 804.027;

		eval "use Win32::API";
		unless ($@) {
			$win32_winpos = Win32::API->new(
					'user32', 'SetWindowPos',
					['N','N','N','N','N','N','N'], 'N'
			);
			return METHOD_WINAPI;
		}

		croak "Sorry you need either Tk version >= 804.027 or Win32::API installed";

	} else {

		eval {
			die "not supported" if !grep {
				$_ eq '_NET_WM_STATE_STAYS_ON_TOP'
			} $obj->property('get', '_NET_SUPPORTED', 'root');
		};
		return METHOD_WMSTATE unless $@;
	}

	return METHOD_SIMPLE;
}

		
#==============================================================================#

=item $toplevel->stayOnTop();

Keep $toplevel in the foreground.

=cut

sub stayOnTop {
	my ($obj) = @_;

	$method ||=  $obj->get_method;
	#warn "Chosen method is $method";

	switch ($method) {

		case METHOD_WINAPI {
			$obj->update;
			# HWND_TOPMOST (-1) and SWP_NOSIZE+SWP_NOMOVE (3)
			$win32_winpos->Call(hex($obj->frame()),-1,0,0,0,0,3);
		}

		case METHOD_ATTRIB {
			$obj->attributes(-topmost => 1);
		}

		case METHOD_WMSTATE {
    			my($wrapper) = $obj->toplevel->wrapper;
			$obj->property('set', '_NET_WM_STATE', "ATOM", 32,
				["_NET_WM_STATE_STAYS_ON_TOP"], $wrapper);
		}

		case METHOD_SIMPLE {
			my $stay_above_after;
			$obj->bind("<Visibility>" => sub {
				if ($repeat_id) {
					$obj->deiconify;
					$obj->raise;
				}
			});
			$repeat_id = $obj->repeat(1000, sub {
				$obj->deiconify;
				$obj->raise;
				undef $stay_above_after;
			}) unless defined $repeat_id;

		}

		else {
			die "Invalid method type [$method]";	
		}
	}
}

#==============================================================================#

=item $toplevel->dontStayOnTop();

Return $toplevel to normal behaviour.

=cut

sub dontStayOnTop {
	my ($obj) = @_;

	$method ||=  $obj->get_method;

	switch ($method) {

		case METHOD_WINAPI {
			$obj->update;
			# HWND_NOTOPMOST (-2) and SWP_NOSIZE+SWP_NOMOVE (3)
			$win32_winpos->Call(hex($obj->frame()),-2,0,0,0,0,3);
		}

		case METHOD_ATTRIB {
			$obj->attributes(-topmost => 0);
		}

		case METHOD_WMSTATE {
    			my($wrapper) = $obj->toplevel->wrapper;
			$obj->property('delete', "_NET_WM_STATE_STAYS_ON_TOP", $wrapper);
		}

		case METHOD_SIMPLE {
			$obj->afterCancel($repeat_id);
			$repeat_id = undef;
		}

		else {
			die "Invalid method type [$method]";	
		}
	}

}

1;

#==============================================================================#

=back

=head1 IMPLEMENTATION DETAILS

The module uses a number of methods for trying to keep the window in the
foreground. It will atomatically choose the most suitable available. The methods
can be split between Microsoft Windows and X-Windows:

=over 4

=item Microsoft Windows

Perl Tk Version 804.027 and newer support the "-toplevel => 1" attribute. This
will be used if possible.

On older Perl Tk versions, the module will search for the Win32::API module and 
use direct API calls to the OS.

=item X-Windows

For newer X window managers (Gnome, myabe KDE) it will try to set the 
NET_WM_STATE_STAYS_ON_TOP property of the window. 

If this is not implemented, it will just try to the raise window every time
it's covered. This could cause problems if you have two windows competing to
stay on top.

=back

I am hoping that the Perl Tk build in "-toplevel => 1" attribute will be
implement in the future and this module will no longer be needed. However
in the mean time, if you have any other platform dependent solutions, please
let me know and I will try to include them.

=head1 BUGS

See limits in X-Windows functionality descibed above.

=head1 AUTHOR

This module is Copyright (c) 2004 Gavin Brock gbrock@cpan.org. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Many thanks to Slaven Rezic for his many implemntation suggestions.

=head1 SEE ALSO

L<Tk>

L<Win32::API>

=cut



#==============================================================================#
# NOTES FOR ME!!
#
# Use of setwindowpos() function.
# See http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winui/winui/windowsuserinterface/windowing/windows/windowreference/windowfunctions/setwindowpos.asp
#define SWP_NOSIZE          0x0001
#define SWP_NOMOVE          0x0002
#define SWP_NOZORDER        0x0004
#define SWP_NOREDRAW        0x0008
#define SWP_NOACTIVATE      0x0010
#define SWP_FRAMECHANGED    0x0020  
#define SWP_SHOWWINDOW      0x0040
#define SWP_HIDEWINDOW      0x0080
#define SWP_NOCOPYBITS      0x0100
#define SWP_NOOWNERZORDER   0x0200  
#define SWP_NOSENDCHANGING  0x0400  
#define SWP_DRAWFRAME       SWP_FRAMECHANGED
#define SWP_NOREPOSITION    SWP_NOOWNERZORDER
#if(WINVER >= 0x0400)
#define SWP_DEFERERASE      0x2000
#define SWP_ASYNCWINDOWPOS  0x4000
#endif /* WINVER >= 0x0400 */
#define HWND_TOP        ((HWND)0)
#define HWND_BOTTOM     ((HWND)1)
#define HWND_TOPMOST    ((HWND)-1)
#define HWND_NOTOPMOST  ((HWND)-2)
#

# That's all folks..
#==============================================================================#

1;
