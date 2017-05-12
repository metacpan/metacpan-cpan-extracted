package Text::Tradition;

use JSON qw / from_json /;
use Module::Load;
use Moose;
use Moose::Util qw/ does_role apply_all_roles /;
use Safe::Isa;
use Text::Tradition::Collation;
use Text::Tradition::Error;
use Text::Tradition::Witness;
use TryCatch;

use vars qw( $VERSION );
$VERSION = '2.1.0';

# Enable plugin(s) if available
eval { with 'Text::Tradition::HasStemma'; };
# Don't warn normally
# if( $@ ) {
# 	warn "Text::Tradition::Analysis not found. Disabling stemma analysis functionality";
# };
eval { with 'Text::Tradition::Language'; };
eval { with 'Text::Tradition::Ownership'; };

has 'collation' => (
    is => 'ro',
    isa => 'Text::Tradition::Collation',
    writer => '_save_collation',
    );

has 'witness_hash' => (
    traits => ['Hash'],
    isa => 'HashRef[Text::Tradition::Witness]',
    handles => {
        witness     => 'get',
        add_witness => 'set',
        del_witness => 'delete',
        has_witness => 'exists',
        witnesses   => 'values',
    },
    default => sub { {} },
    );

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => 'Tradition',
    );
    
has '_initialized' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
	writer => '_init_done',
	); 

# Create the witness if necessary before trying to add it
around 'add_witness' => sub {
    my $orig = shift;
    my $self = shift;
    my $new_wit;
    if( @_ == 1 && $_[0]->$_isa( 'Text::Tradition::Witness' ) ) {
    	$new_wit = shift;
    } else {
   		my %args = @_ == 1 ? %{$_[0]} : @_;
		$args{'tradition'} = $self;
		$new_wit = Text::Tradition::Witness->new( %args );
	}
    $self->$orig( $new_wit->sigil => $new_wit );
    return $new_wit;
};

# Allow deletion of witness by object as well as by sigil
around 'del_witness' => sub {
    my $orig = shift;
    my $self = shift;
    my @key_args;
    foreach my $arg ( @_ ) {
        push( @key_args, 
              ref( $arg ) eq 'Text::Tradition::Witness' ? $arg->sigil : $arg );
    }
    return $self->$orig( @key_args );
};

# Don't allow an empty hash value
around 'witness' => sub {
    my( $orig, $self, $arg ) = @_;
    return unless $self->has_witness( $arg );
    return $self->$orig( $arg );
};

# Cope with witness sigil changes
sub rename_witness {
	my( $self, $sig, $newsig ) = @_;
	my $wit = $self->witness( $sig );
	$self->throw( "No such witness $sig" ) unless $wit;
	$self->throw( "Cannot rename witness that has already been collated" )
		if $wit->is_collated;
	$wit = $self->del_witness( $sig );
	try {
		$wit->_set_sigil( $newsig );
	} catch ( $e ) {
		# Don't lose the witness if the rename failed
		$self->add_witness( $wit );
		$self->throw( $e );
	}
	$self->add_witness( $wit );
}

=head1 NAME

Text::Tradition - a software model for a set of collated texts

=head1 SYNOPSIS

  use Text::Tradition;
  my $t = Text::Tradition->new( 
    'name' => 'this is a text',
    'input' => 'TEI',
    'file' => '/path/to/tei_parallel_seg_file.xml' );

  my @text_wits = $t->witnesses();
  my $manuscript_a = $t->witness( 'A' );

  $t = Text::Tradition->new();
  $t->add_witness( 'sourcetype' => 'xmldesc', 
    'file' => '/path/to/teitranscription.xml' );
  $t->add_witness( 'sourcetype => 'plaintext', 'sigil' => 'Q',
    'string' => 'The quick brown fox jumped over the lazy dogs' );
  ## TODO
  $t->collate_texts;
  
  my $text_path_svg = $t->collation->as_svg();
  ## See Text::Tradition::Collation for more on text collation itself
    
=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  A 'tradition' refers to the aggregation
of surviving versions of a text, generally preserved in multiple
manuscripts (or 'witnesses').  A Tradition object thus has one more more
Witnesses, as well as a Collation that represents the unity of all versions
of the text.

=head1 METHODS

=head2 new

Creates and returns a new text tradition object.  The following options are
accepted.

General options:

=over 4

=item B<name> - The name of the text.

=back

Initialization based on a collation file:

=over 4

=item B<input> - The input format of the collation file.  Can be one of the
following:

=over 4

=item * Self - a GraphML format produced by this module

=item * CollateX - a GraphML format produced by CollateX

=item * CTE - a TEI XML format produced by Classical Text Editor

=item * JSON - an alignment table in JSON format, as produced by CollateX and 
other tools

=item * TEI - a TEI parallel segmentation format file

=item * Tabular - a spreadsheet collation.  See the documentation for 
L<Text::Tradition::Parser::Tabular> for an explanation of additional options.

=back

=item B<file> - The name of the file that contains the data.  One of 'file'
or 'string' should be specified.

=item B<string> - A text string that contains the data.  One of 'file' or
'string' should be specified.

=back

Initialization based on a list of witnesses [NOT YET IMPLEMENTED]:

=over 4

=item B<witnesses> - A reference to an array of Text::Tradition::Witness
objects that carry the text to be collated.

=item B<collator> - A reference to a collation program that will accept
Witness objects.

=back

=head2 B<witnesses>

Return the Text::Tradition::Witness objects associated with this tradition,
as an array.

=head2 B<witness>( $sigil )

Returns the Text::Tradition::Witness object whose sigil is $sigil, or undef
if there is no such object within the tradition.

=head2 B<add_witness>( %opts )

Instantiate a new witness with the given options (see documentation for
Text::Tradition::Witness) and add it to the tradition.

=head2 B<del_witness>( $sigil )

Delete the witness with the given sigil from the tradition.  Returns the
witness object for the deleted witness.

=head2 B<rename_witness>( $oldsigil, $newsigil )

Safely rename (i.e., assign a new sigil to) the given witness. At the moment
this can only be done when the witness does not yet appear in the collation.

=begin testing

use TryCatch;
use_ok( 'Text::Tradition', "can use module" );

my $t = Text::Tradition->new( 'name' => 'empty' );
is( ref( $t ), 'Text::Tradition', "initialized an empty Tradition object" );
is( $t->name, 'empty', "object has the right name" );
is( scalar $t->witnesses, 0, "object has no witnesses" );

my $simple = 't/data/simple.txt';
my $s = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Tabular',
    'file'  => $simple,
    );
is( ref( $s ), 'Text::Tradition', "initialized a Tradition object" );
is( $s->name, 'inline', "object has the right name" );
is( scalar $s->witnesses, 3, "object has three witnesses" );

my $wit_a = $s->witness('A');
is( ref( $wit_a ), 'Text::Tradition::Witness', "Found a witness A" );
if( $wit_a ) {
    is( $wit_a->sigil, 'A', "Witness A has the right sigil" );
}
is( $s->witness('X'), undef, "There is no witness X" );
ok( !exists $s->{'witnesses'}->{'X'}, "Witness key X not created" );

my $wit_d = $s->add_witness( 'sigil' => 'D', 'sourcetype' => 'plaintext',
	'string' => 'je suis depourvu de foi' );
is( ref( $wit_d ), 'Text::Tradition::Witness', "new witness created" );
is( $wit_d->sigil, 'D', "witness has correct sigil" );
is( scalar $s->witnesses, 4, "object now has four witnesses" );

try {
	$s->rename_witness( 'D', 'Invalid Sigil' );
	ok( 0, "Renamed witness with bad sigil" );
} catch ( Text::Tradition::Error $e ) {
	is( $s->witness('D'), $wit_d, "Held onto witness during bad rename" );
}

try {
	$s->rename_witness( 'D', 'Q' );
	ok( 1, "Rename of witness succeeded" );
	is( $s->witness('Q'), $wit_d, "Witness available under new sigil" );
	ok( !$s->has_witness('D'), "Witness no longer available under old sigil" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to rename witness: " . $e->message );
}	

my $del = $s->del_witness( 'Q' );
is( $del, $wit_d, "Deleted correct witness" );
is( scalar $s->witnesses, 3, "object has three witnesses again" );

try {
	$s->rename_witness( 'A', 'WitA' );
	ok( 0, "Successfully renamed an already collated witness" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Cannot rename witness that has already been collated',
		"Refused to rename an already-collated witness" );
}

=end testing

=cut
    

sub BUILD {
    my( $self, $init_args ) = @_;
    
    # First, make a collation object. This will use only those arguments in
    # init_args that apply to the collation.
	my $collation = Text::Tradition::Collation->new( %$init_args,
													'tradition' => $self );
	$self->_save_collation( $collation );

    if( exists $init_args->{'input'} ) {
        # Call the appropriate parser on the given data
        my @format_standalone = qw/ Self CollateText CollateX CTE JSON TEI Tabular /;
        my @format_basetext = qw/ KUL /;
        my $use_base;
        my $format = $init_args->{'input'};
        if( $format && !( grep { $_ eq $format } @format_standalone )
            && !( grep { $_ eq $format } @format_basetext ) ) {
            warn "Unrecognized input format $format; not parsing";
            return;
        }
        if( $format && grep { $_ eq $format } @format_basetext ) {
            $use_base = 1;
            if( !exists $init_args->{'base'} ) {
                warn "Cannot make a collation from $format without a base text";
                return;
            }
        }

        # Now do the parsing. 
        if( $format ) {
            if( $use_base ) { 
                $format = 'BaseText';   # Use the BaseText module for parsing,
                                        # but retain the original input arg.
            }
            my $mod = "Text::Tradition::Parser::$format";
            load( $mod );
            $mod->can('parse')->( $self, $init_args );
        }
    }
    $self->_init_done( 1 );
    return $self;
}

=head2 clear_collation

Blow away the existing collation object and mark all witnesses as uncollated.
Not to be used lightly.

=cut

sub clear_collation {
	my $self = shift;
	$self->_save_collation( Text::Tradition::Collation->new( tradition => $self ) );
	map { $_->is_collated( 0 ) } $self->witnesses;
}

=head2 add_json_witnesses( $jsonstring, $options )

Adds a set of witnesses from a JSON array specification. This is a wrapper
to parse the JSON and call add_witness (with the specified $options) for
each element therein.

=cut

sub add_json_witnesses {
	my( $self, $jsonstr, $extraopts ) = @_;
	my $witarray = from_json( $jsonstr );
	foreach my $witspec ( @{$witarray->{witnesses}} ) {
		my $opts = $extraopts || {};
		$opts->{'sourcetype'} = 'json';
		$opts->{'object'} = $witspec;
		$self->add_witness( $opts );
	}
}

sub throw {
	my $self = shift;
	Text::Tradition::Error->throw( 
		'ident' => 'Tradition error',
		'message' => $_[0],
		);
}

no Moose;
__PACKAGE__->meta->make_immutable;


=head1 BUGS / TODO

=over

=item * Allow tradition to be initialized via passing to a collator.

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
