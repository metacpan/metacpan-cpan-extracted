use Test;  #-*-perl-*-
BEGIN { plan test => 26 }

use Tree::Fat;

sub null_test {
    my $o = shift->new;

    $o->compress(0);

    ok(!defined $o->fetch('bogus'));
    $o->delete('bogus');

    my $c = $o->new_cursor;

    eval { $c->step(0); };
    ok($@ =~ m'step by zero');
    undef $@;
    eval { $c->store('oops') };
    ok($@ =~ m'unset cursor');
    undef $@;

    ok(!$c->seek('bogus'));
    ok($c->pos eq -1);
    ok(!defined $c->each(1));
    ok($c->pos eq -1);

    $o->insert(2,2);
    $c->moveto('start');
#    $c->dump;
    $c->insert(1,1);
    ok(($c->fetch)[1] == 1);
    $c->moveto('end');
    ok($c->pos() == 2);
    $c->insert(3,3);
#    $o->dump;
    ok(($c->fetch)[1] == 3);
    $c->moveto(-1);
    ok($c->pos()==-1);
    $c->seek(1.5);
    eval { $c->pos() };
    ok($@ =~ m'unpositioned') or warn $@;
    undef $@;

    ok(!defined $o->fetch('bogus'));
    $o->delete('bogus');
}

my $t = 'Tree::Fat';
null_test($t);

$t->unique(0);
null_test($t);
