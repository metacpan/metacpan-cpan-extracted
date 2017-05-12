package StringyEval;
use strict;
use warnings 'once';

use constant C => 0;

sub foo {

    if(C){
        my $unused_var;
        $unused_var++;
    }
    return;
}

1;
