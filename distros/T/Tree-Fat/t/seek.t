use Test;  #-*-perl-*-
BEGIN { plan test => 16 }

use strict;
use Tree::Fat;

srand(0);

sub seek_test {
    my $o = shift->new;
    my $at = 'ab';
    my @all;
    while ($at lt 'zz') {
	splice(@all, int(rand(@all)), 0, $at);
	++$at;
    }
    for (@all) { $o->insert($_,$_); }
    unshift(@all, 'aa');
    my @sortall = sort @all;
    my $c = $o->new_cursor;

    for (my $t=0; $t < @sortall; $t++) {
	$c->seek("$sortall[$t]+");
#	$o->dump;
#	warn "seek $sortall[$t]+";
#	$c->dump;
	$c->step(1);
#	warn "step 1"; $c->dump;
	if ($sortall[$t] eq 'zz') {
	    die $t if $c->fetch() || $c->pos() != ($o->stats())[0];
	} else {
	    if ((($c->fetch())[1] || 'false') ne ($sortall[$t+1] or 'false')) {
		warn $c->fetch();
		warn $sortall[$t+1];
		die $t;
	    }
	}
    }
    ok(1);
    for (my $t=1; $t < @all; $t++) {
	$c->seek("$all[$t]");
	$c->fetch() eq $all[$t] or do { $c->dump; die $all[$t]; }
    }
    ok(1);
    for (my $t=0; $t < @all; $t++) {
	$c->seek("$all[$t]+");
#	$o->dump;
#	warn "seek $all[$t]+";
#	$c->dump;
	$c->step(-1);
#	warn "step -1";
#	$c->dump;
	if ($all[$t] eq 'aa') {
	    if ($c->fetch() || $c->pos() != -1) {
		warn $c->fetch;
		warn $c->pos;
		die $t;
	    }
	} else {
	    die $t if ($c->fetch())[1] ne $all[$t];
	}
    }
    ok 1;

    # preliminary
    ok $c->seek('ab'), 1;
    ok $c->seek('ab!'), 0;
    ok !defined $c->fetch(), 1;
}

# incomplete XXX
sub seek2_test {
    my ($class, $unique) = @_;
    my $o = shift->new;
    $o->clear;
    my $c = $o->new_cursor;
    for (qw/b b c/) { $o->insert($_,$_) }
    $c->seek('b');
    $c->step(-1);
    skip($unique, sub { $c->pos() == -1 });

    $o->insert('a','a');
    $c->seek('b');
    $c->step(-1);
    skip($unique, sub { ($c->fetch())[1] eq 'a' });
}

my $tv = 'Tree::Fat';
for my $u (0..1) {
    $tv->unique($u);
    seek_test($tv);
    seek2_test($tv, $u);
}

