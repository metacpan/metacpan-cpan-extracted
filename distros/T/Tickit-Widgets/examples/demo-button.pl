#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Border Button VBox RadioButton );

Tickit::Style->load_style( <<'EOF' );
Button {
  fg: "black";
  bg: "white";
}
EOF

my $border = Tickit::Widget::Border->new(
   h_border => 10,
   v_border => 2,
   child => my $vbox = Tickit::Widget::VBox->new( spacing => 2, bg => "black" ),
);

my @buttons;
foreach my $colour (qw( red blue green yellow )) {
   $vbox->add(
      my $button = Tickit::Widget::Button->new(
         label => $colour,
         on_click => sub { $border->pen->chattr( bg => $colour ) },
      )
   );
   push @buttons, $button;
}

my $tickit = Tickit->new( root => $border );

$vbox->add(
   my $button = Tickit::Widget::Button->new(
      label => "Quit",
      on_click => sub { $tickit->stop },
   )
);
push @buttons, $button;

{
   my $group = Tickit::Widget::RadioButton::Group->new;
   $group->set_on_changed( sub {
      my ( undef, $type ) = @_;
      $_->set_style( linetype => $type ) for @buttons;
   });

   $vbox->add( Tickit::Widget::RadioButton->new(
      label => $_,
      value => $_,
      group => $group,
   ) ) for qw( none single double thick );
}

$tickit->run;
