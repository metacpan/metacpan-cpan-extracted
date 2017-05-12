#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 71_invalid_values.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - test that the constants sub returns undef and sets
#   $! and $^E on non-existant comstants

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
use Win32::GUI::Constants();

my @tests = qw(THIS_DOES_NOT_EXITS NOR_DOES_THIS);

plan tests => 3 * @tests;

# Useful Constants:
sub EINVAL() {22}
sub ERROR_INVALID_ARGUMENT() {87}

# On cygwin, $^E == $! (no OS extended errors)
my $EXPECTED_E = ERROR_INVALID_ARGUMENT;
if(lc $^O eq "cygwin") {
    $EXPECTED_E = EINVAL;
}


for my $c (@tests) {
    my($r, $e);
    $!=0;$^E=0;
    $r = Win32::GUI::Constants::constant($c);
    $e = $^E;  # record $^E immediately
    is($r , undef, "Constant $c does not exist");
    cmp_ok($!, "==", EINVAL, "Errno set to EINVAL");
    cmp_ok($e, "==", $EXPECTED_E, "LastError set to ERROR_INVALID_ARGUMENT");
}
  
