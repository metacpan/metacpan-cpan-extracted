#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;
Test::Synopsis::Expectation::set_ignorings(['++$num;']);
synopsis_ok(*DATA);
done_testing;

__DATA__
=head1 NAME

ignore

=head1 SYNOPSIS

    my $num;
    $num = 1; # => 1
    ++$num;
    $num; # => 1

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
