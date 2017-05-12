# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

use strict;
use warnings;
#########################

use Test::More tests => 2;
BEGIN { use_ok('Tie::Cacher') };
BEGIN { use_ok('Benchmark') };

# Stolen from Tie::Cache
my $Size = 100000;

my $i;
sub report {
    my($desc, $count, $sub) = @_;
    $i = 0;
    print STDERR "[[ timing ]] $desc\n";
    print STDERR timestr(timeit($count, $sub))."\n";
}

sub mark {
    print STDERR "------\n";
}

my (%normal, %tie, %tc, %tcl);
my $cache = Tie::Cacher->new($Size);
tie %tie, "Tie::Cacher", $Size;
eval "use Tie::Cache";
my $tc = !$@;
eval "use Tie::Cache::LRU";
my $tcl = !$@;

tie %tc, "Tie::Cache", $Size if $tc;
tie %tcl, "Tie::Cache::LRU", $Size if $tcl;

print STDERR "\n";
mark();
report("insert of $Size elements into normal %hash",
       $Size,
       sub { $normal{++$i} = $i },
    );
report(
    "insert of $Size elements into Tie::Cache",
    $Size,
    sub { $tc{++$i} = $i },
    ) if $tc;
report(
    "insert of $Size elements into Tie::Cache::LRU",
    $Size,
    sub { $tcl{++$i} = $i },
    ) if $tcl;
report(
    "insert of $Size elements into Tie::Cacher object",
    $Size,
    sub { $cache->store(++$i, $i) }
);
report(
    "insert of $Size elements into Tie::Cacher tie",
    $Size,
    sub { $tie{++$i} = $i }
);

my $rv;
mark();
report("reading $Size elements from normal %hash",
    $Size,
    sub { $rv = $normal{++$i} }
);
report("reading $Size elements from Tie::Cache",
    $Size,
    sub { $rv = $tc{++$i} }
) if $tc;
report("reading $Size elements from Tie::Cache::LRU",
    $Size,
    sub { $rv = $tcl{++$i} }
) if $tcl;
report("reading $Size elements from Tie::Cacher object",
    $Size,
    sub { $rv = $cache->fetch(++$i) }
);
report("reading $Size elements from Tie::Cacher tie",
    $Size,
    sub { $rv = $tie{++$i} }
);

mark();
report("deleting $Size elements from normal %hash",
    $Size,
    sub { $rv = delete $normal{++$i} }
);
report("deleting $Size elements from Tie::Cache",
    $Size,
    sub { $rv = delete $tc{++$i} }
) if $tc;
report("deleting $Size elements from Tie::Cache::LRU",
    $Size,
    sub { $rv = delete $tcl{++$i} }
) if $tcl;
report("deleting $Size elements from Tie::Cacher object",
    $Size,
    sub { $rv = $cache->delete(++$i) }
);
report("deleting $Size elements from Tie::Cacher tie",
    $Size,
    sub { $rv = delete $tie{++$i} }
);

mark();
my $over = $Size * 2;
report("$over inserts overflowing Tie::Cache",
    $over,
    sub { $tc{++$i} = $i }
) if $tc;
report("$over inserts overflowing Tie::Cache::LRU",
    $over,
    sub { $tcl{++$i} = $i }
) if $tcl;
report("$over inserts overflowing Tie::Cacher object",
    $over,
    sub { $cache->store(++$i, $i) }
);
report("$over inserts overflowing Tie::Cacher tie",
    $over,
    sub { $tie{++$i} = $i }
);

1;
