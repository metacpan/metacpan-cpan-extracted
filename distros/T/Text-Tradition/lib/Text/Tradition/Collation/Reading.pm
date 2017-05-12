package Text::Tradition::Collation::Reading;

use Moose;
use Moose::Util qw/ does_role apply_all_roles /;
use Text::Tradition::Datatypes;
use Text::Tradition::Error;
use XML::Easy::Syntax qw( $xml10_name_rx $xml10_namestartchar_rx );
use overload '""' => \&_stringify, 'fallback' => 1;

# Enable plugin(s) if available
eval { with 'Text::Tradition::Morphology'; };
# Morphology package is not on CPAN, so don't warn of its absence
# if( $@ ) {
# 	warn "Text::Tradition::Morphology not found: $@. Disabling lexeme functionality";
# };

=head1 NAME

Text::Tradition::Collation::Reading - represents a reading (usually a word)
in a collation.

=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  A 'reading' refers to a unit of text,
usually a word, that appears in one or more witnesses (manuscripts) of the
tradition; the text of a given witness is composed of a set of readings in
a particular sequence

=head1 METHODS

=head2 new

Creates a new reading in the given collation with the given attributes.
Options include:

=over 4

=item collation - The Text::Tradition::Collation object to which this
reading belongs.  Required.

=item id - A unique identifier for this reading. Required.

=item text - The word or other text of the reading.

=item is_lemma - The reading serves as a lemma for the constructed text.

=item is_start - The reading is the starting point for the collation.

=item is_end - The reading is the ending point for the collation.

=item is_lacuna - The 'reading' represents a known gap in the text.

=item is_ph - A temporary placeholder for apparatus parsing purposes.  Do
not use unless you know what you are doing.

=item rank - The sequence number of the reading. This should probably not
be set manually.

=back

One of 'text', 'is_start', 'is_end', or 'is_lacuna' is required.

=head2 collation

=head2 id

=head2 text

=head2 is_lemma

=head2 is_start

=head2 is_end

=head2 is_lacuna

=head2 rank( $new_rank )

Accessor methods for the given attributes.

=head2 alter_text

Changes the text of the reading.

=head2 make_lemma

Sets this reading as a lemma for the constructed text.

=cut

has 'collation' => (
	is => 'ro',
	isa => 'Text::Tradition::Collation',
	# required => 1,
	weak_ref => 1,
	);

has 'id' => (
	is => 'ro',
	isa => 'ReadingID',
	required => 1,
	);

has 'text' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	writer => 'alter_text',
	);
	
has 'is_lemma' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	writer => 'make_lemma',
	);
	
has 'is_start' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	);

has 'is_end' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	);
    
has 'is_lacuna' => (
    is => 'ro',
    isa => 'Bool',
	default => undef,
    );
    
has 'is_ph' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	);
	
has 'is_common' => (
	is => 'rw',
	isa => 'Bool',
	default => undef,
	);

has 'rank' => (
    is => 'rw',
    isa => 'Int',
    predicate => 'has_rank',
    clearer => 'clear_rank',
    );
    
## For prefix/suffix readings

has 'join_prior' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	writer => '_set_join_prior',
	);
	
has 'join_next' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	writer => '_set_join_next',
	);


around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args;
	if( @_ == 1 ) {
		$args = shift;
	} else {
		$args = { @_ };
	}
			
	# If one of our special booleans is set, we change the text and the
	# ID to match.
	if( exists $args->{'is_lacuna'} && $args->{'is_lacuna'} && !exists $args->{'text'} ) {
		$args->{'text'} = '#LACUNA#';
	} elsif( exists $args->{'is_start'} && $args->{'is_start'} ) {
		$args->{'id'} = '__START__';  # Change the ID to ensure we have only one
		$args->{'text'} = '#START#';
		$args->{'rank'} = 0;
	} elsif( exists $args->{'is_end'} && $args->{'is_end'} ) {
		$args->{'id'} = '__END__';	# Change the ID to ensure we have only one
		$args->{'text'} = '#END#';
	} elsif( exists $args->{'is_ph'} && $args->{'is_ph'} ) {
		$args->{'text'} = $args->{'id'};
	}
	
	# Backwards compatibility for non-XMLname IDs
	my $rid = $args->{'id'};
	$rid =~ s/\#/__/g;
	$rid =~ s/[\/,]/./g;
    if( $rid !~ /^$xml10_namestartchar_rx/ ) {
    	$rid = 'r'.$rid;
    }
	$args->{'id'} = $rid;
	
	$class->$orig( $args );
};

# Look for a lexeme-string argument in the build args; if there, pull in the
# morphology role if possible.
sub BUILD {
	my( $self, $args ) = @_;
	if( exists $args->{'lexemes'} ) {
		unless( $self->can( '_deserialize_lexemes' ) ) {
			warn "No morphology package installed; DROPPING lexemes";
			return;
		}
		$self->_deserialize_lexemes( $args->{'lexemes'} );
	}
}

=head2 

=cut

around make_lemma => sub {
	my $orig = shift;
	my $self = shift;
	my $val = shift;

	my @altered = ( $self );
	my $c = $self->collation;
	if( $val && $c->_graphcalc_done) {
		# Unset the is_lemma flag for other readings at our rank
		foreach my $rdg ( $c->readings_at_rank( $self->rank ) ) {
			next if $rdg eq $self;
			if( $rdg->is_lemma ) {
				$rdg->$orig( 0 );
				push( @altered, $rdg );
			}
		}
		# Call the morphology handler
		if( $self->does( 'Text::Tradition::Morphology' ) ) {
			push( @altered, $self->push_normal_form() );
		}
	}
	$self->$orig( $val );
	return @altered;
};

=head2 is_meta

A meta attribute (ha ha), which should be true if any of our 'special'
booleans are true.  Implies that the reading does not represent a bit 
of text found in a witness.

=cut

sub is_meta {
	my $self = shift;
	return $self->is_start || $self->is_end || $self->is_lacuna || $self->is_ph;	
}

=head2 is_identical( $other_reading )

Returns true if the reading is identical to the other reading. The basic test
is equality of ->text attributes, but this may be wrapped or overridden by 
extensions.

=cut

sub is_identical {
	my( $self, $other ) = @_;
	return $self->text eq $other->text;
}

=head2 is_combinable

Returns true if the reading may in theory be combined into a multi-reading
segment within the collation graph. The reading must not be a meta reading,
and it must not have any relationships in its own right with any others.
This test may be wrapped or overridden by extensions.

=cut

sub is_combinable {
	my $self = shift;
	return undef if $self->is_meta;
	return !$self->related_readings();
}

# Not really meant for public consumption. Adopt the text of the other reading
# into this reading.
sub _combine {
	my( $self, $other, $joinstr ) = @_;
	$self->alter_text( join( $joinstr, $self->text, $other->text ) );
	# Change this reading to a joining one if necessary
	$self->_set_join_next( $other->join_next );
}

=head1 Convenience methods

=head2 related_readings

Calls Collation's related_readings with $self as the first argument.

=cut

sub related_readings {
	my $self = shift;
	return $self->collation->related_readings( $self, @_ );
}

=head2 witnesses 

Calls Collation's reading_witnesses with $self as the first argument.

=cut

sub witnesses {
	my $self = shift;
	return $self->collation->reading_witnesses( $self, @_ );
}

=head2 predecessors

Returns a list of Reading objects that immediately precede $self in the collation.

=cut

sub predecessors {
	my $self = shift;
	my @pred = $self->collation->sequence->predecessors( $self->id );
	return map { $self->collation->reading( $_ ) } @pred;
}

=head2 successors

Returns a list of Reading objects that immediately follow $self in the collation.

=cut

sub successors {
	my $self = shift;
	my @succ = $self->collation->sequence->successors( $self->id );
	return map { $self->collation->reading( $_ ) } @succ;
}

## Utility methods

sub _stringify {
	my $self = shift;
	return $self->id;
}

sub TO_JSON {
	my $self = shift;
	return $self->text;
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Reading error',
		'message' => $_[0],
		);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
