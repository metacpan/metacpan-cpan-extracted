#!/usr/bin/perl

use v5.26;
use warnings;
use experimental qw( signatures );

use IO::Async::Loop;
use IO::Async::Stream;
use IO::Pty 1.12;
use Tickit::Async;
use Tickit::Widgets qw( Border VTerm );

my $loop = IO::Async::Loop->new;

my $t = Tickit::Async->new(
   root => Tickit::Widget::Border->new(
      h_border => 4,
      v_border => 2,
      bg => ( 1 + int rand 6 ),
   )->set_child( my $widget = Tickit::Widget::VTerm->new( bg => 0 ) )
);
$loop->add( $t );

$widget->take_focus;

begin_shell( $loop );

$t->run;

my $_pty;
my $_stream;

sub begin_shell ( $loop )
{
   $_pty = IO::Pty->new;
   $loop->add( $_stream = IO::Async::Stream->new(
      handle => $_pty,
      on_read => sub {
         my ( undef, $buffref ) = @_;

         my $writtenlen = $widget->write_input( $$buffref );

         substr( $$buffref, 0, $writtenlen, "" );

         $widget->flush;

         return 0;
      }
   ) );

   $widget->set_on_output( sub ( $buf ) {
      $_stream->write( $buf );
   });

   $widget->set_on_resize( sub ( $lines, $cols ) {
      $_pty->set_winsize( $lines, $cols );
   });

   my $slave = $_pty->slave;
   $loop->open_child(
      setup => [
         stdin  => $slave,
         stdout => $slave,
         stderr => $slave,
      ],
      code => sub {
         close $_pty;
         POSIX::setsid();

         exec $ENV{SHELL};
      },
      on_finish => sub {
         die "Shell exited\n";
      },
   );

   close $slave;
}
