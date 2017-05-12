use strict;
use warnings;

package testlib::FailTieScalar;
use Tie::Scalar;
use base qw(Tie::StdScalar);

sub TIESCALAR { undef }


package main;
use Test::More;
use Tie::Anon qw(ties);
use Tie::Scalar;
use lib "t";

{
    my $sref = ties("Tie::StdScalar");
    is ref($sref), "SCALAR", "ties should return a scalar-ref";
    is ref(tied($$sref)), "Tie::StdScalar", "... and it's backed by the tied class.";
}

{
    my $sref = ties("testlib::FailTieScalar");
    is $sref, undef, "If tie() fails, it returns undef";
}

done_testing;
