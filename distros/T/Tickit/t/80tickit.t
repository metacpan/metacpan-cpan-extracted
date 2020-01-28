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
use Test::Refcount;

use Errno qw( EAGAIN );

use Tickit;

pipe my( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

my $tickit = Tickit->new(
   UTF8     => 1,
   term_in  => $term_rd,
   term_out => $term_wr,
);

isa_ok( $tickit, "Tickit", '$tickit' );
is_oneref( $tickit, '$tickit has refcount 1 initially' );

my $term = $tickit->term;

isa_ok( $term, "Tickit::Term", '$tickit->term' );

# For unit-test purposes force the size of the terminal to 80x24
$term->set_size( 24, 80 );

# There might be some terminal setup code here... Flush it
$my_rd->blocking( 0 );
sysread( $my_rd, my $buffer, 8192 );

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

$term->print( "Hello" );
$term->flush;
stream_is( "Hello", '$term->print' );

# We'll test with a Unicode character outside of Latin-1, to ensure it
# roundtrips correctly
#
# 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
#  UTF-8: 0xc4 0x89

$term->print( "\x{109}" );
$term->flush;
stream_is( "\xc4\x89", 'print outputs UTF-8' );

my $rootwin = $tickit->rootwin;

isa_ok( $rootwin, "Tickit::Window", '$tickit->rootwin' );

cmp_ok( $rootwin->tickit, '==', $tickit, '$tickit->rootwin->tickit is $tickit' );

is_oneref( $tickit, '$tickit has refcount 1 at EOF' );

done_testing;
