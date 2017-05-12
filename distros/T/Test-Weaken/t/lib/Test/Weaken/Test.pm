package Test::Weaken::Test;
use strict;
use warnings;
use Carp;

Carp::croak('Test::More not loaded')
    unless defined &Test::More::is;

BEGIN {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval 'use Test::Differences';
    ## use critic
}
use Data::Dumper;

## no critic (Subroutines::RequireArgUnpacking)
sub is {
## use critic
    goto &Test::Differences::eq_or_diff
        if defined &Test::Differences::eq_or_diff && @_ > 1;
    @_ = map { ref $_ ? Data::Dumper::Dumper(@_) : $_ } @_;
    goto &Test::More::is;
} ## end sub is

1;

