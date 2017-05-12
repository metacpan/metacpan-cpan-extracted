use strict;
use warnings;

use Tickit::Async;

use IO::Async::Timer::Periodic;

use Tickit::Widget::VBox;

use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;
use Tickit::Widget::Menu::Item;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::RichText;

use String::Tagged;

my $loop = IO::Async::Loop->new;
my $tickit = Tickit::Async->new;
$loop->add( $tickit );

my $scroller;

my $counter = 51;
my $colour = "white";
$loop->add( my $timer = IO::Async::Timer::Periodic->new(
   interval => 0.5,
   on_tick => sub {
      my $str = String::Tagged->new( "Line of content number $counter for testing menu" );
      $str->apply_tag( 0, -1, fg => $colour );
      $scroller->push( Tickit::Widget::Scroller::Item::RichText->new( $str ) );
      $counter++;
   }
) );

my @colours = qw( white red green blue );

my $menubar = Tickit::Widget::MenuBar->new(
   items => [
      Tickit::Widget::Menu->new( name => "Demo",
         items => [
            Tickit::Widget::Menu::Item->new( name => "Start timer", on_activate => sub { $timer->start } ),
            Tickit::Widget::Menu::Item->new( name => "Stop timer",  on_activate => sub { $timer->stop  } ),
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
