use strict;

package test;
use Carp;
require Tree::Fat;
require Exporter;
use vars  qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw(&permutation);

# Thanks to Guy Decoux <decoux@moulon.inra.fr> for this non-recursive
# permutation algorithm.  He attributes it to a french cooking book by
# Lerbart & Morineau.

sub permut {
    my @vect = @_;
    my $n = $#vect;
    return if $n <= 0;
    my ($i,$j,$k);
    for ($j = $n; $j; $j--) {
	last if $vect[$j] > $vect[$j - 1];
    }
    return if !$j;
    my $m = int(($j + $n) / 2);
    for ($i = $j, $k = $n; $i <= $m; $i++, $k--) {
	@vect[$i, $k] = @vect[$k, $i];
    }
    $j--;
    for ($i = $j + 1; $i < $n; $i++) {
	last if $vect[$j] < $vect[$i];
    }
    @vect[$i,$j] = @vect[$j,$i];
    @vect;
}

sub permutation ($) {
    my @vect = @{$_[0]};
    my @indice = (0 .. $#vect);
    my $ok = 0;
    sub {
	@indice = permut(@indice) if $ok;
	$ok = 1;
	@vect[@indice];
    };
}

package Tree::Fat;

sub keys {
    my ($o) = @_;
    my @k;
    my $c = $o->new_cursor;
    while (my($k,$v) = $c->each(1)) {
	push(@k, $k);
    }
    @k;
}

# goofy reverse traversal for testing
sub values {
    my ($o) = @_;
    my @v;
    my $c = $o->new_cursor;
    $c->moveto('end');
    while (my($k,$v) = $c->each(-1)) {
	push(@v, $v);
    }
    @v;
}

1;
