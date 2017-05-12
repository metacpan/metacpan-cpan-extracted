use Test;  #-*-perl-*-
BEGIN { plan test => 10 }

use Tree::Fat;
use lib './t';
use test;

sub insert_test {
    my $o = shift->new;
    my $c = $o->new_cursor;
    my $p = permutation([qw(a b c e f g)]);
    while (my @vector = &$p) {
	for my $q ('b','d','f') { $o->insert($q,$q); }
	for my $kv (@vector) {
	    $o->insert($kv, $kv);
	}
	$c->moveto('start');
#	$c->dump;
	my @done;
	while (my ($k,$v) = $c->each(1)) {
#	    $c->dump;
#	    warn "$k\n";
	    push(@done, $k);
	}
	die @done if join('',@done) ne 'abbcdeffg';
	$o->clear;
    }
    ok(1);
}

sub insert2_test {
    my $o = shift->new;
    my $c = $o->new_cursor;

    # insert at start & end
    $o->insert(1,1);
    $c->moveto('end');
    $c->insert(2,2);
    $c->moveto('start');
    $c->insert(0,0);
    ok(join('', $o->values) eq '210');

    # keep position & direction across splits?
    $o->clear;
    $c->moveto(-1);
    for (1..4) { $c->insert($_,$_); }
    $c->moveto(3);
    $c->step(-1);
    $c->insert(5,5);
    $c->step(-1);
    ok($c->pos() == 1);

    $o->clear;
    $c->moveto(-1);
    for (1..4) { $c->insert($_,$_); }
    $c->moveto(2);
    $c->insert(5,5);
    $c->step(1);
    ok($c->pos() == 3);

    # is treecache updated if top node splits?
    $c->step(-1);
    for (6..9) { $c->insert($_,$_); }
    ok(1);
}

my $tv = 'Tree::Fat';
insert_test($tv);
insert2_test($tv);

$tv->unique(0);
insert_test($tv);
insert2_test($tv);
