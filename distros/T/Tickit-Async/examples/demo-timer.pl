#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Tickit::Async;

use Tickit::Widget::Static;

use Tickit::Widget::VBox;
use Tickit::Widget::Frame;

my $tickit = Tickit::Async->new;

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

$vbox->add( Tickit::Widget::Frame->new(
      child => my $static = Tickit::Widget::Static->new(
         text => "Flashing text",
         align  => "centre",
         valign => "middle",
      ),
      style => { linetype => "single" },
) );

my $fg = 1;
sub tick
{
   $fg++;
   $fg = 1 if $fg > 7;
   $static->pen->chattr( fg => $fg );

   $tickit->timer( after => 0.5, \&tick );
}
tick();

$tickit->set_root_widget( $vbox );

$tickit->run;
