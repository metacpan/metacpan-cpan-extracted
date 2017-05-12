package My::Test::Class;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;

INIT { 
    My::Test::Class->SKIP_CLASS(1);
    Test::Class->runtests; 
}

sub announce_class :Test(startup) { 
    my $self = shift;
    diag "running ", ref $self;
}

1;

