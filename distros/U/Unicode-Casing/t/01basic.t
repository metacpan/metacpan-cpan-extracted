# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unicode-Casing.t'

use Test::More tests => 25;

# So will handle \xb5 properly
use if $^V ge v5.12.0, 'feature', 'unicode_strings';

sub simple_uc2 {
    my $string = shift;
    $string = uc($string);
    $string =~ s/A/_A2_/g;
    return $string;
}

sub simple_ucfirst1 {
    my $string = shift;
    $string = ucfirst($string);
    $string =~ s/^A/_A1_/;
    return $string;
}

sub simple_ucfirst2 {
    my $string = shift;
    $string = ucfirst($string);
    $string =~ s/^A/_A2_/;
    return $string;
}

sub simple_lc1 {
    my $string = shift;
    $string = CORE::lc($string);
    $string =~ s/a/_a1_/g;
    return $string;
}

sub simple_lcfirst1 {
    my $string = shift;
    $string = lcfirst($string);
    $string =~ s/^a/_a1_/;
    return $string;
}

sub simple_fc1 {
    my $string = shift;
    use if $^V ge v5.15.8, 'feature', 'fc';
    $string = fc($string);
    $string =~ s/a/_a1_/g;
    return $string;
}

use Unicode::Casing uc => \&simple_uc1, ucfirst => \&simple_ucfirst1,
                    lc => \&simple_lc1, lcfirst => \&simple_lcfirst1;

# This tests defining the function after the 'use'
sub simple_uc1 {
    my $string = shift;
    $string = uc($string);
    $string =~ s/A/_A1_/g;
    return $string;
}

is (uc("bb"), "BB", "Verify uc() non-overridden character works");
is (uc("aa"), "_A1__A1_", "Verify uc() override works");
is (ucfirst("bb"), "Bb", "Verify ucfirst() non-overridden character works");
is (ucfirst("aa"), "_A1_a", "Verify ucfirst() override works");
is (lc("BB"), "bb", "Verify lc() non-overridden character works");
is (lc("AA"), "_a1__a1_", "Verify lc() override works");
is (lcfirst("BB"), "bB", "Verify lcfirst() non-overridden character works");
is (lcfirst("AA"), "_a1_A", "Verify lcfirst() override works");

use Unicode::Casing ucfirst => \&simple_ucfirst2;

is (ucfirst("bb"), "Bb", "Verify following ucfirst() non-overridden character works");
is (ucfirst("aa"), "_A2_a", "Verify following ucfirst() override works");

{
    use Unicode::Casing uc => \&simple_uc2;

    is (uc("bb"), "BB", "Verify nested block uc() non-overridden character works");
    is (uc("aa"), "_A2__A2_", "Verify nested block uc() override works");
    is (ucfirst("bb"), "Bb", "Verify following in nested block ucfirst() non-overridden character works");
    is (ucfirst("aa"), "_A2_a", "Verify following in nested block ucfirst() override works");
}

is (uc("bb"), "BB", "Verify de-nested uc() non-overridden character works");
is (uc("aa"), "_A1__A1_", "Verify de-nested uc() override works");
is (ucfirst("bb"), "Bb", "Verify following ucfirst() non-overridden character still works");
is (ucfirst("aa"), "_A2_a", "Verify following ucfirst() override still works");

no Unicode::Casing;

is(uc("aa"), "AA", "Verify that reverts to standard behavior after a 'no'");
is(ucfirst("aa"), "Aa", "Verify that reverts to standard behavior after a 'no'");
is(lc("AA"), "aa", "Verify that reverts to standard behavior after a 'no'");
is(lcfirst("AA"), "aA", "Verify that reverts to standard behavior after a 'no'");

SKIP: { 
    skip "fc not in this version of Perl", 3 if $^V lt v5.15.8;

    use if $^V ge v5.15.8, Unicode::Casing, fc => \&simple_fc1;
    use if $^V ge v5.15.8, 'feature', 'fc';

    # The b5 => 3bc distinquishes between lc and fc
    is (fc("BB\x{b5}"), "bb\x{3bc}", "Verify fc() non-overridden character works");
    is (fc("AA"), "_a1__a1_", "Verify fc() override works");

    no Unicode::Casing;
    is(fc("AA"), "aa", "Verify that reverts to standard behavior after a 'no'");
}
