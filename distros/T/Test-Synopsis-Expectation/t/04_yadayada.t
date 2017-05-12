#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;

synopsis_ok(*DATA);

done_testing;
__DATA__
=head1 NAME

yadayada - It's yadayada

=head1 SYNOPSIS

    my $sum;
    ...
    $sum = 1; # => 1

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
