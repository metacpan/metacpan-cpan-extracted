package Normal;
use strict;
use warnings;

sub new {
    return bless { value => 0 }, $_[0];
}

sub inc {
    $_[0]->{value}++;
}

1;
