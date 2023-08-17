#!/usr/bin/perl

use v5.20;
use warnings;

use Tickit;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;

my $hbox = Tickit::Widget::HBox->new(
   style => {
      spacing => 1,
   },
);

foreach ( 1 .. 6 ) {
   $hbox->add(
      Tickit::Widget::Static->new(
         text => "$_",
         style => { bg => $_, fg => "hi-white" },
         align => "centre", valign => "middle",
      ),
      expand => 1,
   )
}

Tickit->new( root => $hbox )->run;
