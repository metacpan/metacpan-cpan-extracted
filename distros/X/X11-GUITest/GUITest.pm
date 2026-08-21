# X11::GUITest ($Id: GUITest.pm 253 2026-08-19 22:37:51Z ctrondlp $)
#
# Copyright (c) 2003-2026  Dennis K. Paulsen, All Rights Reserved.
# Email: ctrondlp@cpan.org
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http\://www.gnu.org/licenses>.
#
#

=head1 NAME

X11::GUITest - Provides GUI testing/interaction routines.

=head1 VERSION

0.29

Updates are made available at the following sites:

  http\://sourceforge.net/projects/x11guitest
  http\://www.cpan.org

Please consult 'Changes' for the list of changes between
module revisions.

=head1 DESCRIPTION

This Perl package is intended to facilitate the testing of GUI applications
by means of user emulation.  It can be used to test/interact with GUI
applications; which have been built upon the X library or toolkits
(i.e., GTK+, Xt, Qt, Motif, etc.) that "wrap" the X library's functionality.

A basic recorder (x11guirecord) is also available, and can be found in
the source code repository.

=head1 DEPENDENCIES

An X server with the XTest extensions enabled.  This seems to be the
norm.  If it is not enabled, it usually can be by modifying the X
server configuration (i.e., XF86Config).

This module talks to the X server via the standard DISPLAY environment
variable, exactly like any other X11 client.  By default DISPLAY is
usually ":0.0" (the local machine).  To target a different X server --
for example, one on a remote host -- set DISPLAY before running your
script:

  export DISPLAY=<hostname-or-ipaddress>:<display>.<screen>

Under most circumstances, xhost will also need to be run on the remote
host to permit the connection.

DISPLAY only helps if there is an actual X11 server to point it at.  This
module requires a real X11 server -- either a native X11 session, or
XWayland running as an X11 compatibility layer inside a Wayland session.
It cannot function under a pure Wayland session with no XWayland present.
See WAYLAND NOTES below for how to diagnose and work around this on a
Wayland desktop.

There is a known incompatibility between the XTest and Xinerama extensions,
which causes the XTestFakeMotionEvent() function to misbehave when the
Xinerama (X server) extension is active.  MoveMouseAbs() has an alternate,
XWarpPointer()-based implementation for this case, but it is not enabled by
default -- it requires rebuilding with the X11_GUITEST_USING_XINERAMA
preprocessor macro defined *in addition to* this module's other defines (a
DEFINE= override on the command line replaces the whole value, it does not
add to it):

  perl Makefile.PL DEFINE="-DNDEBUG -DX11_GUITEST_ALT_L_FALLBACK_META_L -DX11_GUITEST_USING_XINERAMA"
  make
  make install

Only do this if Xinerama is actually active on the target X server;
otherwise leave the module at its default build.

The optional x11guirecord recorder utility (see 'recorder/' and
INSTALLATION below) additionally requires the X server's RECORD extension.
This is separate from XTest, and while common, isn't guaranteed to be
present/enabled on every X server -- particularly minimal or older
commercial X implementations.

=head1 INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

  # If "make install" fails with a permissions error, see INSTALLATION
  # NOTES below.

  # If the build has errors, you may need to install the following dependencies:
  #    libxt-dev, libxtst-dev

  # If you'd like to install the recorder, use these steps:
  cd recorder
  ./autogen.sh
  ./configure
  make
  make install
  x11guirecord --help

  # See INSTALLATION NOTES below if this "make install" fails with a
  # permissions error too.

  # The recorder has its own build-time dependencies, separate from the
  # above:
  #    autoconf, automake     (needed to run autogen.sh)
  #    popt development files (e.g. popt-devel, libpopt-dev)
  #    libX11, libXtst development files, if not already installed
  #      for the main module above
  #
  # GNU gettext (libintl.h) is optional -- if it isn't found, the recorder
  # builds without translation support rather than failing.  This is
  # relevant mainly on AIX and HP-UX, which don't provide GNU gettext
  # natively.

=head1 INSTALLATION NOTES

C<make install> writes into your Perl's installation directories (e.g.
C<site_perl> under F</usr/lib/perl5> or F</usr/local>).  If that location
isn't writable by your user -- the common case for a system Perl -- rerun
the last step as C<sudo make install>.  Perl setups that install to a
user-writable location instead (C<local::lib>, perlbrew, plenv, etc.)
normally don't need C<sudo>.  If you're not sure which applies, try plain
C<make install> first and only add C<sudo> if it fails with a permissions
error.

The same applies to the recorder's C<make install> step.

=head1 SYNOPSIS

For additional examples, please look under the 'eg/'
sub-directory from the installation folder.

  use X11::GUITest qw/
    StartApp
    WaitWindowViewable
    SendKeys
  /;

  # Start gedit application
  # Note: The interface for this example application keeps changing.
  StartApp('gedit');

  # Wait for application window to come up and become viewable.
  my ($GEditWinId) = WaitWindowViewable('Untitled Document 1');
  if (!$GEditWinId) {
    die("Couldn't find gedit window in time!");
  }

  # Send text to it
  SendKeys("Hello, how are you?\n");

  # Close Application (Alt-f, q).
  SendKeys('%(f)q');

  # Handle gedit's Question window if it comes up when closing.  Wait
  # at most 5 seconds for it.
  if (WaitWindowViewable('Question', undef, 5)) {
    # Don't Save (Alt-n)
    SendKeys('%(n)');
  }

=head1 WAYLAND NOTES

Even under XWayland, be aware that Wayland's per-application isolation
model prevents synthetic input (sent via the XTest extension, which this
module relies on) from reaching native Wayland clients -- only
X11/XWayland-rooted windows will respond to it.  This is a deliberate
security property of the Wayland protocol, not a bug, and there is no
compile-time or runtime workaround.  See
https://www.linuxteck.com/x11-vs-wayland/ for background on the X11 vs.
Wayland input model.

On a Wayland session (check with 'echo $XDG_SESSION_TYPE'), most
applications default to running as native Wayland clients, invisible to
this module no matter what DISPLAY is set to.  Forcing a specific
application through XWayland instead is usually enough to fix that.
Which environment variable to set depends on the GUI toolkit the target
application is built with:

  Toolkit             Variable to set       Example
  -------             ---------------       -------
  GTK (GNOME, etc.)   GDK_BACKEND=x11       GDK_BACKEND=x11 gedit &
  Qt / KDE Plasma     QT_QPA_PLATFORM=xcb   QT_QPA_PLATFORM=xcb dolphin &

Two gotchas that can make this appear not to work, regardless of toolkit:

=over 8

=item *

Many apps use single-instance activation (GTK's GApplication or KDE's
KDBusService, both implemented over D-Bus).  If the application is already
running, a new invocation with the variable set just signals the existing
(Wayland) process to open a window -- it does not start a new, X11-backed
process.  Fully quit the application first (i.e., confirm no process is
running), then relaunch it.

=item *

Flatpak-packaged applications (increasingly the default for some apps on
Fedora) do not automatically inherit environment variables from the host
shell.  Use 'flatpak run --env=GDK_BACKEND=x11 <app-id>' (substitute
QT_QPA_PLATFORM=xcb for Qt/KDE apps) instead of GDK_BACKEND=x11 <app> &,
and use 'flatpak list --app' to find the app id if it's not obvious from
the command name.

=back

If neither works, or you need this reliably for many applications, the
more robust fix is a session-level one: log out and choose an X11 session
at the login screen, if your desktop still offers one -- e.g. "GNOME on
Xorg" or "Plasma (X11)" (some recent GNOME/Fedora releases have deprecated
or removed that option).

=cut

package X11::GUITest;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;
#require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);

@EXPORT_OK = qw(
    ClickMouseButton
    ClickWindow
    DefaultScreen
    FindWindowLike
    GetChildWindows
    GetEventSendDelay
    GetInputFocus
    GetKeySendDelay
    GetMousePos
    GetParentWindow
    GetRootWindow
    GetScreenDepth
    GetScreenRes
    GetWindowFromPoint
    GetWindowName
    GetWindowPid
    GetWindowPos
    GetWindowsFromPid
    IconifyWindow
    IsChild
    IsKeyPressed
    IsMouseButtonPressed
    IsWindow
    IsWindowCursor
    IsWindowViewable
    LowerWindow
    MoveMouseAbs
    MoveWindow
    PressKey
    PressMouseButton
    PressReleaseKey
    QSfSK
    QuoteStringForSendKeys
    RaiseWindow
    ReleaseKey
    ReleaseMouseButton
    ResizeWindow
    RunApp
    ScreenCount
    SendKeys
    SetEventSendDelay
    SetInputFocus
    SetKeySendDelay
    SetWindowName
    StartApp
    UnIconifyWindow
    WaitSeconds
    WaitWindowClose
    WaitWindowLike
    WaitWindowViewable
);

# Tags (\:ALL, etc.)
%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw(DEF_WAIT M_LEFT M_MIDDLE M_RIGHT M_UP M_DOWN M_BTN1 M_BTN2 M_BTN3 M_BTN4 M_BTN5 XC_X_CURSOR XC_ARROW XC_BASED_ARROW_DOWN XC_BASED_ARROW_UP XC_BOAT XC_BOGOSITY XC_BOTTOM_LEFT_CORNER XC_BOTTOM_RIGHT_CORNER XC_BOTTOM_SIDE XC_BOTTOM_TEE XC_BOX_SPIRAL XC_CENTER_PTR XC_CIRCLE XC_CLOCK XC_COFFEE_MUG XC_CROSS XC_CROSS_REVERSE XC_CROSSHAIR XC_DIAMOND_CROSS XC_DOT XC_DOTBOX XC_DOUBLE_ARROW XC_DRAFT_LARGE XC_DRAFT_SMALL XC_DRAPED_BOX XC_EXCHANGE XC_FLEUR XC_GOBBLER XC_GUMBY XC_HAND1 XC_HAND2 XC_HEART XC_ICON XC_IRON_CROSS XC_LEFT_PTR XC_LEFT_SIDE XC_LEFT_TEE XC_LEFTBUTTON XC_LL_ANGLE XC_LR_ANGLE XC_MAN XC_MIDDLEBUTTON XC_MOUSE XC_PENCIL XC_PIRATE XC_PLUS XC_QUESTION_ARROW XC_RIGHT_PTR XC_RIGHT_SIDE XC_RIGHT_TEE XC_RIGHTBUTTON XC_RTL_LOGO XC_SAILBOAT XC_SB_DOWN_ARROW XC_SB_H_DOUBLE_ARROW XC_SB_LEFT_ARROW XC_SB_RIGHT_ARROW XC_SB_UP_ARROW XC_SB_V_DOUBLE_ARROW XC_SHUTTLE XC_SIZING XC_SPIDER XC_SPRAYCAN XC_STAR XC_TARGET XC_TCROSS XC_TOP_LEFT_ARROW XC_TOP_LEFT_CORNER XC_TOP_RIGHT_CORNER XC_TOP_SIDE XC_TOP_TEE XC_TREK XC_UL_ANGLE XC_UMBRELLA XC_UR_ANGLE XC_WATCH XC_XTERM)],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);

$VERSION = '0.29';

# Module Constants
sub DEF_WAIT() { 10; }
# Mouse Buttons
sub M_BTN1() { 1; }
sub M_BTN2() { 2; }
sub M_BTN3() { 3; }
sub M_BTN4() { 4; }
sub M_BTN5() { 5; }
sub M_LEFT() { M_BTN1; }
sub M_MIDDLE() { M_BTN2; }
sub M_RIGHT() { M_BTN3; }
sub M_UP() { M_BTN4; }
sub M_DOWN() { M_BTN5; }
# Cursors
sub XC_X_CURSOR() { 0 };
sub XC_ARROW() { 2 };
sub XC_BASED_ARROW_DOWN() { 4 };
sub XC_BASED_ARROW_UP() { 6 };
sub XC_BOAT() { 8 };
sub XC_BOGOSITY() { 10 };
sub XC_BOTTOM_LEFT_CORNER() { 12 };
sub XC_BOTTOM_RIGHT_CORNER() { 14 };
sub XC_BOTTOM_SIDE() { 16 };
sub XC_BOTTOM_TEE() { 18 };
sub XC_BOX_SPIRAL() { 20 };
sub XC_CENTER_PTR() { 22 };
sub XC_CIRCLE() { 24 };
sub XC_CLOCK() { 26 };
sub XC_COFFEE_MUG() { 28 };
sub XC_CROSS() { 30 };
sub XC_CROSS_REVERSE() { 32 };
sub XC_CROSSHAIR() { 34 };
sub XC_DIAMOND_CROSS() { 36 };
sub XC_DOT() { 38 };
sub XC_DOTBOX() { 40 };
sub XC_DOUBLE_ARROW() { 42 };
sub XC_DRAFT_LARGE() { 44 };
sub XC_DRAFT_SMALL() { 46 };
sub XC_DRAPED_BOX() { 48 };
sub XC_EXCHANGE() { 50 };
sub XC_FLEUR() { 52 };
sub XC_GOBBLER() { 54 };
sub XC_GUMBY() { 56 };
sub XC_HAND1() { 58 };
sub XC_HAND2() { 60 };
sub XC_HEART() { 62 };
sub XC_ICON() { 64 };
sub XC_IRON_CROSS() { 66 };
sub XC_LEFT_PTR() { 68 };
sub XC_LEFT_SIDE() { 70 };
sub XC_LEFT_TEE() { 72 };
sub XC_LEFTBUTTON() { 74 };
sub XC_LL_ANGLE() { 76 };
sub XC_LR_ANGLE() { 78 };
sub XC_MAN() { 80 };
sub XC_MIDDLEBUTTON() { 82 };
sub XC_MOUSE() { 84 };
sub XC_PENCIL() { 86 };
sub XC_PIRATE() { 88 };
sub XC_PLUS() { 90 };
sub XC_QUESTION_ARROW() { 92 };
sub XC_RIGHT_PTR() { 94 };
sub XC_RIGHT_SIDE() { 96 };
sub XC_RIGHT_TEE() { 98 };
sub XC_RIGHTBUTTON() { 100 };
sub XC_RTL_LOGO() { 102 };
sub XC_SAILBOAT() { 104 };
sub XC_SB_DOWN_ARROW() { 106 };
sub XC_SB_H_DOUBLE_ARROW() { 108 };
sub XC_SB_LEFT_ARROW() { 110 };
sub XC_SB_RIGHT_ARROW() { 112 };
sub XC_SB_UP_ARROW() { 114 };
sub XC_SB_V_DOUBLE_ARROW() { 116 };
sub XC_SHUTTLE() { 118 };
sub XC_SIZING() { 120 };
sub XC_SPIDER() { 122 };
sub XC_SPRAYCAN() { 124 };
sub XC_STAR() { 126 };
sub XC_TARGET() { 128 };
sub XC_TCROSS() { 130 };
sub XC_TOP_LEFT_ARROW() { 132 };
sub XC_TOP_LEFT_CORNER() { 134 };
sub XC_TOP_RIGHT_CORNER() { 136 };
sub XC_TOP_SIDE() { 138 };
sub XC_TOP_TEE() { 140 };
sub XC_TREK() { 142 };
sub XC_UL_ANGLE() { 144 };
sub XC_UMBRELLA() { 146 };
sub XC_UR_ANGLE() { 148 };
sub XC_WATCH() { 150 };
sub XC_XTERM() { 152 };

# Module Variables


bootstrap X11::GUITest $VERSION;

=head1 FUNCTIONS

Parameters enclosed within [] are optional.

If there are multiple optional parameters available for a function
and you would like to specify the last one, for example, you can
utilize undef for those parameters you don't specify.

REGEX in the documentation below denotes an item that is treated as
a regular expression.  For example, the regex "^OK$" would look for
an exact match for the word OK.


=over 8

=item FindWindowLike TITLEREGEX [, WINDOWIDSTARTUNDER]

Finds the window Ids of the windows matching the specified title regex.
Optionally one can specify the window to start under; which would allow
one to constrain the search to child windows of that window.

An array of window Ids is returned for the matches found.  An empty
array is returned if no matches were found.

  my @WindowIds = FindWindowLike('gedit');
  # Only worry about first window found
  my ($WindowId) = FindWindowLike('gedit');

=back

=cut

my $FindWindowLikeAux =
sub {
    my $titlerx = shift;
    my $start = shift;
    my $winname = '';
    my @wins = ();

    # Match the starting window???
    $winname = GetWindowName($start);
    if (defined $winname && $winname =~ /$titlerx/i) {
        push @wins, $start;
    }

    # Match a child window?
    foreach my $child (GetChildWindows($start)) {
        $winname = GetWindowName($child);
        if (defined $winname && $winname =~ /$titlerx/i) {
            push @wins, $child;
        }
    }
    return(@wins);
};

sub FindWindowLike {
    my $titlerx = shift;
    my $start = shift;

    if (defined $start) {
        return &$FindWindowLikeAux($titlerx, $start);
    }
    else {
        my @wins = ();
        for (my $i = ScreenCount() - 1; $i >= 0 ; --$i) {
            push @wins, &$FindWindowLikeAux($titlerx,
                            GetRootWindow($i));
        }
        return(@wins);
    }
}


=over 8

=item WaitWindowLike TITLEREGEX [, WINDOWIDSTARTUNDER] [, MAXWAITINSECONDS]

Waits for a window to come up that matches the specified title regex.
Optionally one can specify the window to start under; which would allow
one to constrain the search to child windows of that window.

One can optionally specify an alternative wait amount in seconds.  A
window will keep being looked for that matches the specified title regex
until this amount of time has been reached.  The default amount is defined
in the DEF_WAIT constant available through the \:CONST export tag.

If a window is going to be manipulated by input, WaitWindowViewable is the
more robust solution to utilize.

An array of window Ids is returned for the matches found.  An empty
array is returned if no matches were found.

  my @WindowIds = WaitWindowLike('gedit');
  # Only worry about first window found
  my ($WindowId) = WaitWindowLike('gedit');

  WaitWindowLike('gedit') or die("gedit window not found!");

=back

=cut

sub WaitWindowLike {
    my $titlerx = shift;
    my $start   = shift;
    my $wait    = shift;
    $wait = DEF_WAIT unless defined $wait;

    require Time::HiRes;
    my $end_time = Time::HiRes::time() + $wait;

    while (1) {
        my @found = FindWindowLike($titlerx, $start);
        if (@found) {
            return @found;   # return actual matches
        }

        my $remaining = $end_time - Time::HiRes::time();
        last if $remaining <= 0;

        # Avoid bogging down the system, but don't oversleep the requested
        # timeout (fractional seconds are supported).
        my $delay = $remaining < 1 ? $remaining : 1;
        select(undef, undef, undef, $delay);
    }

    # Nothing found
    return ();
}


=over 8

=item WaitWindowViewable TITLEREGEX [, WINDOWIDSTARTUNDER] [, MAXWAITINSECONDS]

Similar to WaitWindow, but only recognizes windows that are viewable.  When GUI
applications are started, their window isn't necessarily viewable yet, let alone
available for input, so this function is very useful.

Likewise, this function will only return an array of the matching window Ids for
those windows that are viewable.  An empty array is returned if no matches were
found.

=back

=cut

sub WaitWindowViewable {
    my $titlerx = shift;
    my $start = shift;
    my $wait = shift;
    $wait = DEF_WAIT unless defined $wait;
    my @wins = ();

    require Time::HiRes;
    my $end_time = Time::HiRes::time() + $wait;

    while (1) {
        # Find windows, but recognize only those that are viewable
        foreach my $win (FindWindowLike($titlerx, $start)) {
            if (IsWindowViewable($win)) {
                push @wins, $win;
            }
        }
        if (@wins) {
            return(@wins);
        }

        my $remaining = $end_time - Time::HiRes::time();
        last if $remaining <= 0;

        # Avoid bogging down the system, but don't oversleep the requested
        # timeout (fractional seconds are supported).
        my $delay = $remaining < 1 ? $remaining : 1;
        select(undef, undef, undef, $delay);
    }

    # Nothing
    return(@wins);
}


=over 8

=item WaitWindowClose WINDOWID [, MAXWAITINSECONDS]

Waits for the specified window to close.

One can optionally specify an alternative wait amount in seconds. The
window will keep being checked to see if it has closed until this amount
of time has been reached.  The default amount is defined in the DEF_WAIT
constant available through the \:CONST export tag.

zero is returned if window is not gone, non-zero if it is gone.

=back

=cut

sub WaitWindowClose {
    my $win = shift;
    my $wait = shift;
    $wait = DEF_WAIT unless defined $wait;

    require Time::HiRes;
    my $end_time = Time::HiRes::time() + $wait;

    while (1) {
        if (not IsWindow($win)) {
            # Success, window isn't recognized
            return(1);
        }

        my $remaining = $end_time - Time::HiRes::time();
        last if $remaining <= 0;

        # Check approximately twice per second, without exceeding the
        # requested timeout.
        my $delay = $remaining < 0.50 ? $remaining : 0.50;
        select(undef, undef, undef, $delay);
    }

    # Failure
    return(0);
}

=over 8

=item WaitSeconds SECONDS

Pauses execution for the specified amount of seconds.

  WaitSeconds(0.5); # Wait 1/2 second
  WaitSeconds(3); # Wait 3 seconds

=back

=cut

sub WaitSeconds {
    select(undef, undef, undef, shift);
}

=over 8

=item ClickWindow WINDOWID [, X Offset] [, Y Offset] [, Button]

Clicks on the specified window with the mouse.

Optionally one can specify the X offset and Y offset.  By default,
the top left corner of the window is clicked on, with these two
parameters one can specify a different position to be clicked on.

One can also specify an alternative button.  The default button is
M_LEFT, but M_MIDDLE and M_RIGHT may be specified too.  Also,
you could use the logical Id for the button: M_BTN1, M_BTN2, M_BTN3,
M_BTN4, M_BTN5.  These are all available through the \:CONST export
tag.

zero is returned on failure, non-zero for success

=back

=cut

sub ClickWindow {
    my $win = shift;
    my $x_offset = shift || 0;
    my $y_offset = shift || 0;
    my $button = shift || M_LEFT;

    my ($x, $y, $scr);
    ($x, $y, undef, undef, undef, $scr) = GetWindowPos($win);
    if (!defined($x) or !defined($y)) {
        return(0);
    }
    if (!MoveMouseAbs($x + $x_offset, $y + $y_offset, $scr)) {
        return(0);
    }
    if (!ClickMouseButton($button)) {
        return(0);
    }
    return(1);
}

=over 8

=item GetWindowsFromPid PID

Returns a list of window ids discovered for the specified process id (pid).

undef is returned on error.

=back

=cut

sub GetWindowsFromPid {
    my $pid = shift;
    my @wins = ();

    if (!defined($pid) || $pid !~ /^\d+$/ || $pid <= 0) {
        return(undef);
    }

    my @all_wins = FindWindowLike('.*');
    foreach my $aw (@all_wins) {
        my $aw_pid = GetWindowPid($aw);
        if ($aw_pid == $pid) {
            push @wins, $aw;
        }
    }
    return(@wins);
}

=over 8

=item GetWindowFromPoint X, Y [, SCREEN]

Returns the window that is at the specified point.  If no screen is given, it
is taken from the value given when opening the X display.

zero is returned if there are no matches (i.e., off screen).

=back

=cut

sub GetWindowFromPoint {
    my $x = shift;
    my $y = shift;
    my $scr = shift;
    my $lastmatch = 0;

    if ( ! defined $scr) {
        $scr = DefaultScreen();
    }

    # Note: Windows are returned in current stacking order, therefore
    # the last match should be the top-most window.
    foreach my $win ( GetChildWindows(GetRootWindow($scr)) ) {
        my ($w_x1, $w_y1, $w_w, $w_h, $w_b) = GetWindowPos($win);
        # Is window position invalid?
        if (!defined $w_x1) {
            next;
        }
        my $w_x2 = ($w_x1 + $w_w + ($w_b << 1));
        my $w_y2 = ($w_y1 + $w_h + ($w_b << 1));
        # Does window match our point?
        if ($x >= $w_x1 && $x < $w_x2 && $y >= $w_y1 && $y < $w_y2) {
            $lastmatch = $win;
        }
    }
    return($lastmatch);
}


=over 8

=item IsChild PARENTWINDOWID, WINDOWID

Determines if the specified window is a child of the
specified parent.

zero is returned for false, non-zero for true.

=back

=cut

sub IsChild {
    my $parent = shift;
    my $win = shift;

    foreach my $child ( GetChildWindows($parent) ) {
        if ($child == $win && $child != $parent) {
            return(1);
        }
    }
    return(0);
}


=over 8

=item QuoteStringForSendKeys STRING

Quotes {} characters in the specified string that would be interpreted
as having special meaning if sent to SendKeys directly.  This function
would be useful if you had a text file in which you wanted to use each
line of the file as input to the SendKeys function, but didn't want
any special interpretation of the characters in the file.

Returns the quoted string, undef is returned on error.

  # Quote  ~, %, etc.  as  {~}, {%}, etc for literal use in SendKeys.
  SendKeys( QuoteStringForSendKeys('Hello: ~%^(){}+#') );
  SendKeys( QSfSK('#+#') );

The international AltGr key - modifier character (&) is not escaped by
this function.  Escape this character manually ("{&}"), if used/needed.

=back

=cut

sub QuoteStringForSendKeys {
    my $str = shift;
    if (!defined($str)) {
        return(undef);
    }

    # Quote {} special characters (^, %, (, {, etc.)
    $str =~ s/(\^|\%|\+|\~|\(|\)|\{|\})/\{$1\}/gm;

    return($str);
}

sub QSfSK {
    return QuoteStringForSendKeys(shift);
}

=over 8

=item StartApp COMMANDLINE

Starts a program directly using exec.  This function returns after
checking that the child process remains running.  Useful for starting GUI
/applications and then going on to work with them.

zero is returned on failure, non-zero for success

  StartApp('gedit');

Environment variable assignments (e.g. GDK_BACKEND=x11, may be needed to
force a GTK application through XWayland instead of native Wayland -- see
DEPENDENCIES above) can be prefixed onto COMMANDLINE, provided the whole
thing is passed as a single string:

  StartApp('GDK_BACKEND=x11 gedit');   # Works.
  StartApp('GDK_BACKEND=x11', 'gedit'); # Does NOT work.

=back

=cut

sub StartApp {
    my @cmd = @_;
    my $pid = fork;
    if ($pid) {
        use POSIX qw(WNOHANG);
        sleep 1;
        waitpid($pid, WNOHANG) != $pid
            and kill(0, $pid) == 1
            and return $pid;
    } elsif (defined $pid) {
        use POSIX qw(_exit);
        # Execute the supplied argument list directly; no shell is invoked.
        exec @cmd or _exit(1);
    }
    return;
}


=over 8

=item RunApp COMMANDLINE

Uses the shell to execute a program until its completion.

Return value will be application specific, however -1 is returned
to indicate a failure in starting the program.

  RunApp('/work/myapp');

=back

=cut

sub RunApp {
    my $cmdline = shift;
    return( system($cmdline) );
}


=over 8

=item ClickMouseButton BUTTON

Clicks the specified mouse button.  Available mouse buttons
are: M_LEFT, M_MIDDLE, M_RIGHT, M_DOWN, M_UP.  Also, you could
use the logical Id for the button: M_BTN1, M_BTN2, M_BTN3,
M_BTN4, M_BTN5.  These are all available through the \:CONST
export tag.

zero is returned on failure, non-zero for success.

=back

=cut

sub ClickMouseButton {
    my $button = shift;

    if (!PressMouseButton($button) ||
        !ReleaseMouseButton($button)) {
        return(0);
    }
    return(1);
}

# Subroutine: INIT
# Description: Used to initialize the underlying mechanisms
#              that this package utilizes.
# Note: Perl idiom not to return values for this subroutine.
sub INIT {
    if (!defined($ENV{'AUTOMATED_TESTING'}) || $ENV{'AUTOMATED_TESTING'} ne 1) {
        InitGUITest();
    }
}

# Subroutine: END
# Description: Used to deinitialize the underlying mechanisms
#              that this package utilizes.
# Note: Perl idiom not to return values for this subroutine.
sub END {
    DeInitGUITest();
}

=over 8

=item DefaultScreen

Returns the screen number specified in the X display value used to open the
display.

Leverages the Xlib macro of the same name.

=back

=cut

=over 8

=item ScreenCount

Returns the number of screens in the X display specified when opening it.

Leverages the Xlib macro of the same name.

=back

=cut

=over 8

=item SetEventSendDelay DELAYINMILLISECONDS

Sets the milliseconds of delay between events being sent to the
X display.  It is usually not a good idea to set this to 0.

Please note that this delay will also affect SendKeys.

Returns the old delay amount in milliseconds.

=back

=cut

=over 8

=item GetEventSendDelay

Returns the current event sending delay amount in milliseconds.

=back

=cut

=over 8

=item SetKeySendDelay DELAYINMILLISECONDS

Sets the milliseconds of delay between keystrokes.

Returns the old delay amount in milliseconds.

=back

=cut

=over 8

=item GetKeySendDelay

Returns the current keystroke sending delay amount in milliseconds.

=back

=cut

=over 8

=item GetWindowName WINDOWID

Returns the window name for the specified window Id.  undef
is returned if name could not be obtained.

  # Return the name of the window that has the input focus.
  my $WinName = GetWindowName(GetInputFocus());

=back

=cut

=over 8

=item GetWindowPid WINDOWID

Returns the process id (pid) associated with the specified 
window.  0 is returned if the pid is not available.

  # Return the pid of the window that has the input focus.
  my $pid = GetWindowPid(GetInputFocus());

=back

=cut

=over 8

=item SetWindowName WINDOWID, NAME

Sets the window name for the specified window Id.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item GetRootWindow [SCREEN]

Returns the Id of the root window of the screen.  This is the top/root level
window that all other windows are under.  If no screen is given, it is taken
from the value given when opening the X display.

=back

=cut

=over 8

=item GetChildWindows WINDOWID

Returns an array of the child windows for the specified
window Id.  If it detects that the window hierarchy
is in transition, it will wait half a second and try
again.

=back

=cut

=over 8

=item MoveMouseAbs X, Y [, SCREEN]

Moves the mouse cursor to the specified absolute position in the optionally
given screen.  If no screen is given, it is taken from the value given when
opening the X display.

Zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item GetMousePos

Returns an array containing the position and the screen (number) of the mouse
cursor.

  my ($x, $y, $scr_num) = GetMousePos();

=back

=cut

=over 8

=item PressMouseButton BUTTON

Presses the specified mouse button.  Available mouse buttons
are: M_LEFT, M_MIDDLE, M_RIGHT, M_DOWN, M_UP.  Also, you could
use the logical Id for the button: M_BTN1, M_BTN2, M_BTN3, M_BTN4,
M_BTN5.  These are all available through the \:CONST export tag.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item ReleaseMouseButton BUTTON

Releases the specified mouse button.  Available mouse buttons
are: M_LEFT, M_MIDDLE, M_RIGHT, M_DOWN, M_UP.  Also, you could
use the logical Id for the button: M_BTN1, M_BTN2, M_BTN3, M_BTN4,
M_BTN5.  These are all available through the \:CONST export tag.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item SendKeys KEYS

Sends keystrokes to the window that has the input focus.

The keystrokes to send are those specified in KEYS parameter.  Some characters
have special meaning, they are:

        Modifier Keys:
        ^       CTRL
        %       ALT
        +       SHIFT
        #       META
        &       ALTGR

        Other Keys:
        ~       ENTER
        \n      ENTER
        \t      TAB
        ( and ) MODIFIER GROUPING
        { and } QUOTE / ESCAPE CHARACTERS

Simply, one can send a text string like so:

        SendKeys('Hello, how are you today?');

Parenthesis allow a modifier to work on one or more characters.  For example:

        SendKeys('%(f)q'); # Alt-f, then press q
        SendKeys('%(fa)^(m)'); # Alt-f, Alt-a, Ctrl-m
        SendKeys('+(abc)'); # Uppercase ABC using shift modifier
        SendKeys('^(+(l))'); # Ctrl-Shift-l
        SendKeys('+'); # Press shift

Braces are used to quote special characters, for utilizing aliased key
names, or for special functionality. Multiple characters can be specified
in a brace by space delimiting the entries.  Characters can be repeated using
a number that is space delimited after the preceding key.

Quote Special Characters

        SendKeys('{{}'); # {
        SendKeys('{+}'); # +
        SendKeys('{#}'); # #

        You can also use QuoteStringForSendKeys (QSfSK) to perform quoting.

Aliased Key Names

        SendKeys('{BAC}'); # Backspace
        SendKeys('{F1 F2 F3}'); # F1, F2, F3
        SendKeys('{TAB 3}'); # Press TAB 3 times
        SendKeys('{SPC 3 a b c}'); # Space 3 times, a, b, c

Special Functionality

        # Pause execution for 500 milliseconds
        SendKeys('{PAUSE 500}');

Combinations

        SendKeys('abc+(abc){TAB PAUSE 500}'); # a, b, c, A, B, C, Tab, Pause 500
        SendKeys('+({a b c})'); # A, B, C

The following abbreviated key names are currently recognized within a brace set.  If you
don't see the desired key, you can still use the unabbreviated name for the key.  If you
are unsure of this name, utilize the xev (X event view) tool, press the key you
want and look at the tools output for the name of that key.  Names that are in the list
below can be utilized regardless of case.  Ones that aren't in this list are going to be
case sensitive and also not abbreviated.  For example, using 'xev' you will find that the
name of the backspace key is BackSpace, so you could use {BackSpace} in place of {bac}
if you really wanted to.

        Name    Action
        -------------------
        BAC     BackSpace
        BS      BackSpace
        BKS     BackSpace
        BRE     Break
        CAN     Cancel
        CAP     Caps_Lock
        DEL     Delete
        DOWN    Down
        END     End
        ENT     Return
        ESC     Escape
        F1      F1
        ...     ...
        F12     F12
        HEL     Help
        HOM     Home
        INS     Insert
        LAL     Alt_L
        LMA     Meta_L
        LCT     Control_L
        LEF     Left
        LSH     Shift_L
        LSK     Super_L
        MNU     Menu
        NUM     Num_Lock
        PGD     Page_Down
        PGU     Page_Up
        PRT     Print
        RAL     Alt_R
        RMA     Meta_R
        RCT     Control_R
        RIG     Right
        RSH     Shift_R
        RSK     Super_R
        SCR     Scroll_Lock
        SPA     Space
        SPC     Space
        TAB     Tab
        UP      Up

zero is returned on failure, non-zero for success.  For configurations (Xvfb)
that don't support Alt_Left, Meta_Left is automatically used in its place.

=back

=cut

=over 8

=item PressKey KEY

Presses the specified key.

One can utilize the abbreviated key names from the table
listed above as outlined in the following example:

  # Alt-n
  PressKey('LAL'); # Left Alt
  PressKey('n');
  ReleaseKey('n');
  ReleaseKey('LAL');

  # Uppercase a
  PressKey('LSH'); # Left Shift
  PressKey('a');
  ReleaseKey('a');
  ReleaseKey('LSH');

The ReleaseKey calls in the above example are there to set
both key states back.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item ReleaseKey KEY

Releases the specified key.  Normally follows a PressKey call.

One can utilize the abbreviated key names from the table
listed above.

  ReleaseKey('n');

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item PressReleaseKey KEY

Presses and releases the specified key.

One can utilize the abbreviated key names from the table
listed above.

  PressReleaseKey('n');

This function is affected by the key send delay.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item IsKeyPressed KEY

Determines if the specified key is currently being pressed.

You can specify such things as 'bac' or the unabbreviated form 'BackSpace' as
covered in the SendKeys information.  Brace forms such as '{bac}' are
unsupported.  A '{' is taken literally and letters are case sensitive.

  if (IsKeyPressed('esc')) {  # Is Escape pressed?
  if (IsKeyPressed('a')) { # Is a pressed?
  if (IsKeyPressed('A')) { # Is A pressed?

Returns non-zero for true, zero for false.

=back

=cut

=over 8

=item IsMouseButtonPressed BUTTON

Determines if the specified mouse button is currently being pressed.

Available mouse buttons are: M_LEFT, M_MIDDLE, M_RIGHT.  Also, you
could use the logical Id for the button: M_BTN1, M_BTN2, M_BTN3,
M_BTN4, M_BTN5.  These are all available through the \:CONST export
tag.

  if (IsMouseButtonPressed(M_LEFT)) { # Is left button pressed?

Returns non-zero for true, zero for false.

=back

=cut

=over 8

=item IsWindow WINDOWID

zero is returned if the specified window Id is not for something
that can be recognized as a window.  non-zero is returned if it
looks like a window.

=back

=cut

=over 8

=item IsWindowViewable WINDOWID

zero is returned if the specified window Id is for a window that
isn't viewable.  non-zero is returned if the window is viewable.

=back

=cut

=over 8

=item IsWindowCursor WINDOWID, CURSOR

Determines if the specified window has the specified cursor.

zero is returned for false, non-zero for true.

The following cursors are available through the \:CONST export tag.

    Name
    -------------------
    XC_NUM_GLYPHS
    XC_X_CURSOR
    XC_ARROW
    XC_BASED_ARROW_DOWN
    XC_BASED_ARROW_UP
    XC_BOAT
    XC_BOGOSITY
    XC_BOTTOM_LEFT_CORNER
    XC_BOTTOM_RIGHT_CORNER
    XC_BOTTOM_SIDE
    XC_BOTTOM_TEE
    XC_BOX_SPIRAL
    XC_CENTER_PTR
    XC_CIRCLE
    XC_CLOCK
    XC_COFFEE_MUG
    XC_CROSS
    XC_CROSS_REVERSE
    XC_CROSSHAIR
    XC_DIAMOND_CROSS
    XC_DOT
    XC_DOTBOX
    XC_DOUBLE_ARROW
    XC_DRAFT_LARGE
    XC_DRAFT_SMALL
    XC_DRAPED_BOX
    XC_EXCHANGE
    XC_FLEUR
    XC_GOBBLER
    XC_GUMBY
    XC_HAND1
    XC_HAND2
    XC_HEART
    XC_ICON
    XC_IRON_CROSS
    XC_LEFT_PTR
    XC_LEFT_SIDE
    XC_LEFT_TEE
    XC_LEFTBUTTON
    XC_LL_ANGLE
    XC_LR_ANGLE
    XC_MAN
    XC_MIDDLEBUTTON
    XC_MOUSE
    XC_PENCIL
    XC_PIRATE
    XC_PLUS
    XC_QUESTION_ARROW
    XC_RIGHT_PTR
    XC_RIGHT_SIDE
    XC_RIGHT_TEE
    XC_RIGHTBUTTON
    XC_RTL_LOGO
    XC_SAILBOAT
    XC_SB_DOWN_ARROW
    XC_SB_H_DOUBLE_ARROW
    XC_SB_LEFT_ARROW
    XC_SB_RIGHT_ARROW
    XC_SB_UP_ARROW
    XC_SB_V_DOUBLE_ARROW
    XC_SHUTTLE
    XC_SIZING
    XC_SPIDER
    XC_SPRAYCAN
    XC_STAR
    XC_TARGET
    XC_TCROSS
    XC_TOP_LEFT_ARROW
    XC_TOP_LEFT_CORNER
    XC_TOP_RIGHT_CORNER
    XC_TOP_SIDE
    XC_TOP_TEE
    XC_TREK
    XC_UL_ANGLE
    XC_UMBRELLA
    XC_UR_ANGLE
    XC_WATCH
    XC_XTERM

=back

=cut

=over 8

=item MoveWindow WINDOWID, X, Y

Moves the window to the specified location.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item ResizeWindow WINDOWID, WIDTH, HEIGHT

Resizes the window to the specified size.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item IconifyWindow WINDOWID

Minimizes (Iconifies) the specified window.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item UnIconifyWindow WINDOWID

Unminimizes (UnIconifies) the specified window.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item RaiseWindow WINDOWID

Raises the specified window to the top of the stack, so
that no other windows cover it.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item LowerWindow WINDOWID

Lowers the specified window to the bottom of the stack, so
other existing windows will cover it.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item GetInputFocus

Returns the window that currently has the input focus.

=back

=cut

=over 8

=item SetInputFocus WINDOWID

Sets the specified window to be the one that has the input focus.

zero is returned on failure, non-zero for success.

=back

=cut

=over 8

=item GetWindowPos WINDOWID

Returns an array containing the position information for the specified
window.  It also returns size information (including border width) and the
number of the screen where the window resides.

  my ($x, $y, $width, $height, $borderWidth, $screen) =
        GetWindowPos(GetRootWindow());

=back

=cut

=over 8

=item GetParentWindow WINDOWID

Returns the parent of the specified window.

zero is returned if parent couldn't be determined (i.e., root window).

=back

=cut

=over 8

=item GetScreenDepth [SCREEN]

Returns the color depth for the screen.  If no screen is specified, it is taken
from the value given when opening the X display.  If the screen (number) is
invalid, -1 will be returned.

Value is represented as bits, i.e. 16.

  my $depth = GetScreenDepth();

=back

=cut

=over 8

=item GetScreenRes [SCREEN]

Returns the screen resolution.  If no screen is specified, it is taken from the
value given when opening the X display.  If the screen (number) is invalid, the
returned list will be empty.

  my ($x, $y) = GetScreenRes();

=back

=cut

=head1 OTHER DOCUMENTATION


=begin html

<p>
<a href='../Changes'>Module Changes</a><br>
<a href='CodingStyle'>Coding-Style Guidelines</a><br>
<a href='../ToDo'>ToDo List</a><br>
<a href='Copying'>Copy of the GPL License</a><br>
</p>

=end html


=begin text

  Available under the docs sub-directory.
    CodingStyle (Coding-Style Guidelines)
    Copying (Copy of the GPL License)

=end text

=begin man

Not installed.

=end man


=head1 COPYRIGHT

Copyright(c) 2003-2026 Dennis K. Paulsen, All Rights Reserved.  This
program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License.

=head1 AUTHOR

Dennis K. Paulsen <ctrondlp@cpan.org> (Iowa USA)

=head1 CONTRIBUTORS

Paulo E. Castro <pauloedgarcastro tata gmail.com>

=head1 CREDITS

Thanks to everyone; including those specifically mentioned below for patches,
suggestions, etc.:

  David Dick
  Alexey Tourbin
  Richard Clamp
  Gustav Larsson
  Nelson D. Caro

=cut


# Autoload methods go after __END__, and are processed by the autosplit program.

# Return success
1;
__END__
