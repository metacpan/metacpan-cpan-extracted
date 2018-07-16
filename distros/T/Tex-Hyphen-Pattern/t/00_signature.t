#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use Test::More;

our $VERSION = 0.100;

## no critic qw(ProhibitCascadingIfElse)
if ( not $ENV{'TEST_SIGNATURE'} ) {
    plan 'skip_all' =>
      q{Set the environment variable TEST_SIGNATURE to enable this test.};
}
elsif ( not eval { require Module::Signature; 1 } ) {
    plan 'skip_all' =>
      q{Next time around, consider installing Module::Signature, }
      . q{so you can verify the integrity of this distribution.};
}
elsif ( not -e 'SIGNATURE' ) {
    plan 'skip_all' => q{SIGNATURE not found};
}
elsif ( -s 'SIGNATURE' == 0 ) {
    plan 'skip_all' => q{SIGNATURE file empty};
}
elsif ( not eval { require Socket; Socket::inet_aton('pgp.mit.edu') } ) {
    plan 'skip_all' => q{Cannot connect to the keyserver to check module }
      . q{signature};
}
else {
    plan 'tests' => 1 + 1;
}
## use critic

my $ret = Module::Signature::verify();

SKIP: {
    if ( $ret eq Module::Signature::CANNOT_VERIFY() ) {
        skip q{Module::Signature cannot verify}, 1;
    }
    cmp_ok $ret, q{==}, Module::Signature::SIGNATURE_OK(), q{Valid signature};
}
