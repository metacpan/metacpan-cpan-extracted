use strict; use warnings;
package
assign::Test;

use assign::0();
use Test::More;
use Capture::Tiny;
use XXX;

use base 'Exporter';

our $t = -d 't' ? 't' : 'test';

our @EXPORT = qw(
    $t
    test
    is ok pass fail like
    capture
    XXX
    WWW
);

sub import {
    strict->import;
    warnings->import;
    goto &Exporter::import;
}

my $test_count = 0;
sub test {
    return if
        defined $ENV{ONLY} and
        $ENV{ONLY} != ++$test_count;

    $assign::assign_class = 'assign::0';
    $assign::var_prefix = '_';
    $assign::var_id = 0;

    my ($spec, $label) = @_;

    $spec =~ /(.*\n)\+\+\+\n(.*)/s
        or die "Invalid spec for 'test()'";
    my ($perl, $want) = ($1, $2);

    my $got = assign->new(code => $perl)->transform;

    is $got, $want, $label;
}

sub capture { goto &Capture::Tiny::capture_merged }

END {
    package main;

    if (not defined $ENV{PERL_ZILD_TEST_000_COMPILE_MODULES}) {
        Test::More::done_testing();
    }
}

1;
