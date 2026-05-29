use Test2::V0;

use Zuzu::Test::ZPathFacelessPortDiagnostics qw(
	classify_query
	format_summary_lines
	summarize_failed_queries
);

is(
	classify_query( 'count(numbers/*)' ),
	'function-node-set-coercion',
	'classifies function coercion query',
);

is(
	classify_query( 'numbers/#0/number/..*' ),
	'position-key-context',
	'classifies position/key context query',
);

is(
	classify_query( '**/td/@id' ),
	'xml-attributes-namespaces',
	'classifies xml attribute query',
);

is(
	classify_query( '[age == 26]' ),
	'comparison-truthiness',
	'classifies comparison query',
);

is(
	classify_query( '2*2' ),
	'numeric-tokenization',
	'classifies numeric tokenization query',
);

is(
	classify_query( 'tag(tagged)' ),
	'other',
	'classifies unmatched query as other',
);

my $summary = summarize_failed_queries([
	'count(numbers/*)',
	'count(**)',
	'numbers/#0',
	'**/td/@id',
	'[age == 26]',
	'2*2',
]);

ok(
	scalar @{ $summary } >= 4,
	'summary contains multiple diagnostic categories',
);

my $lines = format_summary_lines( $summary );
ok( scalar @{ $lines } > 0, 'formatted summary lines exist' );
like( $lines->[0], qr/:\s+\d+\s+\(examples:/, 'summary line includes count and examples' );

done_testing;
