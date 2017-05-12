package Three;
use strict;
use warnings;

sub one {
    two();
    return 1;
}
sub two {
    three();
    return 1;
}
sub three {
    four();
    return 1;
}
sub four {
    five();
    five();
    five();
    five();
    return 1;
}
sub five {
    return 1;
}
sub foo {
    return @_;
}
1;