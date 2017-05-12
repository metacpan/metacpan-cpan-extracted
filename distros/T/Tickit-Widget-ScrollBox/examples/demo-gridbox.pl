#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::GridBox;
use Tickit::Widget::Static;

my $scrollbox = Tickit::Widget::ScrollBox->new(
   horizontal => "on_demand",
   vertical   => "on_demand",

   child => Tickit::Widget::GridBox->new(
      children => [
         map { my $row = $_;
               [ map { Tickit::Widget::Static->new( text => "Row $row Col $_" ) } 1 .. 10 ]
             } 1 .. 10 ],
      row_spacing => 1,
      col_spacing => 2,
   ),
);

Tickit->new( root => $scrollbox )->run;
