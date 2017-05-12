use strict;
use warnings;
use Test::More;
use Tree::Suffix;

unless (eval { require Proc::ProcessTable }) {
    plan skip_all => 'Proc::ProcessTable is not installed';
}

plan tests => 2;

my $p = Proc::ProcessTable->new;
for (@{$p->table}) {
    $p = $_ and last if $_->pid == $$;
}

{
    my $tree = Tree::Suffix->new();
    $tree->insert('aa'..'gg');
    my $start = $p->rss;
    for (my $i=0; $i<200; $i++) {
        $tree->clear;
        $tree->insert('aa'..'gg');
    }
    my $end = $p->rss;
    if ($end - $start > 1_000) {
        diag("\nMemory: $start -> $end\nVerify that you have libstree >= 0.4.2");
        ok(0, 'insert()');
    }
    else {
        ok(1, 'insert()');
    }
}

{
    my $tree = Tree::Suffix->new();
    $tree->insert('aa'..'gg');
    my $start = $p->size;
    for (my $i=0; $i<200; $i++) {
        $tree = Tree::Suffix->new();
        $tree->insert('aa'..'gg');
    }
    my $end = $p->size;
    if ($end - $start > 1_000) {
        diag("\nMemory: $start -> $end\nVerify that you have libstree >= 0.4.2");
        ok(0, 'new()/insert()');
    }
    else {
        ok(1, 'new()/insert()');
    }
}
