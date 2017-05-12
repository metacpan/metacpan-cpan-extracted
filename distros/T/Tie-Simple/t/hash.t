# vim: set ft=perl :

use strict;
use Test::More tests => 7;
use Tie::Simple;

my %y = (A => 1, B => 2, C => 3);
tie my %x, 'Tie::Simple', \%y,
	FETCH    => sub { my ($a, $k) = @_; $$a{$k} },
	STORE    => sub { my ($a, $k, $v) = @_; $$a{$k} = $v },
	DELETE   => sub { my ($a, $k) = @_; delete $$a{$k} },
	CLEAR    => sub { my $a = shift; %$a = () },
	EXISTS   => sub { my ($a, $k) = @_; exists $$a{$k} },
	FIRSTKEY => sub { my $a = shift; keys %$a; each %$a },
	NEXTKEY  => sub { my $a = shift; each %$a };

is($x{A}, 1, 'FETCH');
$x{A} = 4;
is($y{A}, 4, 'STORE');
delete $x{A};
ok(!exists $y{A}, 'DELETE');
%x = ();
ok(!%y, 'CLEAR');
%x = (X => 5, Y => 6, Z => 7);
while (my ($k, $v) = each %x) {
	is($v, $y{$k}, 'FIRSTKEY/NEXTKEY');
}
