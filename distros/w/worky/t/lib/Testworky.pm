package Testworky;

sub works {
    print "This works";
}

no worky;

sub busted {
    say "no worky!";
}

use worky;

sub ok {
    print "ok";
}

1;
