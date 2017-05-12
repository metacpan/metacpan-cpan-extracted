#
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

=head1 NAME

X11::Keyboard - Keyboard support functions for X11

=head1 SYNOPSIS

 use X11::Protocol;
 use X11::Keyboard;

 $x = X11::Protocol->new();
 $k = X11::Keyboard->new($x);
 $keysym = $k->StringToKeysym("plus");
 print $k->KeysymToKeycode($keysym);

 # or, more simply
 print $k->KeysymToKeycode("plus");

=head1 DESCRIPTION

This module is meant to provide access to the keyboard functions of X11.  Whilst the functions names are essentially identical to those used in xlib (minus the prepended X), the parameter lists and return values are different as specified in this document.

=cut

package X11::Keyboard;

# --- external modules --------------------------------------------------------

use warnings;
use strict;

use X11::Keysyms '%keysyms';

# --- module variables --------------------------------------------------------

use vars qw($VERSION %keysyms);

$VERSION = substr q$Revision: 1.4 $, 10;

# --- module interface --------------------------------------------------------

=head1 METHODS

An object oriented interface is provided as follows: 

=head2 new <x-connection>

Used to initialise the system, this method requires a handle to an X connection (typically generated using the X11::Protocol module) and returns an object instance.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = bless({}, $class);

	$self->{x} = shift;
	warn "No X connection available!" unless $self->{x};
	$self->{sym2cd} = $self->GetKeyboardMapping();

	return $self;
	}

=head2 keysym-num = StringToKeysym [keysym-name = $_]

This method requires a keysym name and returns its corresponding numeric value.  If no name is provided, B<$_> is used.

I<- exempli gratia ->

 $c = $k->StringToKeysym("Backspace");
 # $c now contains 65288

=cut

sub StringToKeysym {
	my ($self, $s) = @_;
	$keysyms{$s || $_};
	}

=head2 keycode [state] = KeysymToKeycode [keysym-[num|name] = $_]

This method returns the keycode corresponding to the passed-in keysym name or number (if neither is passed B<$_> is used).  In such cases where the keysym name evaluates to a numeric value e.g. [0-9], the caller is responsible for first converting the value to a true keysym-num.

The method can also return the associated state.  If the calling context is a list it is returned, if scalar, only the keycode is returned.

=cut

sub KeysymToKeycode {
	my ($self, $keysym) = @_;
	$keysym ||= $_;

	$keysym = $self->StringToKeysym($keysym)
		unless $keysym =~ /^[0-9]+$/;

	wantarray() ? @{$self->{sym2cd}{$keysym}} : $self->{sym2cd}{$keysym}[0];
	}

# --- internal functions ------------------------------------------------------

sub GetKeyboardMapping {
	my $self = shift;
	my $x = $self->{x};

	my $min = $x->{min_keycode};
	my $count = $x->{max_keycode} - $min;
	my @mapping = $x->GetKeyboardMapping($min, $count);

	die "No keyboard map!" unless @mapping;

	my %ret;
	for my $i (0 .. $#mapping) {
		$ret{$mapping[$i][0]} = [$i + $min, 0];		# unshifted
		$ret{$mapping[$i][1]} = [$i + $min, 1];		# shifted
		}

	wantarray() ? %ret : \%ret;
	}

1; # :)

__END__

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 ACKNOWLEDGEMENTS

My gratitude to Benjamin Goldberg for his patience and direction in my struggles to put this together, as well as to Somni and dkr from the OPN #perl channel.

=head1 AVAILABILITY + SUPPORT

For support e-mail the author.  This module may be found on the CPAN.  Additionally, both the module and its RPM package are available from:

F<http://perl.arix.com>

=head1 DATE

$Date: 2002/12/04 05:16:01 $

=head1 VERSION

$Revision: 1.4 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.

