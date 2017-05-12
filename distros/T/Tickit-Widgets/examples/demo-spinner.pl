#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Spinner Button HBox VBox );

my $vbox = Tickit::Widget::VBox->new;

$vbox->add( my $spinner = Tickit::Widget::Spinner->new(
      chars => [ map { substr( "-=X=-     -=X=-", 9-$_, 10 ) } 0 .. 9 ],
      interval => 0.1,
   ),
   expand => 3,
);

$vbox->add( my $hbox = Tickit::Widget::HBox->new,
   expand => 1,
);

$hbox->add(
   Tickit::Widget::Button->new( label => "Start", on_click => sub { $spinner->start } ),
   expand => 1
);
$hbox->add(
   Tickit::Widget::Button->new( label => "Stop",  on_click => sub { $spinner->stop  } ),
   expand => 1,
);

Tickit->new( root => $vbox )->run;
