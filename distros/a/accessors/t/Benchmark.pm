package t::Benchmark;

use strict;

use Benchmark qw( timethis timestr countit );
use Test::More;

use base qw( Exporter );

our @EXPORT = qw( &test_generation_performance &test_set_get_performance );

sub test_generation_performance {
    my $accessor_class = shift;

    # generate ~100k accessor names to use up-front (to avoid skewing tests)
    # then loop through the list & time how long it takes to generate 'em
    my $i    = 0;
    my @list = ('aa' .. 'aaaa');

    # run the test
    my $r1;
    {
	package GeneratedAccessors;
	my $generator_code = sub {
	    import $accessor_class ($list[$i++]);
	};
	$r1 = Benchmark::timethis( scalar(@list), $generator_code );
    }
    die "accessor generation benchmark failed!" unless $r1;

    print "# accessor generation: ", timestr( $r1 ), "\n";
    my $gen_per_sec = int iters_per_sec( $r1 );
    cmp_ok( $gen_per_sec, '>', 100,
	    "generates $gen_per_sec accessors/sec (> 100)" );
}

sub test_set_get_performance {
    my %type = @_;
    my $time = delete $type{time} || 1;
    my %r2;

    # don't use timethese - it's too noisy
    while (my ($type, $obj) = each %type) {
	my $x=0;
	print "# $type: ";
	$r2{$type} = countit( -$time, sub{$obj->foo($x++); $obj->foo;} );
	print timestr( $r2{$type} ), "\n";
	ok( $r2{$type}, "got benchmarks for $type" );
    }

    die "set/get benchmark failed!" unless %r2;

    my $percent = percent_faster($r2{generated}, $r2{hardcoded});
    cmp_ok( $percent, '>', 0.0,
	    "set/get generated is faster than hardcoded ($percent%)" );

    $percent = percent_faster($r2{generated}, $r2{optimized});
    if ($percent > 0) {
	pass( "set/get generated is *faster* than optimized ($percent%)" );
    } else {
	$percent = -$percent;
	cmp_ok( $percent, '<=', 30.0,
		"set/get generated is < 30% slower than optimized ($percent%)" );
    }
}

## these really belong in Benchmark.pm
sub iters_per_sec {
    my $benchmark = shift;
    eval { $benchmark->iters / ($benchmark->[1] + $benchmark->[2]) };
}

sub percent_faster {
    my ($b1, $b2) = @_;
    my ($p1, $p2) = map { iters_per_sec( $_ ) } ( $b1, $b2 );
    my $percent   = sprintf( '%.3f', eval { ($p1 - $p2) / $p1 * 100.0 } );
}

1;
