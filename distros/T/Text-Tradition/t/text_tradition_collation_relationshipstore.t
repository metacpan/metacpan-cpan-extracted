#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Text::Tradition;
use TryCatch;

use_ok( 'Text::Tradition::Collation::RelationshipStore' );

# Add some relationships, and delete them

my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
	'name'  => 'inline', 
	'input' => 'CollateX',
	'file'  => $cxfile,
	);
my $c = $t->collation;

my @v1 = $c->add_relationship( 'n21', 'n22', { 'type' => 'lexical' } );
is( scalar @v1, 1, "Added a single relationship" );
is( $v1[0]->[0], 'n21', "Got correct node 1" );
is( $v1[0]->[1], 'n22', "Got correct node 2" );
my @v2 = $c->add_relationship( 'n24', 'n23', 
	{ 'type' => 'spelling', 'scope' => 'global' } );
is( scalar @v2, 2, "Added a global relationship with two instances" );
@v1 = $c->del_relationship( 'n22', 'n21' );
is( scalar @v1, 1, "Deleted first relationship" );
@v2 = $c->del_relationship( 'n12', 'n13', 1 );
is( scalar @v2, 2, "Deleted second global relationship" );
my @v3 = $c->del_relationship( 'n1', 'n2' );
is( scalar @v3, 0, "Nothing deleted on non-existent relationship" );
my @v4 = $c->add_relationship( 'n24', 'n23', 
    { 'type' => 'spelling', 'scope' => 'global' } );
is( @v4, 2, "Re-added global relationship" );
@v4 = $c->del_relationship( 'n12', 'n13' );
is( @v4, 1, "Only specified relationship deleted this time" );
ok( $c->get_relationship( 'n24', 'n23' ), "Other globally-added relationship exists" );
}



# =begin testing
{
use Test::Warn;
use Text::Tradition;
use TryCatch;

my $t1;
warnings_exist {
	$t1 = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/legendfrag.xml' );
} [qr/Cannot set relationship on a meta reading/],
	"Got expected relationship drop warning on parse";

# Test 1.1: try to equate nodes that are prevented with an intermediate collation
ok( $t1, "Parsed test fragment file" );
my $c1 = $t1->collation;
my $trel = $c1->get_relationship( 'r9.2', 'r9.3' );
is( ref( $trel ), 'Text::Tradition::Collation::Relationship',
	"Troublesome relationship exists" );
is( $trel->type, 'collated', "Troublesome relationship is a collation" );

# Try to make the link we want
try {
	$c1->add_relationship( 'r8.6', 'r10.3', { 'type' => 'orthographic' } );
	ok( 1, "Added cross-collation relationship as expected" );
} catch( Text::Tradition::Error $e ) {
	ok( 0, "Existing collation blocked equivalence relationship: " . $e->message );
}

try {
	$c1->calculate_ranks();
	ok( 1, "Successfully calculated ranks" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Collation now has a cycle: " . $e->message );
}

# Test 1.2: attempt merge of an identical reading
try {
	$c1->merge_readings( 'r9.3', 'r11.5' );
	ok( 1, "Successfully merged reading 'pontifex'" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Merge of mergeable readings failed: $e->message" );
	
}

# Test 1.3: attempt relationship with a meta reading (should fail)
try {
	$c1->add_relationship( 'r8.1', 'r9.2', { 'type' => 'collated' } );
	ok( 0, "Allowed a meta-reading to be used in a relationship" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Cannot set relationship on a meta reading', 
		"Relationship link prevented for a meta reading" );
}

# Test 1.4: try to break a relationship near a meta reading
$c1->add_relationship( 'r7.6', 'r7.3', { type => 'orthographic' } );
try {
	$c1->del_relationship( 'r7.6', 'r7.7' );
	$c1->del_relationship( 'r7.6', 'r7.3' );
	ok( 1, "Relationship broken with a meta reading as neighbor" );
} catch {
	ok( 0, "Relationship deletion failed with a meta reading as neighbor" );
}

# Test 2.1: try to equate nodes that are prevented with a real intermediate
# equivalence
my $t2;
warnings_exist {
	$t2 = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/legendfrag.xml' );
} [qr/Cannot set relationship on a meta reading/],
	"Got expected relationship drop warning on parse";
my $c2 = $t2->collation;
$c2->add_relationship( 'r9.2', 'r9.3', { 'type' => 'lexical' } );
my $trel2 = $c2->get_relationship( 'r9.2', 'r9.3' );
is( ref( $trel2 ), 'Text::Tradition::Collation::Relationship',
	"Created blocking relationship" );
is( $trel2->type, 'lexical', "Blocking relationship is not a collation" );
# This time the link ought to fail
try {
	$c2->add_relationship( 'r8.6', 'r10.3', { 'type' => 'orthographic' } );
	ok( 0, "Added cross-equivalent bad relationship" );
} catch ( Text::Tradition::Error $e ) {
	like( $e->message, qr/witness loop/,
		"Existing equivalence blocked crossing relationship" );
}

try {
	$c2->calculate_ranks();
	ok( 1, "Successfully calculated ranks" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Collation now has a cycle: " . $e->message );
}

# Test 3.1: make a straightforward pair of transpositions.
my $t3 = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/lf2.xml' );
# Test 1: try to equate nodes that are prevented with an intermediate collation
my $c3 = $t3->collation;
try {
	$c3->add_relationship( 'r36.4', 'r38.3', { 'type' => 'transposition' } );
	ok( 1, "Added straightforward transposition" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to add normal transposition: " . $e->message );
}
try {
	$c3->add_relationship( 'r36.3', 'r38.2', { 'type' => 'transposition' } );
	ok( 1, "Added straightforward transposition complement" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to add normal transposition complement: " . $e->message );
}

# Test 3.2: try to make a transposition that could be a parallel.
try {
	$c3->add_relationship( 'r28.2', 'r29.2', { 'type' => 'transposition' } );
	ok( 0, "Added bad colocated transposition" );
} catch ( Text::Tradition::Error $e ) {
	like( $e->message, qr/Readings appear to be colocated/,
		"Prevented bad colocated transposition" );
}

# Test 3.3: make the parallel, and then make the transposition again.
try {
	$c3->add_relationship( 'r28.3', 'r29.3', { 'type' => 'orthographic' } );
	ok( 1, "Equated identical readings for transposition" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to equate identical readings: " . $e->message );
}
try {
	$c3->add_relationship( 'r28.2', 'r29.2', { 'type' => 'transposition' } );
	ok( 1, "Added straightforward transposition complement" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to add normal transposition complement: " . $e->message );
}

# Test 4: make a global relationship that involves re-ranking a node first, when 
# the prior rank has a potential match too
my $t4 = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/globalrel_test.xml' );
my $c4 = $t4->collation;
# Can we even add the relationship?
try {
	$c4->add_relationship( 'r463.2', 'r463.4', 
		{ type => 'orthographic', scope => 'global' } );
	ok( 1, "Added global relationship without error" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to add global relationship when same-rank alternative exists: "
		. $e->message );
}
$c4->calculate_ranks();
# Do our readings now share a rank?
is( $c4->reading('r463.2')->rank, $c4->reading('r463.4')->rank, 
	"Expected readings now at same rank" );
	
# Test group 5: relationship transitivity.
my $t5 = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/john.xml' );
my $c5 = $t5->collation;
# Test 5.0: propagate all existing transitive rels and make sure it succeeds
my $orignumrels = scalar $c5->relationships();
try {
	$c5->relations->propagate_all_relationships();
	ok( 1, "Propagated all existing transitive relationships" );
} catch ( Text::Tradition::Error $err ) {
	ok( 0, "Failed to propagate all existing relationships: " . $err->message );
}
ok( scalar( $c5->relationships ) > $orignumrels, "Added some relationships in propagation" );

# Test 5.1: make a grammatical link to an orthographically-linked reading
$c5->add_relationship( 'r13.5', 'r13.2', { type => 'orthographic' } );
$c5->add_relationship( 'r13.1', 'r13.2', { type => 'grammatical', propagate => 1 } );
my $impliedrel = $c5->get_relationship( 'r13.1', 'r13.5' );
ok( $impliedrel, 'Relationship was made between indirectly linked readings' );
if( $impliedrel ) {
	is( $impliedrel->type, 'grammatical', 'Implicit inbound relationship has the correct type' );
}

# Test 5.2: make another orthographic link, see if the grammatical one propagates
$c5->add_relationship( 'r13.3', 'r13.5', { type => 'orthographic', propagate => 1 } );
foreach my $rdg ( qw/ r13.3 r13.5 / ) {
	my $newgram = $c5->get_relationship( 'r13.1', $rdg );
	ok( $newgram, 'Relationship was propagaged up between indirectly linked readings' );
	if( $newgram ) {
		is( $newgram->type, 'grammatical', 'Implicit outbound relationship has the correct type' );
	}
}
my $neworth = $c5->get_relationship( 'r13.2', 'r13.3' );
ok( $neworth, 'Relationship was made between indirectly linked siblings' );
if( $neworth ) {
	is( $neworth->type, 'orthographic', 'Implicit direct relationship has the correct type' );
}

# Test 5.3: make an intermediate (spelling) link to the remaining node
$c5->add_relationship( 'r13.4', 'r13.2', { type => 'spelling', propagate => 1 } );
# Should be linked grammatically to 12.1, spelling-wise to the rest
my $newgram = $c5->get_relationship( 'r13.4', 'r13.1' );
ok( $newgram, 'Relationship was made between indirectly linked readings' );
if( $newgram ) {
	is( $newgram->type, 'grammatical', 'Implicit intermediate-out relationship has the correct type' );
}
foreach my $rdg ( qw/ r13.3 r13.5 / ) {
	my $newspel = $c5->get_relationship( 'r13.4', $rdg );
	ok( $newspel, 'Relationship was made between indirectly linked readings' );
	if( $newspel ) {
		is( $newspel->type, 'spelling', 'Implicit intermediate-in relationship has the correct type' );
	}
}

# Test 5.4: delete a spelling relationship, add it again, make sure it doesn't 
# throw and make sure all the relationships are the same
my $numrel = scalar $c5->relationships;
$c5->del_relationship( 'r13.4', 'r13.2' );
try {
	$c5->add_relationship( 'r13.4', 'r13.2', { type => 'spelling', propagate => 1 } );
	ok( 1, "Managed not to throw an exception re-adding the relationship" );
} catch( Text::Tradition::Error $e ) {
	ok( 0, "Threw an exception trying to re-add our intermediate relationship: " . $e->message );
}
is( $numrel, scalar $c5->relationships, "Number of relationships did not change" );
foreach my $rdg ( qw/ r13.2 r13.3 r13.5 / ) {
	my $newspel = $c5->get_relationship( 'r13.4', $rdg );
	ok( $newspel, 'Relationship was made between indirectly linked readings' );
	if( $newspel ) {
		is( $newspel->type, 'spelling', 'Reinstated intermediate-in relationship has the correct type' );
	}
}
my $stillgram = $c5->get_relationship( 'r13.4', 'r13.1' );
ok( $stillgram, 'Relationship was made between indirectly linked readings' );
if( $stillgram ) {
	is( $stillgram->type, 'grammatical', 'Reinstated intermediate-out relationship has the correct type' );
}

# Test 5.5: add a parallel but not sibling relationship
$c5->add_relationship( 'r13.6', 'r13.2', { type => 'lexical', propagate => 1 } );
ok( !$c5->get_relationship( 'r13.6', 'r13.1' ), 
	"Lexical relationship did not affect grammatical" );
foreach my $rdg ( qw/ r13.3 r13.4 r13.5 / ) {
	my $newlex = $c5->get_relationship( 'r13.6', $rdg );
	ok( $newlex, 'Parallel was made between indirectly linked readings' );
	if( $newlex ) {
		is( $newlex->type, 'lexical', 'Implicit parallel-down relationship has the correct type' );
	}
}

# Test 5.6: try it with non-colocated relationships
$numrel = scalar $c5->relationships;
$c5->add_relationship( 'r62.1', 'r64.1', { type => 'transposition', propagate => 1 } );
is( scalar $c5->relationships, $numrel+1, 
	"Adding non-colo relationship did not propagate" );
# Add a pivot point
$c5->add_relationship( 'r61.1', 'r61.5', { type => 'orthographic' } );
# Add a third transposed node
$c5->add_relationship( 'r62.1', 'r60.3', { type => 'transposition', propagate => 1 } );
my $newtrans = $c5->get_relationship( 'r64.1', 'r60.3' );
ok( $newtrans, 'Non-colo relationship was made between indirectly linked readings' );
if( $newtrans ) {
	is( $newtrans->type, 'transposition', 'Implicit non-colo relationship has the correct type' );
}
is( scalar $c5->relationships, $numrel+4, 
	"Adding non-colo relationship only propagated on non-colos" );

# Test 5.7: ensure that attempts to cross boundaries on bindlevel-equal 
# relationships fail.
try {
	$c5->add_relationship( 'r39.6', 'r41.1', { type => 'grammatical', propagate => 1 } );
	ok( 0, "Did not prevent add of conflicting relationship level" );
} catch( Text::Tradition::Error $err ) {
	like( $err->message, qr/Conflicting existing relationship/, "Got correct error message trying to add conflicting relationship level" );
}

# Test 5.8: ensure that weak relationships don't interfere
$c5->add_relationship( 'r50.1', 'r50.2', { type => 'collated' } );
$c5->add_relationship( 'r50.3', 'r50.4', { type => 'orthographic' } );
try {
	$c5->add_relationship( 'r50.4', 'r50.1', { type => 'grammatical', propagate => 1 } );
	ok( 1, "Collation did not interfere with new relationship add" );
} catch( Text::Tradition::Error $err ) {
	ok( 0, "Collation interfered with new relationship add: " . $err->message );
}
my $crel = $c5->get_relationship( 'r50.1', 'r50.2' );
ok( $crel, "Original relationship still exists" );
if( $crel ) {
	is( $crel->type, 'collated', "Original relationship still a collation" );
}

try {
	$c5->add_relationship( 'r50.1', 'r51.1', { type => 'spelling', propagate => 1 } );
	ok( 1, "Collation did not interfere with relationship re-ranking" );
} catch( Text::Tradition::Error $err ) {
	ok( 0, "Collation interfered with relationship re-ranking: " . $err->message );
}
$crel = $c5->get_relationship( 'r50.1', 'r50.2' );
ok( !$crel, "Collation relationship now gone" );

# Test 5.9: ensure that strong non-transitive relationships don't interfere
$c5->add_relationship( 'r66.1', 'r66.4', { type => 'grammatical' } );
$c5->add_relationship( 'r66.2', 'r66.4', { type => 'uncertain', propagate => 1 } );
try {
	$c5->add_relationship( 'r66.1', 'r66.3', { type => 'grammatical', propagate => 1 } );
	ok( 1, "Non-transitive relationship did not block grammatical add" );
} catch( Text::Tradition::Error $err ) {
	ok( 0, "Non-transitive relationship blocked grammatical add: " . $err->message );
}
is( scalar $c5->related_readings( 'r66.4' ), 3, "Reading 66.4 has all its links" );
is( scalar $c5->related_readings( 'r66.2' ), 1, "Reading 66.2 has only one link" );
is( scalar $c5->related_readings( 'r66.1' ), 2, "Reading 66.1 has all its links" );
is( scalar $c5->related_readings( 'r66.3' ), 2, "Reading 66.3 has all its links" );
}




1;
