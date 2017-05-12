#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widgets qw( GridBox Frame HBox Entry Static Button CheckButton RadioButton );
Tickit::Style->load_style( <<'EOF' );
Entry:focus {
   bg: "blue";
   b: 1;
}

Frame {
   linetype: "single";
}
Frame:focus-child {
   frame-fg: "red";
}

CheckButton:focus {
   check-bg: "blue";
}

RadioButton:focus {
   tick-bg: "blue";
}
EOF

my $gridbox = Tickit::Widget::GridBox->new(
   style => {
      row_spacing => 1,
      col_spacing => 2,
   },
);

foreach my $row ( 0 .. 2 ) {
   $gridbox->add( $row, 0, Tickit::Widget::Static->new( text => "Entry $row" ) );
   $gridbox->add( $row, 1, Tickit::Widget::Entry->new, col_expand => 1 );
}

{
   $gridbox->add( 3, 0, Tickit::Widget::Static->new( text => "Buttons" ) );
   $gridbox->add( 3, 1, Tickit::Widget::Frame->new(
      child => my $hbox = Tickit::Widget::HBox->new( spacing => 2 ),
   ) );

   foreach my $label (qw( One Two Three )) {
      $hbox->add( Tickit::Widget::Button->new( label => $label, on_click => sub {} ), expand => 1 );
   }
}

{
   $gridbox->add( 4, 0, Tickit::Widget::Static->new( text => "Checks" ) );
   $gridbox->add( 4, 1, Tickit::Widget::Frame->new(
      child => my $hbox = Tickit::Widget::HBox->new( spacing => 2 ),
   ) );

   foreach ( 0 .. 2 ) {
      $hbox->add( Tickit::Widget::CheckButton->new( label => "Check $_" ) );
   }
}

{
   $gridbox->add( 5, 0, Tickit::Widget::Static->new( text => "Radios" ) );
   $gridbox->add( 5, 1, Tickit::Widget::Frame->new(
      child => my $hbox = Tickit::Widget::HBox->new( spacing => 2 ),
   ) );

   my $group = Tickit::Widget::RadioButton::Group->new;
   foreach ( 0 .. 2 ) {
      $hbox->add( Tickit::Widget::RadioButton->new( label => "Radio $_", group => $group ) );
   }
}

Tickit->new( root => $gridbox )->run;
