use Test2::V0;

use Scalar::Util qw( blessed );

use Zuzu::Parser;

my $parser = Zuzu::Parser->new;

my @chunks = (
	'let x := 1;',
	'function f (a, b) { return a _ b; }',
	'if ( true ) { let y := 2; } else { let y := 3; }',
	'for ( i in [ 1, 2, 3 ] ) { next; }',
	'class Pet { method name () { return "z"; } }',
	'from std/math import *;',
	'<<< 1, 2, 3 >>>;',
	'dict{key};',
	'fn (x) -> x + 1;',
	'assert(1 = 1, "ok");',
	')',
	'{',
	'let :=',
	'function (',
	'new',
	'###',
	'"unterminated',
	'/* broken',
);

my $seed = 30303;
srand $seed;

my $iterations = 150;
my $crashes = 0;

for my $i ( 1 .. $iterations ) {
	my $parts = 1 + int rand 5;
	my @picked;
	for ( 1 .. $parts ) {
		push @picked, $chunks[ int rand scalar @chunks ];
	}
	my $source = join "\n", @picked;
	my $file = sprintf 'test3-fuzz-%03d.zzs', $i;

	my $ok = eval {
		$parser->parse( $source, $file );
		1;
	};

	next if $ok;

	my $e = $@;
	if ( blessed($e) and $e->isa('Zuzu::Error::Compile') ) {
		next;
	}

	$crashes++;
	fail "parser fuzz iteration $i raised non-compile exception: $e";
}

is $crashes, 0, 'parser fuzz loop produced no unstructured parser crashes';

done_testing;
