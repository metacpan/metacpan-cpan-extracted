#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
   # We need to force TERM=xterm so that we can guarantee the right byte
   # sequences for testing
   $ENV{TERM} = "xterm";
}

use Test::More;
use Test::HexString;
use Test::Refcount;

use Tickit::Term qw( TERM_MOUSEMODE_DRAG );
use Tickit::Pen;

$SIG{PIPE} = "IGNORE";

my $stream = "";
sub stream_is
{
   my ( $expect, $name ) = @_;

   is_hexstr( substr( $stream, 0, length $expect, "" ), $expect, $name );
}

my $writer = bless [], "TestWriter";
sub TestWriter::write { $stream .= $_[1] }

my $term = Tickit::Term->new( writer => $writer );
$term->set_size( 25, 80 );

isa_ok( $term, "Tickit::Term", '$term isa Tickit::Term' );

is( $term->get_output_handle, undef, '$term->get_output_handle undef' );

$stream = "";
$term->goto( 0, 0 );
stream_is( "\e[1H", '$term->goto( 0, 0 )' );

$stream = "";
$term->goto( 1, undef );
stream_is( "\e[2d", '$term->goto( 1 )' );

$stream = "";
$term->goto( undef, 2 );
stream_is( "\e[3G", '$term->goto( undef, 2 )' );

$stream = "";
$term->move( 4, undef );
stream_is( "\e[4B", '$term->move( 4, undef )' );

$stream = "";
$term->move( undef, 7 );
stream_is( "\e[7C", '$term->move( 4, undef )' );

$stream = "";
$term->scrollrect( 3, 0, 7, 80, 3, 0 );
stream_is( "\e[4;10r\e[4H\e[3M\e[r", '$term->scrollrect( 3,0,7,80, 3,0 )' );

$stream = "";
$term->scrollrect( 3, 0, 7, 80, -3, 0 );
stream_is( "\e[4;10r\e[4H\e[3L\e[r", '$term->scrollrect( 3,0,7,80, -3,0 )' );

# Horizontal scroll using ICH/DCH
$stream = "";
$term->scrollrect( 5, 0, 1, 80, 0, 3 );
#           CPA    DCH
stream_is( "\e[6H\e[3P", '$term->scrollrect( 5,0,1,80, 0,3 ) using DCH' );
$stream = "";
$term->scrollrect( 6, 10, 2, 70, 0, 5 );
#           CPA    DCH
stream_is( "\e[7;11H\e[5P\e[8;11H\e[5P", '$term->scrollrect( 6,10,2,70, 0,5 ) using DCH' );

$stream = "";
$term->scrollrect( 5, 0, 1, 80, 0, -3 );
#           CPA    ICH
stream_is( "\e[6H\e[3@", '$term->scrollrect( 5,0,1,80, 0,-3 ) using ICH' );
$stream = "";
$term->scrollrect( 6, 10, 2, 70, 0, -5 );
#           CPA    ICH
stream_is( "\e[7;11H\e[5@\e[8;11H\e[5@", '$term->scrollrect( 6,10,2,70, 0,-5 ) using ICH' );

$stream = "";
$term->chpen( b => 1 );
stream_is( "\e[1m", '$term->chpen( b => 1 )' );

$stream = "";
$term->chpen( b => 0 );
stream_is( "\e[m", '$term->chpen( b => 0 )' );

$stream = "";
$term->print( "Hello" );
stream_is( "Hello", '$term->print' );

$term->setpen( Tickit::Pen->new );
$stream = "";
$term->print( "colour", Tickit::Pen->new( fg => 1 ) );
stream_is( "\e[31mcolour", '$term->print with pen' );

$stream = "";
$term->clear;
stream_is( "\e[2J", '$term->clear' );

$term->setpen( Tickit::Pen->new );
$stream = "";
$term->clear( Tickit::Pen->new( bg => 2 ) );
stream_is( "\e[42m\e[2J", '$term->clear with pen' );

$stream = "";
$term->erasech( 23, undef );
stream_is( "\e[23X", '$term->erasech( 23 )' );

$term->setpen( Tickit::Pen->new );
$stream = "";
$term->erasech( 18, undef, Tickit::Pen->new( bg => 3 ) );
stream_is( "\e[43m\e[18X", '$term->erasech with pen' );

$stream = "";
$term->setctl_int( altscreen => 1 );
stream_is( "\e[?1049h", '$term->setctl_int( altscreen => 1 )' );

$stream = "";
$term->setctl_int( altscreen => 0 );
stream_is( "\e[?1049l", '$term->setctl_int( altscreen => 0 )' );

$stream = "";
$term->setctl_int( mouse => TERM_MOUSEMODE_DRAG );
stream_is( "\e[?1002h\e[?1006h", '$term->setctl_int( mouse => DRAG )' );

$stream = "";
$term->setctl_int( mouse => 0 );
stream_is( "\e[?1002l\e[?1006l", '$term->setctl_int( mouse => 0 )' );

# Reset the pen
$term->setpen;
stream_is( "\e[m", '$term->setpen()' );

$term->chpen( b => 1 );
stream_is( "\e[1m", '$term->chpen( b => 1 )' );

$term->chpen( b => 1 );
stream_is( "", '$term->chpen( b => 1 ) again is no-op' );

$term->chpen( b => undef );
stream_is( "\e[m", '$term->chpen( b => undef ) resets SGR' );

$term->chpen( b => 1, u => 1 );
stream_is( "\e[1;4m", '$term->chpen( b => 1, u => 1 )' );

$term->chpen( b => undef );
stream_is( "\e[22m", '$term->chpen( b => undef )' );

$term->chpen( b => undef );
stream_is( "", '$term->chpen( b => undef ) again is no-op' );

$term->chpen( u => undef );
stream_is( "\e[m", '$term->chpen( u => undef )' );

$term->setpen( fg => 1, bg => 5 );
stream_is( "\e[31;45m", '$term->setpen( fg => 1, bg => 5 )' );

$term->chpen( fg => 9 );
stream_is( "\e[91m", '$term->setpen( fg => 9 )' );

$term->setpen( u => 1 );
stream_is( "\e[39;49;4m", '$term->setpen( u => 1 )' );

# Reset the pen
$term->setpen;
$stream = "";

$term->chpen( Tickit::Pen->new( u => 1 ) );
stream_is( "\e[4m", '$term->chpen( Tickit::Pen )' );

$term->setpen( Tickit::Pen->new( i => 1 ) );
stream_is( "\e[24;3m", '$term->setpen( Tickit::Pen )' );

is_oneref( $term, '$term has refcount 1 before EOF' );
undef $term;

is_oneref( $writer, '$writer has refcount 1 before EOF' );

{
   pipe( my $rd, my $wr ) or die "pipe() - $!";

   my $term = Tickit::Term->new( output_handle => $wr );

   isa_ok( $term, "Tickit::Term", '$term isa Tickit::Term' );
   is( $term->get_output_handle->fileno, $wr->fileno,
      '$term->get_output_handle->fileno is $wr' );
}

done_testing;
