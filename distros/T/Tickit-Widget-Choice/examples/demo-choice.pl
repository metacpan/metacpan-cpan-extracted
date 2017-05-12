#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( VBox Choice );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

foreach ( [qw( one two three four )],
          [qw( five six seven eight )],
          [qw( nine ten eleven twelve )] ) {
   my $choices = $_;
   $vbox->add( Tickit::Widget::Choice->new(
      choices => [ map { [ $_ => $choices->[$_] ] } 0 .. $#$choices ],
   ) );
}

Tickit::Style->load_style_file( "./tickit.style" ) if -e "./tickit.style";

Tickit->new( root => $vbox )->run;
