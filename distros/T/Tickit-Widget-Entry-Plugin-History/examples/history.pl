#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit;
use Tickit::Widgets qw( Entry VBox Scroller );
use Tickit::Widget::Entry::Plugin::History;
use Tickit::Widget::Scroller::Item::Text;

my $vbox = Tickit::Widget::VBox->new(
   spacing => 1,
);

my $scroller;

$vbox->add(
   my $entry = Tickit::Widget::Entry->new(
      on_enter => sub {
         my ( $entry, $line ) = @_;

         $scroller->push(
            Tickit::Widget::Scroller::Item::Text->new( $line )
         );
      },
   ),
);

Tickit::Widget::Entry::Plugin::History->apply( $entry,
);

$vbox->add(
   $scroller = Tickit::Widget::Scroller->new,
   expand => 1,
);

Tickit->new( root => $vbox )->run;
