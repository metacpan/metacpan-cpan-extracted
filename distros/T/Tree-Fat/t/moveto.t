use Test;  #-*-perl-*-
BEGIN { plan test => 4 }

use Tree::Fat;

sub moveto_test {
    my $o = shift->new;
    for my $n (45..90) { $o->insert("$n", $n); }
    for my $n (10..44) { $o->insert("$n", $n); }
#    $o->dump;
    my $c = $o->new_cursor;
    for my $n (10..90) {
	$c->moveto($n-10);
	if (($c->fetch)[0] != $n) {
	    $o->dump;
	    $c->dump;
	    die $n;
	}
    }
    ok(1);
}

sub step_test {
    my $o = shift->new;
    my $max = 100;
    for my $n (1..$max) { $o->insert($n,$n); }
    my $c = $o->new_cursor;
    for my $ss (1..20) {
	my $pos=-1;
	$c->moveto('start');
	while (1) {
	    $c->step($ss);
	    $pos += $ss;
	    last if $c->pos == $max;
	    if ($pos != $c->pos) {
		$c->dump;
		die $c->pos;
	    }
	}
	$pos = 100;
	$c->moveto('end');
	while (1) {
	    $c->step(-$ss);
	    $pos -= $ss;
	    last if $c->pos == -1;
	    if ($pos != $c->pos) {
		$c->dump;
		die $pos;
	    }
	}
    }
    ok(1);
}

my $tv = 'Tree::Fat';
moveto_test($tv);
step_test($tv);

$tv->unique(0);
moveto_test($tv);
step_test($tv);
