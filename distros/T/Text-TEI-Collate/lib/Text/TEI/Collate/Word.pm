package Text::TEI::Collate::Word;

use strict;
use Moose;
use Module::Load;
use Text::TEI::Collate::Error;
use vars qw( $VERSION );

has 'word' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	writer => '_set_word',
	);
	
has 'language' => (
    is => 'ro',
    isa => 'Str',
    default => 'Default',
    );
	
has 'comparison_form' => (
	is => 'ro',
	isa => 'Str',
	writer => '_set_comparison_form',
	);
	
has 'canonical_form' => (
	is => 'ro',
	isa => 'Str',
	writer => '_set_canonical_form',
	);
	
has 'original_form' => (
	is => 'ro',
	isa => 'Str',
	writer => '_set_original_form',
	);

has 'punctuation' => (
	traits => ['Array'],
	isa => 'ArrayRef[HashRef[Str]]',
	default => sub { [] },
	handles => {
		punctuation => 'elements',
		add_punctuation => 'push',
		},
	);
	
has 'placeholders' => (
	traits => ['Array'],
	isa => 'ArrayRef[Str]',
	default => sub { [] },
	handles => {
		'placeholders' => 'elements',
		'add_placeholder' => 'push',
		},
	);
	
has 'links' => (
	traits => ['Array'],
	isa => 'ArrayRef[Text::TEI::Collate::Word]',
	default => sub { [] },
	handles => {
		'links' => 'elements',
		'add_link' => 'push',
		},
	);

has 'linked_to' => (
    is => 'ro',
    isa => 'Text::TEI::Collate::Word',
    writer => '_set_linked',
    );
	
has 'variants' => (
	traits => ['Array'],
	isa => 'ArrayRef[Text::TEI::Collate::Word]',
	default => sub { [] },
	handles => {
		'variants' => 'elements',
		'add_variant' => 'push',
		'get_variant' => 'get',
		'_clear_variants' => 'clear',
		},
	);

has 'variant_of' => (
    is => 'ro',
    isa => 'Text::TEI::Collate::Word',
    writer => '_set_variant_of',
    clearer => '_clear_variant_of',
    );

has 'ms_sigil' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);

has 'special' => (
	is => 'ro',
	isa => 'Str',
	);
	
has 'invisible' => (
	is => 'ro',
	isa => 'Bool',
	writer => '_set_invisible',
	);

has 'is_empty' => (
	is => 'ro',
	isa => 'Bool',
	);
	
has 'is_glommed' => (
	is => 'rw',
	isa => 'Bool',
	);

has 'is_base' => (
	is => 'rw',
	isa => 'Bool',
	);
	
has '_mutable' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ 'glommed' ] },
	);

$VERSION = "1.1";

=head1 NAME

Text::TEI::Collate::Word - represent a collatable word in a manuscript text

=head1 DESCRIPTION

Text::TEI::Collate::Word is an object that describes a word in a collated
text.  This may be a useful way for editors of other things to plug in
their own logic.

=head1 METHODS

=head2 new

Creates a new word object.  This should probably only be called from
Text::TEI::Collate::Manuscript.  Constructor arguments (apart from the 
attributes) are:

=over

=item *

string - the initial word string that should be parsed into its forms

=item *

json - a hash, presumably read from JSON, that has all the attributes

=item *

empty - a flag to say that this should be an empty word.

=back

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate::Word;
use Encode qw( encode_utf8 );

# Initialize a word from a string, check its values

my $word = Text::TEI::Collate::Word->new( string => 'ἔστιν;', ms_sigil => 'A' );
is( $word->word, "ἔστιν", "Got correct word from string");
is( $word->comparison_form, "εστιν", "Got correct normalization from string");
is_deeply( [ $word->punctuation], [ { 'char' => ';', 'pos' => 5 } ], "Got correct punctuation from string");
is( $word->canonical_form, $word->word, "Canonical form is same as passed form");
ok( !$word->invisible, "Word is not invisible");
ok( !$word->is_empty, "Word is not empty");

# Initialize a word from a JSON string, check its values
use JSON qw( decode_json );
my $jstring = encode_utf8( '{"c":"Արդ","n":"արդ","punctuation":[{"char":"։","pos":3}],"t":"Առդ"}' );
$word = Text::TEI::Collate::Word->new( json => decode_json($jstring), ms_sigil => 'B' );
is( $word->word, 'Առդ', "Got correct JSON word before modification" );
is( $word->canonical_form, 'Արդ', "Got correct canonized form" );
is( $word->comparison_form, 'արդ', "Got correct normalized form" );
is( $word->original_form, 'Առդ։', "Restored punctuation correctly for original form");

# Initialize an empty word, check its values
$word = Text::TEI::Collate::Word->new( empty => 1 );
is( $word->word, '', "Got empty word");
ok( $word->is_empty, "Word is marked empty" );

# Initialize a special, check its values and its 'printable'

# Initialize a word with a canonizer, check its values
$word = Text::TEI::Collate::Word->new( string => 'Ἔστιν;', ms_sigil => 'D', canonizer => sub{ lc( $_[0])});
is( $word->word, 'Ἔστιν', "Got correct word before canonization" );
is( $word->canonical_form, 'ἔστιν', "Got correct canonized word");

=end testing

=cut

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %args = @_;
	my %newargs;
	## We might get some legacy options:
	## - string (original word)
	## - empty
	## - json
	foreach my $key ( keys %args ) {
		if( $key eq 'string' ) {
			$newargs{'word'} = $args{'string'};
		} elsif( $key eq 'json' ) {
			%newargs = ( %newargs, _init_from_json( $args{'json'} ) );
		} elsif( $key eq 'empty' ) {
			$newargs{'is_empty'} = 1;
			$newargs{'word'} = '';
			$newargs{'ms_sigil'} = '';
			$newargs{'invisible'} = 1;
		} elsif( $key eq 'special' ) {
			$newargs{'special'} = $args{'special'};
			$newargs{'word'} = '';
			$newargs{'invisible'} = 1;
		} else {
			$newargs{$key} = $args{$key};
		}
	}
	unless( $newargs{'word'} ) {
		$newargs{'comparison_form'} = '';
		$newargs{'canonical_form'} = '';
		$newargs{'original_form'} = '';
	}
	return $class->$orig( %newargs );
};

around add_link => sub {
	my( $orig, $self, @args ) = @_;
	foreach( @args ) {
		$_->_set_linked( $self );
	}
	$self->$orig( @args );
};

around add_variant => sub {
	my( $orig, $self, @args ) = @_;
	foreach( @args ) {
		$_->_set_variant_of( $self );
	}
	$self->$orig( @args );
};

sub _init_from_json {
	my $hash = shift;
	my %newhash;
	foreach my $key ( keys %$hash ) {
		if( $key eq 't' ) {
			$newhash{word} = $hash->{$key};
			$newhash{original_form} = _restore_punct( $hash )
				unless defined $hash->{original_form}
		} elsif( $key eq 'c' ) {
			$newhash{canonical_form} = $hash->{$key};
		} elsif( $key eq 'n' ) {
			$newhash{comparison_form} = $hash->{$key};
		} else {
			$newhash{$key} = $hash->{$key};
		}
	}
	$newhash{canonical_form} ||= $hash->{'t'};
	$newhash{comparison_form} ||= $hash->{'t'};
	return %newhash;
}

sub _restore_punct {
	my $hash = shift;
	my $word = $hash->{t};
	my @punct = @{$hash->{punctuation}}
		if defined $hash->{punctuation};
	foreach my $p ( @punct ) {
		substr( $word, $p->{pos}, 0, $p->{char} );
	}
	return $word;
}

sub BUILD {
	my $self = shift;
	$self->_evaluate_word unless $self->original_form;
	return $self;
}

# Use the passed configuration options to calculate the various forms and
# attributes of the word.
sub _evaluate_word {
	my $self = shift;
	my $word = $self->word;
	return if $word eq '';  # Don't bother for empty words

	# Save the original string we were called with.
	$self->_set_original_form( $word );

    # Has it any punctuation to go with the word?  If so, we need to strip it
    # out, but save where we got it from.
	my $pos = 0;
	my $wspunct = '';  # word sans punctuation
	foreach my $char ( split( //, $word ) ) {
		if( $char =~ /^[[:punct:]]$/ ) {
			$self->add_punctuation( { 'char' => $char, 'pos' => $pos } );
		} else {
 			$wspunct .= $char;
		}
		$pos++;
	}
	$word = $wspunct;

	# Save the word sans punctuation.
    $self->_set_word( $word );
    
    # Get the subroutines we need for the rest.
    my $mod = 'Text::TEI::Collate::Lang::' . $self->language;
    load( $mod );
    my $canonizer = $mod->can( 'canonizer' );
    my $comparator = $mod->can( 'comparator' );

	# Canonicalize the word, if we have been handed a canonizer.
	$self->_set_canonical_form( $canonizer->( $word ) );
	# What is the string we will actually collate against?
	$self->_set_comparison_form( $comparator->( $self->canonical_form ) );
}

# Accessors.

=head1 Access methods

=head2 word

The word according to canonical orthography, without any punctuation.

=head2 printable

Return either the word or the 'special', as applicable

=cut

sub printable {
    my $self = shift;
    return $self->special ? $self->special : $self->canonical_form;
}

=head2 original_form

If called with an argument, sets the form of the word, punctuation and all,
that was originally passed. Returns the word's original form.

=head2 canonical_form

If called with an argument, sets the canonical form of the word (including
punctuation). Returns the word's canonical form.

=head2 comparison_form

If called with an argument, sets the normalized comparison form of the word
(the string that is actually used for collation matching.) Returns the word's
comparison form.

=head2 punctuation

If called with an argument, sets the punctuation marks that were passed with
the word. Returns the word's puncutation.

=head2 language

The name of the language module we are using (from Text::TEI::Collate::Lang)
to derive our canonical and comparison word forms.

=head2 special

Returns a word's special value. Used for meta-words like BEGIN and END.

=head2 is_empty

Returns whether this is an empty word. Useful to distinguish from a special
word.

=head2 is_glommed

Returns true if the word has been matched together with its following word. If
passed with an argument, sets this value.

=head2 is_base

Returns true if the word has been matched together with its following word. If
passed with an argument, sets this value.

=head2 placeholders

Returns the sectional markers, if any, that go before the word.

=head2 add_placeholder

Adds a sectional marker that should precede the word in question.

=head2 ms_sigil

Returns the sigil of the manuscript wherein this word appears.

=head2 links

Returns the list of links, or an empty list.

=head2 add_link

Adds to the list of 'like' words in this word's column.

=head2 linked_to

Returns the (base) word, if any, that this word is linked to.

=head2 variants

Returns the list of variants, or an empty list.

=head2 add_variant

Adds to the list of 'different' words in this word's column.

=head2 variant_of

Returns the word of which this word is a variant.

=head2 unlink_variant

Removes the given word from this word's list of variants.

=cut

sub unlink_variant {
    my( $self, $other ) = @_;
    my @v = grep { $_ ne $other } $self->variants;
    if( @v == $self->variants ) {
        throw( ident => 'missing link',
               message => "Variant " . $other->printable 
                    . "not present in list of variants for " . $self->printable );
    }
    $self->_clear_variants();
    $self->add_variant( @v );
    $other->_clear_variant_of;
}

sub throw {
    Text::TEI::Collate::Error->throw( @_ );
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
