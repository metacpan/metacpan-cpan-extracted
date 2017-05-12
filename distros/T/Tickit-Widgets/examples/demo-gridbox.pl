#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Static GridBox );

my $gridbox = Tickit::Widget::GridBox->new(
   style => {
      row_spacing => 1,
      col_spacing => 2,
   },
);

foreach my $row ( 0 .. 9 ) {
   foreach my $col ( 0 .. 5 ) {
      $gridbox->add( $row, $col, Tickit::Widget::Static->new(
            text => chr( 65 + rand 26 ) x ( 2 + rand 12 ),
            align => 0.5, valign => 0.5,
            bg => (qw( red blue green yellow ))[($row+$col) % 4],
      ),
         row_expand => 1,
         col_expand => 1,
      );
   }
}

Tickit->new( root => $gridbox )->run;
