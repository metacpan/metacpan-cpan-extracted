#!perl -T
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Tripletail', qw($AltTL /dev/null))
      or BAIL_OUT('Failed to load Tripletail');
}

# Validate the symbol table.
subtest 'symtable of package main' => sub {
    plan tests => 2;

    ok exists  $main::{AltTL}, '$::AltTL exists';
    ok !exists $main::{TL   }, '$::TL does not exist';
};

# See if we can actually use $AltTL instead of $TL.
my $dt = eval q{
    $AltTL->newDateTime;
};
isa_ok $dt, 'Tripletail::DateTime';

# Try the alternative import in a different package.
subtest 'different package' => sub {
    plan tests => 3;

    package foo;
    use Test::More;

    eval q{
        BEGIN {
            use_ok('Tripletail', qw($__TL__))
              or BAIL_OUT('Failed to re-import Tripletail');
        }
    };
    is $@, '', 'eval succeeded';

    my $t = eval q{
        $__TL__->newTemplate;
    };
    isa_ok $t, 'Tripletail::Template';
};
