use strict;
use warnings;

package testlib::FailTieArray;
use Tie::Array;
use base qw(Tie::StdArray);

sub TIEARRAY { undef }


package main;
use Test::More;
use Tie::Anon qw(tiea);
use Tie::Array;
use lib "t";

{
    my $aref = tiea("Tie::StdArray");
    is ref($aref), "ARRAY", "tiea should return an array-ref";
    is ref(tied(@$aref)), "Tie::StdArray", "... and it's backed by the tied class.";
}

{
    my $aref = tiea("testlib::FailTieArray");
    is $aref, undef, "If tie() fails, it returns undef";
}

done_testing;
