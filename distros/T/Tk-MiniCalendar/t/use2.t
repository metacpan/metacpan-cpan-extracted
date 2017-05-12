# vim:ft=perl:foldcolumn=4
#########################
use strict;
use warnings;
use Test::More 'no_plan';
use Tk;
use Date::Calc qw(
  Today
  Add_Delta_Days
);
use Tk::MiniCalendar;
ok(1, "load module"); # If we made it this far, we're ok.

#########################

# test usage of two MiniCalendars in one application

use Tk;
use Tk::MiniCalendar;

my $top = MainWindow->new(-title => "use2");
if (! $top) {
  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  exit 0;
}
my $l = $top->Label(
  -text => <<EOT,
  Please select date of tomorrow in upper 
  MiniCalendar.
EOT
  -bg => "white",
  -fg => "red",
)->pack(-pady => 10);;

my $m1 = $top->MiniCalendar->pack;
my $f = $top->Frame->pack;
my $m2 = $f->MiniCalendar->pack;


$m1->register('<Button-1>', \&b11);
$m2->register('<Button-1>', \&b12);

if (! $ENV{INTERACTIVE_MODE}){
  my ($yy, $mm, $dd) = Add_Delta_Days(Today,1);
  $m1->select_date($yy, $mm, $dd);
  $top->after(200, sub{b11($yy, $mm, $dd)});
  
  #($yy, $mm, $dd) = Add_Delta_Days(Today,-1);
  #$m2->select_date($yy, $mm, $dd);
  #$top->after(500, sub{b12($yy, $mm, $dd)});
}
MainLoop;

sub b11 {
  my ($yyyy, $mm, $dd) = @_;
  print "Mini 1: $dd.$mm.$yyyy\n";
  my ($y,$m,$d) = Add_Delta_Days(Today, 1);
  print "Tomorrow: $d.$m.$y\n";
  if ( iseq($y,$m,$d,$yyyy,$mm,$dd) ){ # user clicked tomorrow
         ok(1, "tomorrow");
         ok(iseq( Add_Delta_Days(Today,1), $m1->date), "Mini 1 has Tomorrow");
         ok(iseq(Today, $m2->date), "Mini 2 has Today");
         $l->configure( -text => <<EOT,
  Please select date of yesterday in lower 
  MiniCalendar.
EOT
  -fg => "blue",
    );
    if (! $ENV{INTERACTIVE_MODE}){
     # my ($yy, $mm, $dd) = Add_Delta_Days(Today,1);
    #  $m1->select_date($yy, $mm, $dd);
    #  $top->after(200, sub{b11($yy, $mm, $dd)});
  
      my ($yy, $mm, $dd) = Add_Delta_Days(Today,-1);
      $m2->select_date($yy, $mm, $dd);
      $top->after(500, sub{b12($yy, $mm, $dd)});
    }
  }
}

sub b12 {
  my ($yyyy, $mm, $dd) = @_;
  print "Mini 2: $dd.$mm.$yyyy\n";
  my ($y,$m,$d) = Add_Delta_Days(Today, -1);
  print "Yesterday $d.$m.$y\n";
  if ( iseq($y,$m,$d,$yyyy,$mm,$dd) ){ # user clicked yesterday
         ok(1, "yesterday");
         ok(iseq( Add_Delta_Days(Today,1), $m1->date), "Mini 1 has Tomorrow");
         ok(iseq( Add_Delta_Days(Today,-1), $m2->date), "Mini 2 has Yesterday");
         $l->configure( -text => <<EOT,
  *******************************
  Congratulation, you're done ...
  *******************************
EOT
  -fg => "green",
    ),
    $top->update;
         sleep 3;
         exit;
  }
}

sub iseq {
  my ($y1, $m1, $d1, $y2, $m2, $d2) = @_;
  return 1 if (
    $y1 == $y2 and
    $d1 == $d2 and
    $m1 == $m2
  );
  return 0;
}
