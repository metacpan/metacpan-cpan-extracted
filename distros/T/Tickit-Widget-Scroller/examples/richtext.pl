use strict;
use warnings;

use Tickit;

use Tickit::Widget::VBox;
use Tickit::Widget::Entry;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::RichText;

use String::Tagged;

my $scroller = Tickit::Widget::Scroller->new( gravity => "bottom" );

for my $i ( 0 .. 100 ) {
   my $text = String::Tagged->new( "<Rand $i>: " );
   for ( 0 .. rand( 30 ) + 3 ) {
      $text->append_tagged( chr( rand( 26 ) + 0x40 ) x ( rand( 10 ) + 5 ),
                            fg => int( rand( 7 ) + 1 ),
                            b  => rand > 0.8,
                            u  => rand > 0.8,
                            i  => rand > 0.8,
                          );
      $text->append( " " );
   }

   $scroller->push(
      Tickit::Widget::Scroller::Item::RichText->new( $text, indent => 4 ),
   );
}

my $entry = Tickit::Widget::Entry->new(
   on_enter => sub {
      my ( $self, $line ) = @_;

      $scroller->push(
         Tickit::Widget::Scroller::Item::Text->new( "You wrote: $line" )
      );

      $self->set_text( "" );
   },

   fg => 0,
   bg => 2,
);

my $tickit = Tickit->new;

my $vbox = Tickit::Widget::VBox->new;

$vbox->add( $scroller, expand => 1 );
$vbox->add( $entry );

$tickit->set_root_widget( $vbox );

$tickit->run;
