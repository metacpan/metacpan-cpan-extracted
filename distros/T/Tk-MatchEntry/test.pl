#!perl -w
use Test;
use strict;

BEGIN { plan tests => 12 };

eval { require Tk; };
ok($@, "", "loading Tk module");

my $mw;
eval {$mw = Tk::MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tk::Exists($mw), 1, "MainWindow creation failed");
eval { $mw->geometry('+10+10'); };

my $w;
my $class = 'MatchEntry';

print "Testing $class\n";

eval "require Tk::$class;";
ok($@, "", "Error loading Tk::$class");

eval { $w = $mw->$class(); };
ok($@, "", "can't create $class widget");
skip($@, Tk::Exists($w), 1, "$class instance does not exist");

if (Tk::Exists($w)) {
    eval { $w->pack; };

    ok ($@, "", "Can't pack a $class widget");
    eval { $mw->update; };
    ok ($@, "", "Error during 'update' for $class widget");

    eval { my @dummy = $w->configure; };
    ok ($@, "", "Error: configure list for $class");
    eval { $mw->update; };
    ok ($@, "", "Error: 'update' after configure for $class widget");

    eval { $w->destroy; };
    ok($@, "", "can't destroy $class widget");
    ok(!Tk::Exists($w), 1, "$class: widget not really destroyed");
} else  { 
    for (1..5) { skip (1,1,1, "skipped because widget couldn't be created"); }
}

1;
