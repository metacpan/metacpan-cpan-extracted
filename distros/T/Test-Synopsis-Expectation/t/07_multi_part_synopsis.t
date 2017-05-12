#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;

synopsis_ok(*DATA);

done_testing;
__DATA__
=head1 NAME

multi part synopsis - multi!

=head1 SYNOPSIS

    1; # => 1

Of course following is true!

    2; # => 2

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
