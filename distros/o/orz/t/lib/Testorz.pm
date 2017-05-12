package Testorz;

sub works {
    print "This works";
}

use orz;

sub busted {
    say "orz!";
}

no orz;

sub ok {
    print "ok";
}

1;
