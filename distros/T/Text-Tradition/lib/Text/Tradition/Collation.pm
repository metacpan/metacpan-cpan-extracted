package Text::Tradition::Collation;

use feature 'say';
use Encode qw( decode_utf8 );
use File::Temp;
use File::Which;
use Graph;
use IPC::Run qw( run binary );
use JSON qw/ to_json /;
use Text::CSV;
use Text::Tradition::Collation::Data;
use Text::Tradition::Collation::Reading;
use Text::Tradition::Collation::RelationshipStore;
use Text::Tradition::Error;
use XML::Easy::Syntax qw( $xml10_namestartchar_rx $xml10_namechar_rx );
use XML::LibXML;
use XML::LibXML::XPathContext;
use Moose;

has _data => (
	isa      => 'Text::Tradition::Collation::Data',
	is       => 'ro',
	required => 1,
	handles  => [ qw(
		sequence
		paths
		_set_relations
		relations
		_set_start
		_set_end
		ac_label
		has_cached_table
		relationships
		relationship_types
		related_readings
		get_relationship
		del_relationship
		equivalence
		equivalence_graph
		readings
		reading
		_add_reading
		del_reading
		has_reading
		wit_list_separator
		baselabel
		linear
		wordsep
		direction
		change_direction
		start
		end
		cached_table
		_graphcalc_done
		has_cached_svg
		wipe_table
	)]
);

has 'tradition' => (
    is => 'ro',
    isa => 'Text::Tradition',
    writer => '_set_tradition',
    weak_ref => 1,
    );

=encoding utf8

=head1 NAME

Text::Tradition::Collation - a software model for a text collation

=head1 SYNOPSIS

  use Text::Tradition;
  my $t = Text::Tradition->new( 
    'name' => 'this is a text',
    'input' => 'TEI',
    'file' => '/path/to/tei_parallel_seg_file.xml' );

  my $c = $t->collation;
  my @readings = $c->readings;
  my @paths = $c->paths;
  my @relationships = $c->relationships;
  
  my $svg_variant_graph = $t->collation->as_svg();
    
=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  The Collation is the central feature of
a Tradition, where the text, its sequence of readings, and its relationships
between readings are actually kept.

=head1 CONSTRUCTOR

=head2 new

The constructor.  Takes a hash or hashref of the following arguments:

=over

=item * tradition - The Text::Tradition object to which the collation 
belongs. Required.

=item * linear - Whether the collation should be linear; that is, whether 
transposed readings should be treated as two linked readings rather than one, 
and therefore whether the collation graph is acyclic.  Defaults to true.

=item * baselabel - The default label for the path taken by a base text 
(if any). Defaults to 'base text'.

=item * wit_list_separator - The string to join a list of witnesses for 
purposes of making labels in display graphs.  Defaults to ', '.

=item * ac_label - The extra label to tack onto a witness sigil when 
representing another layer of path for the given witness - that is, when
a text has more than one possible reading due to scribal corrections or
the like.  Defaults to ' (a.c.)'.

=item * wordsep - The string used to separate words in the original text.
Defaults to ' '.

=back

=head1 ACCESSORS

=head2 tradition

=head2 linear

=head2 wit_list_separator

=head2 baselabel

=head2 ac_label

=head2 wordsep

Simple accessors for collation attributes.

=head2 start

The meta-reading at the start of every witness path.

=head2 end

The meta-reading at the end of every witness path.

=head2 readings

Returns all Reading objects in the graph.

=head2 reading( $id )

Returns the Reading object corresponding to the given ID.

=head2 add_reading( $reading_args )

Adds a new reading object to the collation. 
See L<Text::Tradition::Collation::Reading> for the available arguments.

=head2 del_reading( $object_or_id )

Removes the given reading from the collation, implicitly removing its
paths and relationships.

=head2 has_reading( $id )

Predicate to see whether a given reading ID is in the graph.

=head2 reading_witnesses( $object_or_id )

Returns a list of sigils whose witnesses contain the reading.

=head2 paths

Returns all reading paths within the document - that is, all edges in the 
collation graph.  Each path is an arrayref of [ $source, $target ] reading IDs.

=head2 add_path( $source, $target, $sigil )

Links the given readings in the collation in sequence, under the given witness
sigil.  The readings may be specified by object or ID.

=head2 del_path( $source, $target, $sigil )

Links the given readings in the collation in sequence, under the given witness
sigil.  The readings may be specified by object or ID.

=head2 has_path( $source, $target );

Returns true if the two readings are linked in sequence in any witness.  
The readings may be specified by object or ID.

=head2 relationships

Returns all Relationship objects in the collation.

=head2 add_relationship( $reading, $other_reading, $options, $changed_readings )

Adds a new relationship of the type given in $options between the two readings,
which may be specified by object or ID.  Returns a value of ( $status, @vectors)
where $status is true on success, and @vectors is a list of relationship edges
that were ultimately added. If an array reference is passed in as $changed_readings, 
then any readings that were altered due to the relationship creation are added to
the array.

See L<Text::Tradition::Collation::Relationship> for the available options.

=cut 

sub BUILDARGS {
	my ( $class, @args ) = @_;
	my %args = @args == 1 ? %{ $args[0] } : @args;
	# TODO determine these from the Moose::Meta object
	my @delegate_attrs = qw(sequence relations readings wit_list_separator baselabel 
		linear wordsep direction start end cached_table _graphcalc_done);
	my %data_args;
	for my $attr (@delegate_attrs) {
		$data_args{$attr} = delete $args{$attr} if exists $args{$attr};
	}
	$args{_data} = Text::Tradition::Collation::Data->new(%data_args);
	return \%args;
}

sub BUILD {
    my $self = shift;
    $self->_set_relations( Text::Tradition::Collation::RelationshipStore->new( 'collation' => $self ) );
    $self->_set_start( $self->add_reading( 
    	{ 'collation' => $self, 'is_start' => 1, 'init' => 1 } ) );
    $self->_set_end( $self->add_reading( 
    	{ 'collation' => $self, 'is_end' => 1, 'init' => 1 } ) );
}

=head2 register_relationship_type( %relationship_definition )

Add a relationship type definition to this collation. The argument can be either a
hash or a hashref, defining the properties of the relationship. For relationship types 
and their properties, see L<Text::Tradition::Collation::RelationshipType>.

=head2 get_relationship_type( $relationship_name )

Retrieve the RelationshipType object for the relationship with the given name.

=cut

sub register_relationship_type {
	my $self = shift;
	my %args = @_ == 1 ? %{$_[0]} : @_;
	if( $self->relations->has_type( $args{name} ) ) {
		throw( 'Relationship type ' . $args{name} . ' already registered' );
	}
	$self->relations->add_type( %args );
}

sub get_relationship_type {
	my( $self, $name ) = @_;
		return $self->relations->has_type( $name ) 
			? $self->relations->type( $name ) : undef;
}

### Reading construct/destruct functions

sub add_reading {
	my( $self, $reading ) = @_;
	unless( ref( $reading ) eq 'Text::Tradition::Collation::Reading' ) {
		my %args = %$reading;
		if( $args{'init'} ) {
			# If we are initializing an empty collation, don't assume that we
			# have set a tradition.
			delete $args{'init'};
		} elsif( $self->tradition->can('language') && $self->tradition->has_language
			&& !exists $args{'language'} ) {
			$args{'language'} = $self->tradition->language;
		}
		$reading = Text::Tradition::Collation::Reading->new( 
			'collation' => $self,
			%args );
	}
	# First check to see if a reading with this ID exists.
	if( $self->reading( $reading->id ) ) {
		throw( "Collation already has a reading with id " . $reading->id );
	}
	$self->_graphcalc_done(0);
	$self->_add_reading( $reading->id => $reading );
	# Once the reading has been added, put it in both graphs.
	$self->sequence->add_vertex( $reading->id );
	$self->relations->add_reading( $reading->id );
	return $reading;
};

around del_reading => sub {
	my $orig = shift;
	my $self = shift;
	my $arg = shift;
	
	if( ref( $arg ) eq 'Text::Tradition::Collation::Reading' ) {
		$arg = $arg->id;
	}
	# Remove the reading from the graphs.
	$self->_graphcalc_done(0);
	$self->_clear_cache; # Explicitly clear caches to GC the reading
	$self->sequence->delete_vertex( $arg );
	$self->relations->delete_reading( $arg );
	
	# Carry on.
	$self->$orig( $arg );
};

=head2 merge_readings( $main, $second, $concatenate, $with_str )

Merges the $second reading into the $main one. If $concatenate is true, then
the merged node will carry the text of both readings, concatenated with either
$with_str (if specified) or a sensible default (the empty string if the
appropriate 'join_*' flag is set on either reading, or else $self->wordsep.)

The first two arguments may be either readings or reading IDs.

=begin testing

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

=end testing

=cut

sub merge_readings {
	my $self = shift;

	# Sanity check
	my( $kept_obj, $del_obj, $combine, $combine_char ) = $self->_objectify_args( @_ );
	my $mergemeta = $kept_obj->is_meta;
	throw( "Cannot merge meta and non-meta reading" )
		unless ( $mergemeta && $del_obj->is_meta )
			|| ( !$mergemeta && !$del_obj->is_meta );
	if( $mergemeta ) {
		throw( "Cannot merge with start or end node" )
			if( $kept_obj eq $self->start || $kept_obj eq $self->end
				|| $del_obj eq $self->start || $del_obj eq $self->end );
		throw( "Cannot combine text of meta readings" ) if $combine;
	}
	# We can only merge readings in a linear graph if:
	# - they are contiguous with only one edge between them, OR
	# - they are at equivalent ranks in the graph.
	if( $self->linear ) {
		my @delpred = $del_obj->predecessors;
		my @keptsuc = $kept_obj->successors;
		unless ( @delpred == 1 && $delpred[0] eq $kept_obj 
			&& @keptsuc == 1 && $keptsuc[0] eq $del_obj ) {
			my( $is_ok, $msg ) = $self->relations->relationship_valid( 
				$kept_obj, $del_obj, 'collated' );
			unless( $is_ok ) {
				throw( "Readings $kept_obj and $del_obj can be neither concatenated nor collated" );
			} 
		}
	}
	
	# We only need the IDs for adding paths to the graph, not the reading
	# objects themselves.
	my $kept = $kept_obj->id;
	my $deleted = $del_obj->id;
	$self->_graphcalc_done(0);
	
    # The kept reading should inherit the paths and the relationships
    # of the deleted reading.
	foreach my $path ( $self->sequence->edges_at( $deleted ) ) {
		my @vector = ( $kept );
		push( @vector, $path->[1] ) if $path->[0] eq $deleted;
		unshift( @vector, $path->[0] ) if $path->[1] eq $deleted;
		next if $vector[0] eq $vector[1]; # Don't add a self loop
		my %wits = %{$self->sequence->get_edge_attributes( @$path )};
		$self->sequence->add_edge( @vector );
		my $fwits = $self->sequence->get_edge_attributes( @vector );
		@wits{keys %$fwits} = values %$fwits;
		$self->sequence->set_edge_attributes( @vector, \%wits );
	}
	$self->relations->merge_readings( $kept, $deleted, $combine );
	
	# Do the deletion deed.
	if( $combine ) {
		# Combine the text of the readings
		my $joinstr = $combine_char;
		unless( defined $joinstr ) {
			$joinstr = '' if $kept_obj->join_next || $del_obj->join_prior;
			$joinstr = $self->wordsep unless defined $joinstr;
		}
		$kept_obj->_combine( $del_obj, $joinstr );
	}
	$self->del_reading( $deleted );
}

=head2 merge_related( @relationship_types )

Merge all readings linked with the relationship types given. If any of the selected type(s) is not a colocation, the graph will no longer be linear. The majority/plurality reading in each case will be the one kept. 

WARNING: This operation cannot be undone.

=cut

=begin testing

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

=end testing

=cut

# TODO: there should be a way to display merged without affecting the underlying data!

sub merge_related {
	my $self = shift;
	my %reltypehash;
	map { $reltypehash{$_} = 1 } @_;
	
	# Set up the filter for finding related readings
	my $filter = sub {
		exists $reltypehash{$_[0]->type};
	};
	
	# Go through all readings looking for related ones
	foreach my $r ( $self->readings ) {
		next unless $self->reading( "$r" ); # might have been deleted meanwhile
		while( my @related = $self->related_readings( $r, $filter ) ) {
			push( @related, $r );
			@related = sort { 
					scalar $b->witnesses <=> scalar $a->witnesses
				} @related;
			my $keep = shift @related;
			foreach my $delr ( @related ) {
				$self->linear( 0 )
					unless( $self->get_relationship( $keep, $delr )->colocated );
				$self->merge_readings( $keep, $delr );
			}
		}
	}
}

=head2 compress_readings

Where possible in the graph, compresses plain sequences of readings into a
single reading. The sequences must consist of readings with no
relationships to other readings, with only a single witness path between
them and no other witness paths from either that would skip the other. The
readings must also not be marked as nonsense or bad grammar.

WARNING: This operation cannot be undone.

=begin testing

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


=end testing

=cut

sub compress_readings {
	my $self = shift;
	# Sanity check: first save the original text of each witness.
	my %origtext;
	foreach my $wit ( $self->tradition->witnesses ) {
		$origtext{$wit->sigil} = $self->path_text( $wit->sigil );
		if( $wit->is_layered ) {
			my $acsig = $wit->sigil . $self->ac_label;
			$origtext{$acsig} = $self->path_text( $acsig );
		}
	}
	
	# Now do the deed.
	# Anywhere in the graph that there is a reading that joins only to a single
	# successor, and neither of these have any relationships, just join the two
	# readings.
	foreach my $rdg ( sort { $a->rank <=> $b->rank } $self->readings ) {
		# Now look for readings that can be joined to their successors.
		next unless $rdg->is_combinable;
		my %seen;
		while( $self->sequence->successors( $rdg ) == 1 ) {
			my( $next ) = $self->reading( $self->sequence->successors( $rdg ) );
			throw( "Infinite loop" ) if $seen{$next->id};
			$seen{$next->id} = 1;
			last if $self->sequence->predecessors( $next ) > 1;
			last unless $next->is_combinable;
			say "Joining readings $rdg and $next";
			$self->merge_readings( $rdg, $next, 1 );
		}
	}
	
	# Finally, make sure we haven't screwed anything up.
	foreach my $wit ( $self->tradition->witnesses ) {
		my $pathtext = $self->path_text( $wit->sigil );
		throw( "Text differs for witness " . $wit->sigil )
			unless $pathtext eq $origtext{$wit->sigil};
		if( $wit->is_layered ) {
			my $acsig = $wit->sigil . $self->ac_label;
			$pathtext = $self->path_text( $acsig );
			throw( "Layered text differs for witness " . $wit->sigil )
				unless $pathtext eq $origtext{$acsig};
		}
	}

	$self->relations->rebuild_equivalence();
	$self->calculate_ranks();
}

# Helper function for manipulating the graph.
sub _stringify_args {
	my( $self, $first, $second, @args ) = @_;
    $first = $first->id
        if ref( $first ) eq 'Text::Tradition::Collation::Reading';
    $second = $second->id
        if ref( $second ) eq 'Text::Tradition::Collation::Reading';        
    return( $first, $second, @args );
}

# Helper function for manipulating the graph.
sub _objectify_args {
	my( $self, $first, $second, $arg ) = @_;
    $first = $self->reading( $first )
        unless ref( $first ) eq 'Text::Tradition::Collation::Reading';
    $second = $self->reading( $second )
        unless ref( $second ) eq 'Text::Tradition::Collation::Reading';        
    return( $first, $second, $arg );
}

=head2 duplicate_reading( $reading, @witlist )

Split the given reading into two, so that the new reading is in the path for
the witnesses given in @witlist. If the result is that certain non-colocated
relationships (e.g. transpositions) are no longer valid, these will be removed.
Returns the newly-created reading.

=begin testing

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

=end testing

=cut

sub duplicate_reading {
	my( $self, $r, @wits ) = @_;
	# Check that we are not doing anything unwise.
	throw( "Must specify one or more witnesses for the duplicated reading" )
		unless @wits;
	unless( ref( $r ) eq 'Text::Tradition::Collation::Reading' ) {
		$r = $self->reading( $r );
	}
	throw( "Cannot duplicate a meta-reading" )
		if $r->is_meta;
	throw( "Cannot join all witnesses to the new reading" )
		if scalar( @wits ) == scalar( $r->witnesses );

	# Get all the reading attributes and duplicate them.	
	my $rmeta = Text::Tradition::Collation::Reading->meta;
	my %args;
    foreach my $attr( $rmeta->get_all_attributes ) {
		next if $attr->name =~ /^_/;
		my $acc = $attr->get_read_method;
		if( !$acc && $attr->has_applied_traits ) {
			my $tr = $attr->applied_traits;
			if( $tr->[0] =~ /::(Array|Hash)$/ ) {
				my $which = $1;
				my %methods = reverse %{$attr->handles};
				$acc = $methods{elements};
				$args{$attr->name} = $which eq 'Array' 
					? [ $r->$acc ] : { $r->$acc };
			} 
		} elsif( $acc ) {
			my $attrval = $r->$acc;
			if( defined $attrval ) {
				$args{$attr->name} = $attrval;
			}
		}
	}
	# By definition the new reading will no longer be common.
	$args{is_common} = 0;
	# The new reading also needs its own ID.
	$args{id} = $self->_generate_dup_id( $r->id );

	# Try to make the new reading.
	my $newr = $self->add_reading( \%args );
	# The old reading is also no longer common.
	$r->is_common( 0 );
	
	# For each of the witnesses, dissociate from the old reading and
	# associate with the new.
	foreach my $wit ( @wits ) {
		my $prior = $self->prior_reading( $r, $wit );
		my $next = $self->next_reading( $r, $wit );
		$self->del_path( $prior, $r, $wit );
		$self->add_path( $prior, $newr, $wit );
		$self->del_path( $r, $next, $wit );
		$self->add_path( $newr, $next, $wit );
	}
	
	# If the graph is ranked, we need to look for relationships that are now
	# invalid (i.e. 'non-colocation' types that might now be colocated) and
	# remove them. If not, we can skip it.
	my $succ;
	my %rrk;
	my @deleted_relations;
	if( $self->end->has_rank ) {
		# Find the point where we can stop checking
		$succ = $self->common_successor( $r, $newr );
		
		# Hash the existing ranks
		foreach my $rdg ( $self->readings ) {
			$rrk{$rdg->id} = $rdg->rank;
		}
		# Calculate the new ranks	
		$self->calculate_ranks();
	
		# Check for invalid non-colocated relationships among changed-rank readings
		# from where the ranks start changing up to $succ
		my $lastrank = $succ->rank;
		foreach my $rdg ( $self->readings ) {
			next if $rdg->rank > $lastrank;
			next if $rdg->rank == $rrk{$rdg->id};
			my @noncolo = $rdg->related_readings( sub { !$_[0]->colocated } );
			next unless @noncolo;
			foreach my $nc ( @noncolo ) {
				unless( $self->relations->verify_or_delete( $rdg, $nc ) ) {
					push( @deleted_relations, [ $rdg->id, $nc->id ] );
				}
			}
		}
	}
	return ( $newr, @deleted_relations );
}

sub _generate_dup_id {
	my( $self, $rid ) = @_;
	my $newid;
	my $i = 0;
	while( !$newid ) {
		$newid = $rid."_$i";
		if( $self->has_reading( $newid ) ) {
			$newid = '';
			$i++;
		}
	}
	return $newid;
}

### Path logic

sub add_path {
	my $self = shift;

	# We only need the IDs for adding paths to the graph, not the reading
	# objects themselves.
    my( $source, $target, $wit ) = $self->_stringify_args( @_ );

	$self->_graphcalc_done(0);
	# Connect the readings
	unless( $self->sequence->has_edge( $source, $target ) ) {
	    $self->sequence->add_edge( $source, $target );
	    $self->relations->add_equivalence_edge( $source, $target );
	}
    # Note the witness in question
    $self->sequence->set_edge_attribute( $source, $target, $wit, 1 );
}

sub del_path {
	my $self = shift;
	my @args;
	if( ref( $_[0] ) eq 'ARRAY' ) {
		my $e = shift @_;
		@args = ( @$e, @_ );
	} else {
		@args = @_;
	}

	# We only need the IDs for removing paths from the graph, not the reading
	# objects themselves.
    my( $source, $target, $wit ) = $self->_stringify_args( @args );

	$self->_graphcalc_done(0);
	if( $self->sequence->has_edge_attribute( $source, $target, $wit ) ) {
		$self->sequence->delete_edge_attribute( $source, $target, $wit );
	}
	unless( $self->sequence->has_edge_attributes( $source, $target ) ) {
		$self->sequence->delete_edge( $source, $target );
		$self->relations->delete_equivalence_edge( $source, $target );
	}
}


# Extra graph-alike utility
sub has_path {
	my $self = shift;
    my( $source, $target, $wit ) = $self->_stringify_args( @_ );
	return undef unless $self->sequence->has_edge( $source, $target );
	return $self->sequence->has_edge_attribute( $source, $target, $wit );
}

=head2 clear_witness( @sigil_list )

Clear the given witnesses out of the collation entirely, removing references
to them in paths, and removing readings that belong only to them.  Should only
be called via $tradition->del_witness.

=cut

sub clear_witness {
	my( $self, @sigils ) = @_;

	$self->_graphcalc_done(0);
	# Clear the witness(es) out of the paths
	foreach my $e ( $self->paths ) {
		foreach my $sig ( @sigils ) {
			$self->del_path( $e, $sig );
		}
	}
	
	# Clear out the newly unused readings
	foreach my $r ( $self->readings ) {
		unless( $self->reading_witnesses( $r ) ) {
			$self->del_reading( $r );
		}
	}
}

sub add_relationship {
	my $self = shift;
    my( $source, $target, $opts, $altered_readings ) = $self->_stringify_args( @_ );
    my( @vectors ) = $self->relations->add_relationship( $source, $target, $opts );
    my $did_recalc;
    foreach my $v ( @vectors ) {
    	my $rel = $self->get_relationship( $v );
    	next unless $rel->colocated;
    	my $r1 = $self->reading( $v->[0] );
    	my $r2 =  $self->reading( $v->[1] );
    	# If it's a spelling or orthographic relationship, and one is marked
    	# as a lemma, set the normal form on the non-lemma to reflect that.
    	if( $r1->does( 'Text::Tradition::Morphology' ) ) {
    		my @changed = $r1->relationship_added( $r2, $rel );
    		if( ref( $altered_readings ) eq 'ARRAY' ) {
    			push( @$altered_readings, @changed );
    		}
    	}
    	next if $did_recalc;
    	if( $r1->has_rank && $r2->has_rank && $r1->rank ne $r2->rank ) {
    			$self->_graphcalc_done(0);
    			$self->_clear_cache;
    			$did_recalc = 1;
    	}
    }
    return @vectors;
}

around qw/ get_relationship del_relationship / => sub {
	my $orig = shift;
	my $self = shift;
	my @args = @_;
	if( @args == 1 && ref( $args[0] ) eq 'ARRAY' ) {
		@args = @{$_[0]};
	}
	my @stringargs = $self->_stringify_args( @args );
	$self->$orig( @stringargs );
};

=head2 reading_witnesses( $reading )

Return a list of sigils corresponding to the witnesses in which the reading appears.

=cut

sub reading_witnesses {
	my( $self, $reading ) = @_;
	# We need only check either the incoming or the outgoing edges; I have
	# arbitrarily chosen "incoming".  Thus, special-case the start node.
	if( $reading eq $self->start ) {
		return map { $_->sigil } grep { $_->is_collated } $self->tradition->witnesses;
	}
	my %all_witnesses;
	foreach my $e ( $self->sequence->edges_to( $reading ) ) {
		my $wits = $self->sequence->get_edge_attributes( @$e );
		@all_witnesses{ keys %$wits } = 1;
	}
	my $acstr = $self->ac_label;
	foreach my $acwit ( grep { $_ =~ s/^(.*)\Q$acstr\E$/$1/ } keys %all_witnesses ) {
		delete $all_witnesses{$acwit.$acstr} if exists $all_witnesses{$acwit};
	}
	return keys %all_witnesses;
}

=head1 OUTPUT METHODS

=head2 as_svg( \%options )

Returns an SVG string that represents the graph, via as_dot and graphviz.
See as_dot for a list of options.  Must have GraphViz (dot) installed to run.

=begin testing

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

=end testing

=cut

sub as_svg {
    my( $self, $opts ) = @_;
    throw( "Need GraphViz installed to output SVG" )
    	unless File::Which::which( 'dot' );
    my $want_subgraph = exists $opts->{'from'} || exists $opts->{'to'};
    $self->calculate_ranks() 
    	unless( $self->_graphcalc_done || $opts->{'nocalc'} || !$self->linear );
	my @cmd = qw/dot -Tsvg/;
	my( $svg, $err );
	my $dotfile = File::Temp->new();
	## USE FOR DEBUGGING
	# $dotfile->unlink_on_destroy(0);
	binmode $dotfile, ':utf8';
	print $dotfile $self->as_dot( $opts );
	push( @cmd, $dotfile->filename );
	run( \@cmd, ">", binary(), \$svg );
	$svg = decode_utf8( $svg );
	return $svg;
}


=head2 as_dot( \%options )

Returns a string that is the collation graph expressed in dot
(i.e. GraphViz) format.  Options include:

=over 4

=item * from

=item * to

=item * color_common

=back

=cut

sub as_dot {
    my( $self, $opts ) = @_;
    my $startrank = $opts->{'from'} if $opts;
    my $endrank = $opts->{'to'} if $opts;
    my $color_common = $opts->{'color_common'} if $opts;
    my $STRAIGHTENHACK = !$startrank && !$endrank && $self->end->rank 
       && $self->end->rank > 100;
    $STRAIGHTENHACK = 1 if $opts->{'straight'}; # even for subgraphs or small graphs

    # Check the arguments
    if( $startrank ) {
    	return if $endrank && $startrank > $endrank;
    	return if $startrank > $self->end->rank;
	}
	if( defined $endrank ) {
		return if $endrank < 0;
		$endrank = undef if $endrank == $self->end->rank;
	}
	
    my $graph_name = $self->tradition->name;
    $graph_name =~ s/[^\w\s]//g;
    $graph_name = join( '_', split( /\s+/, $graph_name ) );

    my %graph_attrs = (
    	'bgcolor' => 'none',
    	);
    unless( $self->direction eq 'BI' ) {
    	$graph_attrs{rankdir} = $self->direction;
    }
    my %node_attrs = (
    	'fontsize' => 14,
    	'fillcolor' => 'white',
    	'style' => 'filled',
    	'shape' => 'ellipse'
    	);
    my %edge_attrs = ( 
    	'arrowhead' => 'open',
    	'color' => '#000000',
    	'fontcolor' => '#000000',
    	);

    my $dot = sprintf( "digraph %s {\n", $graph_name );
    $dot .= "\tgraph " . _dot_attr_string( \%graph_attrs ) . ";\n";
    $dot .= "\tnode " . _dot_attr_string( \%node_attrs ) . ";\n";

	# Output substitute start/end readings if necessary
	if( $startrank ) {
		$dot .= "\t\"__SUBSTART__\" [ label=\"...\",id=\"__START__\" ];\n";
	}
	if( $endrank ) {
		$dot .= "\t\"__SUBEND__\" [ label=\"...\",id=\"__END__\" ];\n";	
	}
	if( $STRAIGHTENHACK ) {
		## HACK part 1
		my $startlabel = $startrank ? '__SUBSTART__' : '__START__';
		$dot .= "\tsubgraph { rank=same \"$startlabel\" \"#SILENT#\" }\n";  
		$dot .= "\t\"#SILENT#\" [ shape=diamond,color=white,penwidth=0,label=\"\" ];"
	}
	my %used;  # Keep track of the readings that actually appear in the graph
	# Sort the readings by rank if we have ranks; this speeds layout.
	my @all_readings = $self->end->has_rank 
		? sort { $a->rank <=> $b->rank } $self->readings
		: $self->readings;
	# TODO Refrain from outputting lacuna nodes - just grey out the edges.
    foreach my $reading ( @all_readings ) {
    	# Only output readings within our rank range.
    	next if $startrank && $reading->rank < $startrank;
    	next if $endrank && $reading->rank > $endrank;
        $used{$reading->id} = 1;
        # Need not output nodes without separate labels
        next if $reading->id eq $reading->text;
        my $rattrs;
        my $label = $reading->text;
        unless( $label =~ /^[[:punct:]]+$/ ) {
	        $label .= '-' if $reading->join_next;
    	    $label = "-$label" if $reading->join_prior;
    	}
        $label =~ s/\"/\\\"/g;
		$rattrs->{'label'} = $label;
		$rattrs->{'id'} = $reading->id;
		$rattrs->{'fillcolor'} = '#b3f36d' if $reading->is_common && $color_common;
        $dot .= sprintf( "\t\"%s\" %s;\n", $reading->id, _dot_attr_string( $rattrs ) );
    }
    
	# Add the real edges. 
    my @edges = $self->paths;
	my( %substart, %subend );
    foreach my $edge ( @edges ) {
    	# Do we need to output this edge?
    	if( $used{$edge->[0]} && $used{$edge->[1]} ) {
    		my $label = $self->_path_display_label( $opts,
    			$self->path_witnesses( $edge ) );
			my $variables = { %edge_attrs, 'label' => $label };
			
			# Account for the rank gap if necessary
			my $rank0 = $self->reading( $edge->[0] )->rank
				if $self->reading( $edge->[0] )->has_rank;
			my $rank1 = $self->reading( $edge->[1] )->rank
				if $self->reading( $edge->[1] )->has_rank;
			if( defined $rank0 && defined $rank1 && $rank1 - $rank0 > 1 ) {
				$variables->{'minlen'} = $rank1 - $rank0;
			}
			
			# EXPERIMENTAL: make edge width reflect no. of witnesses
			my $extrawidth = scalar( $self->path_witnesses( $edge ) ) * 0.2;
			$variables->{'penwidth'} = $extrawidth + 0.8; # gives 1 for a single wit

			my $varopts = _dot_attr_string( $variables );
			$dot .= sprintf( "\t\"%s\" -> \"%s\" %s;\n", 
				$edge->[0], $edge->[1], $varopts );
        } elsif( $used{$edge->[0]} ) {
        	$subend{$edge->[0]} = $edge->[1];
        } elsif( $used{$edge->[1]} ) {
        	$substart{$edge->[1]} = $edge->[0];
        }
    }
    
    # If we are asked to, add relationship links
    if( exists $opts->{show_relations} ) {
    	my $filter = $opts->{show_relations}; # can be 'transposition' or 'all'
    	if( $filter eq 'transposition' ) {
    		$filter =~ qr/^transposition$/;
    	}
    	my %typecolors;
    	my @types = sort( map { $_->name } $self->relations->types );
    	if( exists $opts->{graphcolors} ) {
    		foreach my $tdx ( 0 .. $#types ) {
    			$typecolors{$types[$tdx]} = $opts->{graphcolors}->[$tdx];
    		}
    	} else {
    		map { $typecolors{$_} = '#FFA14F' } @types;
    	}
    	foreach my $redge ( $self->relationships ) {
    		if( $used{$redge->[0]} && $used{$redge->[1]} ) {
				my $rel = $self->get_relationship( $redge );
				next unless $filter eq 'all' || $rel->type =~ /$filter/;
				my $variables = { 
					arrowhead => 'none',
					color => $typecolors{$rel->type},
					constraint => 'false',
					penwidth => '3',
				};
				unless( exists $opts->{graphcolors} ) {
					$variables->{label} = uc( substr( $rel->type, 0, 4 ) ), 
				}
				$dot .= sprintf( "\t\"%s\" -> \"%s\" %s;\n",
					$redge->[0], $redge->[1], _dot_attr_string( $variables ) );
    		}
    	}
    }
    
    # Add substitute start and end edges if necessary
    foreach my $node ( keys %substart ) {
    	my $witstr = $self->_path_display_label( $opts, 
    		$self->path_witnesses( $substart{$node}, $node ) );
    	my $variables = { %edge_attrs, 'label' => $witstr };
    	my $nrdg = $self->reading( $node );
    	if( $nrdg->has_rank && $nrdg->rank > $startrank ) {
    		# Substart is actually one lower than $startrank
    		$variables->{'minlen'} = $nrdg->rank - ( $startrank - 1 );
    	}	
        my $varopts = _dot_attr_string( $variables );
        $dot .= "\t\"__SUBSTART__\" -> \"$node\" $varopts;\n";
	}
    foreach my $node ( keys %subend ) {
    	my $witstr = $self->_path_display_label( $opts,
    		$self->path_witnesses( $node, $subend{$node} ) );
    	my $variables = { %edge_attrs, 'label' => $witstr };
        my $varopts = _dot_attr_string( $variables );
        $dot .= "\t\"$node\" -> \"__SUBEND__\" $varopts;\n";
	}
	# HACK part 2
	if( $STRAIGHTENHACK ) {
		my $endlabel = $endrank ? '__SUBEND__' : '__END__';
		$dot .= "\t\"$endlabel\" -> \"#SILENT#\" [ color=white,penwidth=0 ];\n";
	}       

    $dot .= "}\n";
    return $dot;
}

sub _dot_attr_string {
	my( $hash ) = @_;
	my @attrs;
	foreach my $k ( sort keys %$hash ) {
		my $v = $hash->{$k};
		push( @attrs, $k.'="'.$v.'"' );
	}
	return( '[ ' . join( ', ', @attrs ) . ' ]' );
}

=head2 path_witnesses( $edge )

Returns the list of sigils whose witnesses are associated with the given edge.
The edge can be passed as either an array or an arrayref of ( $source, $target ).

=cut

sub path_witnesses {
	my( $self, @edge ) = @_;
	# If edge is an arrayref, cope.
	if( @edge == 1 && ref( $edge[0] ) eq 'ARRAY' ) {
		my $e = shift @edge;
		@edge = @$e;
	}
	my @wits = keys %{$self->sequence->get_edge_attributes( @edge )};
	return @wits;
}

# Helper function. Make a display label for the given witnesses, showing a.c.
# witnesses only where the main witness is not also in the list.
sub _path_display_label {
	my $self = shift;
	my $opts = shift;
	my %wits;
	map { $wits{$_} = 1 } @_;

	# If an a.c. wit is listed, remove it if the main wit is also listed.
	# Otherwise keep it for explicit listing.
	my $aclabel = $self->ac_label;
	my @disp_ac;
	foreach my $w ( sort keys %wits ) {
		if( $w =~ /^(.*)\Q$aclabel\E$/ ) {
			if( exists $wits{$1} ) {
				delete $wits{$w};
			} else {
				push( @disp_ac, $w );
			}
		}
	}
	
	if( $opts->{'explicit_wits'} ) {
		return join( ', ', sort keys %wits );
	} else {
		# See if we are in a majority situation.
		my $maj = scalar( $self->tradition->witnesses ) * 0.6;
		$maj = $maj > 5 ? $maj : 5;
		if( scalar keys %wits > $maj ) {
			unshift( @disp_ac, 'majority' );
			return join( ', ', @disp_ac );
		} else {
			return join( ', ', sort keys %wits );
		}
	}
}

=head2 as_adjacency_list

Returns a JSON structure that represents the collation sequence graph.

=begin testing

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

=end testing

=cut

sub as_adjacency_list {
	my( $self, $opts ) = @_;
	# Make a structure that contains all the nodes, the nodes they point to,
	# and the attributes of the edges that connect them. 
	# [ { id: 'n0', label: 'Gallia', adjacent: [ 
	#		{ id: 'n1', label: 'P Q' } , 
	# 		{ id: 'n2', label: 'R S', minlen: 2 } ] },
	#   { id: 'n1', label: 'est', adjacent: [ ... ] },
	#   ... ]
	my $startrank = $opts->{'from'} || 0;
	my $endrank = $opts->{'to'} || $self->end->rank;
	
    $self->calculate_ranks() 
    	unless( $self->_graphcalc_done || $opts->{'nocalc'} || !$self->linear );
	my $list = [];
	foreach my $rdg ( $self->readings ) {
		my @successors;
		my $phony = '';
		# Figure out what the node's successors should be.
		if( $rdg eq $self->start && $startrank > 0 ) {
			# Connect the start node with all the nodes at startrank.
			# Lacunas should be included only if the node really has that rank.
			@successors = $self->readings_at_rank( $startrank, 1 );
			$phony = 'start';
		} elsif( $rdg->rank < $startrank
				 || $rdg->rank > $endrank && $rdg ne $self->end ) {
			next;
		} else {
			@successors = $rdg->successors;
		}
		# Make sure that the end node is at the end of the successors
		# list if it is needed.
		if( grep { $_ eq $self->end } @successors ) {
			my @ts = grep { $_ ne $self->end } @successors;
			@successors = ( @ts, $self->end );
		} elsif ( grep { $_->rank > $endrank } @successors ) {
			push( @successors, $self->end );
		}
		
		my $listitem = { id => $rdg->id, label => $rdg->text };
		my $adjacent = [];
		my @endwits;
		foreach my $succ ( @successors ) {
			my @edgewits;
			if( $phony eq 'start' ) {
				@edgewits = $succ->witnesses;
			} elsif( $self->sequence->has_edge( $rdg->id, $succ->id ) ) {
				@edgewits = $self->path_witnesses( $rdg->id, $succ->id );
			}
			
			if( $succ eq $self->end ) {
				@edgewits = @endwits;
			} elsif( $succ->rank > $endrank ) {
				# These witnesses will point to 'end' instead, not to the
				# actual successor.
				push( @endwits, @edgewits );
				next;
			}
			my $edgelabel = $self->_path_display_label( $opts, @edgewits );
			my $edgedef = { id => $succ->id, label => $edgelabel };
			my $rankoffset = $succ->rank - $rdg->rank;
			if( $rankoffset > 1 and $succ ne $self->end ) {
				$edgedef->{minlen} = $rankoffset;
			}
			push( @$adjacent, $edgedef );
		}
		$listitem->{adjacent} = $adjacent;
		push( @$list, $listitem );
	}
	return to_json( $list );
}

=head2 as_graphml

Returns a GraphML representation of the collation.  The GraphML will contain 
two graphs. The first expresses the attributes of the readings and the witness 
paths that link them; the second expresses the relationships that link the 
readings.  This is the native transfer format for a tradition.

=begin testing

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

=end testing

=cut

## TODO MOVE this to Tradition.pm and modularize it better
sub as_graphml {
    my( $self, $options ) = @_;
	$self->calculate_ranks unless $self->_graphcalc_done;
	
	my $start = $options->{'from'} 
		? $self->reading( $options->{'from'} ) : $self->start;
	my $end = $options->{'to'} 
		? $self->reading( $options->{'to'} ) : $self->end;
	if( $start->has_rank && $end->has_rank && $end->rank < $start->rank ) {
		throw( 'Start node must be before end node' );
	}
	# The readings need to be ranked for this to work.
	$start = $self->start unless $start->has_rank;
	$end = $self->end unless $end->has_rank;
	my $rankoffset = 0;
	unless( $start eq $self->start ) {
		$rankoffset = $start->rank - 1;
	}
	my %use_readings;
	
    # Some namespaces
    my $graphml_ns = 'http://graphml.graphdrawing.org/xmlns';
    my $xsi_ns = 'http://www.w3.org/2001/XMLSchema-instance';
    my $graphml_schema = 'http://graphml.graphdrawing.org/xmlns ' .
        'http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd';

    # Create the document and root node
    require XML::LibXML;
    my $graphml = XML::LibXML->createDocument( "1.0", "UTF-8" );
    my $root = $graphml->createElementNS( $graphml_ns, 'graphml' );
    $graphml->setDocumentElement( $root );
    $root->setNamespace( $xsi_ns, 'xsi', 0 );
    $root->setAttributeNS( $xsi_ns, 'schemaLocation', $graphml_schema );
    
    # List of attribute types to save on our objects and their corresponding
    # GraphML types
    my %save_types = (
    	'Str' => 'string',
    	'Int' => 'int',
    	'Bool' => 'boolean',
    	'ReadingID' => 'string',
    	'RelationshipType' => 'string',
    	'RelationshipScope' => 'string',
    	'Ternary' => 'string',
    );
    
    # Add the data keys for the graph. Include an extra key 'version' for the
    # GraphML output version.
    my %graph_data_keys;
    my $gdi = 0;
    my %graph_attributes = ( 'version' => 'string' );
	# Graph attributes include those of Tradition and those of Collation.
	my %gattr_from;
	# TODO Use meta introspection method from duplicate_reading to do this
	# instead of naming custom keys.
	my $tmeta = $self->tradition->meta;
	my $cmeta = $self->meta;
	map { $gattr_from{$_->name} = 'Tradition' } $tmeta->get_all_attributes;
	map { $gattr_from{$_->name} = 'Collation' } $cmeta->get_all_attributes;
	foreach my $attr ( ( $tmeta->get_all_attributes, $cmeta->get_all_attributes ) ) {
		next if $attr->name =~ /^_/;
		next unless $save_types{$attr->type_constraint->name};
		$graph_attributes{$attr->name} = $save_types{$attr->type_constraint->name};
	}
    # Extra custom keys for complex objects that should be saved in some form.
    # The subroutine should return a string, or undef/empty.
    if( $tmeta->has_method('stemmata') ) {
		$graph_attributes{'stemmata'} = sub { 
			my @stemstrs;
			map { push( @stemstrs, $_->editable( {linesep => ''} ) ) } 
				$self->tradition->stemmata;
			join( "\n", @stemstrs );
		};
	}
	
	if( $tmeta->has_method('user') ) {
		$graph_attributes{'user'} = sub { 
			$self->tradition->user ? $self->tradition->user->id : undef 
		};
	}
	
    foreach my $datum ( sort keys %graph_attributes ) {
    	$graph_data_keys{$datum} = 'dg'.$gdi++;
        my $key = $root->addNewChild( $graphml_ns, 'key' );
        my $dtype = ref( $graph_attributes{$datum} ) ? 'string' 
        	: $graph_attributes{$datum};
        $key->setAttribute( 'attr.name', $datum );
        $key->setAttribute( 'attr.type', $dtype );
        $key->setAttribute( 'for', 'graph' );
        $key->setAttribute( 'id', $graph_data_keys{$datum} );    	
    }

    # Add the data keys for reading nodes
    my %reading_attributes;
    my $rmeta = Text::Tradition::Collation::Reading->meta;
    foreach my $attr( $rmeta->get_all_attributes ) {
		next if $attr->name =~ /^_/;
		next unless $save_types{$attr->type_constraint->name};
		$reading_attributes{$attr->name} = $save_types{$attr->type_constraint->name};
	}
	if( $self->start->does('Text::Tradition::Morphology' ) ) {
		# Extra custom key for the reading morphology
		$reading_attributes{'lexemes'} = 'string';
	}
	
    my %node_data_keys;
    my $ndi = 0;
    foreach my $datum ( sort keys %reading_attributes ) {
        $node_data_keys{$datum} = 'dn'.$ndi++;
        my $key = $root->addNewChild( $graphml_ns, 'key' );
        $key->setAttribute( 'attr.name', $datum );
        $key->setAttribute( 'attr.type', $reading_attributes{$datum} );
        $key->setAttribute( 'for', 'node' );
        $key->setAttribute( 'id', $node_data_keys{$datum} );
    }

    # Add the data keys for edges, that is, paths and relationships. Path
    # data does not come from a Moose class so is here manually.
    my $edi = 0;
    my %edge_data_keys;
    my %edge_attributes = (
    	witness => 'string',			# ID/label for a path
    	extra => 'boolean',				# Path key
    	);
    my @path_attributes = keys %edge_attributes; # track our manual additions
    my $pmeta = Text::Tradition::Collation::Relationship->meta;
    foreach my $attr( $pmeta->get_all_attributes ) {
		next if $attr->name =~ /^_/;
		next unless $save_types{$attr->type_constraint->name};
		$edge_attributes{$attr->name} = $save_types{$attr->type_constraint->name};
	}
    foreach my $datum ( sort keys %edge_attributes ) {
        $edge_data_keys{$datum} = 'de'.$edi++;
        my $key = $root->addNewChild( $graphml_ns, 'key' );
        $key->setAttribute( 'attr.name', $datum );
        $key->setAttribute( 'attr.type', $edge_attributes{$datum} );
        $key->setAttribute( 'for', 'edge' );
        $key->setAttribute( 'id', $edge_data_keys{$datum} );
    }

    # Add the collation graph itself. First, sanitize the name to a valid XML ID.
    my $xmlidname = $self->tradition->name;
    $xmlidname =~ s/(?!$xml10_namechar_rx)./_/g;
    if( $xmlidname !~ /^$xml10_namestartchar_rx/ ) {
    	$xmlidname = '_'.$xmlidname;
    }
    my $sgraph = $root->addNewChild( $graphml_ns, 'graph' );
    $sgraph->setAttribute( 'edgedefault', 'directed' );
    $sgraph->setAttribute( 'id', $xmlidname );
    $sgraph->setAttribute( 'parse.edgeids', 'canonical' );
    $sgraph->setAttribute( 'parse.edges', 0 ); # fill in later
    $sgraph->setAttribute( 'parse.nodeids', 'canonical' );
    $sgraph->setAttribute( 'parse.nodes', 0 ); # fill in later
    $sgraph->setAttribute( 'parse.order', 'nodesfirst' );
    	    
    # Tradition/collation attribute data
    foreach my $datum ( keys %graph_attributes ) {
    	my $value;
    	if( $datum eq 'version' ) {
    		$value = '3.2';
    	} elsif( ref( $graph_attributes{$datum} ) ) {
    		my $sub = $graph_attributes{$datum};
    		$value = &$sub();
    	} elsif( $gattr_from{$datum} eq 'Tradition' ) {
    		$value = $self->tradition->$datum;
    	} else {
    		$value = $self->$datum;
    	}
		_add_graphml_data( $sgraph, $graph_data_keys{$datum}, $value );
	}

    my $node_ctr = 0;
    my %node_hash;
    # Add our readings to the graph
    foreach my $n ( sort { $a->id cmp $b->id } $self->readings ) {
    	next if $n->has_rank && $n ne $self->start && $n ne $self->end &&
    		( $n->rank < $start->rank || $n->rank > $end->rank );
    	$use_readings{$n->id} = 1;
    	# Add to the main graph
        my $node_el = $sgraph->addNewChild( $graphml_ns, 'node' );
        my $node_xmlid = 'n' . $node_ctr++;
        $node_hash{ $n->id } = $node_xmlid;
        $node_el->setAttribute( 'id', $node_xmlid );
        foreach my $d ( keys %reading_attributes ) {
        	my $nval = $n->$d;
        	# Custom serialization
        	if( $d eq 'lexemes' ) {
				# If nval is a true value, we have lexemes so we need to
				# serialize them. Otherwise set nval to undef so that the
				# key is excluded from this reading.
        		$nval = $nval ? $n->_serialize_lexemes : undef;
        	} elsif( $d eq 'normal_form' && $n->normal_form eq $n->text ) {
        		$nval = undef;
        	}
        	if( $rankoffset && $d eq 'rank' && $n ne $self->start ) {
        		# Adjust the ranks within the subgraph.
        		$nval = $n eq $self->end ? $end->rank - $rankoffset + 1 
        			: $nval - $rankoffset;
        	}
        	_add_graphml_data( $node_el, $node_data_keys{$d}, $nval )
        		if defined $nval;
        }
    }

    # Add the path edges to the sequence graph
    my $edge_ctr = 0;
    foreach my $e ( sort { $a->[0] cmp $b->[0] } $self->sequence->edges() ) {
    	# We add an edge in the graphml for every witness in $e.
    	next unless( $use_readings{$e->[0]} || $use_readings{$e->[1]} );
    	my @edge_wits = sort $self->path_witnesses( $e );
    	$e->[0] = $self->start->id unless $use_readings{$e->[0]};
    	$e->[1] = $self->end->id unless $use_readings{$e->[1]};
    	# Skip any path from start to end; that witness is not in the subgraph.
    	next if ( $e->[0] eq $self->start->id && $e->[1] eq $self->end->id );
    	foreach my $wit ( @edge_wits ) {
			my( $id, $from, $to ) = ( 'e'.$edge_ctr++,
										$node_hash{ $e->[0] },
										$node_hash{ $e->[1] } );
			my $edge_el = $sgraph->addNewChild( $graphml_ns, 'edge' );
			$edge_el->setAttribute( 'source', $from );
			$edge_el->setAttribute( 'target', $to );
			$edge_el->setAttribute( 'id', $id );
			
			# It's a witness path, so add the witness
			my $base = $wit;
			my $key = $edge_data_keys{'witness'};
			# Is this an ante-corr witness?
			my $aclabel = $self->ac_label;
			if( $wit =~ /^(.*)\Q$aclabel\E$/ ) {
				# Keep the base witness
				$base = $1;
				# ...and record that this is an 'extra' reading path
				_add_graphml_data( $edge_el, $edge_data_keys{'extra'}, $aclabel );
			}
			_add_graphml_data( $edge_el, $edge_data_keys{'witness'}, $base );
		}
	}
	
	# Report the actual number of nodes and edges that went in
	$sgraph->setAttribute( 'parse.edges', $edge_ctr );
	$sgraph->setAttribute( 'parse.nodes', $node_ctr );
		
	# Add the relationship graph to the XML
	map { delete $edge_data_keys{$_} } @path_attributes;
	$self->relations->_as_graphml( $graphml_ns, $root, \%node_hash, 
		$node_data_keys{'id'}, \%edge_data_keys );

    # Save and return the thing
    my $result = decode_utf8( $graphml->toString(1) );
    return $result;
}

sub _add_graphml_data {
    my( $el, $key, $value ) = @_;
    return unless defined $value;
    my $data_el = $el->addNewChild( $el->namespaceURI, 'data' );
    $data_el->setAttribute( 'key', $key );
    $data_el->appendText( $value );
}

=head2 as_csv

Returns a CSV alignment table representation of the collation graph, one
row per witness (or witness uncorrected.) 

=head2 as_tsv

Returns a tab-separated alignment table representation of the collation graph, 
one row per witness (or witness uncorrected.) 

=begin testing

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

=end testing

=cut

sub _tabular {
    my( $self, $opts ) = @_;
    my $table = $self->alignment_table( $opts );
	my $csv_options = { binary => 1, quote_null => 0 };
	$csv_options->{'sep_char'} = $opts->{fieldsep};
	if( $opts->{fieldsep} eq "\t" ) {
		# If it is really tab separated, nothing is an escape char.
		$csv_options->{'quote_char'} = undef;
		$csv_options->{'escape_char'} = '';
	}
    my $csv = Text::CSV->new( $csv_options );    
    my @result;
    
    # Make the header row
    my @witnesses = map { $_->{'witness'} } @{$table->{'alignment'}};
    if( $opts->{ascii} ) {
    	# TODO think of a fix for this
    	throw( "Cannot currently produce ASCII sigla with witness layers" )
    		unless $opts->{noac};
    	my @awits = map { $self->tradition->witness( $_ )->ascii_sigil } @witnesses;
    	@witnesses = @awits;
    }    
    $csv->combine( @witnesses );
	push( @result, $csv->string );
	
    # Make the rest of the rows
    foreach my $idx ( 0 .. $table->{'length'} - 1 ) {
    	my @rowobjs = map { $_->{'tokens'}->[$idx] } @{$table->{'alignment'}};
    	my @row = map { $_ ? $_->{'t'}->text : $_ } @rowobjs;
    	# Quick and dirty collapse of requested relationship types
    	if( ref( $opts->{mergetypes} ) eq 'ARRAY' ) {
    		# Now substitute the reading in the relevant index of @row
    		# for its merge-related reading
    		my %substitutes;
    		while( @rowobjs ) {
    			my $thisr = shift @rowobjs;
    			next unless $thisr;
				next if exists $substitutes{$thisr->{t}->text};
				# Make sure we don't have A <-> B substitutions.
				$substitutes{$thisr->{t}->text} = $thisr->{t}->text;
    			foreach my $thatr ( @rowobjs ) {
    				next unless $thatr;
    				next if exists $substitutes{$thatr->{t}->text};
    				my $ttrel = $self->get_relationship( $thisr->{t}, $thatr->{t} );
    				next unless $ttrel;
    				next unless grep { $ttrel->type eq $_ } @{$opts->{mergetypes}};
    				# If we have got this far then we need to merge them.
    				$substitutes{$thatr->{t}->text} = $thisr->{t}->text;
    			}
    		}
    		@row = map { $_ && exists $substitutes{$_} ? $substitutes{$_} : $_ } @row;
    	}
        $csv->combine( @row );
        push( @result, $csv->string );
    }
    return join( "\n", @result );
}

sub as_csv {
	my $self = shift;
	my $opts = shift || {};
	$opts->{fieldsep} = ',';
	return $self->_tabular( $opts );
}

sub as_tsv {
	my $self = shift;
	my $opts = shift || {};
	$opts->{fieldsep} = "\t";
	return $self->_tabular( $opts );
}

=head2 alignment_table

Return a reference to an alignment table, in a slightly enhanced CollateX
format which looks like this:

 $table = { alignment => [ { witness => "SIGIL", 
                             tokens => [ { t => "TEXT" }, ... ] },
                           { witness => "SIG2", 
                             tokens => [ { t => "TEXT" }, ... ] },
                           ... ],
            length => TEXTLEN };

=cut

sub alignment_table {
    my( $self, $opts ) = @_;
    if( $self->has_cached_table ) {
		return $self->cached_table
			unless $opts->{noac} || $opts->{safe_ac};
    }
    
    # Make sure we can do this
	throw( "Need a linear graph in order to make an alignment table" )
		unless $self->linear;
    $self->calculate_ranks() 
    	unless $self->_graphcalc_done && $self->end->has_rank;

    my $table = { 'alignment' => [], 'length' => $self->end->rank - 1 };
    my @all_pos = ( 1 .. $self->end->rank - 1 );
    foreach my $wit ( sort { $a->sigil cmp $b->sigil } $self->tradition->witnesses ) {
        # say STDERR "Making witness row(s) for " . $wit->sigil;
        my @wit_path = $self->reading_sequence( $self->start, $self->end, $wit->sigil );
        my @row = _make_witness_row( \@wit_path, \@all_pos );
        my $witobj = { 'witness' => $wit->sigil, 'tokens' => \@row };
        $witobj->{'identifier'} = $wit->identifier if $wit->identifier;
        push( @{$table->{'alignment'}}, $witobj );
        if( $wit->is_layered && !$opts->{noac} ) {
        	my @wit_ac_path = $self->reading_sequence( $self->start, $self->end, 
        		$wit->sigil.$self->ac_label );
            my @ac_row = _make_witness_row( \@wit_ac_path, \@all_pos );
            my $witlabel = $opts->{safe_ac} 
            	? $wit->sigil . '__L' : $wit->sigil.$self->ac_label;
            my $witacobj = { 'witness' => $witlabel, 
            	'tokens' => \@ac_row };
            $witacobj->{'identifier'} = $wit->identifier if $wit->identifier;
			push( @{$table->{'alignment'}}, $witacobj );
        }           
    }
    unless( $opts->{noac} || $opts->{safe_ac} ) {
	    $self->cached_table( $table );
	}
    return $table;
}

sub _make_witness_row {
    my( $path, $positions ) = @_;
    my %char_hash;
    map { $char_hash{$_} = undef } @$positions;
    my $debug = 0;
    foreach my $rdg ( @$path ) {
        say STDERR "rank " . $rdg->rank if $debug;
        # say STDERR "No rank for " . $rdg->id unless defined $rdg->rank;
        $char_hash{$rdg->rank} = { 't' => $rdg };
    }
    my @row = map { $char_hash{$_} } @$positions;
    # Fill in lacuna markers for undef spots in the row
    my $last_el = shift @row;
    my @filled_row = ( $last_el );
    foreach my $el ( @row ) {
        # If we are using node reference, make the lacuna node appear many times
        # in the table.  If not, use the lacuna tag.
        if( $last_el && $last_el->{'t'}->is_lacuna && !defined $el ) {
            $el = $last_el;
        }
        push( @filled_row, $el );
        $last_el = $el;
    }
    return @filled_row;
}


=head1 NAVIGATION METHODS

=head2 reading_sequence( $first, $last, $sigil, $backup )

Returns the ordered list of readings, starting with $first and ending
with $last, for the witness given in $sigil. If a $backup sigil is 
specified (e.g. when walking a layered witness), it will be used wherever
no $sigil path exists.  If there is a base text reading, that will be
used wherever no path exists for $sigil or $backup.

=cut

# TODO Think about returning some lazy-eval iterator.
# TODO Get rid of backup; we should know from what witness is whether we need it.

sub reading_sequence {
    my( $self, $start, $end, $witness ) = @_;

    $witness = $self->baselabel unless $witness;
    my @readings = ( $start );
    my %seen;
    my $n = $start;
    while( $n && $n->id ne $end->id ) {
        if( exists( $seen{$n->id} ) ) {
            throw( "Detected loop for $witness at " . $n->id );
        }
        $seen{$n->id} = 1;
        
        my $next = $self->next_reading( $n, $witness );
        unless( $next ) {
            throw( "Did not find any path for $witness from reading " . $n->id );
        }
        push( @readings, $next );
        $n = $next;
    }
    # Check that the last reading is our end reading.
    my $last = $readings[$#readings];
    throw( "Last reading found from " . $start->text .
        " for witness $witness is not the end!" ) # TODO do we get this far?
        unless $last->id eq $end->id;
    
    return @readings;
}

=head2 readings_at_rank( $rank )

Returns a list of readings at a given rank, taken from the alignment table.

=cut

sub readings_at_rank {
	my( $self, $rank, $nolacuna ) = @_;
	my $table = $self->alignment_table;
	# Table rank is real rank - 1.
	my @elements = map { $_->{'tokens'}->[$rank-1] } @{$table->{'alignment'}};
	my %readings;
	foreach my $e ( @elements ) {
		next unless ref( $e ) eq 'HASH';
		next unless exists $e->{'t'};
		my $rdg = $e->{'t'};
		next if $nolacuna && $rdg->is_lacuna && $rdg->rank ne $rank;
		$readings{$e->{'t'}->id} = $e->{'t'};
	}
	return values %readings;
}

=head2 next_reading( $reading, $sigil );

Returns the reading that follows the given reading along the given witness
path.  

=cut

sub next_reading {
    # Return the successor via the corresponding path.
    my $self = shift;
    my $answer = $self->_find_linked_reading( 'next', @_ );
	return undef unless $answer;
    return $self->reading( $answer );
}

=head2 prior_reading( $reading, $sigil )

Returns the reading that precedes the given reading along the given witness
path.  

=cut

sub prior_reading {
    # Return the predecessor via the corresponding path.
    my $self = shift;
    my $answer = $self->_find_linked_reading( 'prior', @_ );
    return $self->reading( $answer );
}

sub _find_linked_reading {
    my( $self, $direction, $node, $path ) = @_;
    
    # Get a backup if we are dealing with a layered witness
    my $alt_path;
    my $aclabel = $self->ac_label;
    if( $path && $path =~ /^(.*)\Q$aclabel\E$/ ) {
    	$alt_path = $1;
    }
    
    my @linked_paths = $direction eq 'next' 
        ? $self->sequence->edges_from( $node ) 
        : $self->sequence->edges_to( $node );
    return undef unless scalar( @linked_paths );
    
    # We have to find the linked path that contains all of the
    # witnesses supplied in $path.
    my( @path_wits, @alt_path_wits );
    @path_wits = sort( $self->_witnesses_of_label( $path ) ) if $path;
    @alt_path_wits = sort( $self->_witnesses_of_label( $alt_path ) ) if $alt_path;
    my $base_le;
    my $alt_le;
    foreach my $le ( @linked_paths ) {
        if( $self->sequence->has_edge_attribute( @$le, $self->baselabel ) ) {
            $base_le = $le;
        }
		my @le_wits = sort $self->path_witnesses( $le );
		if( _is_within( \@path_wits, \@le_wits ) ) {
			# This is the right path.
			return $direction eq 'next' ? $le->[1] : $le->[0];
		} elsif( _is_within( \@alt_path_wits, \@le_wits ) ) {
			$alt_le = $le;
		}
    }
    # Got this far? Return the alternate path if it exists.
    return $direction eq 'next' ? $alt_le->[1] : $alt_le->[0]
        if $alt_le;

    # Got this far? Return the base path if it exists.
    return $direction eq 'next' ? $base_le->[1] : $base_le->[0]
        if $base_le;

    # Got this far? We have no appropriate path.
    warn "Could not find $direction node from " . $node->id 
        . " along path $path";
    return undef;
}

# Some set logic.
sub _is_within {
    my( $set1, $set2 ) = @_;
    my $ret = @$set1; # will be 0, i.e. false, if set1 is empty
    foreach my $el ( @$set1 ) {
        $ret = 0 unless grep { /^\Q$el\E$/ } @$set2;
    }
    return $ret;
}

# Return the string that joins together a list of witnesses for
# display on a single path.
sub _witnesses_of_label {
    my( $self, $label ) = @_;
    my $regex = $self->wit_list_separator;
    my @answer = split( /\Q$regex\E/, $label );
    return @answer;
}

=head2 common_readings

Returns the list of common readings in the graph (i.e. those readings that are
shared by all non-lacunose witnesses.)

=cut

sub common_readings {
	my $self = shift;
	my @common = grep { $_->is_common } $self->readings;
	return @common;
}

=head2 path_text( $sigil [, $start, $end, $use_normal_form ] )

Returns the text of a witness (plus its backup, if we are using a layer) as
stored in the collation.  The text is returned as a string, where the
individual readings are joined with spaces and the meta-readings (e.g.
lacunae) are omitted.  Optional specification of $start and $end allows the
generation of a subset of the witness text. Optional specification of
$use_normal_form produces a text based on the normal form, rather than the
raw text, of the reading.

=cut

sub path_text {
	my( $self, $wit, $start, $end, $normal ) = @_;
	$start = $self->start unless $start;
	$end = $self->end unless $end;
	my @path = grep { !$_->is_meta } $self->reading_sequence( $start, $end, $wit );
	return $self->known_path_text( $normal, @path );
}

=head2 known_path_text( $use_normal_form, @sequence ) 

Returns the text of a given sequence of readings. No attempt is made to
validate the sequence in question. If $use_normal_form is set to true, the
normal form of each reading in the sequence will be used to construct the
text.

=cut

sub known_path_text {
	my( $self, $normal, @path ) = @_;
	my $pathtext = '';
	my $last;
	foreach my $r ( @path ) {
		unless ( $r->join_prior || !$last || $last->join_next ) {
			$pathtext .= ' ';
		} 
		$pathtext .= $normal ? $r->normal_form : $r->text;
		$last = $r;
	}
	return $pathtext;
}

=head1 INITIALIZATION METHODS

These are mostly for use by parsers.

=head2 make_witness_path( $witness )

Link the array of readings contained in $witness->path (and in 
$witness->uncorrected_path if it exists) into collation paths.
Clear out the arrays when finished.

=head2 make_witness_paths

Call make_witness_path for all witnesses in the tradition.

=cut

# For use when a collation is constructed from a base text and an apparatus.
# We have the sequences of readings and just need to add path edges.
# When we are done, clear out the witness path attributes, as they are no
# longer needed.
# TODO Find a way to replace the witness path attributes with encapsulated functions?

sub make_witness_paths {
    my( $self ) = @_;
    foreach my $wit ( $self->tradition->witnesses ) {
        # say STDERR "Making path for " . $wit->sigil;
        $self->make_witness_path( $wit );
    }
}

sub make_witness_path {
    my( $self, $wit ) = @_;
    my @chain = @{$wit->path};
    my $sig = $wit->sigil;
    # Add start and end if necessary
    unshift( @chain, $self->start ) unless $chain[0] eq $self->start;
    push( @chain, $self->end ) unless $chain[-1] eq $self->end;
    foreach my $idx ( 0 .. $#chain-1 ) {
        $self->add_path( $chain[$idx], $chain[$idx+1], $sig );
    }
    if( $wit->is_layered ) {
        @chain = @{$wit->uncorrected_path};
		unshift( @chain, $self->start ) unless $chain[0] eq $self->start;
		push( @chain, $self->end ) unless $chain[-1] eq $self->end;
        foreach my $idx( 0 .. $#chain-1 ) {
            my $source = $chain[$idx];
            my $target = $chain[$idx+1];
            $self->add_path( $source, $target, $sig.$self->ac_label )
                unless $self->has_path( $source, $target, $sig );
        }
    }
    $wit->clear_path;
    $wit->clear_uncorrected_path;
}

=head2 calculate_ranks

Calculate the reading ranks (that is, their aligned positions relative
to each other) for the graph.  This can only be called on linear collations.

=begin testing

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

=end testing

=cut

sub calculate_ranks {
    my $self = shift;
    # Save the existing ranks, in case we need to invalidate the cached SVG.
    throw( "Cannot calculate ranks on a non-linear graph" ) 
    	unless $self->linear;
    my %existing_ranks;
    map { $existing_ranks{$_} = $_->rank } $self->readings;

    # Do the rankings based on the relationship equivalence graph, starting 
    # with the start node.
    my ( $node_ranks, $rank_nodes ) = $self->relations->equivalence_ranks();

    # Transfer our rankings from the topological graph to the real one.
    foreach my $r ( $self->readings ) {
        if( defined $node_ranks->{$self->equivalence( $r->id )} ) {
            $r->rank( $node_ranks->{$self->equivalence( $r->id )} );
        } else {
        	# Die. Find the last rank we calculated.
        	my @all_defined = sort { ( $node_ranks->{$self->equivalence( $a->id )}||-1 )
        			 <=> ( $node_ranks->{$self->equivalence( $b->id )}||-1 ) }
        		$self->readings;
        	my $last = pop @all_defined;
            throw( "Ranks not calculated after $last - do you have a cycle in the graph?" );
        }
    }
    # Do we need to invalidate the cached data?
    if( $self->has_cached_table ) {
    	foreach my $r ( $self->readings ) {
    		next if defined( $existing_ranks{$r} ) 
    			&& $existing_ranks{$r} == $r->rank;
    		# Something has changed, so clear the cache
    		$self->_clear_cache;
			# ...and recalculate the common readings.
			$self->calculate_common_readings();
    		last;
    	}
    }
	# The graph calculation information is now up to date.
	$self->_graphcalc_done(1);
}

sub _clear_cache {
	my $self = shift;
	$self->wipe_table if $self->has_cached_table;
}	


=head2 flatten_ranks

A convenience method for parsing collation data.  Searches the graph for readings
with the same text at the same rank, and merges any that are found.

=cut

sub flatten_ranks {
    my ( $self, %args ) = shift;
    my %unique_rank_rdg;
    my $changed;
    foreach my $p ( $self->identical_readings( %args ) ) {
		# say STDERR "Combining readings at same rank: @$p";
		$changed = 1;
		$self->merge_readings( @$p );
		# TODO see if this now makes a common point.
    }
    # If we merged readings, the ranks are still fine but the alignment
    # table is wrong. Wipe it.
    $self->wipe_table() if $changed;
}

=head2 identical_readings
=head2 identical_readings( start => $startnode, end => $endnode )
=head2 identical_readings( startrank => $startrank, endrank => $endrank )

Goes through the graph identifying all pairs of readings that appear to be
identical, and therefore able to be merged into a single reading. Returns the 
relevant identical pairs. Can be restricted to run over only a part of the 
graph, specified either by node or by rank.

=cut

sub identical_readings {
	my ( $self, %args ) = @_;
    # Find where we should start and end.
    my $startrank = $args{startrank} || 0;
    if( $args{start} ) {
    	throw( "Starting reading has no rank" ) unless $self->reading( $args{start} ) 
    		&& $self->reading( $args{start} )->has_rank;
    	$startrank = $self->reading( $args{start} )->rank;
    }
    my $endrank = $args{endrank} || $self->end->rank;
    if( $args{end} ) {
    	throw( "Ending reading has no rank" ) unless $self->reading( $args{end} ) 
    		&& $self->reading( $args{end} )->has_rank;
    	$endrank = $self->reading( $args{end} )->rank;
    }
    
    # Make sure the ranks are correct.
    unless( $self->_graphcalc_done ) {
    	$self->calculate_ranks;
    }
    # Go through the readings looking for duplicates.
    my %unique_rank_rdg;
    my @pairs;
    foreach my $rdg ( $self->readings ) {
        next unless $rdg->has_rank;
        my $rk = $rdg->rank;
        next if $rk > $endrank || $rk < $startrank;
        my $key = $rk . "||" . $rdg->text;
        if( exists $unique_rank_rdg{$key} ) {
        	# Make sure they don't have different grammatical forms
			my $ur = $unique_rank_rdg{$key};
        	if( $rdg->is_identical( $ur ) ) {
				push( @pairs, [ $ur, $rdg ] );
			}
        } else {
            $unique_rank_rdg{$key} = $rdg;
        }
    }	
    
    return @pairs;
}
	

=head2 calculate_common_readings

Goes through the graph identifying the readings that appear in every witness 
(apart from those with lacunae at that spot.) Marks them as common and returns
the list.

=begin testing

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

=end testing

=cut

sub calculate_common_readings {
	my $self = shift;
	my @common;
	map { $_->is_common( 0 ) } $self->readings;
	# Implicitly calls calculate_ranks
	my $table = $self->alignment_table;
	foreach my $idx ( 0 .. $table->{'length'} - 1 ) {
		my @row = map { $_->{'tokens'}->[$idx] 
							? $_->{'tokens'}->[$idx]->{'t'} : '' } 
					@{$table->{'alignment'}};
		my %hash;
		foreach my $r ( @row ) {
			if( $r ) {
				$hash{$r->id} = $r unless $r->is_meta;
			} else {
				$hash{'UNDEF'} = $r;
			}
		}
		if( keys %hash == 1 && !exists $hash{'UNDEF'} ) {
			my( $r ) = values %hash;
			$r->is_common( 1 );
			push( @common, $r );
		}
	}
	return @common;
}

=head2 text_from_paths

Calculate the text array for all witnesses from the path, for later consistency
checking.  Only to be used if there is no non-graph-based way to know the
original texts.

=cut

sub text_from_paths {
	my $self = shift;
    foreach my $wit ( $self->tradition->witnesses ) {
    	my @readings = $self->reading_sequence( $self->start, $self->end, $wit->sigil );
    	my @text;
    	foreach my $r ( @readings ) {
    		next if $r->is_meta;
    		push( @text, $r->text );
    	}
    	$wit->text( \@text );
    	if( $wit->is_layered ) {
			my @ucrdgs = $self->reading_sequence( $self->start, $self->end, 
												  $wit->sigil.$self->ac_label );
			my @uctext;
			foreach my $r ( @ucrdgs ) {
				next if $r->is_meta;
				push( @uctext, $r->text );
			}
			$wit->layertext( \@uctext );
    	}
    }    
}

=head1 UTILITY FUNCTIONS

=head2 common_predecessor( $reading_a, $reading_b )

Find the last reading that occurs in sequence before both the given readings.
At the very least this should be $self->start.

=head2 common_successor( $reading_a, $reading_b )

Find the first reading that occurs in sequence after both the given readings.
At the very least this should be $self->end.
    
=begin testing

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

=end testing

=cut

## Return the closest reading that is a predecessor of both the given readings.
sub common_predecessor {
	my $self = shift;
	my( $r1, $r2 ) = $self->_objectify_args( @_ );
	return $self->_common_in_path( $r1, $r2, 'predecessors' );
}

sub common_successor {
	my $self = shift;
	my( $r1, $r2 ) = $self->_objectify_args( @_ );
	return $self->_common_in_path( $r1, $r2, 'successors' );
}


# TODO think about how to do this without ranks...
sub _common_in_path {
	my( $self, $r1, $r2, $dir ) = @_;
	my $iter = $self->end->rank;
	my @candidates;
	my @last_r1 = ( $r1 );
	my @last_r2 = ( $r2 );
	# my %all_seen = ( $r1 => 'r1', $r2 => 'r2' );
	my %all_seen;
	# say STDERR "Finding common $dir for $r1, $r2";
	while( !@candidates ) {
		last unless $iter--;  # Avoid looping infinitely
		# Iterate separately down the graph from r1 and r2
		my( @new_lc1, @new_lc2 );
		foreach my $lc ( @last_r1 ) {
			foreach my $p ( $lc->$dir ) {
				if( $all_seen{$p->id} && $all_seen{$p->id} ne 'r1' ) {
					# say STDERR "Path candidate $p from $lc";
					push( @candidates, $p );
				} elsif( !$all_seen{$p->id} ) {
					$all_seen{$p->id} = 'r1';
					push( @new_lc1, $p );
				}
			}
		}
		foreach my $lc ( @last_r2 ) {
			foreach my $p ( $lc->$dir ) {
				if( $all_seen{$p->id} && $all_seen{$p->id} ne 'r2' ) {
					# say STDERR "Path candidate $p from $lc";
					push( @candidates, $p );
				} elsif( !$all_seen{$p->id} ) {
					$all_seen{$p->id} = 'r2';
					push( @new_lc2, $p );
				}
			}
		}
		@last_r1 = @new_lc1;
		@last_r2 = @new_lc2;
	}
	my @answer = sort { $a->rank <=> $b->rank } @candidates;
	return $dir eq 'predecessors' ? pop( @answer ) : shift ( @answer );
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Collation error',
		'message' => $_[0],
		);
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 BUGS/TODO

=over

=item * Rework XML serialization in a more modular way

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
