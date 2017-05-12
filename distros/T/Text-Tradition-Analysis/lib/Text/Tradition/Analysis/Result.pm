package Text::Tradition::Analysis::Result;

use Moose;
use Digest::MD5 qw/ md5_hex /;
use Encode qw/ encode_utf8 /;
use JSON qw/ to_json /;
use Set::Scalar;
use Text::Tradition::Error;

=head1 NAME

=encoding utf8

Text::Tradition::Analysis::Result - object to express an IDP calculation result
for a particular graph problem.
    
=head1 DESCRIPTION

Given a graph (expressing a stemma hypothesis) and a set of witness groupings 
(expressing variation in reading between witnesses related according to the
stemma hypothesis), it is possible to calculate certain properties of how the
readings might be related to each other. This calculation depends on a custom
program run under the IDP system [TODO URL]. As the problem is NP-hard, the
calculation can take a long time. The purpose of this object is to allow storage
of calculated results in a database.

For each graph problem, the following features can be calculated:

=over 4

=item * Whether the reading groups form a genealogical pattern on the stemma.

=item * The groupings, including lost/hypothetical witnesses if necessary, that minimize the amount of non-genealogical variation on the stemma.

=item * The classes, which for each witness express whether (in a minimally non-genealogical case) the witness is a source of its reading, follows a parent witness, or reverts to an ancestral reading that is not the parent's.

=back

=head1 CONSTRUCTOR

=head2 new

Creates a new graph problem. Requires two properties:

=over 4

=item * setlist - An array of arrays expressing the witness sets. The inner
arrays will be converted to Set::Scalar objects, and must have distinct members.

=item * graph - A dot description of a graph (e.g. the output of a call to
Text::Tradition::Stemma::editable) against which the sets will be analyzed.

=back

All other properties should be calculated by IDP rather than set manually.
These include:

=over 4

=item * is_genealogical - Boolean, indicating whether the witness sets form
genealogical groupings on the graph.

=item * status - String to indicate whether a solution has been calculated
for this analysis problem. Recognized values are "OK" (calculated) and
"running" (being calculated now). All other values, or no value, imply that
the calculation has yet to take place.

=item * groupings - These are extended (if necessary) versions of the witness
sets, which include the hypothetical witnesses necessary to minimize coincidence
of variation.

=item * classes - These are key/value pairs, keyed by witness, indicating for
each witness whether it is the source of a reading variant, whether it represents
a reversion to an ancestor (but not parent) reading, or whether its reading 
follows that of a parent on the graph.

=back

=begin testing

use Set::Scalar;
use Test::More::UTF8;
use Text::Tradition;
use TryCatch;
use_ok( 'Text::Tradition::Analysis::Result' );

# Make a problem with a graph and a set of groupings

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'flortest',
                                      'file' => $datafile );
my $s = $tradition->add_stemma( 'dotfile' => 't/data/florilegium.dot' );

my $sets = [ [ qw/ D Q / ], [ qw/ F H / ], [ qw/ A B C P S T / ] ];
my $extant = {};
foreach my $set ( @$sets ) {
	map { $extant->{$_} = 1 } @$set;
}
my $sitgraph = $s->editable( { extant => $extant } );
my $result = Text::Tradition::Analysis::Result->new(
	graph => $sitgraph,
	setlist => $sets );
is( ref( $result ), 'Text::Tradition::Analysis::Result', "Got a Result object" );
is( $result->graph, $sitgraph, "Got identical graph string back" );
is( $result->status, "new", "Calculation status of result set correctly" );
my @rsets = $result->sets;
is( $rsets[0], '(A B C P S T)', "First set is biggest set" );
is( $rsets[1], '(D Q)', "Second set is by alphabetical order" );
is( $rsets[2], '(F H)', "Second set is by alphabetical order" );

# Add some calculation values
$result->is_genealogical( 1 );
$result->record_grouping( [ qw/ 4 5 D Q / ] );
try {
	$result->record_grouping( [ qw/ 3 4 D H / ] );
	ok( 0, "Recorded a grouping that does not match the input sets" );
} catch ( Text::Tradition::Error $e ) {
	like( $e->message, qr/Failed to find witness set that is a subset of/, 
		"Correct error thrown on bad record_grouping attempt" );
}
# Test manually setting an out-of-range group
try {
	$result->_set_grouping( 3, Set::Scalar->new( qw/ X Y / ) );
	ok( 0, "Set a grouping at an invalid index" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Set / group index 3 out of range for set_grouping', 
		"Caught attempt to set grouping at invalid index" );
}
$result->record_grouping( [ qw/ 3 F H / ] );
my $gp1 = $result->grouping(1);
is( $result->minimum_grouping_for( $rsets[1] ), $gp1, 
	"Found a minimum grouping for D Q" );
is( "$gp1", "(4 5 D Q)", "Retrieved minimum grouping is correct" );
is( $result->minimum_grouping_for( $rsets[0] ), $rsets[0], 
	"Default minimum grouping found for biggest group" );
$result->record_grouping( [ qw/ 1 α δ A B C P S T / ] );
my %classes = (
	α => 'source',
	3 => 'source',
	4 => 'source' );
foreach my $gp ( $result->groupings ) {
	map { my $c = $classes{$_} || 'copy'; $result->set_class( $_, $c ) } @$gp;
}
foreach my $gp ( $result->groupings ) {
	foreach my $wit ( @$gp ) {
		my $expected = $classes{$wit} || 'copy';
		is( $result->class( $wit ), $expected, "Got expected witness class for $wit" );
	}
}

# Now write it out to JSON
my $struct = $result->TO_JSON;
my $newresult = Text::Tradition::Analysis::Result->new( $struct );
is( $result->object_key, $newresult->object_key, 
	"Object key stayed constant on export/import" );
my $problem = Text::Tradition::Analysis::Result->new( graph => $sitgraph, setlist => $sets );
is( $problem->object_key, $result->object_key, 
	"Object key stayed constant for newly created problem" );


=end testing

=head1 METHODS

=head2 $self->has_class( $witness )

=head2 $self->class( $witness )

If a class has been calculated for the given witness, has_class returns true
and class returns the calculated answer.

=cut

has 'setlist' => (
	traits => ['Array'],
	isa => 'ArrayRef[Set::Scalar]',
	handles => {
		sets => 'elements',
		set_index => 'first_index',
	},
	required => 1
);

has 'graph' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'status' => (
	is => 'rw',
	isa => 'Str'
);

has 'is_genealogical' => (
	is => 'rw',
	isa => 'Bool',
	predicate => 'has_genealogical_result'
);

has 'groupinglist' => (
	traits => ['Array'],
	isa => 'ArrayRef[Set::Scalar]',
	handles => {
		groupings => 'elements',
		_set_grouping => 'set',
		grouping => 'get',
	},
	default => sub { [] }
);

has 'classlist' => (
	traits => ['Hash'],
	isa => 'HashRef[Str]',
	handles => {
		class => 'get',
		has_class => 'exists',
		set_class => 'set',
		classes => 'elements',
		assigned_wits => 'keys',
	},
);

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args = @_ == 1 ? $_[0] : { @_ };
	
	# Convert the set list into a list of Set::Scalars, ordered first by size and
	# then alphabetically by first-sorted.
	throw( "Must specify a set list to Analysis::Result->new()" )
		unless ref( $args->{'setlist'} ) eq 'ARRAY'; 
	throw( "Empty set list specified to Analysis::Result->new()" )
		unless @{$args->{'setlist'}};
	# Order the sets and make sure they are all distinct Set::Scalars.
	$args->{'setlist'} = [ sort { by_size_and_alpha( $a, $b ) } 
							_check_set_args( $args->{'setlist'} ) ];
	if( exists $args->{'groupinglist'} ) {
		$args->{'groupinglist'} = [ _check_set_args( $args->{'groupinglist'} ) ];
	}
	
	# If we have been passed a Text::Tradition::Stemma or a Graph, save only
	# its string.
	if( ref( $args->{'graph'} ) ) {
		my $st = delete $args->{'graph'};
		my $type = ref( $st );
		my $gopt = { linesep => ' ' };
		if( $type eq 'Text::Tradition::Stemma' ) {
			$args->{'graph'} = $st->editable( $gopt );
		} elsif( $type eq 'Graph' ) {
			$args->{'graph'} = Text::Tradition::Stemma::editable_graph( $st, $gopt );
		} else {
			throw( "Passed argument to graph that is neither Stemma nor Graph" );
		}
	} 
	
	# If our only args are graph and setlist, then status should be 'new'
	if( scalar keys %$args == 2 ) {
		$args->{'status'} = 'new';
	}
		
	return $class->$orig( $args );
};

sub _check_set_args {
	my $setlist = shift;
	my @sets;
	foreach my $set ( @{$setlist} ) {
		my $s = $set;
		# Check uniqueness of the current set
		if( ref( $set ) ne 'Set::Scalar' ) {
			$s = Set::Scalar->new( @$set );
			throw( "Duplicate element(s) in set or group passed to Analysis::Result->new()" )
				unless @$set == $s->elements;
		}
		# Check distinctness of the set from all other sets given so far
		foreach my $ps ( @sets ) {
			throw( "Two sets $s / $ps are not disjoint" )
				unless $s->is_disjoint( $ps );
		}
		# Save the set.
		push( @sets, $s );
	}
	return @sets;
}	

sub BUILD {
	my $self = shift;
	
	# Initialize the groupings array
	my @sets = $self->sets;
	foreach my $idx( 0 .. $#sets ) {
		unless( $self->grouping( $idx ) ) {
			my $g = $sets[$idx]->clone();
			$self->_set_grouping( $idx, $g );
		}
	}
}

before '_set_grouping' => sub {
	my $self = shift;
	my $idx = $_[0];
	my $max = scalar $self->sets;
	if( $idx >= $max ) {
		throw( "Set / group index $idx out of range for set_grouping" );
	}
};

=head2 $self->object_key

Returns a unique key that can be used to look up this graph/set combination in
a database. Currently an MD5 hash of the request_string.

=cut

sub object_key {
	my $self = shift;
	return md5_hex( encode_utf8( $self->request_string ) );
}

=head2 $self->request_string

A request string is the graph followed by the groups, which should form a unique
key for the result.

=cut

sub request_string {
	my $self = shift;
	return $self->graph . '//' . join( ',', $self->sets );
}

=head2 by_size_and_alpha

A useful utility function to sort Set::Scalar objects first in descending 
order by size, then in ascending alphabetical order by first element (i.e. 
by stringification.)

=cut

sub by_size_and_alpha {
	my( $a, $b ) = @_;
	my $size = $b->members <=> $a->members;
	return $size if $size;
	# Then sort by alphabetical order of set elements.
	return "$a" cmp "$b";
}

=head2 $self->sources

Return all 'source' class witnesses in these sets for this graph.

=cut

sub sources {
	my $self = shift;
	my @sources = grep { $self->class( $_ ) eq 'source' } $self->assigned_wits;
	return @sources;
}

=head2 $self->minimum_grouping_for( $set )

Return the minimum grouping (including necessary hypothetical witnesses) for
the witness set specified. Will return undef if $set does not match one of
the defined witness sets in $self->sets.

=cut

# Look for a matching set in our setlist, and return its corresponding group
sub minimum_grouping_for {
	my( $self, $set ) = @_;
	my $midx = $self->set_index( sub { "$set" eq "$_" } );
	return undef unless defined $midx;
	return $self->grouping( $midx );
}

=head1 CALCULATION STORAGE METHODS

=head2 $self->is_genealogical( $bool )

Record that the sets are genealogical for this graph.

=head2 $self->set_class( $witness, $class )

Record that the witness in question is of the given class.

=head2 $self->record_grouping( $group )

Record that the group in question (either an arrayref or a Set::Scalar) forms
a minimum grouping on the graph. Will throw an error unless the group is a
(non-proper) superset of an existing witness set.

=cut

sub record_grouping {
	my( $self, $group ) = @_;
	unless( ref( $group ) eq 'Set::Scalar' ) {
		my $s = Set::Scalar->new( @$group );
		$group = $s;
	}
	# Find the set that is a subset of this group, and record it in the
	# correct spot in our groupinglist.
	my $idx = 0;
	foreach my $set ( $self->sets ) {
		if( _is_subset( $set, $group ) ) {
			$self->_set_grouping( $idx, $group );
			last;
		}
		$idx++;
	}
	if( $idx == scalar( $self->sets ) ) {
		throw( "Failed to find witness set that is a subset of $group" );
	}
}

sub _is_subset {
    # A replacement for the stupid Set::Scalar::is_subset
    my( $set1, $set2 ) = @_;
    my %all;
    map { $all{$_} = 1 } $set2->members;
    foreach my $m ( $set1->members ) {
        return 0 unless $all{$m};
    }
    return 1;
}

sub TO_JSON {
	my $self = shift;
	# Required values: graph and setlist
	my $data = { 
		graph => $self->graph, 
		setlist => [],
	};
	foreach my $set ( $self->sets ) {
		push( @{$data->{setlist}}, [ $set->members ] );
	}
	# Scalar values, if they are set
	$data->{is_genealogical} = 1 if $self->is_genealogical;
	$data->{status} = $self->status if $self->status;
	
	# Set values, if they exist
	$data->{groupinglist} = [] if $self->groupings;
	foreach my $group ( $self->groupings ) {
		push( @{$data->{groupinglist}}, [ $group->members ] );
	}
	$data->{classlist} = {} if $self->assigned_wits;
	foreach my $wit ( $self->assigned_wits ) {
		$data->{classlist}->{$wit} = $self->class( $wit );
	}
	return $data;
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Analysis::Result error',
		'message' => $_[0],
	);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
