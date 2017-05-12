use Test;
use strict;
 
my ($testcount, $widget, $mw);
BEGIN { $testcount = 11;  plan tests => $testcount };
 
eval { require Tk; };
ok($@, "", "loading Tk module");
 
eval {$mw = MainWindow->new() };
if ($mw) {
    $mw->geometry('+1+1');
    eval "require Tk::TipEntry;";
    ok($@, "", "Error loading Tk::TipEntry");
 
    eval { $widget = $mw->TipEntry(-tip => 'Search...'); };
    ok($@, "", "can't create TipEntry widget");
    skip($@, Tk::Exists($widget), 1, "TipEntry instance does not exist");
 
    if (Tk::Exists($widget)) {
        eval { $widget->pack; };
 
        ok ($@, "", "Can't pack a TipEntry widget");
        eval { $mw->update; };
        ok ($@, "", "Error during 'update' for TipEntry widget");
        #------------------------------------------------------------------
        eval { $widget->configure( -tip  => 'Tip...' ); };
        ok ($@, "", "Error: can't configure  '-command' for TipEntry widget");
 
        # here we need some more tests
        #...
 
        #------------------------------------------------------------------
 
        eval { my @dummy = $widget->configure; };
        ok ($@, "", "Error: configure list for TipEntry");
        eval { $mw->update; };
        ok ($@, "", "Error: 'update' after configure for TipEntry widget");
 
        eval { $widget->destroy; };
        ok($@, "", "can't destroy TipEntry widget");
        ok(!Tk::Exists($widget), 1, "TipEntry: widget not really destroyed");
    } else  { 
        for (1..5) { skip (1,1,1, "skipped because widget couldn't be created"); }
    }
}
else {
    # Until very recently, Tk wouldn't build without a display. 
    # As a result, the testing software would look at the test 
    # failures for your module and think "ah well, one of his
    # pre-requisites failed to build, so it's not his fault"
    # and throw the report away. The most recent versions of Tk,
    # however, *will* build without a display - 
    # it just skips all the tests.
    skip ("Skip  (No local X11 environment for Tk available) ") for (2 .. $testcount);
}
 
1;