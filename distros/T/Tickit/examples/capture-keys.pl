#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit::Term;

my $term = Tickit::Term->open_stdio;

$term->await_started( 0.05 );

my @keys;
$term->bind_event( key => sub {
   my ( $term, $ev, $info ) = @_;
   push @keys, $info;
});

sub get_next_key
{
   while(1) {
      return shift @keys if @keys;
      $term->input_wait;
   }
}

while( my $key = get_next_key ) {
   print "Pressed key ", $key->str, "\n";
}
