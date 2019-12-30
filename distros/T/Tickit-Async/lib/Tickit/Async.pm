#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2019 -- leonerd@leonerd.org.uk

package Tickit::Async;

use strict;
use warnings;
use base qw( Tickit IO::Async::Notifier );
Tickit->VERSION( '0.69' ); # Tickit::_Tickit->_new_with_evloop
IO::Async::Notifier->VERSION( '0.43' ); # Need support for being a nonprinciple mixin

our $VERSION = '0.23';

use IO::Async::Loop 0.47; # ->run and ->stop methods
use IO::Async::Stream;

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

sub _make_tickit
{
   my $self = shift;
   my ( $term ) = @_;

   my $loop = $self->get_loop;

   my $signalid;

   return Tickit::_Tickit->_new_with_evloop( $term,
      sub { # init
         $signalid = $loop->attach_signal( WINCH => $_[0] );
      },
      sub { # destroy
         warn "TODO: destroy\n";
      },
      sub { $loop->run },
      sub { $loop->stop },
      sub { $loop->watch_io  ( handle => $_[0], on_read_ready => $_[1] ) },
      sub { $loop->unwatch_io( handle => $_[0], on_read_ready => 1     ) },
      sub { return $loop->watch_time( at => $_[0], code => $_[1] ) },
      sub { $loop->unwatch_time( $_[0] ) },
      sub { $loop->watch_idle( when => "later", code => $_[0] ) },
      sub { warn "TODO: cancel idle" },
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
