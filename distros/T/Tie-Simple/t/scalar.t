# vim: set ft=perl :

use strict;
use Test::More tests => 2;
use Tie::Simple;

my $y = 'A';
tie my $x, 'Tie::Simple', \$y,
	FETCH => sub { my $a = shift; $$a },
	STORE => sub { my $a = shift; $$a = shift; };

is($x, 'A', 'FETCH');
$x = 'Z';
is($y, 'Z', 'STORE');
