#!perl

use strict;
use warnings;
use Test::Synopsis::Expectation;

Test::Synopsis::Expectation::prepare('my $foo = 1;');
synopsis_ok(*DATA);

done_testing;
__DATA__
=head1 NAME

prepared - prepare!

=head1 SYNOPSIS

    $foo; # => 1

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
