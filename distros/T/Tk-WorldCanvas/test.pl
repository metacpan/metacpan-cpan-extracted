use strict;
use Test;

BEGIN {
    plan tests => 15
}

eval {require Tk};
ok($@, '', 'loading Tk module');

my $mw;
eval {$mw = Tk::MainWindow->new};
ok($@, '', "Can't create MainWindow");
ok(Tk::Exists($mw), 1, "MainWindow creation failed");
eval {$mw->geometry('+10+10')};

my $w;
my $class = 'WorldCanvas';

undef $w;

eval "require Tk::$class";
ok($@, '', "Error loading Tk::$class");

eval {$w = $mw->$class(-width => '6i', -height => '6i')};
ok($@, '', "can't create $class widget");
skip($@, Tk::Exists($w), 1, "$class instance does not exist");

if (Tk::Exists($w)) {
    eval {$w->pack};
    ok($@, '', "Can't pack a $class widget");

    eval {$mw->update};
    ok($@, '', "Error during 'update' for $class widget");

    eval {my @dummy = $w->configure};
    ok($@, '', "Error: configure list for $class");

    eval {$mw->update};
    ok($@, '', "Error: 'update' after configure for $class widget");

    my $id1 = $w->createOval( 1,  5,  3,  3, -fill => 'green', -tags => 'blue');
    my $id2 = $w->createOval( 1, 13,  3, 11, -fill => 'green');
    my $id3 = $w->createOval( 5,  9,  7,  7, -fill => 'green');

    my $id4 = $w->createOval( 9,  5, 11,  3, -fill => 'green');
    my $id5 = $w->createOval(13, 13, 15, 11, -fill => 'green');

    my $idll = $w->createOval(-1, -1,  1,  1, -fill => 'green', -tags => 'up');
    my $idul = $w->createOval(-1,  7,  1,  9, -fill => 'green', -tags => 'up');
    my $idlr = $w->createOval(15,  7, 17,  9, -fill => 'green', -tags => 'down');
    my $idur = $w->createOval(15, 15, 17, 17, -fill => 'green', -tags => 'down');
    my $idlt = $w->createOval(-1, 15,  1, 17, -fill => 'green', -tags => 'right');
    my $idrt = $w->createOval( 7, 15,  9, 17, -fill => 'green', -tags => 'right');
    my $idlb = $w->createOval( 7, -1,  9,  1, -fill => 'green', -tags => 'left');
    my $idrb = $w->createOval(15, -1, 17,  1, -fill => 'green', -tags => 'left');
    $w->viewAll;
    $mw->update;
    my $dir = 1;

    for (my $j = 0; $j < 110; $j++) {
        if ($j >= 21 and $j < 46) {
            $w->zoom(0.9);
        } elsif ($j >= 46 and $j < 66) {
            $w->zoom(1 / 0.9);
        } elsif ($j >=80) {
            $w->zoom(0.9);
        }
        if ($j == 45) {$w->itemconfigure('blue', -fill => 'blue');}
        if ($j == 65) {
            my @c = $w->coords($id5);
            ok(@c, 4, "Error: wrong number of args returned from 'coords'");
            my $correct = 0;
            if (abs($c[0] - 13) < 0.01 and
                abs($c[1] -  3) < 0.01 and
                abs($c[2] - 15) < 0.01 and
                abs($c[3] -  5) < 0.01) {
                $correct = 1;
            }
            ok($correct, 1, "Error: object not in correct place");
        }
        if ($j == 72) {
            my $x = $w->worldx($w->width / 2);
            my $y = $w->worldy($w->height / 2);
            my $correct = 0;
            $correct = 1 if abs($x - 2.0) < 0.01 and abs($y - 4.0) < 0.01;
            ok($correct, 1, "Error: center is not at the correct location");
        }
        for (my $i = 0; $i < 8; $i++) {
            $w->move(   'up',  0,  1);
            $w->move( 'down',  0, -1);
            $w->move('right',  1,  0);
            $w->move( 'left', -1,  0);

            $w->move($id1,  0,  1);
            $w->move($id4,  0, $dir);

            if ($i < 4) {
                $w->move($id2,  1,  0);
                $w->move($id3,  0, -1);
                $w->move($id5, -1, -$dir);
            } else {
                $w->move($id2,  0, -1);
                $w->move($id3, -1,  0);
                $w->move($id5,  1, -$dir);
                if ($j == 70) {
                    $w->panWorld(-0.5, 0);
                    sleep 1;
                }
            }
            $w->centerTags(-exact => 1, 'blue') if $j > 70;
            $mw->update;
        }
        ($id1, $id2, $id3) = ($id3, $id1, $id2);
        $dir = -$dir;

        $w->move(   'up',  0, -8);
        $w->move( 'down',  0,  8);
        $w->move('right', -8,  0);
        $w->move( 'left',  8,  0);
    }

    eval {$w->destroy};
    ok($@, '', "can't destroy $class widget");
    ok(!Tk::Exists($w), 1, "$class: widget not really destroyed");
} else {
    for (1..9) {
	skip(1, 1, 1, "skipped because widget couldn't be created");
    }
}
