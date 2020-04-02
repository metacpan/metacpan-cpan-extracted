#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::GridBox;
use Tickit::Widget::Static;

my $gridbox = Tickit::Widget::GridBox->new(
   row_spacing => 1,
   col_spacing => 2,
);
foreach my $row ( 1 .. 10 ) {
   $gridbox->append_row(
      [ map { Tickit::Widget::Static->new( text => "Row $row Col $_" ) } 1 .. 10 ]
   );
}

my $scrollbox = Tickit::Widget::ScrollBox->new(
   horizontal => "on_demand",
   vertical   => "on_demand",
)->set_child( $gridbox );

Tickit->new( root => $scrollbox )->run;
