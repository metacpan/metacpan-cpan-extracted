#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::Static;

use Getopt::Long;

GetOptions(
   'lines|l=i' => \(my $LINES = 100),
) or exit 1;

my $scrollbox = Tickit::Widget::ScrollBox->new(
   horizontal => "on_demand",
   vertical   => "on_demand",

   child => Tickit::Widget::Static->new(
      text => join( "\n", map { "The content for line $_ " x 3 } 1 .. $LINES ),
   ),
);

Tickit->new( root => $scrollbox )->run;
