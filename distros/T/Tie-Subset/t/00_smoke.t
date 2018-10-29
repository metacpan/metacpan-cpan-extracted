#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Array> and L<Tie::Subset::Hash>.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Tie_Subset_Testlib;

use constant TESTCOUNT => 10;  ## no critic (ProhibitConstantPragma)
use Test::More tests=>TESTCOUNT;

BEGIN {
	diag "This is Perl $] at $^X on $^O";
	use_ok 'Tie::Subset' or BAIL_OUT("failed to use Tie::Subset");
	use_ok 'Tie::Subset::Hash'  or BAIL_OUT("failed to use Tie::Subset::Hash");
	use_ok 'Tie::Subset::Array' or BAIL_OUT("failed to use Tie::Subset::Array");
}
is $Tie::Subset::VERSION, '0.01', 'Tie::Subset version matches tests';
is $Tie::Subset::Hash::VERSION,  '0.01', 'Tie::Subset::Hash version matches tests';
is $Tie::Subset::Array::VERSION, '0.01', 'Tie::Subset::Array version matches tests';

my %hash = map {$_=>uc() x 3} 'a'..'z';
tie my %subset, 'Tie::Subset::Hash', \%hash, ['f'..'k'];
is_deeply \%subset, { map {$_=>uc() x 3} 'f'..'k' }, 'basic tied hash'
	or diag explain \%subset;
$subset{i} = 9;
is_deeply \%hash, { i=>9, map {$_=>uc() x 3} 'a'..'h','j'..'z' },
	'assignment to tied hash passed through';

my @array = ('a'..'z');
tie my @subset, 'Tie::Subset::Array', \@array, [5..10];
is_deeply \@subset, ['f'..'k'], 'basic tied array' or diag explain \@subset;
$subset[3] = 9;
is_deeply \@array, ['a'..'h',9,'j'..'z'], 'assignment to tied array passed through';

if (my $cnt = grep {!$_} Test::More->builder->summary)
	{ BAIL_OUT("$cnt smoke tests failed") }
done_testing(TESTCOUNT);
