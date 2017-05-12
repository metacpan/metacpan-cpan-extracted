#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;

synopsis_ok(*DATA);

done_testing;
__DATA__
=head1 NAME

wrapped_brace - Values in the wrapped_brace

=head1 SYNOPSIS

    my $var;
    if (1) {
        $var = 1; # => 1
        ++$var;   # => 2
    }
    if (1) {
        $var = 3; # => 3
        if (1) {
            ++$var;   # => 4
        }
    }
    $var = 5; # => 5

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
