#!/usr/bin/perl

use strict;
use warnings;

use Tickit::Async;
use Tickit::Console;
use Tickit::Widgets qw( Frame );

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use String::Tagged;

my $loop = IO::Async::Loop->new();

my $globaltab;
my $warntab;

my $counter = 1;
sub add_a_line
{
   my $text = String::Tagged->new( "<Rand>: Line $counter " );
   $counter++;

   for ( 0 .. rand( 30 ) + 3 ) {
      $text->append_tagged( chr( rand( 26 ) + 0x40 ) x ( rand( 10 ) + 5 ),
                            fg => int( rand( 7 ) + 1 ),
                            b  => rand > 0.8,
                            u  => rand > 0.8,
                            i  => rand > 0.8,
                          );
      $text->append( " " );
   }

   $globaltab->add_line( $text, indent => 8 );
}

my $timercount = 0;
my $timer = IO::Async::Timer::Periodic->new(
   interval => 1,
   on_tick => \&add_a_line,
);
$loop->add( $timer );

my $console = Tickit::Console->new(
   on_line => sub {
      my ( $self, $line ) = @_;

      if( $line eq "quit" ) {
         $loop->stop;
      }
      elsif( $line eq "start" ) {
         $timercount = 0;
         $timer->start;
      }
      elsif( $line eq "stop" ) {
         $timer->stop;
      }
      else {
         $globaltab->add_line( "<INPUT>: $line", indent => 9 );
      }
   },

   on_key => sub {
      my ( $self, $type, $str, $key ) = @_;

      # Encode nicely
      $str =~ s/\//\\\\/g;
      $str =~ s/\n/\\n/g;
      $str =~ s/\r/\\r/g;
      $str =~ s/\e/\\e/g;
      $str =~ s{([^\x20-\x7e])}{sprintf "\\x%02x", ord $1}eg;

      $globaltab->add_line( "<KEY>: $type => $str", indent => 7 );
   },
);

$globaltab = $console->add_tab( name => "GLOBAL" );
$warntab   = $console->add_tab( name => "WARN" );

$SIG{__WARN__} = sub {
   return unless defined $warntab;
   $warntab->add_line( "WARN: $_[0]", 6 );
};

my $framedtab = $console->add_tab(
   name => "FRAME",
   make_widget => sub {
      my ( $scroller ) = @_;

      return Tickit::Widget::Frame->new(
         child => $scroller,
         style => { linetype => "single" },
         title => "The scroller",
      )
   },
);

# Lines of content for the frame
$framedtab->add_line( $_ ) for qw( Content for the frame );

my $tickit = Tickit::Async->new;
$loop->add( $tickit );

$tickit->set_root_widget( $console );

# Create some inital content so the tab has something interesting to scroll around
add_a_line for 1 .. 50;

eval { $tickit->run };

undef $console;

die "$@" if $@;
