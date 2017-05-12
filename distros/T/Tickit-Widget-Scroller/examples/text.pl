use strict;
use warnings;

use Tickit;

use Tickit::Widget::VBox;
use Tickit::Widget::Entry;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

my $scroller = Tickit::Widget::Scroller->new(
   gravity => "bottom",
   gen_top_indicator => sub {
      my $self = shift;
      my $lines = $self->lines_above or return;
      return sprintf "+ %d more", $lines;
   },
   gen_bottom_indicator => sub {
      my $self = shift;
      my $lines = $self->lines_below or return;
      return sprintf "+ %d more", $lines;
   },
);

for my $i ( 0 .. 100 ) {
   my $text = "<Rand $i>: ";
   for ( 0 .. rand( 30 ) + 3 ) {
      $text .= chr( rand( 26 ) + 0x40 ) x ( rand( 10 ) + 5 );
      $text .= " ";
   }

   $scroller->push(
      Tickit::Widget::Scroller::Item::Text->new( $text, indent => 4 ),
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
