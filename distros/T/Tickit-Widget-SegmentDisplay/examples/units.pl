#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Tickit;
use Tickit::Widgets 0.30 qw(
   SegmentDisplay
   Box=0.53
   VBox=0.48
   HBox=0.48
);
use Tickit::Widget::Box 0.53;

my $tickit = Tickit->new(
   root => Tickit::Widget::VBox->new(
      spacing => 1,
   )->add_children(
      my $unit_box = Tickit::Widget::HBox->new(
         spacing => 2,
      ),
      my $prefix_box = Tickit::Widget::HBox->new(
         spacing => 2,
      ),
   )
);

sub _add
{
   my ( $hbox, $unit ) = @_;

   $hbox->add(
      Tickit::Widget::Box->new(
         child_lines => 11,
         child_cols  => 14,
      )->set_child(
         Tickit::Widget::SegmentDisplay->new(
            type => 'symb',
            value => $unit,
            use_halfline => 1,
            thickness    => 1,
         ),
      )
   );
}

# Unit symbols
_add( $unit_box,   $_ ) for qw( V A W Ω F H s );
_add( $prefix_box, $_ ) for qw( G M k m µ n p );

$tickit->run;
