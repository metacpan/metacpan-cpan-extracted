package Text::Tradition::Collation::Relationship;

use Moose;
use Text::Tradition::Datatypes;

=head1 NAME

Text::Tradition::Collation::Relationship - represents a syntactic or semantic
relationship between two readings
    
=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  A relationship connects two readings
within a collation, usually when they appear in the same place in different
texts.

=head1 CONSTRUCTOR

=head2 new

Creates a new relationship. Usually called via $collation->add_relationship.
Options include:

=over 4

=item * type - Can be one of spelling, orthographic, grammatical, lexical, 
collated, repetition, transposition.  All but the last two are only valid 
relationships between readings that occur at the same point in the text. 
The 'collated' relationship should only be used by parsers to align readings 
in the graph when the input information would otherwise be lost, e.g. from
an alignment table.

=item * displayform - (Optional) The reading that should be displayed if the 
related nodes are treated as one.

=item * scope - (Optional) A meta-attribute.  Can be one of 'local', 
'document', or 'global'. Denotes whether the relationship between the two 
readings holds always, independent of context, either within this tradition 
or across all traditions.

=item * annotation - (Optional) A freeform note to attach to the relationship.

=item * alters_meaning - Indicate whether, in context, the related words cause
the text to have different meanings. Possible values are 0 (no), 1 (slightly),
and >1 (yes).

=item * a_derivable_from_b - (Optional) True if the first reading is likely to 

=item * b_derivable_from_a - (Optional) True if the second reading is likely to

=item * non_independent - (Optional) True if the variant is unlikely to have 
occurred independently in unrelated witnesses.

=item * is_significant - (Optional) Indicates whether, in the opinion of the scholar,
the variation in question is stemmatically significant. Possible values are 'yes',
'maybe', and 'no'.

=back

=head1 ACCESSORS

=head2 type

=head2 displayform

=head2 scope

=head2 annotation

=head2 a_derivable_from_b

=head2 b_derivable_from_a

=head2 non_independent

=head2 is_significant

See the option descriptions above.

=cut

has 'type' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);

has 'reading_a' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);

has 'reading_b' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);

has 'displayform' => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_displayform',
	);

has 'scope' => (
	is => 'ro',
	isa => 'RelationshipScope', 
	default => 'local',
	);
	
has 'annotation' => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_annotation',
	);
	
has 'alters_meaning' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
	);

has 'a_derivable_from_b' => (
	is => 'ro',
	isa => 'Bool',
	);
	
has 'b_derivable_from_a' => (
	is => 'ro',
	isa => 'Bool',
	);
	
has 'non_independent' => (
	is => 'ro',
	isa => 'Bool',
	);
	
has 'is_significant' => (
	is => 'ro',
	isa => 'Ternary',
	default => 'no',
	);
	
around 'alters_meaning' => sub {
	my $orig = shift;
	my $self = shift;
	if( @_ ) {
		if( $_[0] eq 'no' ) {
			return $self->$orig( 0 );
		} elsif( $_[0] eq 'slightly' ) {
			return $self->$orig( 1 );
		} elsif( $_[0] eq 'yes' ) {
			return $self->$orig( 2 );
		} 
	}
	return $self->$orig( @_ );
};		
	
# A read-only meta-Boolean attribute.

=head2 colocated

Returns true if the relationship type is one that requires that its readings
occupy the same place in the collation.

=cut

sub colocated {
	my $self = shift;
	return $self->type !~ /^(repetition|transposition)$/;
}

=head2 nonlocal

Returns true if the relationship scope is anything other than 'local'.

=cut

sub nonlocal {
	my $self = shift;
	return $self->scope ne 'local';
}

=head2 is_equivalent( $otherrel )

Returns true if the type and scope of $otherrel match ours.

=cut

sub is_equivalent {
	my( $self, $other, $check_ann ) = @_;
	my $oksofar = $self->type eq $other->type && $self->scope eq $other->scope;
	if( $check_ann ) {
		return $oksofar && $self->annotation eq $other->annotation;
	} else {
		return $oksofar;
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
