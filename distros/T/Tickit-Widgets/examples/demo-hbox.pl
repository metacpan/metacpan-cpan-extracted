#!/usr/bin/perl

use strict;
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
         text => "$_", bg => $_, fg => "hi-white",
         align => "centre", valign => "middle",
      ),
      expand => 1,
   )
}

Tickit->new( root => $hbox )->run;
