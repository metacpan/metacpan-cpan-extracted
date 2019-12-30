#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2018 -- leonerd@leonerd.org.uk

package Tickit::Term;

use strict;
use warnings;

our $VERSION = '0.69';

use Carp;

# Load the XS code
use Tickit qw( MOD_SHIFT MOD_ALT MOD_CTRL BIND_FIRST );

# We export some constants
use Exporter 'import';

# Old names for these
use constant {
   TERM_CURSORSHAPE_BLOCK    => CURSORSHAPE_BLOCK,
   TERM_CURSORSHAPE_UNDER    => CURSORSHAPE_UNDER,
   TERM_CURSORSHAPE_LEFT_BAR => CURSORSHAPE_LEFT_BAR,
};

push our @EXPORT_OK, qw(
   TERM_CURSORSHAPE_BLOCK TERM_CURSORSHAPE_UNDER TERM_CURSORSHAPE_LEFT_BAR
   MOD_SHIFT MOD_ALT MOD_CTRL
   BIND_FIRST
);

=head1 NAME

C<Tickit::Term> - terminal formatting abstraction

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides terminal control primitives for L<Tickit>; a number of methods that
control the terminal by writing control strings. This object itself performs
no actual IO work; it writes bytes to a delegated object given to the
constructor called the writer.

This object is not normally constructed directly by the containing
application; instead it is used indirectly by other parts of the C<Tickit>
distribution.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $term = Tickit::Term->new( %params )

Constructs a new C<Tickit::Term> object.

Takes the following named arguments at construction time:

=over 8

=item UTF8 => BOOL

If defined, overrides locale detection to enable or disable UTF-8 mode. If not
defined then this will be detected from the locale by using Perl's
C<${^UTF8LOCALE}> variable.

=item writer => OBJECT

An object delegated to for sending strings of terminal control bytes to the
terminal itself. This object must support a single method, C<write>, taking
a string of bytes.

 $writer->write( $data )

Such an interface is supported by an C<IO::Handle> object.

=item output_handle => HANDLE

Optional. If supplied, will be used as the terminal filehandle for querying
the size. Even if supplied, all writing operations will use the C<writer>
function rather than performing IO operations on this filehandle.

=item input_handle => HANDLE

Optional. If supplied, will be used as the terminal filehandle for reading
keypress and other events.

=back

=cut

sub new
{
   my $class = shift;
   my %params = @_;

   my $self = $class->_new( $ENV{TERM} ) or croak "Cannot construct Tickit::Term - $!";

   $self->set_input_handle ( $params{input_handle}  ) if $params{input_handle};
   $self->set_output_handle( $params{output_handle} ) if $params{output_handle};

   my $writer = $params{writer};
   $self->set_output_func( sub { $writer->write( @_ ) } ) if $writer;

   $self->set_utf8( $params{UTF8} ) if defined $params{UTF8};

   return $self;
}

=head2 open_stdio

   $term = Tickit::Term->open_stdio

Convenient shortcut for obtaining a L<Tickit::Term> instance bound to the
STDIN and STDOUT streams of the process.

=cut

=head1 METHODS

=cut

=head2 get_input_handle

   $fh = $term->get_input_handle

Returns the input handle set by the C<input_handle> constructor arg.

Note that because L<Tickit::Term> merely wraps an object provided by the
lower-level F<libtickit> C library, it is no longer guaranteed that this
method will return the same perl-level object that was given to the
constructor. The object may be newly-constructed to represent a new perl-level
readable filehandle on the same file number.

=cut

sub get_input_handle
{
   my $self = shift;
   return IO::Handle->new_from_fd( $self->get_input_fd, "r" );
}

=head2 get_output_handle

   $fh = $term->get_output_handle

Returns the output handle set by the C<output_handle> constructor arg.

Note that because L<Tickit::Term> merely wraps an object provided by the
lower-level F<libtickit> C library, it is no longer guaranteed that this
method will return the same perl-level object that was given to the
constructor. The object may be newly-constructed to represent a new perl-level
writable filehandle on the same file number.

=cut

sub get_output_handle
{
   my $self = shift;
   return IO::Handle->new_from_fd( $self->get_output_fd, "w" );
}

=head2 set_output_buffer

   $term->set_output_buffer( $len )

Sets the size of the output buffer

=cut

=head2 await_started

   $term->await_started( $timeout )

Waits for the terminal startup process to complete, up to the timeout given in
seconds.

=cut

=head2 pause

   $term->pause

Suspends operation of the terminal by resetting it to its default state.

=cut

=head2 resume

   $term->resume

Resumes operation of the terminal after a L</pause>.

Typically these two methods are used together, either side of a blocking wait
around a C<SIGSTOP>.

   sub suspend
   {
      $term->pause;
      kill STOP => $$;
      $term->resume;
      $rootwin->expose;
   }

=cut

=head2 flush

   $term->flush

Flushes the output buffer to the terminal

=cut

=head2 bind_event

   $id = $term->bind_event( $ev, $code, $data )

Installs a new event handler to watch for the event specified by C<$ev>,
invoking the C<$code> reference when it occurs. C<$code> will be invoked with
the given terminal, the event name, an event information object, and the
C<$data> value it was installed with. C<bind_event> returns an ID value that
may be used to remove the handler by calling C<unbind_event_id>.

 $ret = $code->( $term, $ev, $info, $data )

The type of C<$info> will depend on the kind of event that was received, as
indicated by C<$ev>. The information structure types are documented in
L<Tickit::Event>.

=head2 bind_event (with flags)

   $id = $term->bind_event( $ev, $flags, $code, $data )

The C<$code> argument may optionally be preceded by an integer of flag
values. This should be zero to apply default semantics, or a bitmask of one or
more of the following constants:

=over 4

=item TICKIT_BIND_FIRST

Inserts this event handler first in the chain, before any existing ones.

=back

=head2 unbind_event_id

   $term->unbind_event_id( $id )

Removes an event handler that returned the given C<$id> value.

=cut

sub bind_event
{
   my $self = shift;
   my $ev = shift;
   my ( $flags, $code, $data ) = ( ref $_[0] ) ? ( 0, @_ ) : @_;

   $self->_bind_event( $ev, $flags, $code, $data );
}

=head2 refresh_size

   $term->refresh_size

If a filehandle was supplied to the constructor, fetch the size of the
terminal and update the cached sizes in the object. May invoke C<on_resize> if
the new size is different.

=cut

=head2 set_size

   $term->set_size( $lines, $cols )

Defines the size of the terminal. Invoke C<on_resize> if the new size is
different.

=cut

=head2 lines

=head2 cols

   $lines = $term->lines

   $cols = $term->cols

Query the size of the terminal, as set by the most recent C<refresh_size> or
C<set_size> operation.

=cut

sub lines { ( shift->get_size )[0] }
sub cols  { ( shift->get_size )[1]  }

=head2 goto

   $success = $term->goto( $line, $col )

Move the cursor to the given position on the screen. If only one parameter is
defined, does not alter the other. Both C<$line> and C<$col> are 0-based.

Note that not all terminals can support these partial moves. This method
returns a boolean indicating success; if the terminal could not perform the
move it will need to be retried using a fully-specified call.

=cut

=head2 move

   $term->move( $downward, $rightward )

Move the cursor relative to where it currently is.

=cut

=head2 scrollrect

   $success = $term->scrollrect( $top, $left, $lines, $cols, $downward, $rightward )

Attempt to scroll the rectangle of the screen defined by the first four
parameters by an amount given by the latter two. Since most terminals cannot
perform arbitrary rectangle scrolling, this method returns a boolean to
indicate if it was successful. The caller should test this return value and
fall back to another drawing strategy if the attempt was unsuccessful.

The cursor may move as a result of calling this method; its location is
undefined if this method returns successful.

=cut

=head2 chpen

   $term->chpen( $pen )

   $term->chpen( %attrs )

Changes the current pen attributes to those given. Any attribute whose value
is given as C<undef> is reset. Any attributes not named are unchanged.

For details of the supported pen attributes, see L<Tickit::Pen>.

=cut

=head2 setpen

   $term->setpen( $pen )

   $term->setpen( %attrs )

Similar to C<chpen>, but completely defines the state of the terminal pen. Any
attribute not given will be reset to its default value.

=cut

=head2 print

   $term->print( $text, [ $pen ] )

Print the given text to the terminal at the current cursor position.

An optional C<Tickit::Pen> may be provided; if present it will be set as if
given to C<setpen> first.

=cut

=head2 clear

   $term->clear( [ $pen ] )

Erase the entire screen.

An optional C<Tickit::Pen> may be provided; if present it will be set as if
given to C<setpen> first.

=cut

=head2 erasech

   $term->erasech( $count, $moveend, [ $pen ] )

Erase C<$count> characters forwards. If C<$moveend> is true, the cursor is
moved to the end of the erased region. If defined but false, the cursor will
remain where it is. If undefined, the terminal will perform whichever of these
behaviours is more efficient, and the cursor will end at some undefined
location.

Using C<$moveend> may be more efficient than separate C<erasech> and C<goto>
calls on terminals that do not have an erase function, as it will be
implemented by printing spaces. This removes the need for two cursor jumps.

An optional C<Tickit::Pen> may be provided; if present it will be set as if
given to C<setpen> first.

=cut

=head2 getctl_int

=head2 setctl_int

   $value = $term->getctl_int( $ctl )

   $success = $term->setctl_int( $ctl, $value )

Gets or sets the value of an integer terminal control option. C<$ctl> should
be one of the following options. They can be specified either as integers,
using the following named constants, or as strings giving the part following
C<TERMCTL_> in lower-case.

On failure, each method returns C<undef>.

=over 8

=item TERMCTL_ALTSCREEN

Enables DEC Alternate Screen mode

=item TERMCTL_CURSORVIS

Enables cursor visible mode

=item TERMCTL_CURSORBLINK

Enables cursor blinking mode

=item TERMCTL_CURSORSHAPE

Sets the shape of the cursor. C<$value> should be one of
C<CURSORSHAPE_BLOCK>, C<CURSORSHAPE_UNDER> or C<CURSORSHAPE_LEFT_BAR>.

=item TERMCTL_KEYPAD_APP

Enables keypad application mode

=item TERMCTL_MOUSE

Enables mouse tracking mode. C<$vaule> should be one of
C<TERM_MOUSEMODE_CLICK>, C<TERM_MOUSEMODE_DRAG>, C<TERM_MOUSEMODE_MOVE> or
C<TERM_MOUSEMODE_OFF>.

=back

=head2 setctl_str

   $success = $term->setctl_str( $ctl, $value )

Sets the value of a string terminal control option. C<$ctrl> should be one of
the following options. They can be specified either as integers or strings, as
for C<setctl_int>.

=over 8

=item TERMCTL_ICON_TEXT

=item TERMCTL_TITLE_TEXT

=item TERMCTL_ICONTITLE_TEXT

Sets the terminal window icon text, title, or both.

=back

=head2 getctl

=head2 setctl

   $value = $term->getctl( $ctl )

   $success = $term->setctl( $ctl, $value )

A newer form of the various typed get and set methods above. This version
will interpret the given value as appropriate, depending on the control type.

=cut

=head2 input_push_bytes

   $term->input_push_bytes( $bytes )

Feeds more bytes of input. May result in C<key> or C<mouse> events.

=cut

=head2 input_readable

   $term->input_readable

Informs the term that the input handle may be readable. Attempts to read more
bytes of input. May result in C<key> or C<mouse> events.

=cut

=head2 input_wait

   $term->input_wait( $timeout )

Block until some input is available, and process it. Returns after one round
of input has been processed. May result in C<key> or C<mouse> events. If
C<$timeout> is defined, it will wait a period of time no longer than this time
before returning, even if no input events were received.

=cut

=head2 check_timeout

   $timeout = $term->check_timeout

Returns a number in seconds to represent when the next timeout should occur on
the terminal, or C<undef> if nothing is waiting. May invoke expired timeouts,
and cause a C<key> event to occur.

=cut

=head2 emit_key

   $term->emit_key(
      type => $type, str => $str, [ mod => $mod ]
   )

Invokes the key event handlers as if an event with the given info had just
been received. The C<mod> argument is optional, a default of 0 will apply if
it is missing.

=cut

sub emit_key
{
   my $self = shift;
   my %args = @_;

   $self->_emit_key( Tickit::Event::Key->_new(
      $args{type}, $args{str}, $args{mod} // 0
   ) );
}

=head2 emit_mouse

   $term->emit_mouse(
      type => $type, button => $button, line => $line, col => $col,
      [ mod => $mod ]
   )

Invokes the mouse event handlers as if an event with the given info had just
been received. The C<mod> argument is optional, a default of 0 will apply if
it is missing.

=cut

sub emit_mouse
{
   my $self = shift;
   my %args = @_;

   $self->_emit_mouse( Tickit::Event::Mouse->_new(
      $args{type}, $args{button}, $args{line}, $args{col}, $args{mod} // 0
   ) );
}

=head1 EVENTS

The following event types are emitted and may be observed by L</bind_event>.

=head2 resize

Emitted when the terminal itself has been resized.

=head2 key

Emitted when a key on the keyboard is pressed.

=head2 mouse

Emitted when a mouse button is pressed or released, the cursor moved while a
button is held (a dragging event), or the wheel is scrolled.

Behaviour of events involving more than one mouse button is not well-specified
by terminals.

=cut

=head1 TODO

=over 4

=item *

Track cursor position, and optimise (or eliminate entirely) C<goto> calls.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
