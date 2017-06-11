#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2017 -- leonerd@leonerd.org.uk

package Tickit::Async;

use strict;
use warnings;
use base qw( Tickit IO::Async::Notifier );
Tickit->VERSION( '0.17' );
IO::Async::Notifier->VERSION( '0.43' ); # Need support for being a nonprinciple mixin

our $VERSION = '0.21';

use IO::Async::Loop 0.47; # ->run and ->stop methods
use IO::Async::Signal;
use IO::Async::Stream;
use IO::Async::Handle;
use IO::Async::Timer::Countdown;

=head1 NAME

C<Tickit::Async> - use C<Tickit> with C<IO::Async>

=head1 SYNOPSIS

 use IO::Async;
 use Tickit::Async;

 my $tickit = Tickit::Async->new;

 # Create some widgets
 # ...

 $tickit->set_root_widget( $rootwidget );

 my $loop = IO::Async::Loop->new;
 $loop->add( $tickit );

 $tickit->run;

=head1 DESCRIPTION

This class allows a L<Tickit> user interface to run alongside other
L<IO::Async>-driven code, using C<IO::Async> as a source of IO events.

As a shortcut convenience, a containing L<IO::Async::Loop> will be constructed
using the default magic constructor the first time it is needed, if the object
is not already a member of a loop. This will allow a C<Tickit::Async> object
to be used without being aware it is not a simple C<Tickit> object.

To avoid accidentally creating multiple loops, callers should be careful to
C<add> the C<Tickit::Async> object to the main application's loop if one
already exists as soon as possible after construction.

=cut

sub new
{
   my $class = shift;
   my $self = $class->Tickit::new( @_ );

   $self->add_child( IO::Async::Signal->new( 
      name => "WINCH",
      on_receipt => $self->_capture_weakself( "_SIGWINCH" ),
   ) );

   $self->add_child( IO::Async::Handle->new(
      read_handle => $self->term->get_input_handle,
      on_read_ready => $self->_capture_weakself( "_input_readready" ),
   ) );

   $self->add_child( $self->{timer} = IO::Async::Timer::Countdown->new(
      on_expire => $self->_capture_weakself( "_timeout" ),
   ) );

   return $self;
}

sub get_loop
{
   my $self = shift;
   return $self->SUPER::get_loop || do {
      my $newloop = IO::Async::Loop->new;
      $newloop->add( $self );
      $newloop;
   };
}

sub _make_writer
{
   my $self = shift;
   my ( $out ) = @_;

   my $writer = IO::Async::Stream->new(
      write_handle => $out,
      autoflush => 1,
   );

   $self->add_child( $writer );

   return $writer;
}

sub _input_readready
{
   my $self = shift;
   my $term = $self->term;

   $self->{timer}->stop;

   $term->input_readable;

   $self->_timeout;
}

sub _timeout
{
   my $self = shift;
   my $term = $self->term;

   if( defined( my $timeout = $term->check_timeout ) ) {
      $self->{timer}->configure( delay => $timeout / 1000 ); # msec
      $self->{timer}->start;
   }
}

sub later
{
   my $self = shift;
   my ( $code ) = @_;

   $self->get_loop->later( $code );
}

sub timer
{
   my $self = shift;
   my ( $mode, $amount, $code ) = @_;

   return $self->get_loop->watch_time( $mode => $amount, code => $code );
}

sub cancel_timer
{
   my $self = shift;
   my ( $id ) = @_;

   $self->get_loop->unwatch_time( $id );
}

sub tick
{
   my $self = shift;
   $self->get_loop->loop_once;
}

sub stop
{
   my $self = shift;
   $self->get_loop->stop;
}

sub run
{
   my $self = shift;

   my $loop = $self->get_loop;

   $self->setup_term;

   my $running = 1;

   $loop->add( my $sigint_notifier = IO::Async::Signal->new(
      name => "INT",
      on_receipt => $self->_capture_weakself( sub { undef $running }),
   ) );

   my $ret = eval {
      $self->_flush;
      while($running) {
         $loop->loop_once;
         $self->_flush;
      }
   };
   my $e = $@;

   {
      local $@;

      $self->teardown_term;
      $loop->remove( $sigint_notifier );

      # Restore STDIN's blocking mode
      $self->term->get_input_handle->blocking( 1 );
   }

   die $@ if $@;
   return $ret;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
