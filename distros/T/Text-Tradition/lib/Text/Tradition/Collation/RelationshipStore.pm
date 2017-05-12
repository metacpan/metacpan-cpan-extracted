package Text::Tradition::Collation::RelationshipStore;

use strict;
use warnings;
use Safe::Isa;
use Text::Tradition::Error;
use Text::Tradition::Collation::Relationship;
use Text::Tradition::Collation::RelationshipType;
use TryCatch;

use Moose;

=head1 NAME

Text::Tradition::Collation::RelationshipStore - Keeps track of the relationships
between readings in a given collation
    
=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  The RelationshipStore is an internal object
of the collation, to keep track of the defined relationships (both specific and
general) between readings.

=begin testing

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

=end testing

=head1 METHODS

=head2 new( collation => $collation );

Creates a new relationship store for the given collation.

=cut

has 'collation' => (
	is => 'ro',
	isa => 'Text::Tradition::Collation',
	required => 1,
	weak_ref => 1,
	);
	
=head2 types 

Registry of possible relationship types. See RelationshipType for more info.

=cut
	
has 'relationship_types' => (
	is => 'ro',
	traits => ['Hash'],
	handles => {
		has_type => 'exists',
		add_type => 'set',
		del_type => 'delete',
		type     => 'get',
		types    => 'values'
		},
	);

has 'scopedrels' => (
	is => 'ro',
	isa => 'HashRef[HashRef[Text::Tradition::Collation::Relationship]]',
	default => sub { {} },
	);

has 'graph' => (
	is => 'ro',
	isa => 'Graph',
	default => sub { Graph->new( undirected => 1 ) },
    handles => {
    	relationships => 'edges',
    	add_reading => 'add_vertex',
    	delete_reading => 'delete_vertex',
    	},
	);
	
=head2 equivalence_graph()

Returns an equivalence graph of the collation, in which all readings
related via a 'colocated' relationship are transformed into a single
vertex. Can be used to determine the validity of a new relationship. 

=cut

has 'equivalence_graph' => (
	is => 'ro',
	isa => 'Graph',
	default => sub { Graph->new() },
	writer => '_reset_equivalence',
	);
	
has '_node_equivalences' => (
	is => 'ro',
	traits => ['Hash'],
	handles => {
		equivalence => 'get',
		set_equivalence => 'set',
		remove_equivalence => 'delete',
		_clear_equivalence => 'clear',
		},
	);

has '_equivalence_readings' => (
	is => 'ro',
	traits => ['Hash'],
	handles => {
		eqreadings => 'get',
		set_eqreadings => 'set',
		remove_eqreadings => 'delete',
		_clear_eqreadings => 'clear',
		},
	);
	
## Build function - here we have our default set of relationship types.

sub BUILD {
	my $self = shift;
	
	my @DEFAULT_TYPES = (
		{ name => 'collated', bindlevel => 50, is_weak => 1, is_transitive => 0, 
			is_generalizable => 0, description => 'Internal use only' },
		{ name => 'orthographic', bindlevel => 0, use_regular => 0,
			description => 'These are the same reading, neither unusually spelled.' },
		{ name => 'punctuation', bindlevel => 0,
			description => 'These are the same reading apart from punctuation.' },
		{ name => 'spelling', bindlevel => 1,
			description => 'These are the same reading, spelled differently.' },
		{ name => 'grammatical', bindlevel => 2,
			description => 'These readings share a root (lemma), but have different parts of speech (morphologies).' },
		{ name => 'lexical', bindlevel => 2,
			description => 'These readings share a part of speech (morphology), but have different roots (lemmata).' },
		{ name => 'uncertain', bindlevel => 0, is_transitive => 0, is_generalizable => 0,
			use_regular => 0, description => 'These readings are related, but a clear category cannot be assigned.' },
		{ name => 'other', bindlevel => 0, is_transitive => 0, is_generalizable => 0,
			description => 'These readings are related in a way not covered by the existing types.' },
		{ name => 'transposition', bindlevel => 50, is_colocation => 0,
			description => 'This is the same (or nearly the same) reading in a different location.' },
		{ name => 'repetition', bindlevel => 50, is_colocation => 0, is_transitive => 0,
			description => 'This is a reading that was repeated in one or more witnesses.' }
		);
	
	foreach my $type ( @DEFAULT_TYPES ) {
		$self->add_type( $type );
	}
}

around add_type => sub {
    my $orig = shift;
    my $self = shift;
    my $new_type;
    if( @_ == 1 && $_[0]->$_isa( 'Text::Tradition::Collation::RelationshipType' ) ) {
    	$new_type = shift;
    } else {
   		my %args = @_ == 1 ? %{$_[0]} : @_;
		$new_type = Text::Tradition::Collation::RelationshipType->new( %args );
	}
    $self->$orig( $new_type->name => $new_type );
    return $new_type;
};
	
around add_reading => sub {
	my $orig = shift;
	my $self = shift;
	
	$self->equivalence_graph->add_vertex( @_ );
	$self->set_equivalence( $_[0], $_[0] );
	$self->set_eqreadings( $_[0], [ $_[0] ] );
	$self->$orig( @_ );
};

around delete_reading => sub {
	my $orig = shift;
	my $self = shift;
	
	$self->_remove_equivalence_node( @_ );
	$self->$orig( @_ );
};

=head2 get_relationship

Return the relationship object, if any, that exists between two readings.

=cut

sub get_relationship {
	my $self = shift;
	my @vector;
	if( @_ == 1 && ref( $_[0] ) eq 'ARRAY' ) {
		# Dereference the edge arrayref that was passed.
		my $edge = shift;
		@vector = @$edge;
	} else {
		@vector = @_[0,1];
	}
	my $relationship;
	if( $self->graph->has_edge_attribute( @vector, 'object' ) ) {
		$relationship = $self->graph->get_edge_attribute( @vector, 'object' );
	} 
	return $relationship;
}

sub _set_relationship {
	my( $self, $relationship, @vector ) = @_;
	$self->graph->add_edge( @vector );
	$self->graph->set_edge_attribute( @vector, 'object', $relationship );
	$self->_make_equivalence( @vector ) if $relationship->colocated;
}

=head2 create

Create a new relationship with the given options and return it.
Warn and return undef if the relationship cannot be created.

=cut

sub create {
	my( $self, $options ) = @_;
	# Check to see if a relationship exists between the two given readings
	my $source = delete $options->{'orig_a'};
	my $target = delete $options->{'orig_b'};
	my $rel = $self->get_relationship( $source, $target );
	if( $rel ) {
		if( $self->type( $rel->type )->is_weak ) {
			# Always replace a weak relationship with a more descriptive
			# one, if asked.
			$self->del_relationship( $source, $target );
		} elsif( $rel->type ne $options->{'type'} ) {
			throw( "Another relationship of type " . $rel->type 
				. " already exists between $source and $target" );
		} else {
			return $rel;
		}
	}
	
	$rel = Text::Tradition::Collation::Relationship->new( $options );
	my $reltype = $self->type( $rel->type );
	throw( "Unrecognized relationship type " . $rel->type ) unless $reltype;
	# Validate the options given against the relationship type wanted
	throw( "Cannot set nonlocal scope on relationship of type " . $reltype->name )
		if $rel->nonlocal && !$reltype->is_generalizable;
	
	$self->add_scoped_relationship( $rel ) if $rel->nonlocal;
	return $rel;
}

=head2 add_scoped_relationship( $rel )

Keep track of relationships defined between specific readings that are scoped
non-locally.  Key on whichever reading occurs first alphabetically.

=cut

sub add_scoped_relationship {
	my( $self, $rel ) = @_;
	my $rdga = $rel->reading_a;
	my $rdgb = $rel->reading_b;	
	my $r = $self->scoped_relationship( $rdga, $rdgb );
	if( $r ) {
		warn sprintf( "Scoped relationship of type %s already exists between %s and %s",
			$r->type, $rdga, $rdgb );
		return;
	}
	my( $first, $second ) = sort ( $rdga, $rdgb );
	$self->scopedrels->{$first}->{$second} = $rel;
}

=head2 scoped_relationship( $reading_a, $reading_b )

Returns the general (document-level or global) relationship that has been defined 
between the two reading strings. Returns undef if there is no general relationship.

=cut

sub scoped_relationship {
	my( $self, $rdga, $rdgb ) = @_;
	my( $first, $second ) = sort( $rdga, $rdgb );
	if( exists $self->scopedrels->{$first}->{$second} ) {
		return $self->scopedrels->{$first}->{$second};
	} 
	return undef;
}

=head2 add_relationship( $self, $source, $sourcetext, $target, $targettext, $opts )

Adds the relationship specified in $opts (see Text::Tradition::Collation::Relationship 
for the possible options) between the readings given in $source and $target.  Sets
up a scoped relationship between $sourcetext and $targettext if the relationship is
scoped non-locally.

Returns a status boolean and a list of all reading pairs connected by the call to
add_relationship.

=begin testing

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

=end testing

=cut

sub add_relationship {
	my( $self, $source, $target, $options ) = @_;
    my $c = $self->collation;
	my $sourceobj = $c->reading( $source );
	my $targetobj = $c->reading( $target );
	throw( "Adding self relationship at $source" ) if $source eq $target;
	throw( "Cannot set relationship on a meta reading" )
		if( $sourceobj->is_meta || $targetobj->is_meta );
	my $relationship;
	my $reltype;
	my $thispaironly = delete $options->{thispaironly};
	my $propagate = delete $options->{propagate};
	my $droppedcolls = [];
	if( ref( $options ) eq 'Text::Tradition::Collation::Relationship' ) {
		$relationship = $options;
		$reltype = $self->type( $relationship->type );
		$thispaironly = 1;  # If existing rel, set only where asked.
		# Test the validity
		my( $is_valid, $reason ) = $self->relationship_valid( $source, $target, 
			$relationship->type, $droppedcolls );
		unless( $is_valid ) {
			throw( "Invalid relationship: $reason" );
		}
	} else {
		$reltype = $self->type( $options->{type} );
		
		# Try to create the relationship object.
		my $rdga = $reltype->regularize( $sourceobj );
		my $rdgb = $reltype->regularize( $targetobj );
		$options->{'orig_a'} = $sourceobj;
		$options->{'orig_b'} = $targetobj;
		$options->{'reading_a'} = $rdga;
		$options->{'reading_b'} = $rdgb;
    	if( exists $options->{'scope'} && $options->{'scope'} ne 'local' ) {
			# Is there a relationship with this a & b already?
			if( $rdga eq $rdgb ) {
				# If we have canonified to the same thing for the relationship
				# type we want, something is wrong.
				# NOTE we want to allow this at the local level, as a cheap means
				# of merging readings in the UI, until we get a better means.
				throw( "Canonifier returns identical form $rdga for this relationship type" );
			}
			
			my $otherrel = $self->scoped_relationship( $rdga, $rdgb );
			if( $otherrel && $otherrel->type eq $options->{type}
				&& $otherrel->scope eq $options->{scope} ) {
				# warn "Applying existing scoped relationship for $rdga / $rdgb";
				$relationship = $otherrel;
			} elsif( $otherrel ) {
				throw( 'Conflicting scoped relationship ' 
					. join( '/', $otherrel->type, $otherrel->scope ) . ' vs. ' 
					. join( '/', $options->{type}, $options->{scope} ) 
					. " for $rdga / $rdgb at $source / $target" );
			}
    	}
		$relationship = $self->create( $options ) unless $relationship;  
		# ... Will throw on error

		# See if the relationship is actually valid here
		my( $is_valid, $reason ) = $self->relationship_valid( $source, $target, 
			$options->{'type'}, $droppedcolls );
		unless( $is_valid ) {
			throw( "Invalid relationship: $reason" );
		}
    }


    # Now set the relationship(s).
    my @pairs_set;
	my $rel = $self->get_relationship( $source, $target );
	my $skip;
	if( $rel && $rel ne $relationship ) {
		if( $rel->nonlocal ) {
			throw( "Found conflicting relationship at $source - $target" );
		} elsif( !$reltype->is_weak ) {
			# Replace a weak relationship; leave any other sort in place.
			my $r1ann = $rel->has_annotation ? $rel->annotation : '';
			my $r2ann = $relationship->has_annotation ? $relationship->annotation : '';
			unless( $rel->type eq $relationship->type && $r1ann eq $r2ann ) {
				warn sprintf( "Not overriding local relationship %s with global %s " 
					. "set at %s -> %s (%s -> %s)", $rel->type, $relationship->type,
					$source, $target, $rel->reading_a, $rel->reading_b );
			}
			$skip = 1;
		}
	}
	$self->_set_relationship( $relationship, $source, $target ) unless $skip;
	push( @pairs_set, [ $source, $target, $relationship->type ] );
    
	# Find all the pairs for which we need to set the relationship.
    if( $relationship->colocated && $relationship->nonlocal && !$thispaironly ) {
    	my @global_set = $self->add_global_relationship( $relationship );
		push( @pairs_set, @global_set );
    }
    if( $propagate ) {
		my @prop;
    	foreach my $ps ( @pairs_set ) {
    		my @extra = $self->propagate_relationship( $ps->[0], $ps->[1] );
    		push( @prop, @extra );
    	}
    	push( @pairs_set, @prop ) if @prop;
    }
    	
    # Finally, restore whatever collations we can, and return.
    $self->_restore_weak( @$droppedcolls );
    return @pairs_set;
}

=head2 add_global_relationship( $options, $skipvector )

Adds the relationship specified wherever the relevant readings appear together 
in the graph.  Options as in add_relationship above. 

=cut

sub add_global_relationship {
	my( $self, $relationship ) = @_;
	# Sanity checking
	my $reltype = $self->type( $relationship->type );
	throw( "Relationship passed to add_global is not global" )
		unless $relationship->nonlocal;
	throw( "Relationship passed to add_global is not a valid global type" )
		unless $reltype->is_generalizable;
		
	# Apply the relationship wherever it is valid
	my @pairs_set;
    foreach my $v ( $self->_find_applicable( $relationship ) ) {
    	my $exists = $self->get_relationship( @$v );
    	my $etype = $exists ? $self->type( $exists->type ) : '';
    	if( $exists && !$etype->is_weak ) {
			unless( $exists->is_equivalent( $relationship ) ) {
	    		throw( "Found conflicting relationship at @$v" );
	    	}
    	} else {
    		my @added;
    		try {
		    	@added = $self->add_relationship( @$v, $relationship );
		    } catch {
		    	my $reldesc = sprintf( "%s %s -> %s", $relationship->type,
		    		$relationship->reading_a, $relationship->reading_b );
		    	# print STDERR "Global relationship $reldesc not applicable at @$v\n";
		    }
    		push( @pairs_set, @added ) if @added;
    	}
    }
	return @pairs_set;	
}


=head2 del_scoped_relationship( $reading_a, $reading_b )

Returns the general (document-level or global) relationship that has been defined 
between the two reading strings. Returns undef if there is no general relationship.

=cut

sub del_scoped_relationship {
	my( $self, $rdga, $rdgb ) = @_;
	my( $first, $second ) = sort( $rdga, $rdgb );
	return delete $self->scopedrels->{$first}->{$second};
}

sub _find_applicable {
	my( $self, $rel ) = @_;
	my $c = $self->collation;
	my $reltype = $self->type( $rel->type );
	my @vectors;
	my @identical_readings;
	@identical_readings = grep { $reltype->regularize( $_ ) eq $rel->reading_a } 
		$c->readings;
	foreach my $ir ( @identical_readings ) {
		my @itarget;
		@itarget = grep { $reltype->regularize( $_ ) eq $rel->reading_b } 
			$c->readings_at_rank( $ir->rank );
		if( @itarget ) {
			# Warn if there is more than one hit with no closer link between them.
			my $itmain = shift @itarget;
			if( @itarget ) {
				my %all_targets;
				my $bindlevel = $reltype->bindlevel;
				map { $all_targets{$_} = 1 } @itarget;
				map { delete $all_targets{$_} } 
					$self->related_readings( $itmain, sub { 
						$self->type( $_[0]->type )->bindlevel < $bindlevel } );
    			warn "More than one unrelated reading with text " . $itmain->text
    				. " at rank " . $ir->rank . "!" if keys %all_targets;
			}
			push( @vectors, [ $ir->id, $itmain->id ] );
		}
	}
	return @vectors;
}

=head2 del_relationship( $source, $target, $allscope )

Removes the relationship between the given readings. If the relationship is
non-local and $allscope is true, removes the relationship throughout the 
relevant scope.

=cut

sub del_relationship {
	my( $self, $source, $target, $allscope ) = @_;
	my $rel = $self->get_relationship( $source, $target );
	return () unless $rel; # Nothing to delete; return an empty set.
	my $reltype = $self->type( $rel->type );
	my $colo = $rel->colocated;
	my @vectors = ( [ $source, $target ] );
	$self->_remove_relationship( $colo, $source, $target );
	if( $rel->nonlocal && $allscope ) {
		# Remove the relationship wherever it occurs.
		my @rel_edges = grep { $self->get_relationship( @$_ ) eq $rel }
			$self->relationships;
		foreach my $re ( @rel_edges ) {
			$self->_remove_relationship( $colo, @$re );
			push( @vectors, $re );
		}
		$self->del_scoped_relationship( $rel->reading_a, $rel->reading_b );
	}
	return @vectors;
}

sub _remove_relationship {
	my( $self, $equiv, @vector ) = @_;
	$self->graph->delete_edge( @vector );
	$self->_break_equivalence( @vector ) if $equiv;
}
	
=head2 relationship_valid( $source, $target, $type )

Checks whether a relationship of type $type may exist between the readings given
in $source and $target.  Returns a tuple of ( status, message ) where status is
a yes/no boolean and, if the answer is no, message gives the reason why.

=cut

sub relationship_valid {
    my( $self, $source, $target, $rel, $mustdrop ) = @_;
    $mustdrop = [] unless $mustdrop; # in case we were passed nothing
    my $c = $self->collation;
    my $reltype = $self->type( $rel );
    ## Assume validity is okay if we are initializing from scratch.
    return ( 1, "initializing" ) unless $c->tradition->_initialized;
    ## TODO Move this block to relationship type definition when we can save
    ## coderefs
    if ( $rel eq 'transposition' || $rel eq 'repetition' ) {
		# Check that the two readings do (for a repetition) or do not (for
		# a transposition) appear in the same witness.
		# TODO this might be called before witness paths are set...
		my %seen_wits;
		map { $seen_wits{$_} = 1 } $c->reading_witnesses( $source );
		foreach my $w ( $c->reading_witnesses( $target ) ) {
			if( $seen_wits{$w} ) {
				return ( 0, "Readings both occur in witness $w" ) 
					if $rel eq 'transposition';
				return ( 1, "ok" ) if $rel eq 'repetition';
			}
		}
		return ( 0, "Readings occur only in distinct witnesses" )
			if $rel eq 'repetition';
	} 
	if ( $reltype->is_colocation ) {
		# Check that linking the source and target in a relationship won't lead
		# to a path loop for any witness. 
		# First, drop/stash any collations that might interfere
		my $sourceobj = $c->reading( $source );
		my $targetobj = $c->reading( $target );
		my $sourcerank = $sourceobj->has_rank ? $sourceobj->rank : -1;
		my $targetrank = $targetobj->has_rank ? $targetobj->rank : -1;
		unless( $rel eq 'collated' || $sourcerank == $targetrank ) {
			push( @$mustdrop, $self->_drop_weak( $source ) );
			push( @$mustdrop, $self->_drop_weak( $target ) );
			if( $c->end->has_rank ) {
				foreach my $rk ( $sourcerank .. $targetrank ) {
					map { push( @$mustdrop, $self->_drop_weak( $_->id ) ) }
						$c->readings_at_rank( $rk );
				}
			}
		}
		unless( $self->test_equivalence( $source, $target ) ) {
			$self->_restore_weak( @$mustdrop );
			return( 0, "Relationship would create witness loop" );
		}
		return ( 1, "ok" );
	} else {
		# We also need to check that the readings are not in the same place. 
		# That is, proposing to equate them should cause a witness loop.
		if( $self->test_equivalence( $source, $target ) ) {
			return ( 0, "Readings appear to be colocated" );
		} else {
			return ( 1, "ok" );
		}
	}
}

sub _drop_weak {
	my( $self, $reading ) = @_;
	my @dropped;
	foreach my $n ( $self->graph->neighbors( $reading ) ) {
		my $nrel = $self->get_relationship( $reading, $n );
		if( $self->type( $nrel->type )->is_weak ) {
			push( @dropped, [ $reading, $n, $nrel->type ] );
			$self->del_relationship( $reading, $n );
			#print STDERR "Dropped weak relationship $reading -> $n\n";
		}
	}
	return @dropped;
}

sub _restore_weak {
	my( $self, @vectors ) = @_;
	foreach my $v ( @vectors ) {
		my $type = pop @$v;
		eval {
			$self->add_relationship( @$v, { 'type' => $type } );
			#print STDERR "Restored weak relationship @$v\n";
		}; # if it fails we don't care
	}
}

=head2 verify_or_delete( $reading1, $reading2 ) {

Given the existing relationship at ( $reading1, $reading2 ), make sure it is
still valid. If it is not still valid, delete it. Use this only to check
non-colocated relationships!

=cut

sub verify_or_delete {
	my( $self, @vector ) = @_;
	my $rel = $self->get_relationship( @vector );
	throw( "You should not now be verifying colocated relationships!" )
		if $rel->colocated;
	my( $ok, $reason ) = $self->relationship_valid( @vector, $rel->type );
	unless( $ok ) {
		$self->del_relationship( @vector );
	}
	return $ok;
}
	

=head2 related_readings( $reading, $filter )

Returns a list of readings that are connected via direct relationship links
to $reading. If $filter is set to a subroutine ref, returns only those
related readings where $filter( $relationship ) returns a true value.

=cut

sub related_readings {
	my( $self, $reading, $filter ) = @_;
	my $return_object;
	if( ref( $reading ) eq 'Text::Tradition::Collation::Reading' ) {
		$reading = $reading->id;
		$return_object = 1;
	}
	my @answer;
	if( $filter ) {
		# Backwards compat
		if( $filter eq 'colocated' ) {
			$filter = sub { $_[0]->colocated };
		} elsif( !ref( $filter ) ) {
			my $type = $filter;
			$filter = sub { $_[0]->type eq $type };
		}
		@answer = grep { &$filter( $self->get_relationship( $reading, $_ ) ) }
			$self->graph->neighbors( $reading );
	} else {
		@answer = $self->graph->neighbors( $reading );
	}
	if( $return_object ) {
		my $c = $self->collation;
		return map { $c->reading( $_ ) } @answer;
	} else {
		return @answer;
	}
}

=head2 propagate_relationship( $rel )

Apply the transitivity and binding level rules to propagate the consequences of
the specified relationship link, ensuring all consequent relationships exist.
For now, we only propagate colocation links if we are passed a colocation, and
we only propagate displacement links if we are given a displacement.

Returns an array of tuples ( rdg1, rdg2, type ) for each new reading set.

=cut

sub propagate_relationship {
	my( $self, @rel ) = @_;
	## Check that the vector is an arrayref
	my $rel = @rel > 1 ? \@rel : $rel[0];
	## Get the relationship info
	my $relobj = $self->get_relationship( $rel );
	my $reltype = $self->type( $relobj->type );
	return () unless $reltype->is_transitive;
	my @newly_set;
	
	my $colo = $reltype->is_colocation;
	my $bindlevel = $reltype->bindlevel;
	
	## Find all readings that are linked via this relationship type
	my %thislevel = ( $rel->[0] => 1, $rel->[1] => 1 );
	my $check = $rel;
	my $iter = 0;
	while( @$check ) {
		my $more = [];
		foreach my $r ( @$check ) {
			push( @$more, grep { !exists $thislevel{$_}
				&& $self->get_relationship( $r, $_ )
				&& $self->get_relationship( $r, $_ )->type eq $relobj->type }
					$self->graph->neighbors( $r ) );
		}
		map { $thislevel{$_} = 1 } @$more;
		$check = $more;
	}
	
	## Make sure every reading of our relationship type is linked to every other
	my @samelevel = keys %thislevel;
	while( @samelevel ) {
		my $r = shift @samelevel;
		foreach my $nr ( @samelevel ) {
			my $existing = $self->get_relationship( $r, $nr );
			my $skip;
			if( $existing ) {
				my $extype = $self->type( $existing->type );
				unless( $extype->is_weak ) {
					# Check that it's a matching type, or a type subsumed by our
					# bindlevel
					throw( "Conflicting existing relationship of type "
						. $existing->type . " at $r, $nr trying to propagate "
						. $relobj->type . " relationship at @$rel" )
						unless $existing->type eq $relobj->type
							|| $extype->bindlevel <= $reltype->bindlevel;
					$skip = 1;
				}
			}
			unless( $skip ) {
				# Try to add a new relationship here
				try {
					my @new = $self->add_relationship( $r, $nr, { type => $relobj->type, 
						annotation => "Propagated from relationship at @$rel" } );
					push( @newly_set, @new );
				} catch ( Text::Tradition::Error $e ) {
					throw( "Could not propagate " . $relobj->type . 
						" relationship (original @$rel) at $r -- $nr: " .
						$e->message );
				}
			}
		}

		## Now for each sibling our set, look for its direct connections to 
		## transitive readings of a different bindlevel, and make sure that 
		## all siblings are related to those readings.
		my @other;
		foreach my $n ( $self->graph->neighbors( $r ) ) {
			my $crel = $self->get_relationship( $r, $n );
			next unless $crel;
			my $crt = $self->type( $crel->type );
			if( $crt->is_transitive && $crt->is_colocation == $colo ) {
				next if $crt->bindlevel == $reltype->bindlevel;
				my $nrel = $crt->bindlevel < $reltype->bindlevel 
					? $reltype->name : $crt->name;
				push( @other, [ $n, $nrel ] );
			}
		}
		# The @other array now contains tuples of ( reading, type ) where the
		# reading is the non-sibling and the type is the type of relationship 
		# that the siblings should have to the non-sibling.	
		foreach ( @other ) {
			my( $nr, $nrtype ) = @$_;
			foreach my $sib ( keys %thislevel ) {
				next if $sib eq $r;
				next if $sib eq $nr; # can happen if linked to $r by tightrel
									 # but linked to a sib of $r by thisrel
									 # e.g. when a rel has been part propagated
				my $existing = $self->get_relationship( $sib, $nr );
				my $skip;
				if( $existing ) {
					# Check that it's compatible. The existing relationship type
					# should match or be subsumed by the looser of the two 
					# relationships in play, whether the original relationship 
					# being worked on or the relationship between $r and $or.
					my $extype = $self->type( $existing->type );
					unless( $extype->is_weak ) {
						if( $nrtype ne $extype->name 
							&& $self->type( $nrtype )->bindlevel <= $extype->bindlevel ) {
							throw( "Conflicting existing relationship at $nr ( -> "
								. $self->get_relationship( $nr, $r )->type . " to $r) "
								. " -- $sib trying to propagate " . $relobj->type 
								. " relationship at @$rel" );
						}
						$skip = 1;
					}
				} 
				unless( $skip ) {
					# Try to add a new relationship here
					try {
						my @new = $self->add_relationship( $sib, $nr, { type => $nrtype, 
							annotation => "Propagated from relationship at @$rel" } );
						push( @newly_set, @new );
					} catch ( Text::Tradition::Error $e ) {
						throw( "Could not propagate $nrtype relationship (original " . 
							$relobj->type . " at @$rel) at $sib -- $nr: " .
							$e->message );
					}
				}
			}
		}
	}
	
	return @newly_set;
}

=head2 propagate_all_relationships

Apply propagation logic retroactively to all relationships in the tradition.

=cut

sub propagate_all_relationships {
	my $self = shift;
	my @allrels = sort { $self->_propagate_rel_order( $a, $b ) } $self->relationships;
	foreach my $rel ( @allrels ) {
		my $relobj = $self->get_relationship( $rel );
		if( $self->type( $relobj->type )->is_transitive ) {
			my @added = $self->propagate_relationship( $rel );
		}
	}
}

# Helper sorting function for retroactive propagation order.
sub _propagate_rel_order {
	my( $self, $a, $b ) = @_;
	my $aobj = $self->get_relationship( $a ); 
	my $bobj = $self->get_relationship( $b );
	my $at = $self->type( $aobj->type ); my $bt = $self->type( $bobj->type );
	# Apply strong relationships before weak
	return -1 if $bt->is_weak && !$at->is_weak;
	return 1 if $at->is_weak && !$bt->is_weak;
	# Apply more tightly bound relationships first
	return $at->bindlevel <=> $bt->bindlevel;
}


=head2 merge_readings( $kept, $deleted );

Makes a best-effort merge of the relationship links between the given readings, and
stops tracking the to-be-deleted reading.

=cut

sub merge_readings {
	my( $self, $kept, $deleted, $combined ) = @_;
	foreach my $edge ( $self->graph->edges_at( $deleted ) ) {
		# Get the pair of kept / rel
		my @vector = ( $kept );
		push( @vector, $edge->[0] eq $deleted ? $edge->[1] : $edge->[0] );
		next if $vector[0] eq $vector[1]; # Don't add a self loop
		
		# If kept changes its text, drop the relationship.
		next if $combined;
			
		# If kept / rel already has a relationship, just keep the old
		my $rel = $self->get_relationship( @vector );
		next if $rel;
		
		# Otherwise, adopt the relationship that would be deleted.
		$rel = $self->get_relationship( @$edge );
		$self->_set_relationship( $rel, @vector );
	}
	$self->_make_equivalence( $deleted, $kept );
}

### Equivalence logic

sub _remove_equivalence_node {
	my( $self, $node ) = @_;
	my $group = $self->equivalence( $node );
	my $nodelist = $self->eqreadings( $group );
	if( @$nodelist == 1 && $nodelist->[0] eq $node ) {
		$self->equivalence_graph->delete_vertex( $group );
		$self->remove_eqreadings( $group );
		$self->remove_equivalence( $group );
	} elsif( @$nodelist == 1 ) {
		throw( "DATA INCONSISTENCY in equivalence graph: " . $nodelist->[0] .
			" in group that should have only $node" );
	} else {
 		my @newlist = grep { $_ ne $node } @$nodelist;
		$self->set_eqreadings( $group, \@newlist );
		$self->remove_equivalence( $node );
	}
}

=head2 add_equivalence_edge

Add an edge in the equivalence graph corresponding to $source -> $target in the
collation. Should only be called by Collation.

=cut

sub add_equivalence_edge {
	my( $self, $source, $target ) = @_;
	my $seq = $self->equivalence( $source );
	my $teq = $self->equivalence( $target );
	$self->equivalence_graph->add_edge( $seq, $teq );
}

=head2 delete_equivalence_edge

Remove an edge in the equivalence graph corresponding to $source -> $target in the
collation. Should only be called by Collation.

=cut

sub delete_equivalence_edge {
	my( $self, $source, $target ) = @_;
	my $seq = $self->equivalence( $source );
	my $teq = $self->equivalence( $target );
	$self->equivalence_graph->delete_edge( $seq, $teq );
}

sub _is_disconnected {
	my $self = shift;
	return( scalar $self->equivalence_graph->predecessorless_vertices > 1
		|| scalar $self->equivalence_graph->successorless_vertices > 1 );
}

# Equate two readings in the equivalence graph
sub _make_equivalence {
	my( $self, $source, $target ) = @_;
	# Get the source equivalent readings
	my $seq = $self->equivalence( $source );
	my $teq = $self->equivalence( $target );
	# Nothing to do if they are already equivalent...
	return if $seq eq $teq;
	my $sourcepool = $self->eqreadings( $seq );
	# and add them to the target readings.
	push( @{$self->eqreadings( $teq )}, @$sourcepool );
	map { $self->set_equivalence( $_, $teq ) } @$sourcepool;
	# Then merge the nodes in the equivalence graph.
	foreach my $pred ( $self->equivalence_graph->predecessors( $seq ) ) {
		next if $pred eq $teq; # don't add a self-loop on concatenation merge
		$self->equivalence_graph->add_edge( $pred, $teq );
	}
	foreach my $succ ( $self->equivalence_graph->successors( $seq ) ) {
		next if $succ eq $teq; # don't add a self-loop on concatenation merge
		$self->equivalence_graph->add_edge( $teq, $succ );
	}
	$self->equivalence_graph->delete_vertex( $seq );
	throw( "Graph got disconnected making $source / $target equivalence" )
		if $self->_is_disconnected && $self->collation->tradition->_initialized;
}

=head2 test_equivalence

Test whether, if two readings were equated with a 'colocated' relationship, 
the graph would still be valid.

=cut

# TODO Used the 'is_reachable' method; it killed performance. Think about doing away
# with the equivalence graph in favor of a transitive closure graph (calculated ONCE)
# on the sequence graph, and test that way.

sub test_equivalence {
	my( $self, $source, $target ) = @_;
	# Try merging the nodes in the equivalence graph; return a true value if
	# no cycle is introduced thereby. Restore the original graph first.
	
	# Keep track of edges we add
	my %added_pred;
	my %added_succ;
	# Get the reading equivalents
	my $seq = $self->equivalence( $source );
	my $teq = $self->equivalence( $target );
	# Maybe this is easy?
	return 1 if $seq eq $teq;
	
	# Save the first graph
	my $checkstr = $self->equivalence_graph->stringify();
	# Add and save relevant edges
	foreach my $pred ( $self->equivalence_graph->predecessors( $seq ) ) {
		if( $self->equivalence_graph->has_edge( $pred, $teq ) ) {
			$added_pred{$pred} = 0;
		} else {
			$self->equivalence_graph->add_edge( $pred, $teq );
			$added_pred{$pred} = 1;
		}
	}
	foreach my $succ ( $self->equivalence_graph->successors( $seq ) ) {
		if( $self->equivalence_graph->has_edge( $teq, $succ ) ) {
			$added_succ{$succ} = 0;
		} else {
			$self->equivalence_graph->add_edge( $teq, $succ );
			$added_succ{$succ} = 1;
		}
	}
	# Delete source equivalent and test
	$self->equivalence_graph->delete_vertex( $seq );
	my $ret = !$self->equivalence_graph->has_a_cycle;
	
	# Restore what we changed
	$self->equivalence_graph->add_vertex( $seq );
	foreach my $pred ( keys %added_pred ) {
		$self->equivalence_graph->add_edge( $pred, $seq );
		$self->equivalence_graph->delete_edge( $pred, $teq ) if $added_pred{$pred};
	}
	foreach my $succ ( keys %added_succ ) {
		$self->equivalence_graph->add_edge( $seq, $succ );
		$self->equivalence_graph->delete_edge( $teq, $succ ) if $added_succ{$succ};
	}
	unless( $self->equivalence_graph->eq( $checkstr ) ) {
		throw( "GRAPH CHANGED after testing" );
	}
	# Return our answer
	return $ret;
}

# Unmake an equivalence link between two readings. Should only be called internally.
sub _break_equivalence {
	my( $self, $source, $target ) = @_;
	
	# This is the hard one. Need to reconstruct the equivalence groups without
	# the given link.
	my( %sng, %tng );
	map { $sng{$_} = 1 } $self->_find_equiv_without( $source, $target );
	map { $tng{$_} = 1 } $self->_find_equiv_without( $target, $source );
	# If these groups intersect, they are still connected; do nothing.
	foreach my $el ( keys %tng ) {
		return if( exists $sng{$el} );
	}
	# If they don't intersect, then we split the nodes in the graph and in
	# the hashes. First figure out which group has which name
	my $oldgroup = $self->equivalence( $source ); # same as $target
	my $keepsource = $sng{$oldgroup};
	my $newgroup = $keepsource ? $target : $source;
	my( $oldmembers, $newmembers );
	if( $keepsource ) {
		$oldmembers = [ keys %sng ];
		$newmembers = [ keys %tng ];
	} else {
		$oldmembers = [ keys %tng ];
		$newmembers = [ keys %sng ];
	}
		
	# First alter the old group in the hash
	$self->set_eqreadings( $oldgroup, $oldmembers );
	foreach my $el ( @$oldmembers ) {
		$self->set_equivalence( $el, $oldgroup );
	}
	
	# then add the new group back to the hash with its new key
	$self->set_eqreadings( $newgroup, $newmembers );
	foreach my $el ( @$newmembers ) {
		$self->set_equivalence( $el, $newgroup );
	}
	
	# Now add the new group back to the equivalence graph
	$self->equivalence_graph->add_vertex( $newgroup );
	# ...add the appropriate edges to the source group vertext
	my $c = $self->collation;
	foreach my $rdg ( @$newmembers ) {
		foreach my $rp ( $c->sequence->predecessors( $rdg ) ) {
			next unless $self->equivalence( $rp );
			$self->equivalence_graph->add_edge( $self->equivalence( $rp ), $newgroup );
		}
		foreach my $rs ( $c->sequence->successors( $rdg ) ) {
			next unless $self->equivalence( $rs );
			$self->equivalence_graph->add_edge( $newgroup, $self->equivalence( $rs ) );
		}
	}
	
	# ...and figure out which edges on the old group vertex to delete.
	my( %old_pred, %old_succ );
	foreach my $rdg ( @$oldmembers ) {
		foreach my $rp ( $c->sequence->predecessors( $rdg ) ) {
			next unless $self->equivalence( $rp );
			$old_pred{$self->equivalence( $rp )} = 1;
		}
		foreach my $rs ( $c->sequence->successors( $rdg ) ) {
			next unless $self->equivalence( $rs );
			$old_succ{$self->equivalence( $rs )} = 1;
		}
	}
	foreach my $p ( $self->equivalence_graph->predecessors( $oldgroup ) ) {
		unless( $old_pred{$p} ) {
			$self->equivalence_graph->delete_edge( $p, $oldgroup );
		}
	}
	foreach my $s ( $self->equivalence_graph->successors( $oldgroup ) ) {
		unless( $old_succ{$s} ) {
			$self->equivalence_graph->delete_edge( $oldgroup, $s );
		}
	}
	# TODO enable this after collation parsing is done
	throw( "Graph got disconnected breaking $source / $target equivalence" )
		if $self->_is_disconnected && $self->collation->tradition->_initialized;
}

sub _find_equiv_without {
	my( $self, $first, $second ) = @_;
	my %found = ( $first => 1 );
	my $check = [ $first ];
	my $iter = 0;
	while( @$check ) {
		my $more = [];
		foreach my $r ( @$check ) {
			foreach my $nr ( $self->graph->neighbors( $r ) ) {
				next if $r eq $second;
				if( $self->get_relationship( $r, $nr )->colocated ) {
					push( @$more, $nr ) unless exists $found{$nr};
					$found{$nr} = 1;
				}
			}
		}
		$check = $more;
	}
	return keys %found;
}

=head2 rebuild_equivalence

(Re)build the equivalence graph from scratch. Dumps the graph, makes a new one,
adds all readings and edges, then makes an equivalence for all relationships.

=cut

sub rebuild_equivalence {
	my $self = shift;
	my $newgraph = Graph->new();
	# Set this as the new equivalence graph
	$self->_reset_equivalence( $newgraph );
	# Clear out the data hashes
	$self->_clear_equivalence;
	$self->_clear_eqreadings;
	
	$self->collation->tradition->_init_done(0);
	# Add the readings
	foreach my $r ( $self->collation->readings ) {
		my $rid = $r->id;
		$newgraph->add_vertex( $rid );
		$self->set_equivalence( $rid, $rid );
		$self->set_eqreadings( $rid, [ $rid ] );
	}

	# Now add the edges
	foreach my $e ( $self->collation->paths ) {
		$self->add_equivalence_edge( @$e );
	}

	# Now equate the colocated readings. This does no testing; 
	# it assumes that all preexisting relationships are valid.
	foreach my $rel ( $self->relationships ) {
		my $relobj = $self->get_relationship( $rel );
		next unless $relobj && $relobj->colocated;
		$self->_make_equivalence( @$rel );
	}
	$self->collation->tradition->_init_done(1);
}

=head2 equivalence_ranks 

Rank all vertices in the equivalence graph, and return a hash reference with
vertex => rank mapping.

=cut

sub equivalence_ranks {
	my $self = shift;
	my $eqstart = $self->equivalence( $self->collation->start );
	my $eqranks = { $eqstart => 0 };
	my $rankeqs = { 0 => [ $eqstart ] };
	my @curr_origin = ( $eqstart );
    # A little iterative function.
    while( @curr_origin ) {
        @curr_origin = $self->_assign_rank( $eqranks, $rankeqs, @curr_origin );
    }
	return( $eqranks, $rankeqs );
}

sub _assign_rank {
    my( $self, $node_ranks, $rank_nodes, @current_nodes ) = @_;
    my $graph = $self->equivalence_graph;
    # Look at each of the children of @current_nodes.  If all the child's 
    # parents have a rank, assign it the highest rank + 1 and add it to 
    # @next_nodes.  Otherwise skip it; we will return when the highest-ranked
    # parent gets a rank.
    my @next_nodes;
    foreach my $c ( @current_nodes ) {
        warn "Current reading $c has no rank!"
            unless exists $node_ranks->{$c};
        foreach my $child ( $graph->successors( $c ) ) {
            next if exists $node_ranks->{$child};
            my $highest_rank = -1;
            my $skip = 0;
            foreach my $parent ( $graph->predecessors( $child ) ) {
                if( exists $node_ranks->{$parent} ) {
                    $highest_rank = $node_ranks->{$parent} 
                        if $highest_rank <= $node_ranks->{$parent};
                } else {
                    $skip = 1;
                    last;
                }
            }
            next if $skip;
            my $c_rank = $highest_rank + 1;
            # print STDERR "Assigning rank $c_rank to node $child \n";
            $node_ranks->{$child} = $c_rank if $node_ranks;
            push( @{$rank_nodes->{$c_rank}}, $child ) if $rank_nodes;
            push( @next_nodes, $child );
        }
    }
    return @next_nodes;
}

### Output logic

sub _as_graphml { 
	my( $self, $graphml_ns, $xmlroot, $node_hash, $nodeid_key, $edge_keys ) = @_;
	
    my $rgraph = $xmlroot->addNewChild( $graphml_ns, 'graph' );
	$rgraph->setAttribute( 'edgedefault', 'directed' );
    $rgraph->setAttribute( 'id', 'relationships', );
    $rgraph->setAttribute( 'parse.edgeids', 'canonical' );
    $rgraph->setAttribute( 'parse.edges', 0 );
    $rgraph->setAttribute( 'parse.nodeids', 'canonical' );
    $rgraph->setAttribute( 'parse.nodes', 0 );
    $rgraph->setAttribute( 'parse.order', 'nodesfirst' );
    
    # Add the vertices according to their XML IDs
    my %rdg_lookup = ( reverse %$node_hash );
    # my @nlist = sort _by_xmlid keys( %rdg_lookup ); ## CAUSES SEGFAULT
    my @nlist = sort keys( %rdg_lookup );
    foreach my $n ( @nlist ) {
    	my $n_el = $rgraph->addNewChild( $graphml_ns, 'node' );
    	$n_el->setAttribute( 'id', $n );
    	_add_graphml_data( $n_el, $nodeid_key, $rdg_lookup{$n} );
    }
	$rgraph->setAttribute( 'parse.nodes', scalar @nlist );
    
    # Add the relationship edges, with their object information
    my $edge_ctr = 0;
    foreach my $e ( sort { $a->[0] cmp $b->[0] } $self->graph->edges ) {
    	# Add an edge and fill in its relationship info.
    	next unless( exists $node_hash->{$e->[0]} && exists $node_hash->{$e->[1]} );
		my $edge_el = $rgraph->addNewChild( $graphml_ns, 'edge' );
		$edge_el->setAttribute( 'source', $node_hash->{$e->[0]} );
		$edge_el->setAttribute( 'target', $node_hash->{$e->[1]} );
		$edge_el->setAttribute( 'id', 'e'.$edge_ctr++ );

		my $rel_obj = $self->get_relationship( @$e );
		foreach my $key ( keys %$edge_keys ) {
			my $value = $rel_obj->$key;
			_add_graphml_data( $edge_el, $edge_keys->{$key}, $value ) 
				if defined $value;
		}
	}
	$rgraph->setAttribute( 'parse.edges', $edge_ctr );
}

sub _by_xmlid {
	my $tmp_a = $a;
	my $tmp_b = $b;
	$tmp_a =~ s/\D//g;
	$tmp_b =~ s/\D//g;
	return $tmp_a <=> $tmp_b;
}

sub _add_graphml_data {
    my( $el, $key, $value ) = @_;
    return unless defined $value;
    my $data_el = $el->addNewChild( $el->namespaceURI, 'data' );
    $data_el->setAttribute( 'key', $key );
    $data_el->appendText( $value );
}

sub _dump_segment {
	my( $self, $from, $to ) = @_;
	open( DUMP, ">debug.svg" ) or die "Could not open debug.svg";
	binmode DUMP, ':utf8';
	print DUMP $self->collation->as_svg({ from => $from, to => $to, nocalc => 1 });
	close DUMP;
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Relationship error',
		'message' => $_[0],
		);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
