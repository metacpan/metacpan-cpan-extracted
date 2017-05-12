
$Tk::LockDisplay::VERSION = '1.3';

package Tk::LockDisplay;

# An xlock-like dialog that requires authentication before unlocking the display.
#
# Stephen.O.Lidie@Lehigh.EDU, Lehigh University Computing Center.  98/08/12
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

use 5.004;
use Carp;
use Tk::Toplevel;
use strict;
use base qw/Tk::Derived Tk::Toplevel/;
Construct Tk::Widget 'LockDisplay';

sub Lock {

    # Realize the dialog, start the screensaver and snooze timer events, clear the password entry, save the current
    # focus and grab and set ours, raise the dialog and wait for the password, release our grab, clear timers, hide
    # the dialog and restore the original focus and grab.  Whew.  (Of course, no timer stuff unless we're animating.)

    my($self) = @_;
    
    my $mez = $self->{Configure}{-animation};
    unless ($mez eq 'none') {
	$self->{mid} = $self->repeat($self->{Configure}{-animationinterval} => [$self => 'mesmerize']);
	$self->{tid} = $self->after($self->{Configure}{-hide} * 1000  => [$self => 'snooze']);
    }
    $self->deiconify;
    $self->waitVisibility;
    $self->{entry}->delete(0 => 'end');
    my $old_focus = $self->focusSave;
    my $old_grab  = $self->grabSave;
    $self->{entry}->focusForce;
    $self->grab(-global);
    $self->raise;
    $self->waitVariable(\$self->{unlock});
    $self->grabRelease;
    unless ($mez eq 'none') {
	$self->afterCancel($self->{tid});
	$self->afterCancel($self->{mid});
    }
    $self->withdraw;
    &$old_focus;
    &$old_grab;

} # end Lock

sub Populate {

    # LockDisplay constructor.  These are the composite widget instance keys:
    #
    # -authenticate => authentication subroutine
    # user          => username
    # pw            => password
    # unlock        => modified when user properly authenticates
    #
    # w             => display width, pixels
    # h             => display height, pixels
    # canvas        => canvas widget reference
    # label         => label widget reference
    # entry         => entry widget reference
    #
    # tid           => -hide after() timer id
    # mid           => -animationinterval repeat() id
    #
    # plug_init     => 1 IFF plugin initialized
    # -debug        => 1 IFF <Double-1> can unlock display

    my($cw, $args) = @_;

    # Disable interactions with the window manager.
    
    $cw->withdraw;
    $cw->protocol('WM_DELETE_WINDOW' => sub {});
    $cw->overrideredirect(1);

    # Process arguments.

    my $user;
    if (not $user = getlogin) {
        if ($^O eq 'MSWin32') {
            $user = $^O;
        } else {
            die "Can't get user name." if not $user = getpwuid($<);
        }
    }
    $cw->{user} = $user;
    $cw->{-authenticate} = delete $args->{-authenticate};
    die "-authenticate callback is improper or missing." unless ref($cw->{-authenticate}) eq 'CODE';
    $cw->{-debug} = delete $args->{-debug};
    $cw->{-debug} ||= 0;
    $args->{-animation} ||= 'lines';
    $cw->SUPER::Populate($args);
    
    # Miscellaneous constants.

    my($w, $h) = ($cw->screenwidth, $cw->screenheight);
    $cw->{w} = $w;
    $cw->{h} = $h;
    my $ti = "tklock $Tk::LockDisplay::VERSION";

    # The canvas/label/entry, et.al.
    
    my $mez = $args->{-animation};
    my $pw;
    $cw->{pw} = \$pw;
    my $canvas = $cw->Canvas;
    $cw->{canvas} = $canvas;
    my $frame = $canvas->Frame;
    my $l = $frame->Label(-text => $ti, -font => 'fixed')->grid;
    $cw->{label} = $l;
    my $e = $frame->Entry(-textvariable => \$pw, -show => '*', -width => 10)->grid;
    $cw->{entry} = $e;

    if ($mez eq 'none') {
	$cw->geometry('+' . int($w/2) . '+' . int($h/2));
	$canvas->createWindow(64, 24, -window => $frame);
	$canvas->configure(-width => 126, -height => 47);
    } else {
	$canvas->configure(-width => $w, -height => $h);
	$canvas->createWindow($w/2, $h/2, -window => $frame);
    }
    $canvas->grid;

    # Composite widget parameter definitions.

    $cw->ConfigSpecs(
		     -animation         => [qw/PASSIVE animation Animation lines/],
		     -animationinterval => [qw/PASSIVE animationInterval AnimationInterval 200/],
		     -background        => [$canvas, qw/background Background black/],
		     -foreground        => [$l, qw/ foreground Foreground blue/],
		     -hide              => [qw/PASSIVE hide Hide 10/],
		     -text              => [qw/METHOD text Text/, $ti],
		     );

    $cw->{tid} = undef;		# timer ID
    $cw->{mid} = undef;		# mesmerizer ID
    $cw->{unlock} = 1;		# unlock flag
    $cw->{plug_init} = 0;	# 0 until plugin initialized

    # Widget bindings.

    $cw->bind('<Motion>'   => [\&awake, $cw]);
    $cw->bind('<Any-Key>'  => [\&awake, $cw]);
    $cw->bind('<Double-1>' => [$cw => 'unlock']) if $cw->{-debug};

} # end Populate

# Private methods.

sub awake {

    # Make title and password entry visible by moving them from hyperspace to a visible portion of the canvas.

    my($subwidget, $self) = @_;

    my $canvas = $self->{canvas};
    unless ($self->{Configure}{-animation} eq 'none') {
	$canvas->afterCancel($self->{tid});
	my($w, $h) = ($self->{w}, $self->{h});
	$canvas->coords(1, $w/2, $h/2);
	$self->{tid} = $canvas->after($self->{Configure}{-hide} * 1000 => [$self => 'snooze']);
    }
    
    if (ref($subwidget) eq 'Tk::Entry') {
	if ($Tk::event->K eq 'Return') {
	    return unless ${$self->{pw}};
	    if (&{$self->{-authenticate}}($self->{user}, ${$self->{pw}})) {
	        $self->unlock;
	    } else {
		$self->{entry}->delete(0 => 'end');
		$self->bell;
	    }
        } # ifend <Return>
    } # ifend Entry widget

} # end awake

sub mesmerize {

    # Animate mesmerizer, either user supplied <CODE>, no screensaver, or a builtin plugin.

    my($self) = @_;

    my $canvas = $self->{canvas};
    my $mez = $self->{Configure}{-animation};
    my $ai = undef;

    if (ref($mez) eq 'CODE') {	# user specified mesmerizing routine
        exit unless &$mez($canvas) >= 1;
    } elsif ($mez eq 'none') {
	return;
    } else {
	if ($self->{plug_init}) {
	    exit unless &Animation($canvas) >= 1;
	} else { 
	    no strict qw/refs/;
	    unless (eval "require Tk::LockDisplay::$mez") {
		warn "Couldn't load plugin file '$mez': $@";
		exit;
	    }
	    $ai = &Animation($canvas);
	    unless ($ai >= 1) {
		warn "Plugin '$mez' failed to initialize.";
		exit;
	    }
	    use strict qw/refs/;
	    if ($ai > 1) {	# restart timer event with new cycle value
		$self->{Configure}{-animationinterval} = $ai;
		$self->afterCancel($self->{mid});
		$self->{mid} = $self->repeat($self->{Configure}{-animationinterval} => [$self => 'mesmerize']);
	    }
	    $self->{plug_init} = 1;
	}
    } # end lines
    $canvas->idletasks;		# update() gives deep recursion!

} # end mesmerize

sub snooze {

    # Hide title and password entry by moving the items way off the canvas.

    my($self) = @_;

    my $canvas = $self->{canvas};
    my $mez = $self->{Configure}{-animation};
    $canvas->coords(1, -1000, -1000);

} # end snooze

sub text {

    # Set canvas title text.

    my($self, $text) = @_;
    
    $self->{label}->configure(-text => $text);

} # end text

sub unlock {$_[0]->{unlock}++}	# alert waitVariable() that we're done

1;

=head1 NAME

Tk::LockDisplay - Create modal dialog and wait for a password response.

=for pm Tk/LockDisplay.pm

=for category Screensavers, Popups and Dialogs

=head1 SYNOPSIS

S<    >I<$lock> = I<$parent>-E<gt>B<LockDisplay>(I<-option> =E<gt> I<value>, ... );

=head1 DESCRIPTION

This widget fills the display with a screensaver-like animation, makes
a global grab and then waits for the user's authentication string,
usually their password.  Until the password is entered the display
cannot be used: window manager commands are ignored, etcetera. Note, X
server requests are not blocked.

Password verification is perforemd via a callback passed during widget
creation.

While waiting for the user to respond, B<LockDisplay> sets a global
grab.  This prevents the user from interacting with any application in
any way except to type characters in the LockDisplay entry box.  See
the B<Lock()> method.

The following option/value pairs are supported:

=over 4

=item B<-authenticate>

Password verification subroutine - it's passed two positional
parameters, the username and password, and should return 1 if success,
else 0.

=item B<-animation>

A string indicating what screensaver plugin to use, or 'none' to
disable the screensaver.  Supplied plugins are 'lines' (default), 'neko'  and
'counter', which reside in the directory .../Tk/LockDisplay.  You can
drop a plugin of your own in that directory - see the section Plugin
Format below for details.  You can also supply your own animation
subroutine by passing a B<CODE> reference.  The subroutine is passed a
single parameter, the canvas widget reference, which you can
draw upon as you please.

=item B<-animationinterval>

The number of milliseconds between calls to the screen saver animation code.
Default is 200 milliseconds.  Plugins can specifiy their own interval by
returning the number of milliseconds (> 1) during initialization.

=item B<-hide>

How many seconds of display inactivity before hiding the password
entry widget and canvas title text. Default is 10 seconds.

=item B<-text>

Title text centered in canvas.

=item B<-foreground>

Title text color.

=item B<-background>

Canvas color.

=item B<-debug>

Set to 1 allows a <Double-1> event to unlock the display.  Used while
debugging your authentication callback or plugin.

=back

=head1 METHODS

=over 4

=item C<$lock-E<gt>B<Lock>;>

This method locks the display and waits for the user's authentication data.

=back

=head1 EXAMPLE

I<$lock> = I<$mw>-E<gt>B<LockDisplay>(-authenticate =E<gt> \&check_pw);

sub check_pw {

    # Perform AFS validation unless on Win32.

    my($user, $pw) = @_;

    if ($^O eq 'MSWin32') {
	($pw eq $^O) ? exit(0) : return(0);
    } else {
	system "/usr/afsws/bin/klog $user " . quotemeta($pw) . " 2> /dev/null";
	($? == 0) ? exit(0) : return(0);
    }

} # end check_pw

=head1 PLUGIN FORMAT

Refer to the "counter" plugin file .../Tk/LockDisplay/counter.pm for
details on the structure of a LockDisplay animation plugin.  Basically,
you create a ".pm" file that describes your plugin, "counter.pm" for
instance.  This file must contain a subroutine called Animate($canvas),
where $canvas is the canvas widget reference passed to it.

LockDisplay first require()s your plugin file, and, if that succeeds,
calls it once to perform initialization.  Animate() should return 0 for
failure, 1 for success, and > 1 for success I<and> to specifiy a private
-animationinterval (in milliseconds).  Subsequent calls to Animate() are
for its "main loop" processing.  As before, the return code should be
0 or 1 for failure or success, respectively.

=head1 HISTORY

=over 4

=item Version 1.0

    Beta Release.

=item Version 1.1

    . Implement plugins and other fixes suggested by Achim Bohnet.
      Thanks!
    . Allow plugin name 'none' to disable screensaver.  Thanks to
      Roderick Anderson!

=item Version 1.2

    . getlogin() fails on HPUX, so try getpwuid() as a fallback.
      Thanks to Paul Schinder for the CPAN-Testers bug report.
    . Plugins can return() their own -animationinterval value 
      during preset.
    . Add 'neko' plugin.

=item Version 1.3

    . Fix value of pi in neko plugin!
    . Add Windows 95 support

=back

=head1 AUTHOR

Stephen.O.Lidie@Lehigh.EDU

=head1 COPYRIGHT

Copyright (C) 1998 - 1998, Stephen O. Lidie.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 KEYWORDS

screeensaver, dialog, modal

=cut
