#!/usr/bin/perl

use v5.20;
use warnings;

use Tickit;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;

my $vbox = Tickit::Widget::VBox->new(
   style => {
      spacing => 1,
   },
);

foreach ( 1 .. 6 ) {
   $vbox->add(
      Tickit::Widget::Static->new(
         text => "Row $_",
         style => { bg => $_, fg => "hi-white" },
         align => "centre", valign => "middle",
      ),
      expand => 1,
   )
}

Tickit->new( root => $vbox )->run;
