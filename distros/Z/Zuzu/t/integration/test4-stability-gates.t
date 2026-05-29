use Test2::V0;

use Time::HiRes qw( time );

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;
my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );

my $ast = $parser->parse(
	<<'SRC',
function stable_compute (n) {
	let total := 0;
	for ( let i in [ 1, 2, 3, 4, 5 ] ) {
		total := total + n + i;
	}
	return total;
}
SRC
	'test4-stability.zzs',
);

$runtime->evaluate($ast);

my $iterations = $ENV{TEST4_STABILITY_ITERATIONS};
$iterations = 1500 if !defined $iterations or $iterations !~ /^\d+$/;

my $max_seconds = $ENV{TEST4_STABILITY_MAX_SECONDS};
$max_seconds = 20 if !defined $max_seconds or $max_seconds !~ /^\d+(?:\.\d+)?$/;

my $max_growth_kb = $ENV{TEST4_STABILITY_MAX_RSS_GROWTH_KB};
$max_growth_kb = 24 * 1024
	if !defined $max_growth_kb or $max_growth_kb !~ /^\d+$/;

for ( 1 .. 100 ) {
	$runtime->call( 'stable_compute', $_ );
}

my $rss_before = _current_rss_kb();
my $start = time;

my $dies = 0;
for my $i ( 1 .. $iterations ) {
	my $ok = eval {
		my $got = $runtime->call( 'stable_compute', $i );
		my $want = ( 5 * $i ) + 15;
		die "compute mismatch\n" if $got != $want;
		1;
	};

	if ( !$ok ) {
		$dies++;
		last;
	}
}

my $elapsed = time - $start;
my $rss_after = _current_rss_kb();
my $rss_growth = defined $rss_before && defined $rss_after
	? $rss_after - $rss_before
	: undef;

is $dies, 0, 'long-run stability loop completes without runtime failure';
ok( $elapsed <= $max_seconds,
	sprintf 'stability loop runtime %.3fs stays below %.3fs budget',
	$elapsed,
	$max_seconds,
);

if ( defined $rss_growth ) {
	ok( $rss_growth <= $max_growth_kb,
		sprintf 'RSS growth (%d KB) stays below %d KB leak budget',
		$rss_growth,
		$max_growth_kb,
	);
} else {
	note 'RSS tracking unavailable on this platform; skipping leak budget assertion';
	ok( 1, 'platform does not expose /proc RSS, leak gate skipped' );
}

done_testing;

sub _current_rss_kb {
	my $status = '/proc/self/status';
	return undef if !-e $status;

	open my $fh, '<', $status or return undef;
	while ( my $line = <$fh> ) {
		if ( $line =~ /^VmRSS:\s+(\d+)\s+kB/i ) {
			close $fh;
			return $1 + 0;
		}
	}
	close $fh;
	return undef;
}
