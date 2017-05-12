package Text::Tradition::Collation::RelationshipType;

use Moose;

=head1 NAME

Text::Tradition::Collation::RelationshipType - describes a syntactic,
semantic, etc. relationship that can be made between two readings

=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  A relationship connects two readings
within a collation, usually when they appear in the same place in different
texts.

=head1 CONSTRUCTOR

=head2 new

Creates a new relationship type. Usually called via
$collation->register_relationship_type. Options include:

=over 4

=item * name - (Required string) The name of this relationship type.

=item * bindlevel - (Required int) How tightly the relationship binds. A
lower number indicates a closer binding. If A and B are related at
bindlevel 0, and B and C at bindlevel 1, it implies that A and C have the
same relationship as B and C do.

=item * is_weak - (Default false) Whether this relationship should be
replaced silently by a stronger type if requested. This is used primarily
for the internal 'collated' relationship, only to be used by parsers.

=item * is_colocation - (Default true) Whether this relationship implies
that the readings in question have parallel locations.

=item * is_transitive - (Default 1) Whether this relationship type is
transitive - that is, if A is related to B and C this way, is B necessarily
related to C?

=item * is_generalizable - (Default is_colocation) Whether this
relationship can have a non-local scope.

=item * use_regular - (Default is_generalizable) Whether, when a
relationship has a non-local scope, the search should be made on the
regularized form of the reading.

=back

=head1 ACCESSORS

=head2 name

=head2 bindlevel

=head2 is_weak

=head2 is_colocation

=head2 is_transitive

=head2 is_generalizable

=head2 use_regular

See the option descriptions above. All attributes are read-only.

=cut

has 'name' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);
	
has 'bindlevel' => (
	is => 'ro',
	isa => 'Int',
	required => 1
	);
	
has 'description' => (
	is => 'ro',
	isa => 'Str',
	required => 1
	);
	
has 'is_weak' => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
	);
	
has 'is_colocation' => (
	is => 'ro',
	isa => 'Bool',
	default => 1
	);
	
has 'is_transitive' => (
	is => 'ro',
	isa => 'Bool',
	default => 1
	);
	
has 'is_generalizable' => (
	is => 'ro',
	isa => 'Bool',
	lazy => 1,
	default => sub { $_[0]->is_colocation }
	);
	
# TODO I really want to make some configurable coderefs...

has 'use_regular' => (
	is => 'ro',
	isa => 'Bool',
	lazy => 1,
	default => sub { $_[0]->is_generalizable }
	);
	
=head1 DEFAULTS

This package provides the following set of relationships as default:

=head2 orthographic: bindlevel => 0, use_regular => 0

The readings are orthographic variants of each other (e.g. upper vs. lower case letters.) If the Morphology plugin is in use, orthographically related readings should regularize to the same string.

=head2 spelling: bindlevel => 1

The readings are spelling variations of the same word(s), e.g. 'color' vs. 'colour'.

=head2 punctuation: bindlevel => 2

The readings are both punctuation markers.

=head2 grammatical: bindlevel => 2

The readings are morphological variants of the same root word, e.g. 'was' vs. 'were'.

=head2 lexical: bindlevel => 2

The readings have the same morphological function but different root words, e.g. '[they] worked' vs. '[they] played'.

=head2 uncertain: bindlevel => 50, is_transitive => 0, is_generalizable => 0

The readings are (probably) related, but it is impossible to say for sure how. Useful for when one or both of the readings is itself uncertain.

=head2 transposition: bindlevel => 50, is_colocation => 0

The readings are the same (or perhaps close variants), but the position has shifted across witnesses.

=head2 repetition: bindlevel => 50, is_colocation => 0, is_transitive => 0

One of the readings is a repetition of the other, e.g. "pet the cat" vs. "pet the the cat".

=head2 other: bindlevel => 50, is_transitive => 0, is_generalizable => 0

A catch-all relationship for cases not covered by the other relationship types.

=head2 collated: bindlevel => 50, is_weak => 1, is_generalizable => 0

For internal use only. Denotes a parallel pair of variant readings as detected by an automatic collator.

=head1 METHODS

=head2 regularize( $reading )

Given a Reading object, return the regular form of the reading text that this
relationship type expects.

=cut
	
# TODO Define extra validation conditions here when we can store coderefs

sub regularize {
	my( $self, $rdg ) = @_;
	if( $self->use_regular && $rdg->can('regularize') ) {
		return $rdg->regularize;
	}
	return $rdg->text;
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
