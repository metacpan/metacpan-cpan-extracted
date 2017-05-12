#!/usr/bin/perl

use strict;
use warnings;

# We need a UTF-8 locale to force libtermkey into UTF-8 handling, even if the
# system locale is not
BEGIN {
   $ENV{LANG} .= ".UTF-8" unless $ENV{LANG} =~ m/\.UTF-8$/;
}

use Test::More;
use Test::HexString;
use Test::Refcount;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Tickit::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $my_rd, $term_wr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";

my $tickit = Tickit::Async->new(
   UTF8     => 1,
   term_out => $term_wr,
);

$loop->add( $tickit );

my $term = $tickit->term;

isa_ok( $term, 'Tickit::Term', '$tickit->term' );

# There might be some terminal setup code here... Flush it
$my_rd->blocking( 0 );
sysread( $my_rd, my $buffer, 8192 );

my $stream = "";
sub stream_is
{
   my ( $expect, $name ) = @_;

   wait_for_stream { length $stream >= length $expect } $my_rd => $stream;

   is_hexstr( substr( $stream, 0, length $expect, "" ), $expect, $name );
}

$term->print( "Hello" );
$term->flush;

$stream = "";
stream_is( "Hello", '$term->print' );

# We'll test with a Unicode character outside of Latin-1, to ensure it
# roundtrips correctly
#
# 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
#  UTF-8: 0xc4 0x89

$term->print( "\x{109}" );
$term->flush;

$stream = "";
stream_is( "\xc4\x89", 'print outputs UTF-8' );

$loop->remove( $tickit );

done_testing;
