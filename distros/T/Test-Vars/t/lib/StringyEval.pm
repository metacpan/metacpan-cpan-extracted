package StringyEval;
use strict;
use warnings 'once';

sub foo {
    my($unused_param) = @_;
    my $unused_var;

    eval q{ $unused_param++; $unused_var++ };
    return;
}

1;
