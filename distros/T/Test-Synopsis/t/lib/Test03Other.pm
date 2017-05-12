package Test::Synopsis::__TestBait_Test03Other;
# Dummy module used during testing of Test::Synopsis

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

Testing stuff:

    BEGIN {
        no strict 'refs';
        die "CLASHING!" if grep $_ eq 'Foo', keys %{ __PACKAGE__ .'::' };
    }

    sub foobar { return 2; }

=cut
