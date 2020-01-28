#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2016 -- leonerd@leonerd.org.uk

package Tickit::Event;

use strict;
use warnings;

our $VERSION = '0.70';

use Carp;

=head1 NAME

C<Tickit::Event> - event information structures

=head1 DESCRIPTION

When event handlers bound to L<Tickit::Term> or L<Tickit::Window> instances
are invoked they receive an object instance to contain information about the
event. Details of the event can be accessed as via accessor methods on these
instances.

=head1 ACCESSORS

The following methods are shared between C<Tickit::Event::Key> and
C<Tickit::Event::Mouse> instances.

=head2 mod_is_alt

=head2 mod_is_ctrl

=head2 mod_is_shift

Convenient shortcuts to tests on the C<mod> bitmask to test if each of the
modifiers is set.

=cut

sub mod_is_alt   { shift->mod & Tickit::MOD_ALT }
sub mod_is_ctrl  { shift->mod & Tickit::MOD_CTRL }
sub mod_is_shift { shift->mod & Tickit::MOD_SHIFT }

package
   Tickit::Event::Expose;
our @ISA = qw( Tickit::Event );

=head1 Tickit::Event::Expose

=head2 rb

The L<Tickit::RenderBuffer> instance containing the buffer for this redraw
cycle.

=head2 rect

A L<Tickit::Rect> instance containing the region of the window that needs
repainting.

=cut

package
   Tickit::Event::Focus;
our @ISA = qw( Tickit::Event );

=head1 Tickit::Event::Focus

=head2 type

This accessor has two forms of operation.

The new behaviour is that it returns a dualvar giving the focus event type as
an integer or a string event name (C<in> or C<out>). This behaviour is
selected if the method is invoked with any true value as an argument.

The legacy behaviour is that it returns a simple boolean giving the focus
direction; C<1> for in, C<0> for out. This legacy behaviour will be removed in
a later version.

=head2 win

The child L<Tickit::Window> instance for child-focus notify events.

=cut

package
   Tickit::Event::Key;
our @ISA = qw( Tickit::Event );

=head1 Tickit::Event::Key

=head2 type

A dualvar giving the key event type as an integer or string event name (C<text> or C<key>).

=head2 str

A string containing the key event string.

=head2 mod

An integer bitmask indicating the modifier state.

=cut

package
   Tickit::Event::Mouse;
our @ISA = qw( Tickit::Event );

=head1 Tickit::Event::Mouse

=head2 type

A dualvar giving the mouse event type as an integer or string event name (C<press>, C<drag>, C<release> or C<wheel>).

=head2 button

An integer for non-wheel events or a dualvar for wheel events giving the
wheel direction (C<up> or C<down>).

=head2 line

=head2 col

Integers giving the mouse position.

=head2 mod

An integer bitmask indicating the modifier state.

=cut

package
   Tickit::Event::Resize;
our @ISA = qw( Tickit::Event );

=head1 Tickit::Event::Resize

=head2 lines

=head2 cols

Integers giving the new size.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
