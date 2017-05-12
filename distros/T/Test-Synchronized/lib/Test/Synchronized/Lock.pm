package Test::Synchronized::Lock;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub lock {
    ;
}

sub unlock {
    ;
}

sub DESTROY {
    shift->unlock;
}

1;
