#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN {
   # We need to force TERM=xterm so that we can guarantee the right byte
   # sequences for testing
   $ENV{TERM} = "xterm";
}

use Test2::V0 0.000149; # is_refcount

use Tickit qw( BIND_FIRST );
use Tickit::Term;

use Time::HiRes qw( sleep );

my $term = Tickit::Term->new( UTF8 => 1 );
$term->set_size( 25, 80 );

is( $term->get_input_handle, undef, '$term->get_input_handle undef' );

is_oneref( $term, '$term has refcount 1 initially' );

# key events
{
   my ( $type, $str );
   my $id = $term->bind_event( key => sub {
      my ( undef, $ev, $info ) = @_;
      cmp_ok( $_[0], '==', $term, '$_[0] is term for resize event' );
      is( $ev, "key", '$ev is key' );
      $type = $info->type;
      $str  = $info->str;

      return 1;
   } );

   is_oneref( $term, '$term has refcount 1 after ->bind_event' );

   $term->emit_key( type => "text", str => " ", mod => 0 );

   is( $type, "text", '$type after emit_key Space' );
   is( $str,  " ",    '$str after emit_key Space' );

   $term->input_push_bytes( "A" );

   is( $type, "text", '$type after push_bytes A' );
   is( $str,  "A",    '$str after push_bytes A' );

   is( $term->check_timeout, undef, '$term has no timeout after A' );

   # We'll test with a Unicode character outside of Latin-1, to ensure it
   # roundtrips correctly
   #
   # 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
   #  UTF-8: 0xc4 0x89

   undef $type; undef $str;
   $term->input_push_bytes( "\xc4\x89" );

   is( $type, "text",    '$type after push_bytes for UTF-8' );
   is( $str,  "\x{109}", '$str after push_bytes for UTF-8' );

   $term->input_push_bytes( "\e[A" );

   is( $type, "key", '$type after push_bytes Up' );
   is( $str,  "Up",  '$str after push_bytes Up' );

   is( $term->check_timeout, undef, '$term has no timeout after Up' );

   undef $type; undef $str;
   $term->input_push_bytes( "\e[" );

   is( $type, undef, '$type undef after partial Down' );
   ok( defined $term->check_timeout, '$term has timeout after partial Down' );

   $term->input_push_bytes( "B" );

   is( $type, "key",  '$type after push_bytes after completed Down' );
   is( $str,  "Down", '$str after push_bytes after completed Down' );

   is( $term->check_timeout, undef, '$term has no timeout after completed Down' );

   undef $type; undef $str;
   $term->input_push_bytes( "\e" );

   is( $type, undef, '$type undef after partial Escape' );

   my $timeout = $term->check_timeout;
   ok( $timeout, '$term has timeout after partial Escape' );

   sleep $timeout + 0.01; # account for timing overlaps

   is( $term->check_timeout, undef, '$term has no timeout after timedout' );

   is( $type, "key",    '$type after push_bytes after timedout' );
   is( $str,  "Escape", '$str after push_bytes after timedout' );

   $term->unbind_event_id( $id );
}

# event handler return values
{
   my $first_ret = 0;
   my @called;
   my @ids = (
      $term->bind_event( key => sub { push @called, "A"; return $first_ret } ),
      $term->bind_event( key => sub { push @called, "B"; return 0 } ),
   );

   $term->emit_key( type => "key", str => "X" );

   is( \@called, [qw( A B )], 'both event handlers called when first returns 0' );

   $first_ret = 1;
   @called = ();

   $term->emit_key( type => "key", str => "X" );

   is( \@called, [qw( A )], 'second event handlers not called when first returns 1' );

   $term->unbind_event_id( $_ ) for @ids;
}

# BIND_FIRST
{
   my @called;
   my @ids = map {
      my $str = $_;
      $term->bind_event( key => BIND_FIRST, sub { push @called, $str; return 0 } );
   } qw( A B );

   $term->emit_key( type => "key", str => "X" );

   is( \@called, [qw( B A )], 'event handlers called in reverse order with BIND_FIRST' );

   $term->unbind_event_id( $_ ) for @ids;
}

# mouse events
{
   my ( $type, $button, $line, $col );
   my $id = $term->bind_event( mouse => sub {
      my ( $term, $ev, $info ) = @_;
      is( $ev, "mouse", '$ev is mouse' );
      $type   = $info->type;
      $button = $info->button;
      $line   = $info->line;
      $col    = $info->col;

      return 1;
   } );

   $term->emit_mouse( type => "press", button => 1, line => 2, col => 3 );

   is( $type,   "press", '$type after emit_mouse' );
   is( $button, 1,       '$button after emit_mouse' );
   is( $line,   2,       '$line after emit_mouse' );
   is( $col,    3,       '$col after emit_mouse' );

   $term->emit_mouse( type => "wheel", button => "down", line => 2, col => 3 );

   is( $type,   "wheel", '$type after emit_mouse wheel' );
   is( $button, "down",  '$button after emit_mouse wheel' );
   is( $line,   2,       '$line after emit_mouse wheel' );
   is( $col,    3,       '$col after emit_mouse wheel' );

   $term->unbind_event_id( $id );
}

{
   pipe( my $rd, my $wr ) or die "pipe() - $!";

   my $term = Tickit::Term->new( input_handle => $rd );

   isa_ok( $term, [ "Tickit::Term" ], '$term isa Tickit::Term' );
   is( $term->get_input_handle->fileno, $rd->fileno,
      '$term->get_input_handle->fileno is $rd' );
}

done_testing;
