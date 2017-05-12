use Test;  #-*-perl-*-
BEGIN { plan test => 4 }

use Tree::Fat;
use lib './t';
use test;

sub delete_test {
    # delete just one element
    my $o = shift->new;
    my $c = $o->new_cursor;
    for my $targ (-10 .. 10) {
	$o->clear;
	for (my $n=1; $n < 10; $n += 2) {
	    $o->insert("$n", $n); 
	    $o->insert("-$n", -$n);
	}
	for (my $n=2; $n <= 10; $n += 2) {
	    $o->insert("$n", $n); 
	    $o->insert("-$n", -$n);
	}
	$o->insert(0,0);
	$c->seek($targ);
#	$o->dump;
#	$c->dump;
	my $pos = $c->pos();
	$c->delete();
#	$o->dump;
	# 9 is the last element due to strcmp
	if ($c->pos() != $pos) {
	    $o->dump;
	    $c->dump;
	    die "deleted $targ at $pos: moved to ".$c->pos();
	}
	for my $n (-10 .. 10) {
	    $c->seek($n);
	    my $got = ($c->fetch())[1];
#	    my $got = $o->fetch($n);
	    if ($n != $targ) {
		if ($got != $n) {
		    $o->dump;
		    $c->dump;
		    die "$targ: got $got, expected $n";
		}
	    } else {
		if ($got) {
		    die "$targ: got $got, expected () at $n";
		}
	    }
	}
    }
    ok(1);
}

sub delete_test2 {
    # delete all elements 1-by-1
    my $o = shift->new;
    my $c = $o->new_cursor;
    my @mirror;
    $o->clear;
    srand(1);
    for my $n (1..1000) {
	my $z = int(rand(1000));
	$o->insert($z,$z);
	push(@mirror, $z);
    }
    $o->compress(0);
    $o->balance(0);
    if (join(' ',sort(@mirror)) ne join(' ', sort($o->keys()))) {
	die "mismatch keys";
    }
    if (join(' ',sort(@mirror)) ne join(' ', sort($o->values()))) {
	die "mismatch values";
    }
#	Tree::Fat::Test::debug(2);
    while (@mirror) {
#	$o->dump;
#	warn scalar(@mirror);
	for (1..20) {
	    $o->delete(pop @mirror);
	}
	die "delete mismatch" if ($o->stats)[0] != @mirror;
	for (my $x=0; $x < @mirror; $x++) {
	    die "delete mismatch" if !$c->seek($mirror[$x]);
	}
    }
    ok(1);
}

my $tv = 'Tree::Fat';

delete_test($tv);
delete_test2($tv);

$tv->unique(0);
delete_test($tv);
delete_test2($tv);
