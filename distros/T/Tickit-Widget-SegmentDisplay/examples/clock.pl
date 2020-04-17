#!/usr/bin/perl

use strict;
use warnings;

use Tickit::Async;
use Tickit::Widgets 0.30 qw(
   SegmentDisplay
   Border=0.30
   HBox
);
use IO::Async::Loop;
use IO::Async::Timer::Absolute;

use Getopt::Long;
use List::Util qw( any );
use POSIX qw( strftime );

GetOptions(
   'style|S=s' => \( my $STYLE = "halfline" ),
) or exit 1;

any { $STYLE eq $_ } qw( halfline unicode linedraw ) or
   die "Expected --style to be halfline|unicode|linedraw\n";

my $THICKNESS = ( $STYLE eq "halfline" ) ? 1 : 2;

my $loop = IO::Async::Loop->new;

my @digits = map { Tickit::Widget::SegmentDisplay->new( type => '7', "use_$STYLE" => 1, thickness => $THICKNESS ) } 0 .. 5;
my @colons = map { Tickit::Widget::SegmentDisplay->new( type => ':', "use_$STYLE" => 1, thickness => $THICKNESS ) } 0 .. 1;

my $nexttime = time;
$loop->add( IO::Async::Timer::Absolute->new(
   time => $nexttime + 0.01, # placate timing race bug between poll() and gettimeofday()
   on_expire => sub {
      my $self = shift;
      my $timestr = strftime "%H%M%S", localtime time;
      $digits[$_]->set_value( substr $timestr, $_, 1 ) for 0 .. 5;

      $self->configure( time => ++$nexttime );
      $self->stop; $self->start;
   }
));

# Put 5 lines border top and bottom, to try to correct aspect ratio on a
# standard 80x25 terminal
my $tickit = Tickit::Async->new(
   root => Tickit::Widget::Border->new(
      v_border => 5,
   )->set_child(
      my $hbox = Tickit::Widget::HBox->new(
         spacing => 1,
      )
   )
);
$loop->add( $tickit );

$hbox->add( $_, expand => 1 ) for @digits[0,1];
$hbox->add( $_, expand => 1 ) for $colons[0];
$hbox->add( $_, expand => 1 ) for @digits[2,3];
$hbox->add( $_, expand => 1 ) for $colons[1];
$hbox->add( $_, expand => 1 ) for @digits[4,5];

$tickit->run;
