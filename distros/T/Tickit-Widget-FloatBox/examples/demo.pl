#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Placegrid Box FloatBox );

my $tickit = Tickit->new(
   root => my $fb = Tickit::Widget::FloatBox->new(
      base_child => Tickit::Widget::Placegrid->new,
   )
);

my $float = $fb->add_float(
   child => Tickit::Widget::Box->new(
      child => Tickit::Widget::Placegrid->new( grid_fg => "red" ),
      child_lines => 5, child_cols => 20,
   ),
   top => 1, left => 1,
);

$tickit->bind_key( Up   => sub { $float->move( top => 1, bottom => undef ) } );
$tickit->bind_key( Down => sub { $float->move( top => undef, bottom => -2 ) } );

$tickit->bind_key( Left  => sub { $float->move( left => 1, right => undef ) } );
$tickit->bind_key( Right => sub { $float->move( left => undef, right => -2 ) } );

$tickit->run;
