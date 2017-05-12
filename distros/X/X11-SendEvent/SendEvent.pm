#
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

=head1 NAME

X11::SendEvent - a module for sending events to X windows

=head1 SYNOPSIS

 use X11::SendEvent;

 $win = X11::SendEvent->new(win => "MyWindowName");
 $win->SendString("testing", ["Return"]);

=head1 DESCRIPTION

This module presents a simple interface for sending events, keycodes, keysyms and strings to an X window from a perl application.

=cut

package X11::SendEvent;

# --- external modules --------------------------------------------------------

use warnings;
use strict;

use X11::Protocol;
use X11::Keyboard;

# --- module variables --------------------------------------------------------

use vars qw($VERSION);

$VERSION = substr q$Revision: 1.3 $, 10;

# --- module interface --------------------------------------------------------

=head1 METHODS

An object oriented interface is provided as follows: 

=head2 new [options-hash]

Used to initialise the system and create a module instance.  The optional hash may contain any of the following keys:

=item disp

Specifies X display to use.  If this item is not provided, the environment variable B<DISPLAY> is used.  If the aforementioned variable is not set the item defaults to C<localhost:0.0>

=item x

The caller may pass an X connection independently generated using the B<X11::Protocol> module.  When both I<disp> and I<x> are passed, I<x> takes precedence.

=item win => [criteria]

Setting this item instructs the module to automatically find a window to be used for sending events to.  The value passed must be an array reference of values which are handed "as is" to the I<-E<gt>FindWin()> method; for further information please refer to its description below.

=item debug

Turns debugging output on.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = bless({}, $class);

	my %args = @_;
		
	$self->{disp}	= $args{disp} || $ENV{DISPLAY} || "localhost:0.0";
	$self->{x}		= $args{x} || X11::Protocol->new($self->{disp});
	$self->{kbd}	= X11::Keyboard->new($self->{x});
	$self->{debug}	= $args{debug} || 0;

	if ($args{win} =~ /^\d+$/) {
		$self->{win} = $args{win};			# window id passed
		}
	elsif ($args{win}) {
		$self->FindWin( @{$args{win}} );	# autoload
		}

	return $self;
	}

=head2 [win-ref] = FindWin <string> [property = "WM_NAME"]

This method can find a window by specifying certain criteria.  The required string is used to compare against the selected window I<property> which, if left unspecified, defaults as shown above.

The the return value is an object reference which may be used to call methods.  When multiple windows are found, any method called on the object will operate on all windows.  If no windows are found the method returns I<undef>.

I<- exempli gratia ->

 $win = $self->FindWin("x");
 $win->SendString("HELLO");

the code above finds all windows containing the string C<x> in their names and sends them the string C<HELLO>.

=cut

sub FindWin {
	my ($self, $val, $key) = @_;
	return warn "No window name specified!" unless $val;
	$key ||= "WM_NAME";
	$self->debug("FindWin()");

	my @win;
	my $x = $self->{x};
	my $class = $x->atom($key);
	for ($self->wins()) {
		my ($wc) = $x->GetProperty($_, $class, "AnyPropertyType", 0, 256, 0);
		push @win, $_ if $wc =~ /^$val/i;
		$self->debug($wc, 2);
		}
	
	$self->debug(sprintf("- %d [0x%x]", $_, $_)) for @win;
	$self->{win} = \@win;
	$self;
	}

=head2 SendEvent [args]

Use this method to send generic events to a window.  The arguments are passed as a hash, where valid keys are as follows:

=item type

A string containing the event type of event to send e.g. I<IKeyPress>, I<IKeyRelease> etc.

=item win

The id of the window to which to send the event.  If omitted, the window identified in the call to I<-E<gt>new()> (if any is used), else the function warns and returns.

=item detail, state

For more information on both of these keys, please refer to the X11 protocol specification.

=cut

sub SendEvent {
	my $self = shift;
	my %args = (%$self, @_);
	my $x = $self->{x};

	return warn "No window id specified!" unless @{$args{win}};

	my $event = $x->pack_event(
		name		=> $args{type},
		detail		=> $args{detail},
		state		=> $args{state},
		time		=> time(),
		root		=> $x->root(),
		same_screen	=> 1,
		# event		=> 'Normal',
		);

	my $mask = $x->pack_event_mask($args{type});
	$x->SendEvent($_, 1, $mask, $event)
		for @{$args{win}};
	}

=head2 SendKeycode <keycode> [state = 0]

Use this method to send a keycode to the window.  A shift state may also be specified, defaulting to the value shown above.

=head2 SendKeycode [list-ref = $_]

Alternatively, the arguments may be passed as a list reference, which defaults to B<$_>.

=cut

sub SendKeycode {
	my $self = shift;
	my $args = shift || $_;
	my $state = shift;

	($args, $state) = @$args if ref($args) eq "ARRAY";
	$state ||= 0;

	my %args = (detail => $args, state => $state);
	$self->SendEvent(type => "KeyPress", %args);
	$self->SendEvent(type => "KeyRelease", %args);
	}

=head2 SendKeysym <keysym-name>

This method translates the given keysym name into a keycode and sends it to the window.

=cut

sub SendKeysym {
	my $self = shift;
	my ($keysym, $kbd) = (shift, $self->{kbd});
	$self->SendKeycode($kbd->KeysymToKeycode($keysym));
	}

=head2 SendString <string[-list]>

Use this method to send strings to a window.  Keysyms and/or keycode/states may be interspersed in the parameter list via the inclusion of array references.  The arrays passed may contain either a keysym name or a keycode and state (separated by a slash).

I<- exempli gratia ->

 $win->SendString("user", ["Return"], "joe", ["9/1"]);

In the above example, the string C<user> is sent to the application, followed by a C<return> key.  Then the string C<joe> is sent, followed by the shifted keycode 9.

=cut

sub SendString {
	my $self = shift;
	my $k = $self->{kbd};

	my @keycodes;
	for (@_) {
		if (ref($_) eq "ARRAY") {
			$_ = shift @$_;
			push @keycodes, [ m|/| ? split "/" : $k->KeysymToKeycode() ];
			}
		else {
			push @keycodes, [ $k->KeysymToKeycode() ] for split //;
			}
		}
		
	$self->SendKeycode() for @keycodes;

	#for (@keycodes) {
	#	print $_->[0], "/", $_->[1], "\n";
	#	$self->SendKeycode();
	#	}
	}

# --- internal functions ------------------------------------------------------

#	returns a list of all open X windows in no particular order
#	including child windows

sub wins {
	my $self = shift;
	my $win = shift || $_;
	my $x = $self->{x};
	my (undef, undef, @wins) = $x->QueryTree($win || $x->root());

	my @ret = @wins;
	push @ret, $self->wins() for @wins;
	@ret;
	}

sub debug {
	my $self = shift;
	my $arg = shift;
	my $debug = shift || 1;
	return unless $self->{debug} >= $debug;
	local ($\, $,) = ("\n", " ");
	print STDERR ">", "X11::SendEvent", "-", $arg;
	}

1; # :)

__END__

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 AVAILABILITY + SUPPORT

For support e-mail the author.  This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 DATE

$Date: 2002/12/04 22:10:13 $

=head1 VERSION

$Revision: 1.3 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.

