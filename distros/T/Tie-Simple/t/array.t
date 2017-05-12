# vim: set ft=perl :

use strict;
use Test::More tests => 16;
use Tie::Simple;

my @y = qw(A B C);
my $c = 3;
tie my @x, 'Tie::Simple', [ \@y, \$c ],
	FETCH     => sub { my ($a, $i) = @_; $$a[0][$i] },
	STORE     => sub { my ($a, $i, $v) = @_; $$a[0][$i] = $v },
	FETCHSIZE => sub { my $a = shift; scalar @{$$a[0]} },
	STORESIZE => sub { my ($a, $c) = @_; $#{$$a[0]} = $c - 1 },
	EXTEND    => sub { my ($a, $c) = @_; ${$$a[1]} = $c },
	EXISTS    => sub { my ($a, $i) = @_; exists $$a[0][$i] },
	DELETE    => sub { my ($a, $i) = @_; delete $$a[0][$i] },
	CLEAR     => sub { my $a = shift; @{$$a[0]} = () },
	PUSH      => sub { my $a = shift; push @{$$a[0]}, @_ },
	POP       => sub { my $a = shift; pop @{$$a[0]} },
	SHIFT     => sub { my $a = shift; shift @{$$a[0]} },
	UNSHIFT   => sub { my $a = shift; unshift @{$$a[0]}, @_ },
	SPLICE    => sub { my ($a, $o, $c, @l) = @_; splice @{$$a[0]}, $o, $c, @l };

is_deeply(\@x, [ qw(A B C) ], 'FETCH');
($x[0], $x[1], $x[2]) = qw(X Y Z);
is_deeply(\@y, [ qw(X Y Z) ], 'STORE');
is(@x, 3, 'FETCHSIZE');
$#x = 4;
is(scalar @y, 5, 'STORESIZE');
ok(exists $x[$_], "EXISTS $_") foreach (0 .. 2);
ok(!exists $x[3], "EXISTS 3");
delete $x[0];
ok(!defined $y[0], 'DELETE');
@x = ();
if ($] > 5.023003) {
     # EXTEND not called anymore on @x=(), see https://rt.perl.org/Ticket/Display.html?id=126472
     is($c, 3, 'no EXTEND');
} else {
    is($c, 0, 'EXTEND');
}
is(scalar @y, 0, 'CLEAR');
push @x, 'M', 'N', 'O', 'P';
is_deeply(\@y, [ qw(M N O P) ], 'PUSH');
pop @x;
is_deeply(\@y, [ qw(M N O) ], 'POP');
shift @x;
is_deeply(\@y, [ qw(N O) ], 'SHIFT');
unshift @x, qw(Q R S);
is_deeply(\@y, [ qw(Q R S N O) ], 'UNSHIFT');
splice @x, 2, 2, qw(F G H);
is_deeply(\@y, [ qw(Q R F G H O) ], 'SPLICE');
