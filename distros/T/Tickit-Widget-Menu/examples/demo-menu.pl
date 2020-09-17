use strict;
use warnings;

use Tickit;

use Tickit::Widget::VBox;

use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;
use Tickit::Widget::Menu::Item;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::RichText;

use String::Tagged;

my $tickit = Tickit->new;

my $scroller;

my $counter = 51;
my $colour = "white";
my $timerid;
sub tick
{
   my $str = String::Tagged->new( "Line of content number $counter for testing menu" );
   $str->apply_tag( 0, -1, fg => $colour );
   $scroller->push( Tickit::Widget::Scroller::Item::RichText->new( $str ) );
   $scroller->scroll_to_bottom;
   $counter++;

   $timerid = $tickit->watch_timer_after( 0.5, \&tick )
}

my @colours = qw( white red green blue );

my $menubar = Tickit::Widget::MenuBar->new(
   items => [
      Tickit::Widget::Menu->new( name => "Demo",
         items => [
            Tickit::Widget::Menu::Item->new( name => "Start timer", on_activate => sub { tick() } ),
            Tickit::Widget::Menu::Item->new( name => "Stop timer",  on_activate => sub { $tickit->watch_cancel( $timerid ); } ),
            Tickit::Widget::Menu->separator,
            Tickit::Widget::Menu::Item->new( name => "Exit", on_activate => sub { $tickit->stop } ),
         ],
      ),
      Tickit::Widget::Menu->new( name => "Scroller",
         items => [
            Tickit::Widget::Menu::Item->new( name => "Scroll to top",    on_activate => sub { $scroller->scroll_to_top } ),
            Tickit::Widget::Menu::Item->new( name => "Scroll to bottom", on_activate => sub { $scroller->scroll_to_bottom } ),
            Tickit::Widget::Menu->separator,
            Tickit::Widget::Menu->new(
               name => "Set colour...",
               items => [ map {
                  my $c = $_;
                  Tickit::Widget::Menu::Item->new( name => $c, on_activate => sub { $colour = $c } ),
               } @colours ] ),
         ],
      ),
      Tickit::Widget::Menu->separator,
      Tickit::Widget::Menu->new( name => "Help",
         items => [
            Tickit::Widget::Menu::Item->new( name => "About" ),
         ],
      ),
   ],
);

my $vbox = Tickit::Widget::VBox->new;

$vbox->add( $menubar );

$vbox->add( $scroller = Tickit::Widget::Scroller->new, expand => 1 );

$scroller->push( Tickit::Widget::Scroller::Item::Text->new( "Line of content number $_ for testing menu" ) ) for 1 .. 50;
$scroller->scroll_to_bottom;

$tickit->set_root_widget( $vbox );

$tickit->run;
