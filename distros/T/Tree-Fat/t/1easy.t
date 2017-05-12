use Test;  #-*-perl-*-
BEGIN { plan test => 16 }

use Tree::Fat;

sub easy_test {
    my $o = shift->new;
    $o->insert('chorze', 'fwaz');
    $o->insert('fwap', 'fwap');
    $o->insert('snorf', 'snorf');

    my $c = $o->new_cursor;
    ok($c->seek('snorf'));
    my @r = $c->fetch();
    ok($r[0] eq 'snorf') or warn $r[0];
    ok($r[1] eq 'snorf') or warn $r[1];

    $c->store('borph');
    @r = $c->fetch();
    ok($r[0] eq 'snorf' and $r[1] eq 'borph') or warn @r;
    
    $c->step(1);
    ok(!defined $c->fetch());
    $c->step(-1);
    @r = $c->fetch();
    ok($r[0] eq 'snorf' and $r[1] eq 'borph') or warn @r;

    for (qw(a chorze fwap snorf)) { $o->delete($_); }
    ok(($o->stats)[0]==0 and ($o->stats)[1]==0) or warn $o->stats;

    eval { $c->fetch() };
    ok($@ =~ m'out of sync') or warn $@;
    undef $@;
}

my $t = 'Tree::Fat';
easy_test($t);
$t->unique(0);
easy_test($t);

