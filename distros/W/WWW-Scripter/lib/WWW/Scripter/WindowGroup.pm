package WWW::Scripter::WindowGroup;

$VERSION = '0.032'; # update POD, too

use Carp;
use WWW'Scripter;

sub new {
 my(undef,%args) = @_;
 if($args{empty}) {
  bless [],shift
 }
 else {
  my $self = bless [my $w = new WWW'Scripter], shift;
  $w->window_group($self);
  $self;
 }
}

sub active_window {
 return $_[0][0]
}

sub windows {
 @{$_[0]}
}

sub new_window {
 unshift
  @{$_[0]},
  my $w = $_[0][0] ? clear_history{clone{$_[0][0]}}1 : new WWW'Scripter;
 $w->window_group($_[0]);
 $w
}

sub detach {
 my $self = shift;
 my $inddx = 0;
 for(@$self) {
  $_ == $_[0]
   and splice(@$self, $inddx, 1), $_->window_group(undef),return;
  ++$inddx
 }
 croak "detach cannot find $_[0] in $self";
}

sub bring_to_front {
 my $self = shift;
 my $inddx = 0;
 for(@$self) {
  $_ == $_[0] and splice(@$self, $inddx, 1), unshift(@$self,$_), return;
  ++$inddx
 }
 croak "bring_to_front cannot find $_[0] in $self";
}

sub attach {
  unshift @{$_[0]}, $_[1];
  $_[1]->window_group($_[0]);
 _:
}

=head1 NAME

WWW::Scripter::WindowGroup - Multiple-window browsing environment

=head1 VERSION

Version 0.032

=head1 SYNOPSIS

 use WWW'Scripter'WindowGroup;
 
 $browser = new WWW'Scripter'WindowGroup;
 # This has one window already
 
 # OR:
 
 $browser = new WWW'Scripter'WindowGroup empty => 1;
 $browser->attach($w = new WWW'Scripter);
 
 $w = $browser->active_window;
 $w->get('http://ghare.dr/');
 $w->close;
 
 $w = $browser->new_window;
 @w = $browser->windows;

=head1 DESCRIPTION

This module provides a virtual multiple-window browsing environment for
L<WWW::Scripter>. It does not actually create any windows on the screen, 
but
it can be used to script websites that make use of multiple windows. The
individual windows themselves are WWW::Scripter objects.

Before you start using this, consider whether the site you are scripting
actually I<needs> multiple windows. If a single-window environment will do,
use L<WWW::Scripter> directly.

Note: Window groups hold strong references to their windows, but the 
windows themselves hold weak references to the window group. So if you let
a window group go out of scope while retaining a reference to a window,
that window will revert to single-window mode.

=head1 METHODS

=over

=item new

The constructor. Call this method on the class, not on an object thereof.
It takes no arguments.

=item active_window

Returns the window that is currently 'active'. This can be changed by
scripts calling the C<focus> method on a window, or opening a new one, so
keep your own
reference to it if you need to refer to a specific window repeatedly.

=item windows

Returns a list of all windows in list context, or the number of windows in
scalar context.

=item new_window

Adds a new WWW::Scripter to the window group and returns it.

=item attach ($window)

This methods adds a window to the group, making it the frontmost window and
setting its C<window_group>
attribute appropriately.

If you attach a window that is already attached to another group, strange
things may happen. Detach it first.

=item detach ($window)

This removes the window from the group and sets its C<window_group>
attribute to C<undef>. This is used internally by
WWW::Scripter's C<close> method.

=item bring_to_front ($window)

This makes C<$window> the active window.

=back

=head1 AUTHOR & COPYRIGHT

See L<WWW::Scripter>

=head1 SEE ALSO

=over 4

=item -

L<WWW::Scripter>

=back
