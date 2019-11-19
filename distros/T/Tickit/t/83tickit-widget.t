#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
   # We have some unit tests of terminal control strings. Best to be running
   # on a known terminal
   $ENV{TERM} = "xterm";
}

use Test::More;
use Test::HexString;

use Errno qw( EAGAIN );

use Tickit;

pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

sub stream_is
{
   my ( $expect, $name ) = @_;

   my $stream = "";
   while(1) {
      my $ret = sysread( $my_rd, $stream, 8192, length $stream );
      defined $ret or
         ( $! == EAGAIN and last ) or
         die "sysread() - $!";

      $ret or die "sysread() - EOF";

      last if length $stream >= length $expect or
              $stream ne substr( $expect, 0, length $stream );
   }

   is_hexstr( substr( $stream, 0, length $expect, "" ), $expect, $name );
}

my $tickit = Tickit->new(
   UTF8     => 1,
   term_out => $term_wr,
   root     => TestWidget->new,
);

#$tickit->setup_term;
$tickit->later( sub { $tickit->stop } );
$tickit->run;

# There might be some terminal setup code here... Flush it
$my_rd->blocking( 0 );
sysread( $my_rd, my $buffer, 8192 );

#$tickit->rootwin->flush;
$tickit->later( sub { $tickit->stop } );
$tickit->run;

# These strings are fragile but there's not much else we can do for an end-to-end
# test. If this unit test breaks likely these strings need updating. Sorry.
stream_is( "\e[13;38HHello", 'root widget rendered' );

done_testing;

package TestWidget;

sub new { bless {}, shift }

sub window { shift->{window} }

sub set_window
{
   my $self = shift;
   ( $self->{window} ) = @_;

   if( my $window = $self->{window} ) {
      $window->bind_event( expose => sub {
         my ( $win, undef, $info ) = @_;
         $self->render_to_rb( $info->rb, $info->rect );
      } );
      $window->expose;
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;
   my $win = $self->window or return;

   $rb->text_at( $win->lines / 2, ( $win->cols - 5 ) / 2,
      "Hello"
   );
}
