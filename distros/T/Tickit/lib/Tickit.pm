#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2022 -- leonerd@leonerd.org.uk

package Tickit 0.74;

use v5.14;
use warnings;

use Carp;

use IO::Handle;

use Scalar::Util qw( weaken );
use Time::HiRes qw( time );

BEGIN {
   require XSLoader;
   XSLoader::load( __PACKAGE__, our $VERSION );
}

# We export some constants
use Exporter 'import';

use Tickit::Event;
use Tickit::Term;
use Tickit::Window;

=head1 NAME

C<Tickit> - Terminal Interface Construction KIT

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Box;
   use Tickit::Widget::Static;

   my $box = Tickit::Widget::Box->new(
      h_border => 4,
      v_border => 2,
      bg       => "green",
      child    => Tickit::Widget::Static->new(
         text     => "Hello, world!",
         bg       => "black",
         align    => "centre",
         valign   => "middle",
      ),
   );

   Tickit->new( root => $box )->run;

=head1 DESCRIPTION

C<Tickit> is a high-level toolkit for creating full-screen terminal-based
interactive programs. It allows programs to be written in an abstracted way,
working with a tree of widget objects, to represent the layout of the
interface and implement its behaviours.

Its supported terminal features includes a rich set of rendering attributes
(bold, underline, italic, 256-colours, etc), support for mouse including wheel
and position events above the 224th column and arbitrary modified key input
via F<libtermkey> (all of these will require a supporting terminal as well).
It also supports having multiple instances and non-blocking or asynchronous
control.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $tickit = Tickit->new( %args )

Constructs a new C<Tickit> framework container object.

Takes the following named arguments at construction time:

=over 8

=item term_in => IO

IO handle for terminal input. Will default to C<STDIN>.

=item term_out => IO

IO handle for terminal output. Will default to C<STDOUT>.

=item UTF8 => BOOL

If defined, overrides locale detection to enable or disable UTF-8 mode. If not
defined then this will be detected from the locale by using Perl's
C<${^UTF8LOCALE}> variable.

=item root => Tickit::Widget

If defined, sets the root widget using C<set_root_widget> to the one
specified.

=item use_altscreen => BOOL

If defined but false, disables the use of altscreen, even if supported by the
terminal. This will mean that the screen contents are stll available after the
program has finished.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $root = delete $args{root};
   my $term = delete $args{term};

   my $self = bless {
      use_altscreen => $args{use_altscreen} // 1,
   }, $class;

   if( $args{term_in} or $args{term_out} ) {
      my $in  = delete $args{term_in}  || \*STDIN;
      my $out = delete $args{term_out} || \*STDOUT;

      my $writer = $self->_make_writer( $out );

      require Tickit::Term;

      $term = Tickit::Term->new(
         writer        => $writer,
         input_handle  => $in,
         output_handle => $out,
         UTF8          => delete $args{UTF8},
      );
   }

   $self->{term} = $term;

   $self->set_root_widget( $root ) if $root;

   return $self;
}

=head1 METHODS

=cut

sub _make_writer
{
   my $self = shift;
   my ( $out ) = @_;

   $out->autoflush( 1 );

   return $out;
}

sub _tickit
{
   my $self = shift;
   return $self->{_tickit} //= do {
      my $tickit = $self->_make_tickit( $self->{term} );

      $tickit->setctl( 'use-altscreen' => $self->{use_altscreen} );

      $tickit;
   };
}

sub _make_tickit
{
   my $self = shift;
   return Tickit::_Tickit->new( @_ );
}

=head2 watch_io

   $id = $tickit->watch_io( $fh, $cond, $code )

I<Since version 0.71.>

Runs the given CODE reference at some point in the future, when IO operations
are possible on the given filehandle. C<$cond> should be a bitmask of at least
one of the C<IO_IN>, C<IO_OUT> or C<IO_HUP> constants describing which kinds
of IO operation the callback is interested in.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

When invoked, the callback will receive an event parameter which will be an
instances of a type with a field called C<cond>. This will contain the kinds
of IO operation that are currently possible.

   $code->( $info )

   $current_cond = $info->cond;

For example, to watch for both input and hangup conditions and respond to each
individually:

   $tickit->watch_io( $fh, Tickit::IO_IN|Tickit::IO_HUP,
      sub {
         my ( $info ) = @_;
         if( $info->cond & Tickit::IO_IN ) {
            ...
         }
         if( $info->cond & Tickit::IO_HUP ) {
            ...
         }
      }
   );

=cut

sub watch_io
{
   my $self = shift;
   my ( $fh, $cond, $code ) = @_;

   return $self->_tickit->watch_io( $fh->fileno, $cond, $code );
}

=head2 watch_later

   $id = $tickit->watch_later( $code )

I<Since version 0.70.>

Runs the given CODE reference at some time soon in the future. It will not be
invoked yet, but will be invoked at some point before the next round of input
events are processed.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

=head2 later

   $tickit->later( $code )

For back-compatibility this method is a synonym for L</watch_later>.

=cut

sub watch_later
{
   my $self = shift;
   my ( $code ) = @_;

   return $self->_tickit->watch_later( $code )
}

sub later { shift->watch_later( @_ ); return }

=head2 watch_timer_at

   $id = $tickit->watch_timer_at( $epoch, $code )

I<Since version 0.70.>

Runs the given CODE reference at the given absolute time expressed as an epoch
number. Fractions are supported to a resolution of microseconds.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

=cut

sub watch_timer_at
{
   my $self = shift;
   my ( $epoch, $code ) = @_;

   return $self->_tickit->watch_timer_at( $epoch, $code );
}

=head2 watch_timer_after

   $id = $tickit->watch_timer_after( $delay, $code )

I<Since version 0.70.>

Runs the given CODE reference at the given relative time expressed as a number
of seconds hence. Fractions are supported to a resolution of microseconds.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

=cut

sub watch_timer_after
{
   my $self = shift;
   my ( $delay, $code ) = @_;

   return $self->_tickit->watch_timer_after( $delay, $code );
}

=head2 timer

   $id = $tickit->timer( at => $epoch, $code )

   $id = $tickit->timer( after => $delay, $code )

For back-compatibility this method is a wrapper for either L</watch_timer_at>
or L</watch_timer_after> depending on the first argument.

Returns an opaque integer value that may be passed to L</cancel_timer>. This
value is safe to ignore if not required.

=cut

sub timer
{
   my $self = shift;
   my ( $mode, $amount, $code ) = @_;

   return $self->watch_timer_at   ( $amount, $code ) if $mode eq "at";
   return $self->watch_timer_after( $amount, $code ) if $mode eq "after";
   croak "Mode should be 'at' or 'after'";
}

=head2 watch_signal

   $id = $tickit->watch_signal( $signum, $code )

I<Since version 0.72.>

Runs the given CODE reference whenever the given POSIX signal is received.
Signals are given by number, not name.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

=cut

sub watch_signal
{
   my $self = shift;
   my ( $signum, $code ) = @_;

   return $self->_tickit->watch_signal( $signum, $code );
}

=head2 watch_process

   $id = $tickit->watch_process( $pid, $code )

I<Since version 0.72.>

Runs the given CODE reference when the given child process terminates.

Returns an opaque integer value that may be passed to L</watch_cancel>. This
value is safe to ignore if not required.

When invoked, the callback will receive an event parameter which will be an
instance of a type with a field called C<wstatus>. This will contain the exit
status of the terminated child process.

   $code->( $info )

   $pid    = $info->pid;
   $status = $info->wstatus;

=cut

sub watch_process
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   return $self->_tickit->watch_process( $pid, $code );
}

=head2 watch_cancel

   $tickit->watch_cancel( $id )

I<Since version 0.70.>

Removes an idle or timer watch previously installed by one of the other
C<watch_*> methods. After doing so the code will no longer be invoked.

=head2 cancel_timer

   $tickit->cancel_timer( $id )

For back-compatibility this method is a synonym for L</watch_cancel>.

=cut

sub watch_cancel
{
   my $self = shift;
   my ( $id ) = @_;

   $self->_tickit->watch_cancel( $id );
}

sub cancel_timer { shift->watch_cancel( @_ ) }

=head2 term

   $term = $tickit->term

Returns the underlying L<Tickit::Term> object.

=cut

sub term { shift->_tickit->term }

=head2 cols

=head2 lines

   $cols = $tickit->cols

   $lines = $tickit->lines

Query the current size of the terminal. Will be cached and updated on receipt
of C<SIGWINCH> signals.

=cut

sub lines { shift->term->lines }
sub cols  { shift->term->cols  }

=head2 bind_key

   $tickit->bind_key( $key, $code )

Installs a callback to invoke if the given key is pressed, overwriting any
previous callback for the same key. The code block is invoked as

   $code->( $tickit, $key )

The C<$key> name is encoded as given by the C<str> accessor of
C<Tickit::Event::Key> (see L<Tickit::Event> for detail).

If C<$code> is missing or C<undef>, any existing callback is removed.

As a convenience for the common application use case, the C<Ctrl-C> key is
bound to the C<stop> method.

To remove this binding, simply bind another callback, or remove the binding
entirely by setting C<undef>.

=cut

sub bind_key
{
   my $self = shift;
   my ( $key, $code ) = @_;

   my $keybinds = $self->{key_binds} //= {};

   if( $code ) {
      if( !%$keybinds ) {
         weaken( my $weakself = $self );

         # Need to ensure a root window exists before this so it gets its
         # key bind event first
         $self->rootwin;

         $self->{key_bind_id} = $self->term->bind_event( key => sub {
            my $self = $weakself or return;
            my ( $term, $ev, $info ) = @_;
            my $str = $info->str;

            if( my $code = $self->{key_binds}{$str} ) {
               $code->( $self, $str );
            }

            return 0;
         } );
      }

      $keybinds->{$key} = $code;
   }
   else {
      delete $keybinds->{$key};

      if( !%$keybinds ) {
         $self->term->unbind_event_id( $self->{key_bind_id} );
         undef $self->{key_bind_id};
      }
   }
}

=head2 rootwin

   $tickit->rootwin

Returns the root L<Tickit::Window>.

=cut

# root window needs to know where the toplevel "tickit" instance is
sub rootwin { $_[0]->_tickit->rootwin( $_[0] ) }

=head2 set_root_widget

   $tickit->set_root_widget( $widget )

Sets the root widget for the application's display. This must be a subclass of
L<Tickit::Widget>.

=cut

sub set_root_widget
{
   my $self = shift;
   ( $self->{root_widget} ) = @_;
}

=head2 tick

   $tickit->tick( $flags )

Run a single round of IO events. Does not call C<setup_term> or
C<teardown_term>.

C<$flags> may optionally be a bitmask of the following exported constants:

=over 4

=item RUN_NOHANG

Does not block waiting for IO; simply process whatever is available then
return immediately.

=item RUN_NOSETUP

Do not perform initial terminal setup before waiting on IO events.

=back

=cut

sub tick
{
   my $self = shift;

   # TODO: Consider root widget

   $self->_tickit->tick( @_ );
}

=head2 run

   $tickit->run

Calls the C<setup_term> method, then processes IO events until stopped, by the
C<stop> method, C<SIGINT>, C<SIGTERM> or the C<Ctrl-C> key. Then runs the
C<teardown_term> method, and returns.

=cut

sub run
{
   my $self = shift;

   if( my $widget = $self->{root_widget} ) {
      $widget->set_window( $self->rootwin );
   }

   my $term = $self->_tickit->term;

   my $err = (defined eval {
      $self->_tickit->run;
      1;
   }) ? undef : $@;

   if( my $widget = $self->{root_widget} ) {
      $widget->set_window( undef );
   }

   if( defined $err ) {
      # Teardown before application exit so the message appears properly
      $term->teardown;
      die $err;
   }
}

=head2 stop

   $tickit->stop

Causes a currently-running C<run> method to stop processing events and return.

=cut

sub stop { shift->_tickit->stop( @_ ) }

=head1 MISCELLANEOUS FUNCTIONS

=head2 version_major

=head2 version_minor

=head2 version_patch

   $major = Tickit::version_major()
   $minor = Tickit::version_minor()
   $patch = Tickit::version_patch()

These non-exported functions query the version of the F<libtickit> library
that the module is linked to.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
