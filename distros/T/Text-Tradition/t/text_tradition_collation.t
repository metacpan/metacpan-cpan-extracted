#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Test::More::UTF8;
use Text::Tradition;
use TryCatch;

my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );
my $c = $t->collation;

my $rno = scalar $c->readings;
# Split n21 ('unto') for testing purposes
my $new_r = $c->add_reading( { 'id' => 'n21p0', 'text' => 'un', 'join_next' => 1 } );
my $old_r = $c->reading( 'n21' );
$old_r->alter_text( 'to' );
$c->del_path( 'n20', 'n21', 'A' );
$c->add_path( 'n20', 'n21p0', 'A' );
$c->add_path( 'n21p0', 'n21', 'A' );
$c->add_relationship( 'n21', 'n22', { type => 'collated', scope => 'local' } );
$c->flatten_ranks();
ok( $c->reading( 'n21p0' ), "New reading exists" );
is( scalar $c->readings, $rno, "Reading add offset by flatten_ranks" );

# Combine n3 and n4 ( with his )
$c->merge_readings( 'n3', 'n4', 1 );
ok( !$c->reading('n4'), "Reading n4 is gone" );
is( $c->reading('n3')->text, 'with his', "Reading n3 has both words" );

# Collapse n9 and n10 ( rood / root )
$c->merge_readings( 'n9', 'n10' );
ok( !$c->reading('n10'), "Reading n10 is gone" );
is( $c->reading('n9')->text, 'rood', "Reading n9 has an unchanged word" );

# Try to combine n21 and n21p0. This should break.
my $remaining = $c->reading('n21');
$remaining ||= $c->reading('n22');  # one of these should still exist
try {
	$c->merge_readings( 'n21p0', $remaining, 1 );
	ok( 0, "Bad reading merge changed the graph" );
} catch( Text::Tradition::Error $e ) {
	like( $e->message, qr/neither concatenated nor collated/, "Expected exception from bad concatenation" );
} catch {
	ok( 0, "Unexpected error on bad reading merge: $@" );
}

try {
	$c->calculate_ranks();
	ok( 1, "Graph is still evidently whole" );
} catch( Text::Tradition::Error $e ) {
	ok( 0, "Caught a rank exception: " . $e->message );
}

# Test right-to-left reading merge.
my $rtl = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Tabular',
    'sep_char' => ',',
    'direction' => 'RL',
    'file'  => 't/data/arabic_snippet.csv'
    );
my $rtlc = $rtl->collation;
is( $rtlc->reading('r8.1')->text, 'سبب', "Got target first reading in RTL text" );
my $pt = $rtlc->path_text('A');
my @path = $rtlc->reading_sequence( $rtlc->start, $rtlc->end, 'A' );
is( $rtlc->reading('r9.1')->text, 'صلاح', "Got target second reading in RTL text" );
$rtlc->merge_readings( 'r8.1', 'r9.1', 1 );
is( $rtlc->reading('r8.1')->text, 'سبب صلاح', "Got target merged reading in RTL text" );
is( $rtlc->path_text('A'), $pt, "Path text is still correct" );
is( scalar($rtlc->reading_sequence( $rtlc->start, $rtlc->end, 'A' )), 
	scalar(@path) - 1, "Path was shortened" );
}



# =begin testing
{
use Test::Warn;
use Text::Tradition;
use TryCatch;

my $t;
warnings_exist {
	$t = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/legendfrag.xml' );
} [qr/Cannot set relationship on a meta reading/],
	"Got expected relationship drop warning on parse";

my $c = $t->collation;
# Force the transitive propagation of all existing relationships.
$c->relations->propagate_all_relationships();

my %rdg_ids;
map { $rdg_ids{$_} = 1 } $c->readings;
$c->merge_related( 'orthographic' );
is( scalar( $c->readings ), keys( %rdg_ids ) - 9, 
	"Successfully collapsed orthographic variation" );
map { $rdg_ids{$_} = undef } qw/ r13.3 r11.4 r8.5 r8.2 r7.7 r7.5 r7.4 r7.3 r7.1 /;
foreach my $rid ( keys %rdg_ids ) {
	my $exp = $rdg_ids{$rid};
	is( !$c->reading( $rid ), !$exp, "Reading $rid correctly " . 
		( $exp ? "retained" : "removed" ) );
}
ok( $c->linear, "Graph is still linear" );
try {
	$c->calculate_ranks; # This should succeed
	ok( 1, "Can still calculate ranks on the new graph" );
} catch {
	ok( 0, "Rank calculation on merged graph failed: $@" );
}

# Now add some transpositions
$c->add_relationship( 'r8.4', 'r10.4', { type => 'transposition' } );
$c->merge_related( 'transposition' );
is( scalar( $c->readings ), keys( %rdg_ids ) - 10, 
	"Transposed relationship is merged away" );
ok( !$c->reading('r8.4'), "Correct transposed reading removed" );
ok( !$c->linear, "Graph is no longer linear" );
try {
	$c->calculate_ranks; # This should fail
	ok( 0, "Rank calculation happened on nonlinear graph?!" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Cannot calculate ranks on a non-linear graph', 
		"Rank calculation on merged graph threw an error" );
}
}



# =begin testing
{
use Text::Tradition;

my $t = Text::Tradition->new( input => 'CollateX', file => 't/data/Collatex-16.xml' );
my $c = $t->collation;
my $n = scalar $c->readings;
$c->compress_readings();
is( scalar $c->readings, $n - 6, "Compressing readings seems to work" );

# Now put in a join-word and make sure the thing still works.
my $t2 = Text::Tradition->new( input => 'CollateX', file => 't/data/Collatex-16.xml' );
my $c2 = $t2->collation;
# Split n21 ('unto') for testing purposes
my $new_r = $c2->add_reading( { 'id' => 'n21p0', 'text' => 'un', 'join_next' => 1 } );
my $old_r = $c2->reading( 'n21' );
$old_r->alter_text( 'to' );
$c2->del_path( 'n20', 'n21', 'A' );
$c2->add_path( 'n20', 'n21p0', 'A' );
$c2->add_path( 'n21p0', 'n21', 'A' );
$c2->calculate_ranks();
is( scalar $c2->readings, $n + 1, "We have our extra test reading" );
$c2->compress_readings();
is( scalar $c2->readings, $n - 6, "Compressing readings also works with join_next" );
is( $c2->reading( 'n21p0' )->text, 'unto', "The joined word has no space" );
}



# =begin testing
{
use Test::More::UTF8;
use Text::Tradition;
use TryCatch;

my $st = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/collatecorr.xml' );
is( ref( $st ), 'Text::Tradition', "Got a tradition from test file" );
ok( $st->has_witness('Ba96'), "Tradition has the affected witness" );

my $sc = $st->collation;
my $numr = 17;
ok( $sc->reading('n131'), "Tradition has the affected reading" );
is( scalar( $sc->readings ), $numr, "There are $numr readings in the graph" );
is( $sc->end->rank, 14, "There are fourteen ranks in the graph" );

# Detach the erroneously collated reading
my( $newr, @del_rdgs ) = $sc->duplicate_reading( 'n131', 'Ba96' );
ok( $newr, "New reading was created" );
ok( $sc->reading('n131_0'), "Detached the bad collation with a new reading" );
is( scalar( $sc->readings ), $numr + 1, "A reading was added to the graph" );
is( $sc->end->rank, 10, "There are now only ten ranks in the graph" );
my $csucc = $sc->common_successor( 'n131', 'n131_0' );
is( $csucc->id, 'n136', "Found correct common successor to duped reading" ); 

# Check that the bad transposition is gone
is( scalar @del_rdgs, 1, "Deleted reading was returned by API call" );
is( $sc->get_relationship( 'n130', 'n135' ), undef, "Bad transposition relationship is gone" );

# The collation should not be fixed
my @pairs = $sc->identical_readings();
is( scalar @pairs, 0, "Not re-collated yet" );
# Fix the collation
ok( $sc->merge_readings( 'n124', 'n131_0' ), "Collated the readings correctly" );
@pairs = $sc->identical_readings( start => 'n124', end => $csucc->id );
is( scalar @pairs, 3, "Found three more identical readings" );
is( $sc->end->rank, 11, "The ranks shifted appropriately" );
$sc->flatten_ranks();
is( scalar( $sc->readings ), $numr - 3, "Now we are collated correctly" );

# Check that we can't "duplicate" a reading with no wits or with all wits
try {
	my( $badr, @del_rdgs ) = $sc->duplicate_reading( 'n124' );
	ok( 0, "Reading duplication without witnesses throws an error" );
} catch( Text::Tradition::Error $e ) {
	like( $e->message, qr/Must specify one or more witnesses/, 
		"Reading duplication without witnesses throws the expected error" );
} catch {
	ok( 0, "Reading duplication without witnesses threw the wrong error" );
}

try {
	my( $badr, @del_rdgs ) = $sc->duplicate_reading( 'n124', 'Ba96', 'Mü11475' );
	ok( 0, "Reading duplication with all witnesses throws an error" );
} catch( Text::Tradition::Error $e ) {
	like( $e->message, qr/Cannot join all witnesses/, 
		"Reading duplication with all witnesses throws the expected error" );
} catch {
	ok( 0, "Reading duplication with all witnesses threw the wrong error" );
}

try {
	$sc->calculate_ranks();
	ok( 1, "Graph is still evidently whole" );
} catch( Text::Tradition::Error $e ) {
	ok( 0, "Caught a rank exception: " . $e->message );
}
}



# =begin testing
{
use File::Which;
use Text::Tradition;
use XML::LibXML;
use XML::LibXML::XPathContext;


SKIP: {
	skip( 'Need Graphviz installed to test graphs', 16 )
		unless File::Which::which( 'dot' );

	my $datafile = 't/data/Collatex-16.xml';

	my $tradition = Text::Tradition->new( 
		'name'  => 'inline', 
		'input' => 'CollateX',
		'file'  => $datafile,
		);
	my $collation = $tradition->collation;

	# Test the svg creation
	my $parser = XML::LibXML->new();
	$parser->load_ext_dtd( 0 );
	my $svg = $parser->parse_string( $collation->as_svg() );
	is( $svg->documentElement->nodeName(), 'svg', 'Got an svg document' );

	# Test for the correct number of nodes in the SVG
	my $svg_xpc = XML::LibXML::XPathContext->new( $svg->documentElement() );
	$svg_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	my @svg_nodes = $svg_xpc->findnodes( '//svg:g[@class="node"]' );
	is( scalar @svg_nodes, 26, "Correct number of nodes in the graph" );

	# Test for the correct number of edges
	my @svg_edges = $svg_xpc->findnodes( '//svg:g[@class="edge"]' );
	is( scalar @svg_edges, 32, "Correct number of edges in the graph" );

	# Test svg creation for a subgraph
	my $part_svg = $parser->parse_string( $collation->as_svg( { from => 15 } ) ); # start, no end
	is( $part_svg->documentElement->nodeName(), 'svg', "Got an svg subgraph to end" );
	my $part_xpc = XML::LibXML::XPathContext->new( $part_svg->documentElement() );
	$part_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	@svg_nodes = $part_xpc->findnodes( '//svg:g[@class="node"]' );
	is( scalar( @svg_nodes ), 9, 
		"Correct number of nodes in the subgraph" );
	@svg_edges = $part_xpc->findnodes( '//svg:g[@class="edge"]' );
	is( scalar( @svg_edges ), 10,
		"Correct number of edges in the subgraph" );

	$part_svg = $parser->parse_string( $collation->as_svg( { from => 10, to => 13 } ) ); # start, no end
	is( $part_svg->documentElement->nodeName(), 'svg', "Got an svg subgraph in the middle" );
	$part_xpc = XML::LibXML::XPathContext->new( $part_svg->documentElement() );
	$part_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	@svg_nodes = $part_xpc->findnodes( '//svg:g[@class="node"]' );
	is( scalar( @svg_nodes ), 9, 
		"Correct number of nodes in the subgraph" );
	@svg_edges = $part_xpc->findnodes( '//svg:g[@class="edge"]' );
	is( scalar( @svg_edges ), 11,
		"Correct number of edges in the subgraph" );


	$part_svg = $parser->parse_string( $collation->as_svg( { to => 5 } ) ); # start, no end
	is( $part_svg->documentElement->nodeName(), 'svg', "Got an svg subgraph from start" );
	$part_xpc = XML::LibXML::XPathContext->new( $part_svg->documentElement() );
	$part_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	@svg_nodes = $part_xpc->findnodes( '//svg:g[@class="node"]' );
	is( scalar( @svg_nodes ), 7, 
		"Correct number of nodes in the subgraph" );
	@svg_edges = $part_xpc->findnodes( '//svg:g[@class="edge"]' );
	is( scalar( @svg_edges ), 7,
		"Correct number of edges in the subgraph" );

	# Test a right-to-left graph
	my $arabic = Text::Tradition->new(
		input => 'Tabular',
		sep_char => ',',
		name => 'arabic',
		direction => 'RL',
		file => 't/data/arabic_snippet.csv' );
	my $rl_svg = $parser->parse_string( $arabic->collation->as_svg() );
	is( $rl_svg->documentElement->nodeName(), 'svg', "Got an svg subgraph from start" );
	my $rl_xpc = XML::LibXML::XPathContext->new( $rl_svg->documentElement() );
	$rl_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	my %node_cx;
	foreach my $node ( $rl_xpc->findnodes( '//svg:g[@class="node"]' ) ) {
		my $nid = $node->getAttribute('id');
		$node_cx{$nid} = $rl_xpc->findvalue( './svg:ellipse/@cx', $node );
	}
	my @sorted = sort { $node_cx{$a} <=> $node_cx{$b} } keys( %node_cx );
	is( $sorted[0], '__END__', "End node is the leftmost" );
	is( $sorted[$#sorted], '__START__', "Start node is the rightmost" );
	
	# Now try making it bidirectional
	$arabic->collation->change_direction('BI');
	my $bi_svg = $parser->parse_string( $arabic->collation->as_svg() );
	is( $bi_svg->documentElement->nodeName(), 'svg', "Got an svg subgraph from start" );
	my $bi_xpc = XML::LibXML::XPathContext->new( $bi_svg->documentElement() );
	$bi_xpc->registerNs( 'svg', 'http://www.w3.org/2000/svg' );
	my %node_cy;
	foreach my $node ( $bi_xpc->findnodes( '//svg:g[@class="node"]' ) ) {
		my $nid = $node->getAttribute('id');
		$node_cy{$nid} = $rl_xpc->findvalue( './svg:ellipse/@cy', $node );
	}
	@sorted = sort { $node_cy{$a} <=> $node_cy{$b} } keys( %node_cy );
	is( $sorted[0], '__START__', "Start node is the topmost" );
	is( $sorted[$#sorted], '__END__', "End node is the bottom-most" );
	

} #SKIP
}



# =begin testing
{
use JSON qw/ from_json /;
use Text::Tradition;

my $t = Text::Tradition->new( 
	'input' => 'Self',
	'file' => 't/data/florilegium_graphml.xml' );
my $c = $t->collation;
	
# Make a connection so we can test rank preservation
$c->add_relationship( 'w91', 'w92', { type => 'grammatical' } );

# Create an adjacency list of the whole thing; test the output.
my $adj_whole = from_json( $c->as_adjacency_list() );
is( scalar @$adj_whole, scalar $c->readings(), 
	"Same number of nodes in graph and adjacency list" );
my @adj_whole_edges;
map { push( @adj_whole_edges, @{$_->{adjacent}} ) } @$adj_whole;
is( scalar @adj_whole_edges, scalar $c->sequence->edges,
	"Same number of edges in graph and adjacency list" );
# Find the reading whose rank should be preserved
my( $test_rdg ) = grep { $_->{id} eq 'w89' } @$adj_whole;
my( $test_edge ) = grep { $_->{id} eq 'w92' } @{$test_rdg->{adjacent}};
is( $test_edge->{minlen}, 2, "Rank of test reading is preserved" );

# Now create an adjacency list of just a portion. w76 to w122
my $adj_part = from_json( $c->as_adjacency_list(
	{ from => $c->reading('w76')->rank,
	  to   => $c->reading('w122')->rank }));
is( scalar @$adj_part, 48, "Correct number of nodes in partial graph" );
my @adj_part_edges;
map { push( @adj_part_edges, @{$_->{adjacent}} ) } @$adj_part;
is( scalar @adj_part_edges, 58,
	"Same number of edges in partial graph and adjacency list" );
# Check for consistency
my %part_nodes;
map { $part_nodes{$_->{id}} = 1 } @$adj_part;
foreach my $edge ( @adj_part_edges ) {
	my $testid = $edge->{id};
	ok( $part_nodes{$testid}, "ID $testid referenced in edge is given as node" );
}
}



# =begin testing
{
use Text::Tradition;
use TryCatch;

my $READINGS = 311;
my $PATHS = 361;

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'test0',
                                      'file' => $datafile,
                                      'linear' => 1 );

ok( $tradition, "Got a tradition object" );
is( scalar $tradition->witnesses, 13, "Found all witnesses" );
ok( $tradition->collation, "Tradition has a collation" );

my $c = $tradition->collation;
is( scalar $c->readings, $READINGS, "Collation has all readings" );
is( scalar $c->paths, $PATHS, "Collation has all paths" );
is( scalar $c->relationships, 0, "Collation has all relationships" );

# Add a few relationships
$c->add_relationship( 'w123', 'w125', { 'type' => 'collated' } );
$c->add_relationship( 'w193', 'w196', { 'type' => 'collated' } );
$c->add_relationship( 'w257', 'w262', { 'type' => 'transposition', 
					  'is_significant' => 'yes' } );

# Now write it to GraphML and parse it again.

my $graphml = $c->as_graphml;
my $st = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml );
is( scalar $st->collation->readings, $READINGS, "Reparsed collation has all readings" );
is( scalar $st->collation->paths, $PATHS, "Reparsed collation has all paths" );
is( scalar $st->collation->relationships, 3, "Reparsed collation has new relationships" );
my $sigrel = $st->collation->get_relationship( 'w257', 'w262' );
is( $sigrel->is_significant, 'yes', "Ternary attribute value was restored" );

# Now add a stemma, write to GraphML, and look at the output.
SKIP: {
	skip "Analysis module not present", 3 unless $tradition->can( 'add_stemma' );
	my $stemma = $tradition->add_stemma( 'dotfile' => 't/data/florilegium.dot' );
	is( ref( $stemma ), 'Text::Tradition::Stemma', "Parsed dotfile into stemma" );
	is( $tradition->stemmata, 1, "Tradition now has the stemma" );
	$graphml = $c->as_graphml;
	like( $graphml, qr/digraph/, "Digraph declaration exists in GraphML" );
}
}



# =begin testing
{
use Text::Tradition;
use Text::CSV;

my $READINGS = 311;
my $PATHS = 361;
my $WITS = 13;
my $WITAC = 4;

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'test0',
                                      'file' => $datafile,
                                      'linear' => 1 );

my $c = $tradition->collation;
# Export the thing to CSV
my $csvstr = $c->as_csv();
# Count the columns
my $csv = Text::CSV->new({ sep_char => ',', binary => 1 });
my @lines = split(/\n/, $csvstr );
ok( $csv->parse( $lines[0] ), "Successfully parsed first line of CSV" );
is( scalar( $csv->fields ), $WITS + $WITAC, "CSV has correct number of witness columns" );
my @q_ac = grep { $_ eq 'Q'.$c->ac_label } $csv->fields;
ok( @q_ac, "Found a layered witness" );

my $t2 = Text::Tradition->new( input => 'Tabular',
							   name => 'test2',
							   string => $csvstr,
							   sep_char => ',' );
is( scalar $t2->collation->readings, $READINGS, "Reparsed CSV collation has all readings" );
is( scalar $t2->collation->paths, $PATHS, "Reparsed CSV collation has all paths" );

# Now do it with TSV
my $tsvstr = $c->as_tsv();
my $t3 = Text::Tradition->new( input => 'Tabular',
							   name => 'test3',
							   string => $tsvstr,
							   sep_char => "\t" );
is( scalar $t3->collation->readings, $READINGS, "Reparsed TSV collation has all readings" );
is( scalar $t3->collation->paths, $PATHS, "Reparsed TSV collation has all paths" );

my $table = $c->alignment_table;
my $noaccsv = $c->as_csv({ noac => 1 });
my @noaclines = split(/\n/, $noaccsv );
ok( $csv->parse( $noaclines[0] ), "Successfully parsed first line of no-ac CSV" );
is( scalar( $csv->fields ), $WITS, "CSV has correct number of witness columns" );
is( $c->alignment_table, $table, "Request for CSV did not alter the alignment table" );

my $safecsv = $c->as_csv({ safe_ac => 1});
my @safelines = split(/\n/, $safecsv );
ok( $csv->parse( $safelines[0] ), "Successfully parsed first line of safe CSV" );
is( scalar( $csv->fields ), $WITS + $WITAC, "CSV has correct number of witness columns" );
@q_ac = grep { $_ eq 'Q__L' } $csv->fields;
ok( @q_ac, "Found a sanitized layered witness" );
is( $c->alignment_table, $table, "Request for CSV did not alter the alignment table" );

# Test relationship collapse
$c->add_relationship( $c->readings_at_rank( 37 ), { type => 'spelling' } );
$c->add_relationship( $c->readings_at_rank( 60 ), { type => 'spelling' } );

my $mergedtsv = $c->as_tsv({mergetypes => [ 'spelling', 'orthographic' ] });
my $t4 = Text::Tradition->new( input => 'Tabular',
							   name => 'test4',
							   string => $mergedtsv,
							   sep_char => "\t" );
is( scalar $t4->collation->readings, $READINGS - 2, "Reparsed TSV merge collation has fewer readings" );
is( scalar $t4->collation->paths, $PATHS - 4, "Reparsed TSV merge collation has fewer paths" );

# Test non-ASCII sigla
my $t5 = Text::Tradition->new( input => 'Tabular',
							   name => 'nonascii',
							   file => 't/data/armexample.xlsx',
							   excel => 'xlsx' );
my $awittsv = $t5->collation->as_tsv({ noac => 1, ascii => 1 });
my @awitlines = split( /\n/, $awittsv );
like( $awitlines[0], qr/_A_5315622/, "Found ASCII sigil variant in TSV" );
}



# =begin testing
{
use Text::Tradition;

my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );
my $c = $t->collation;

# Make an svg
my $table = $c->alignment_table;
ok( $c->has_cached_table, "Alignment table was cached" );
is( $c->alignment_table, $table, "Cached table returned upon second call" );
$c->calculate_ranks;
is( $c->alignment_table, $table, "Cached table retained with no rank change" );
$c->add_relationship( 'n13', 'n23', { type => 'repetition' } );
is( $c->alignment_table, $table, "Alignment table unchanged after non-colo relationship add" );
$c->add_relationship( 'n24', 'n23', { type => 'spelling' } );
isnt( $c->alignment_table, $table, "Alignment table changed after colo relationship add" );
}



# =begin testing
{
use Text::Tradition;

my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );
my $c = $t->collation;

my @common = $c->calculate_common_readings();
is( scalar @common, 8, "Found correct number of common readings" );
my @marked = sort $c->common_readings();
is( scalar @common, 8, "All common readings got marked as such" );
my @expected = qw/ n1 n11 n16 n19 n20 n5 n6 n7 /;
is_deeply( \@marked, \@expected, "Found correct list of common readings" );
}



# =begin testing
{
use Text::Tradition;

my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );
my $c = $t->collation;

is( $c->common_predecessor( 'n24', 'n23' )->id, 
    'n20', "Found correct common predecessor" );
is( $c->common_successor( 'n24', 'n23' )->id, 
    '__END__', "Found correct common successor" );

is( $c->common_predecessor( 'n19', 'n17' )->id, 
    'n16', "Found correct common predecessor for readings on same path" );
is( $c->common_successor( 'n21', 'n10' )->id, 
    '__END__', "Found correct common successor for readings on same path" );
}




1;
