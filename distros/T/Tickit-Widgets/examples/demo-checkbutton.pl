#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( VBox CheckButton );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

foreach ( 1 .. 5 ) {
   $vbox->add( Tickit::Widget::CheckButton->new(
         class => "check$_",
         style => { fg => $_ },

         label => "Check $_",
   ) );
}

Tickit::Style->load_style_file( "./tickit.style" ) if -e "./tickit.style";

Tickit->new( root => $vbox )->run;
