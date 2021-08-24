#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2021 -- leonerd@leonerd.org.uk

package Tickit::Async 0.25;

use v5.14;
use warnings;
use base qw( Tickit IO::Async::Notifier );
Tickit->VERSION( '0.72' ); # ->_new_with_evloop with signal/process
IO::Async::Notifier->VERSION( '0.43' ); # Need support for being a nonprinciple mixin

use IO::Async::Loop 0.47; # ->run and ->stop methods
use IO::Async::Stream;

# TODO: It'd be lovely if IO::Async::OS provided this
{
   require Config;
   my @signames = split ' ', $Config::Config{sig_name};
   my @signums  = split ' ', $Config::Config{sig_num};

   my %signum2name; @signum2name{@signums} = @signames;
   sub signum2name { return $signum2name{ +shift } };
}

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
      init => sub {
         $signalid = $loop->attach_signal( WINCH => $_[0] );
      },
      destroy => sub {
         warn "TODO: destroy\n";
      },

      run  => sub { $loop->run },
      stop => sub { $loop->stop },

      io => sub {
         my ( $fh, $cond, $iowatch ) = @_;
         $loop->watch_io(
            handle => $fh,
            ( $cond & Tickit::IO_IN  ) ? ( on_read_ready  => sub { $iowatch->( Tickit::IO_IN  ) } ) : (),
            ( $cond & Tickit::IO_OUT ) ? ( on_write_ready => sub { $iowatch->( Tickit::IO_OUT ) } ) : (),
            ( $cond & Tickit::IO_HUP ) ? ( on_hangup      => sub { $iowatch->( Tickit::IO_HUP ) } ) : (),
         );
      },
      cancel_io => sub { $loop->unwatch_io( handle => $_[0], on_read_ready => 1     ) },

      timer =>  sub {
         my ( $time, $watch ) = @_;
         return $loop->watch_time( at => $time, code => $watch );
      },
      cancel_timer => sub { $loop->unwatch_time( $_[0] ) },

      later => sub {
         my ( $watch ) = @_;
         $loop->watch_idle( when => "later", code => $watch );
      },
      cancel_later => sub { warn "TODO: cancel idle" },

      signal => sub {
         my ( $signum, $watch ) = @_;
         my $signame = signum2name( $signum );
         return [ $signame => $loop->attach_signal( $signame => $watch ) ];
      },
      cancel_signal => sub {
         my ( $signame, $id ) = @{ +shift };
         $loop->detach_signal( $signame => $id );
      },

      process => sub {
         my ( $pid, $watch ) = @_;
         $loop->watch_process( $pid => sub {
            my ( $pid, $wstatus ) = @_;
            $watch->( $wstatus );
         });
         return $pid;
      },
      cancel_process => sub {
         my ( $pid ) = @_;
         $loop->unwatch_process( $pid );
      },
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
