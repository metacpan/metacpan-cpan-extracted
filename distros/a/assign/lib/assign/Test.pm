use strict; use warnings;
package assign::Test;

use Test::More;

use base 'Exporter';

our @EXPORT = qw( test );

sub test {
    my ($input, $want, $label) = @_;
    pass $label;
}

END {
    package main;

    if (not defined $ENV{PERL_ZILD_TEST_000_COMPILE_MODULES}) {
        Test::More::done_testing();
    }
}

1;
