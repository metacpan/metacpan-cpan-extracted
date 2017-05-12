#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;
synopsis_ok(*DATA);
done_testing;

__DATA__
=head1 NAME

no-test

=head1 SYNOPSIS

    my $sum;
    $sum = 1; # => 1

The following is invalid. So it should not be tested.

=for test_synopsis_expectation_no_test

    my $sum;
    $sum = 1; # => 2

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
