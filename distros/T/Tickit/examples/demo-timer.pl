#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Static;

my $static = Tickit::Widget::Static->new(
   text => "temporary",
   align => 0.5,
   valign => 0.5,
);

my $tickit = Tickit->new( root => $static );

my $counter = 0;
sub timer
{
   $static->set_text( "Counter: $counter" );
   $counter++;

   $tickit->timer( after => 1, \&timer );
}

timer();

$tickit->run;
