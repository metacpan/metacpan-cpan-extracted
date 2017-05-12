#!/usr/bin/perl

use strict;
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

use IO::Handle;  # ->binmode
use Tickit;

pipe my ( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
# IO::Handle->binmode doesn't exist before 5.14
binmode( $my_wr, ":raw" );

open my $term_wr, ">", \my $output;

my $tickit = Tickit->new(
   UTF8    => 1,
   term_in => $term_rd,
   term_out => $term_wr,
);

my $got_Ctrl_A;
$tickit->bind_key( "C-a" => sub { $got_Ctrl_A++ } );

syswrite( $my_wr, "\x01" );

$tickit->tick;

is( $got_Ctrl_A, 1, 'got Ctrl-A after ->tick' );

my $rootwin = $tickit->rootwin;

my @key_events;
$rootwin->bind_event( key => sub {
   my ( $win, undef, $info ) = @_;
   push @key_events, [ $info->type => $info->str ];
} );

my @mouse_events;
$rootwin->bind_event( mouse => sub {
   my ( $win, undef, $info ) = @_;
   push @mouse_events, [ $info->type => $info->button, $info->line, $info->col ];
} );

syswrite( $my_wr, "A" );
$tickit->tick;

is_deeply( \@key_events, [ [ text => "A" ] ], 'on_key A' );

# We'll test with a Unicode character outside of Latin-1, to ensure it
# roundtrips correctly
#
# 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
#  UTF-8: 0xc4 0x89

undef @key_events;
syswrite( $my_wr, "\xc4\x89" );
$tickit->tick;

is_deeply( \@key_events, [ [ text => "\x{109}" ] ], 'on_key UTF-8' );

syswrite( $my_wr, "\e[M !!" );
$tickit->tick;

is_deeply( \@mouse_events, [ [ press => 1, 0, 0 ] ], 'on_mouse @0,0' );

done_testing;
