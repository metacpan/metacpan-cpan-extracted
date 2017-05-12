use strict;
use Test;

BEGIN { plan tests => 15 }

eval {require Tk};
ok($@, '', 'loading Tk module');

my $mwin;
eval { $mwin = Tk::MainWindow->new() };
ok($@, '', "Can't create MainWindow");
ok(Tk::Exists($mwin), 1, "MainWindow creation failed");
eval { $mwin->geometry('+10+10') };

my $widg; undef($widg);
my $clas = 'AbstractCanvas';

eval "require Tk::$clas";
ok($@, '', "Error loading Tk::$clas");

eval {$widg = $mwin->$clas(-width => '6i', -height => '6i')};
ok($@, '', "can't create $clas widget");
skip($@, Tk::Exists($widg), 1, "$clas instance does not exist");

if(Tk::Exists($widg)) {
  eval { $widg->pack() };
  ok($@, '', "Can't pack a $clas widget");

  eval { $mwin->update() };
  ok($@, '', "Error during 'update' for $clas widget");

  eval { my @dumy = $widg->configure() };
  ok($@, '', "Error: configure list for $clas");

  eval { $mwin->update() };
  ok($@, '', "Error: 'update' after configure for $clas widget");

  my $id01 = $widg->createOval( 1,  5,  3,  3, -fill => 'green', -tags => 'blue');
  my $id02 = $widg->createOval( 1, 13,  3, 11, -fill => 'green');
  my $id03 = $widg->createOval( 5,  9,  7,  7, -fill => 'green');
  my $id04 = $widg->createOval( 9,  5, 11,  3, -fill => 'green');
  my $id05 = $widg->createOval(13, 13, 15, 11, -fill => 'green');

  my $idll = $widg->createOval(-1, -1,  1,  1, -fill => 'green', -tags => 'up');
  my $idul = $widg->createOval(-1,  7,  1,  9, -fill => 'green', -tags => 'up');
  my $idlr = $widg->createOval(15,  7, 17,  9, -fill => 'green', -tags => 'down');
  my $idur = $widg->createOval(15, 15, 17, 17, -fill => 'green', -tags => 'down');
  my $idlt = $widg->createOval(-1, 15,  1, 17, -fill => 'green', -tags => 'right');
  my $idrt = $widg->createOval( 7, 15,  9, 17, -fill => 'green', -tags => 'right');
  my $idlb = $widg->createOval( 7, -1,  9,  1, -fill => 'green', -tags => 'left');
  my $idrb = $widg->createOval(15, -1, 17,  1, -fill => 'green', -tags => 'left');
  $widg->viewAll();
  $mwin->update();
  my $dirr = 1;
  for(my $jndx = 0; $jndx < 110; $jndx++) {
    if($jndx >= 21 && $jndx < 46) {
      $widg->zoom(0.9);
    } elsif($jndx >= 46 && $jndx < 66) {
      $widg->zoom(1 / 0.9);
    } elsif($jndx >=80) {
      $widg->zoom(0.9);
    }
    if($jndx == 45) { $widg->itemconfigure('blue', -fill => 'blue'); }
    if($jndx == 65) {
      my @crds = $widg->coords($id05);
      ok(@crds, 4, "Error: wrong number of args returned from 'coords'");
      my $crct = 0;
      if(abs($crds[0] - 13) < 0.01 &&
         abs($crds[1] -  3) < 0.01 &&
         abs($crds[2] - 15) < 0.01 &&
         abs($crds[3] -  5) < 0.01) {
        $crct = 1;
      }
      ok($crct, 1, "Error: object not in correct place");
    }
    if($jndx == 72) {
      my $absx = $widg->abstractx($widg->width()  / 2);
      my $absy = $widg->abstracty($widg->height() / 2);
      my $crct = 0;
      $crct = 1 if(abs($absx - 2.0) < 0.01 && abs($absy - 4.0) < 0.01);
      ok($crct, 1, "Error: center is not at the correct location");
    }
    for(my $indx = 0; $indx < 8; $indx++) {
      $widg->move(   'up',  0,  1);
      $widg->move( 'down',  0, -1);
      $widg->move('right',  1,  0);
      $widg->move( 'left', -1,  0);
      $widg->move($id01,  0,  1);
      $widg->move($id04,  0, $dirr);
      if($indx < 4) {
        $widg->move($id02,  1,  0);
        $widg->move($id03,  0, -1);
        $widg->move($id05, -1, -$dirr);
      } else {
        $widg->move($id02,  0, -1);
        $widg->move($id03, -1,  0);
        $widg->move($id05,  1, -$dirr);
        if($jndx == 70) {
          $widg->panAbstract(-0.5, 0);
          sleep(1);
        }
      }
      $widg->centerTags(-exact => 1, 'blue') if($jndx > 70);
      $mwin->update();
    }
    ($id01, $id02, $id03) = ($id03, $id01, $id02);
    $dirr = -$dirr;
    $widg->move(   'up',  0, -8);
    $widg->move( 'down',  0,  8);
    $widg->move('right', -8,  0);
    $widg->move( 'left',  8,  0);
  }
  eval { $widg->destroy() };
  ok($@, '', "can't destroy $clas widget");
  ok(!Tk::Exists($widg), 1, "$clas: widget not really destroyed");
} else {
  for(1..9) {
    skip(1, 1, 1, "skipped because widget couldn't be created");
  }
}
