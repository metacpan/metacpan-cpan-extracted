use strict;
use warnings;

package testlib::FailTieHash;
use Tie::Hash;
use base qw(Tie::StdHash);

sub TIEHASH { undef }


package main;
use Test::More;
use Tie::Anon qw(tieh);
use Tie::Hash;
use lib "t";

{
    my $href = tieh("Tie::StdHash");
    is ref($href), "HASH", "tieh should return a hash-ref";
    is ref(tied(%$href)), "Tie::StdHash", "... and it's backed by the tied class.";
}

{
    my $href = tieh("testlib::FailTieHash");
    is $href, undef, "If tie() fails, it returns undef";
}

done_testing;
