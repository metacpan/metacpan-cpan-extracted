use Test;  #-*-perl-*-
BEGIN { plan test => 4 }

use Tree::Fat;

sub cursor_test {
    my $o = shift->new;
    my @e = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
    my $max = $#e;
    for (@e) { $o->insert($_, $_); }

    # forward
    my $c = $o->new_cursor;
    $c->moveto('start');
    for (my $r=0; $r <= @e+2; $r++) {
	my @r=();
#	warn $r;
	for (my $s=0; $s <= $r; $s++) {
	    push(@r, ($c->each(1))[0]);
#	    $c->dump;
	}
	for (my $s=0; $s <= $r; $s++) { 
	    push(@r, ($c->each(-1))[0]);
#	    $c->dump;
	}
	my $mess1 = join('',@r);
	my @tmp = (@e[0..$r], reverse(@e[0..($r-1)]));
	my $mess2 = join('', map {defined $_? $_ : '' } @tmp);
	if ($mess1 ne $mess2) {
	    die "Expecting '$mess2', got '$mess1'";
	}
#	warn "$mess1\n";
    }
    ok(1);

    # backward
    $c->moveto('end');
    for (my $r=0; $r <= @e+2; $r++) {
	my @r=();
#	warn $r;
	for (my $s=0; $s <= $r; $s++) {
	    push(@r, ($c->each(-1))[0]);
#	    warn "each-1\n"; $c->dump;
	}
	for (my $s=0; $s <= $r; $s++) { 
	    push(@r, ($c->each(1))[0]);
#	    warn "each1\n"; $c->dump;
	}
	my $mess1 = join('',@r);
	my $ex = $max-$r;
	my $mess2 = join('', reverse(@e[($ex<0?0:$ex)..$max]),
			 @e[($ex+1<0?0:$ex+1)..$max]);
	if ($mess1 ne $mess2) {
	    die "Expecting '$mess2', got '$mess1'";
	}
#	warn "$mess1\n";
    }
    ok(1);
}

my $p = 'Tree::Fat';
cursor_test($p);
$p->unique(0);
cursor_test($p);
