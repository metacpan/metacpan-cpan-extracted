#!/usr/bin/perl

use v5.14;
use warnings;

# We need a UTF-8 locale to force libtermkey into UTF-8 handling, even if the
# system locale is not
# We also need to fool libtermkey into believing TERM=xterm even if it isn't,
# so we can reliably control it with fake escape sequences
BEGIN {
   $ENV{LANG} .= ".UTF-8" unless $ENV{LANG} =~ m/\.UTF-8$/;
   $ENV{TERM} = "xterm";
}

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Tickit::Async;

use Tickit 0.58;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $term_rd, $my_wr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
open my $term_wr, ">", \my $output;

my $tickit = Tickit::Async->new(
   UTF8     => 1,
   term_in  => $term_rd,
   term_out => $term_wr,
);

$loop->add( $tickit );

my $rootwin = $tickit->rootwin;

{
   my @key_events;
   my $id = $rootwin->bind_event( key => sub {
      my ( $win, undef, $info ) = @_;
      push @key_events, {
         +map { $_ => $info->$_ } qw( type str mod )
      };
   } );

   $my_wr->syswrite( "h" );

   undef @key_events;
   wait_for { @key_events };

   is_deeply( \@key_events, [ { type => "text", str => "h", mod => 0 } ], 'on_key h' );

   $my_wr->syswrite( "\cA" );

   undef @key_events;
   wait_for { @key_events };

   is_deeply( \@key_events, [ { type => "key", str => "C-a", mod => 4 } ], 'on_key Ctrl-A' );

   $my_wr->syswrite( "\eX" );

   undef @key_events;
   wait_for { @key_events };

   is_deeply( \@key_events, [ { type => "key", str => "M-X", mod => 2 } ], 'on_key Alt-X' );

   $my_wr->syswrite( "\e" );
   # 10msec should be enough for us to have to wait but short enough for
   # libtermkey to consider this
   $loop->watch_time( after => 0.010, code => sub { $my_wr->syswrite( "Y" ) } );

   undef @key_events;
   wait_for { @key_events };

   is_deeply( \@key_events, [ { type => "key", str => "M-Y", mod => 2 } ], 'on_key Alt-Y split write' );

   # We'll test with a Unicode character outside of Latin-1, to ensure it
   # roundtrips correctly
   #
   # 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
   #  UTF-8: 0xc4 0x89

   $my_wr->syswrite( "\xc4\x89" );

   undef @key_events;
   wait_for { @key_events };

   is_deeply( \@key_events, [ { type => "text", str => "\x{109}", mod => 0 } ], 'on_key reads UTF-8' );

   $rootwin->unbind_event_id( $id );
}

{
   my @mouse_events;
   my $id = $rootwin->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      push @mouse_events, {
         +map { $_ => $info->$_ } qw( type button line col mod )
      };
   } );

   # Mouse encoding == CSI M $b $x $y
   # where $b, $l, $c are encoded as chr(32+$). Position is 1-based
   $my_wr->syswrite( "\e[M".chr(32+0).chr(32+21).chr(32+11) );

   undef @mouse_events;
   wait_for { @mouse_events };

   # Tickit::Term reports position 0-based
   is_deeply( \@mouse_events,
              [ { type => "press", button => 1, line => 10, col => 20, mod => 0 } ],
              'on_mouse press(1) @20,10' );

   $rootwin->unbind_event_id( $id );
}

{
   my $got_Ctrl_A;
   $tickit->bind_key( "C-a" => sub { $got_Ctrl_A++ } );

   $my_wr->syswrite( "\cA" );

   wait_for { $got_Ctrl_A };

   is( $got_Ctrl_A, 1, 'bind Ctrl-A' );
}

$loop->remove( $tickit );

done_testing;
