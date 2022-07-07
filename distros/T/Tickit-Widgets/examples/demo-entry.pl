#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Static Entry Border VBox );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

$vbox->add( Tickit::Widget::Static->new( text => "Enter some text here:" ) );

$vbox->add(
   Tickit::Widget::Border->new(
      h_border => 2,
      v_border => 1,
      style => { bg => 'blue' },
   )
   ->set_child( my $entry = Tickit::Widget::Entry->new ),
);

$vbox->add( my $label = Tickit::Widget::Static->new( text => "" ) );

$entry->set_on_enter( sub {
   my ( $entry, $text ) = @_;
   $label->set_text( "You entered: $text" );
   $entry->set_text( "" );
} );

Tickit->new( root => $vbox )->run;
