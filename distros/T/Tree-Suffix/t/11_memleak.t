use strict;
use warnings;
use Test::More;
use Tree::Suffix;

unless (eval { require Proc::ProcessTable }) {
    plan skip_all => 'Proc::ProcessTable is not installed';
}

plan tests => 1;

my $p = Proc::ProcessTable->new;
for (@{$p->table}) {
    $p = $_ and last if $_->pid == $$;
}

{
    my $str = "mississippi";
    my $tree = Tree::Suffix->new($str);

    my $start = $p->size;
    for (my $i=0; $i<100_000; $i++) {
        my @matches = $tree->find('is');
    }
    my $end = $p->size;
    if ($end - $start > 1_000) {
        diag("Memory leak: $start -> $end");
        ok(0, 'find()');
    }
    else {
        ok(1, 'find()');
    }
}
