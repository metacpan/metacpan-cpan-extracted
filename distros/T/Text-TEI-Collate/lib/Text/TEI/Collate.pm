package Text::TEI::Collate;

use strict;
use warnings;
use 5.010;
use vars qw( $VERSION );

use Moose;
use Encode qw( decode_utf8 );
use File::Temp;
use Graph::Easy;
use IPC::Run qw( run binary );
use JSON qw( decode_json );
use Module::Load;
use Text::CSV_XS;
use Text::TEI::Collate::Diff;
use Text::TEI::Collate::Error;
use Text::TEI::Collate::Word;
use Text::TEI::Collate::Manuscript;
use TryCatch;
use XML::LibXML;

$VERSION = "2.1";

eval { no warnings; binmode $DB::OUT, ":utf8" };

### Instance attributes

has 'debuglevel' => (
	is => 'ro',
	isa => 'Int', 
	default => 0,
	);
	
has 'title' => (
    is => 'rw',
    isa => 'Str',
    default => 'An nCritic collation',
    );
    
has 'language' => (
    is => 'rw',
    isa => 'Str',
    default => 'Default',
    );
    
has 'fuzziness' => (
    is => 'rw',
    isa => 'HashRef[Int]',
    default => sub{ { 'val' => 40, 'short' => 6, 'shortval' => 50 } },
    );
    
has 'binmode' => (
    is => 'ro',
    isa => 'Str',
    default => 'utf8',
    predicate => 'has_binmode',
    );
    
has 'distance_sub' => (
    is => 'rw',
    isa => 'CodeRef',
    );
    
has 'fuzziness_sub' => (
    is => 'rw',
    isa => 'CodeRef',
    predicate => 'has_fuzziness_sub',
    );

=head1 NAME

Text::TEI::Collate - a collation program for variant manuscript texts

=head1 SYNOPSIS

  use Text::TEI::Collate;
  my $aligner = Text::TEI::Collate->new( 'language' => 'Armenian' );

  # Read from strings.
  my @manuscripts;
  foreach my $str ( @strings_to_collate ) {
    push( @manuscripts, $aligner->read_source( $str ) );
  }
  $aligner->align( @manuscripts; );

  # Read from files.  Also works for XML::LibXML::Document objects.
  @manuscripts = ();
  foreach my $xml_file ( @TEI_files_to_collate ) {
    push( @manuscripts, $aligner->read_source( $xml_file ) )
  }
  $aligner->align( @manuscripts );

  # Read from a JSON input.
  @manuscripts = $aligner->read_source( $JSON_string );
  $aligner->align( @manuscripts );
  
=head1 DESCRIPTION

Text::TEI::Collate is a collation program for multiple (transcribed)
manuscript copies of a known text.  It is an object-oriented interface,
mostly for the convenience of the author and for the ability to have global
settings.

The object is the alignment engine, or "aligner". The methods that a user
will care about are "read_source" and "align", as well as the various
output methods; the other methods in this file are public in case a user
needs a subset of this package's functionality.

An aligner takes two or more texts; the texts can be strings, filenames, or
XML::LibXML::Document objects. It returns two or more Manuscript objects --
one for each text input -- in which identical and similar words are lined
up with each other, via empty-string padding.

Please see the documentation for L<Text::TEI::Collate::Manuscript> and
L<Text::TEI::Collate::Word> for more information about the manuscript and
word objects.

=head1 METHODS

=head2 new

Creates a new aligner object.  Takes a hash of options; available
options are listed.

=over 4

=item B<debuglevel> - Default 0. The higher the number (between 0 and 3), the 
more the debugging output.

=item B<title> - Display title for the collation output results, should those
results need a display title (e.g. TEI or JSON output).

=item B<language> - Specify the language module we should use from those
available in Text::TEI::Collate::Lang.  Default is 'Default'.

=item B<fuzziness> - The maximum allowable word distance for an approximate
match, expressed as a percentage of word distance / word length. It can
also be expressed as a hashref with keys 'val', 'short', and 'shortval', if
you want to increase the tolerance for short words (defined as at or below the
value of 'short').

=item B<binmode> - If STDERR should be using something other than UTF-8, you 
can set it here. You are probably in for a world of hurt anyway though.

=back

=begin testing

use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();

is( ref( $aligner ), 'Text::TEI::Collate', "Got a Collate object from new()" );

=end testing

=cut

# Set the options.  Main option is a pointer to the fuzzy matching algorithm
# that the user wishes to use.

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;
    # Support a single 'fuzziness' argument
    if( exists $args{'fuzziness'} && !ref( $args{'fuzziness'} ) ) {
        my $fuzz = $args{'fuzziness'};
		$args{'fuzziness'} = { val => $fuzz, short => '0', shortval => $fuzz };
	}
	return $class->$orig( %args );
};

sub BUILD {
	my $self = shift;
	if( $self->has_binmode ) {
	    my $b = $self->binmode;
		binmode STDERR, ":$b";
	}
	
	$self->_use_language( $self->language );
}

around 'language' => sub {
	my $orig = shift;
	my $self = shift;
	if( @_ ) {
		# Check that we can use this language.
		$self->_use_language( @_ );
	}
	# We didn't throw an exception? Good.
	$self->$orig( @_ );
};

=begin testing

use Text::TEI::Collate;
use TryCatch;

my $aligner = Text::TEI::Collate->new();
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Default::distance, "Have correct default distance sub" );
my $ok = eval { $aligner->language( 'Armenian' ); };
ok( $ok, "Used existing language module" );
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Armenian::distance, "Set correct distance sub" );

$aligner->language( 'default' );
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Default::distance, "Back to default distance sub" );

# TODO test Throwable object
try {
    $aligner->language( 'Klingon' );
} catch( Text::TEI::Collate::Error $e ) {
    is( $e->ident, 'bad language module', "Caught the lang module error we expected" );
} catch {
    ok( 0, "FAILED to catch expected exception" );
}
=end testing

=cut

sub _use_language {
    my( $self, $lang ) = @_;
    # Are we reverting to a default?
    if( !$lang || $lang =~ /default/i ) {
        # Use the default.
        $lang = 'Default';
    } 
    
    # Is the given language module defined, and does it have all the
    # required subroutines?
    my $mod = 'Text::TEI::Collate::Lang::' . $lang;
    try {
        load( $mod );
    } catch {
        throw( ident => 'bad language module',
               message => "Could not load $lang module: $@" );
    }
    foreach my $langsub ( qw/ distance canonizer comparator / ) {
        unless( $mod->can( $langsub ) ) {
            throw( ident => 'bad language module',
                   message => "Language module $lang has no $langsub function" );
        }
    }
    $self->distance_sub( $mod->can( 'distance' ) );
}

=head2 read_source

Pass in a word source (a plaintext file, a TEI XML file, or a JSON structure) 
and a set of options, and get back one or more manuscript objects that can be 
collated.  Options include:

=over

=item B<encoding> - The encoding of the word source if we are reading from a file.  
Defaults to utf-8.

=item B<sigil> - The sigil that should be assigned to this manuscript in the collation 
output.  Should be a valid XML attribute value.  This can also be read from a
TEI XML source.

=item B<identifier> - A string to identify this manuscript (e.g. library, MS number).
Can also be read from a TEI <msdesc/> element.

=back

=begin testing

use XML::LibXML;

my $aligner = Text::TEI::Collate->new();
$aligner->language( 'Armenian' );

# Test a manuscript with a plaintext source, filename

my @mss = $aligner->read_source( 't/data/plaintext/test1.txt',
	'identifier' => 'plaintext 1',
	);
is( scalar @mss, 1, "Got a single object for a plaintext file");
my $ms = pop @mss;
	
is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'A', "Got correct sigil A");
is( scalar( @{$ms->words}), 181, "Got correct number of words in A");

# Test a manuscript with a plaintext source, string
open( T2, "t/data/plaintext/test2.txt" ) or die "Could not open test file";
my @lines = <T2>;
close T2;
@mss = $aligner->read_source( join( '', @lines ),
	'identifier' => 'plaintext 2',
	);
is( scalar @mss, 1, "Got a single object for a plaintext string");
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'B', "Got correct sigil B");
is( scalar( @{$ms->words}), 183, "Got correct number of words in B");
is( $ms->identifier, 'plaintext 2', "Got correct identifier for B");

# Test two manuscripts with a JSON source
open( JS, "t/data/json/testwit.json" ) or die "Could not read test JSON";
@lines = <JS>;
close JS;
@mss = $aligner->read_source( join( '', @lines ) );
is( scalar @mss, 2, "Got two objects from the JSON string" );
is( ref( $mss[0] ), 'Text::TEI::Collate::Manuscript', "Got manuscript object 1");
is( ref( $mss[1] ), 'Text::TEI::Collate::Manuscript', "Got manuscript object 2");
is( $mss[0]->sigil, 'MsAJ', "Got correct sigil for ms 1");
is( $mss[1]->sigil, 'MsBJ', "Got correct sigil for ms 2");
is( scalar( @{$mss[0]->words}), 182, "Got correct number of words in ms 1");
is( scalar( @{$mss[1]->words}), 263, "Got correct number of words in ms 2");
is( $mss[0]->identifier, 'JSON 1', "Got correct identifier for ms 1");
is( $mss[1]->identifier, 'JSON 2', "Got correct identifier for ms 2");

# Test a manuscript with an XML source
@mss = $aligner->read_source( 't/data/xml_plain/test3.xml' );
is( scalar @mss, 1, "Got a single object from XML file" );
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'BL5260', "Got correct sigil BL5260");
is( scalar( @{$ms->words}), 178, "Got correct number of words in MsB");
is( $ms->identifier, 'London OR 5260', "Got correct identifier for MsB");

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file( 't/data/xml_plain/test3.xml' );
@mss = $aligner->read_source( $doc );
is( scalar @mss, 1, "Got a single object from XML object" );
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'BL5260', "Got correct sigil BL5260");
is( scalar( @{$ms->words}), 178, "Got correct number of words in MsB");
is( $ms->identifier, 'London OR 5260', "Got correct identifier for MsB");

## The mss we will test the rest of the tests with.
$aligner->language( 'Greek' );
@mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
is( scalar @mss, 28, "Got correct number of mss from CX file" );
my %wordcount = (
	'base' => 57,
	'P60' => 20,
	'P66' => 55,
	'w1' => 58,
	'w11' => 57,
	'w13' => 58,
	'w17' => 58,
	'w19' => 57,
	'w2' => 58,
	'w21' => 58,
	'w211' => 54,
	'w22' => 57,
	'w28' => 57,
	'w290' => 46,
	'w3' => 56,
	'w30' => 59,
	'w32' => 58,
	'w33' => 57,
	'w34' => 58,
	'w36' => 58,
	'w37' => 56,
	'w38' => 57,
	'w39' => 58,
	'w41' => 58,
	'w44' => 56,
	'w45' => 58,
	'w54' => 57,
	'w7' => 57,
);
foreach( @mss ) {
	is( scalar @{$_->words}, $wordcount{$_->sigil}, "Got correct number of words for " . $_->sigil );
}

=end testing

=cut 

sub read_source {
	my( $self, $wordsource, %options ) = @_;
	my @docroots;  # Holds an array of { sigil, source }
	my $format;
	
	if( !ref( $wordsource ) ) {  # Assume it's a filename.
		my $parser = XML::LibXML->new();
		my $doc;
		eval { local $SIG{__WARN__} = sub { 1 }; $doc = $parser->parse_file( $wordsource ); };
		if( $doc ) {
			( $format, @docroots) = _get_xml_roots( $doc );
			return unless @docroots;
		} else {
			# It's not an XML document filename.  Determine plaintext
			# filename, plaintext string, or JSON string.
			my $encoding = delete $options{'binmode'};
			$encoding ||= 'utf8';
			my $binmode = "<:" . $encoding;
			my $rc = open( INFILE, $binmode, $wordsource );
			$format = 'plaintext';
			if( $rc ) {
				# It is a filename, thus plaintext.
				my @lines = <INFILE>;
				close INFILE;
				@docroots = ( { source => join( '', @lines ) } );
			} else {
				my $json;
				eval { $json = decode_json( $wordsource ) };
				if( $json ) {
					# It is a JSON string.
					$format = 'json';
					push( @docroots, map { { source => $_ } } @{$json->{'witnesses'}} );
				} else {
					# Assume plain old string input.
					@docroots = ( { source => $wordsource } );
				}
			}
		}
	} elsif ( ref( $wordsource ) eq 'XML::LibXML::Document' ) { # A LibXML object
		( $format, @docroots ) = _get_xml_roots( $wordsource );
	} else {
	    throw( ident => 'bad source',
	           message => "Unrecognized object $wordsource; reading no words" );
	}
	
	# Add any language-specific canonizer / comparator that we have defined.
	$options{'language'} = $self->language;

	# We have the representations of the manuscript(s).  Initialize our object(s).
	my @ms_objects;
	foreach my $doc ( @docroots ) {
		push( @ms_objects, Text::TEI::Collate::Manuscript->new( 
			'sourcetype' => $format,
			%options,
			%$doc,
			) );
	}
	return @ms_objects;
}

sub _get_xml_roots {
	my( $xmldoc ) = @_;
	my( @docroots, $format );
	if( $xmldoc->documentElement->nodeName =~ /^examples/i ) {
		# It is CollateX simple input format.  Read the text
		# strings and then treat it as plaintext.
		my @collationtexts = $xmldoc->documentElement->getChildrenByTagName( 'example' );
		if( @collationtexts ) {
			# Use the first text example in the file; we do not handle multiple
			# collation runs on different texts.
			my @witnesses = $collationtexts[0]->getChildrenByTagName( 'witness' );
			@docroots = map { { sigil => $_->getAttribute( 'id' ),
								source => $_->textContent } } @witnesses;
			$format = 'plaintext';
		} else {
            throw( ident => 'bad source',
	               message => "Found no example elements in CollateX XML" );
		}
	} else {
		# Assume that it is TEI format.  We will throw an error later if not.
		@docroots = ( { source => $xmldoc->documentElement } );
		$format = 'xmldesc';
	}
	return( $format, @docroots );  
}

=head2 align

The meat of the program.  Takes a list of Text::TEI::Collate::Manuscript 
objects (created by new_manuscript above.)  Returns the same objects with 
their wordlists collated. 

=begin testing

my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
my @orig_wordlists = map { $_->words } @mss;
$aligner->align( @mss );
my $cols = 75;
foreach( @mss ) {
	is( scalar @{$_->words}, $cols, "Got correct collated columns for " . $_->sigil);
}
foreach my $i ( 0 .. $#mss ) {
    my $ms = $mss[$i];
    my @old_words = map { $_->canonical_form } @{$orig_wordlists[$i]};
    my @real_words = map { $_->canonical_form } grep { !$_->invisible } @{$ms->words};
    is( scalar @old_words, scalar @real_words, "Manuscript " . $ms->sigil . " has an unchanged word total" );
    foreach my $j ( 0 .. $#old_words ) {
        my $rw = $j < scalar @real_words ? $real_words[$j] : '';
        is( $rw, $old_words[$j], "...word at index $j is correct" );
    }
}

=end testing

=cut

sub align {
	my( $self, @manuscripts ) = @_;

 	if( scalar( @manuscripts ) == 1 ) {
		# That was easy then.
		return @manuscripts;
	}

	# At this point we have an array of arrays.  Each member array
 	# contains a hash object for each word, describing its
 	# characteristics.  These are the uncollated texts, now in the
 	# object form that we will eventually return.

 	# The first file becomes the base, for now.
 	# SOMEDAY: Work parsimony info into the choosing of a base
	my @ms_texts = map { $_->words } @manuscripts;
	my $base_text = shift @ms_texts;

	for ( 0 .. $#ms_texts ) {
		my $text = $ms_texts[$_];
		$self->debug( "Beginning run of build_array for text " . ($_+2) );
		my( $result1, $result2 ) = $self->build_array( $base_text, $text );
		
		# Are the resulting arrays the same length?
		if( scalar( @$result1 ) != scalar( @$result2 ) ) {
            throw( ident => 'bad collation',
                   message => "Result arrays for text $_ are not the same length!" );
		}
		
		# Generate the new base by flattening result2 onto the back of result1,
		# filling in all the gaps.
		$base_text = $self->generate_base( $result1, $result2 );
	}

	# $base_text now holds all the words, linked in one way or another.
	# Make a result array from this.
  	my @result_array = map { [] } @manuscripts;
	my %ridx;
	foreach( 0 .. $#manuscripts ) {
  		$ridx{ $manuscripts[$_]->sigil } = $_;
	}
	foreach my $word ( @$base_text ) {
 		my %unseen;
 		map { $unseen{$_->sigil} = 1 } @manuscripts;
 		my @row_words;
 		push( @row_words, $word, $word->links );
 		foreach ( $word->variants ) {
			push( @row_words, $_, $_->links );
		}
 		foreach my $r ( @row_words ) {
			push( @{$result_array[$ridx{$r->ms_sigil}]}, $r );
			delete $unseen{$r->ms_sigil};
 		}
 		foreach my $s ( keys %unseen ) {
			push( @{$result_array[$ridx{$s}]}, $self->empty_word );
 		}
	}

	# Take the contents of @result_array and put them back into the
 	# manuscripts.
	foreach my $i ( 0 .. $#result_array ) {
		$manuscripts[$i]->replace_words( $result_array[$i] );
	}

    # Top and tail each array.
	$self->begin_end_mark( @manuscripts );
	return @manuscripts;
}

# Small utility to get a string out of an array of word objects.
sub _stripped_words {
    my $text = shift;
    my @words = map { $_->comparison_form } @$text;
    return @words;
}

sub empty_word {
    my $self = shift;
    unless( defined $self->{'null_word'} 
	    && ref( $self->{'null_word'} ) eq 'Text::TEI::Collate::Word' ) {
	# Make a null word and save it.
	$self->{'null_word'} = Text::TEI::Collate::Word->new( empty => 1 );
    }
    return $self->{'null_word'};
}

# Given two collections of word objects, return two collated collections of
# word objects.  Pass a ref to the whole array so far so that we can consult
# it if necessary.  That array should *not* be written to here below.
sub build_array {
 	my $self = shift;
 	my( $base_text, $text ) = @_;
 	my( @base_result, @new_result );   # All the good things we'll return.
	# Generate our fuzzy-match lookup table.
	$self->make_fuzzy_matches( $base_text, $text );
	# Do the diff.
 	my $diff = Text::TEI::Collate::Diff->new( $base_text, $text, $self );
	while( my $diffpos = $diff->Next ) {
		if( $diff->Same ) {
  			$self->_handle_diff_same( $diff, $base_text, $text, \@base_result, \@new_result );
		} elsif( !scalar( $diff->Range( 1 ) ) ) {  # Addition
 			$self->_handle_diff_interpolation( $diff, 2, $text, \@new_result, \@base_result );
		} elsif( !scalar( $diff->Range( 2 ) ) ) {  # Deletion
			$self->_handle_diff_interpolation( $diff, 1, $base_text, \@base_result, \@new_result );
		} else {  # No fuzzy matching here.
			$self->debug( "Diff: collating words " 
 				. join( '.', map { $_->comparison_form } $diff->Items( 1 ) ) . " / " 
 				. join( '.', map { $_->comparison_form } $diff->Items( 2 ) ), 1 );
	    
			# Grab the word sets from each text.
			my @base_wlist = @{$base_text}[$diff->Range( 1 )];
			my @new_wlist = @{$text}[$diff->Range( 2 )];
			# Does the base have variants against which we can collate the 
			# new words? If so, try running against the variants, and 
			# collate according to the result.
			my @var_wlist;
 			my %base_idx;
 			map { push( @var_wlist, $_->variants ) } @base_wlist;
			my $matched_variants;
			my( $b, $n );
 			if( scalar @var_wlist ) {
				# Keep track of which base index each variant is at
				foreach my $i ( 0 .. $#base_wlist ) {
					foreach my $v ( $base_wlist[$i]->variants ) {
						$base_idx{$v} = $i;
					}
				}
				# Get the last variant(s) of the previous hunk
				if( @base_result ) {
					unshift( @var_wlist, $base_result[-1]->variants );
					foreach my $v ( $base_result[-1]->variants ) {
						$base_idx{$v} = -1;
					}
				}
				# Get the first variant(s) of the next hunk
				if( $diff->Next && $diff->Items(1) ) {
					my @next = $diff->Items(1);
					push( @var_wlist, $next[0]->variants );
					foreach my $v ( $next[0]->variants ) {
						$base_idx{$v} = scalar @base_wlist;
					}
				}
				# Put the diff back where it was.
				$diff->Reset( $diffpos );
			
				# Collate against the variants
				my @match_sets = $self->_match_variants( \@var_wlist, \@new_wlist, \%base_idx );
				if( @match_sets ) {
					$matched_variants = 1;
					( $b, $n ) = $self->_add_variant_matches( \@match_sets, \@base_wlist, \@new_wlist, \%base_idx );
				}
			}
			unless( $matched_variants ) {
				( $b, $n ) = ( \@base_wlist, \@new_wlist );
				$self->_balance_arrays( $b, $n );
			}
			push( @base_result, @$b );
			push( @new_result, @$n );
		}	
	}

 	return( \@base_result, \@new_result );
}

sub _balance_arrays {
 	my( $self, $base, $new, $nolink ) = @_;
 	my $difflen = @$base - @$new;
 	my $shorter = $difflen > 0 ? $new : $base;
	push( @$shorter, ( $self->empty_word ) x abs( $difflen ) ) if $difflen;
	# Set variant links.
	unless( $nolink ) {
		foreach my $i ( 0 .. $#{$base} ) {
			next if $base->[$i] eq $self->empty_word;
			next if $new->[$i] eq $self->empty_word;
			$base->[$i]->add_variant( $new->[$i] );
		}
	}
	return( $base, $new );
}

=begin testing

use Text::TEI::Collate;

my @test = (
    'the black dog had his day',
    'the white dog had her day',
    'the bright red dog had his day',
    'the bright white cat had her day',
);
my $aligner = Text::TEI::Collate->new();
my @mss = map { $aligner->read_source( $_ ) } @test;
$aligner->align( @mss );
my $base = $aligner->generate_base( @mss );
# Get rid of the specials
pop @$base;
shift @$base;
is( scalar @$base, 8, "Got right number of words" );
is( $base->[0]->word, 'the', "Got correct first word" );
is( scalar $base->[0]->links, 3, "Got 3 links" );
is( scalar $base->[0]->variants, 0, "Got 0 variants" );
is( $base->[1]->word, 'black', "Got correct second word" );
is( scalar $base->[1]->links, 0, "Got 0 links" );
is( scalar $base->[1]->variants, 1, "Got 1 variant" );
is( $base->[1]->get_variant(0)->word, 'bright', "Got correct first variant" );
is( scalar $base->[1]->get_variant(0)->links, 1, "Got a variant link" );
is( $base->[2]->word, 'white', "Got correct second word" );
is( scalar $base->[2]->links, 1, "Got 1 links" );
is( scalar $base->[2]->variants, 0, "Got 0 variants" );
is( $base->[3]->word, 'red', "Got correct third word" );
is( scalar $base->[3]->links, 0, "Got 0 links" );
is( scalar $base->[3]->variants, 1, "Got a variant" );
is( $base->[3]->get_variant(0)->word, 'cat', "Got correct second variant" );
is( scalar $base->[3]->get_variant(0)->links, 0, "Variant has no links" );
is( $base->[4]->word, 'dog', "Got correct fourth word" );
is( scalar $base->[4]->links, 2, "Got 2 links" );
is( scalar $base->[4]->variants, 0, "Got 0 variants" );
is( $base->[5]->word, 'had', "Got correct fifth word" );
is( scalar $base->[5]->links, 3, "Got 3 links" );
is( scalar $base->[5]->variants, 0, "Got 0 variants" );
is( $base->[6]->word, 'his', "Got correct sixth word" );
is( scalar $base->[6]->links, 1, "Got 1 link" );
is( scalar $base->[6]->variants, 1, "Got 1 variant" );
is( scalar $base->[6]->get_variant(0)->links, 1, "Got 1 variant link" );
is( $base->[6]->get_variant(0)->word, 'her', "Got correct third variant");
is( $base->[7]->word, 'day', "Got correct seventh word" );
is( scalar $base->[7]->links, 3, "Got 3 links" );
is( scalar $base->[7]->variants, 0, "Got 0 variants" );

=end testing

=cut

sub _match_variants {
	my( $self, $variants, $new, $base_idx ) = @_;
	my @match_sets;
	my $last_idx_matched = -1;
	my %variant_matched;
	foreach my $n_idx ( 0 .. $#{$new} ) {
		my $n = $new->[$n_idx];
		foreach my $v ( @$variants ) {
			next if $base_idx->{$v} < $last_idx_matched;
			next if exists $variant_matched{$v};
			if( $self->{fuzzy_matches}->{$n->comparison_form}
				eq $self->{fuzzy_matches}->{$v->comparison_form} ) {
				$v->add_link( $n );
				$variant_matched{$v} = 1;
				push( @match_sets, [ $base_idx->{$v}, $n_idx, $v ] );
				$last_idx_matched = $base_idx->{$v};
				last; # N is matched, stop looking at Vs.
			}
		}
	}
	return @match_sets;
}

=begin testing

use Text::TEI::Collate;
use Text::TEI::Collate::Word;

my $aligner = Text::TEI::Collate->new();

# Set up the base: 'and|B(very|D) white|B(green|C/special|D)'
my @base;
foreach my $w ( qw/ and white / ) {
    push( @base, Text::TEI::Collate::Word->new( 'string' => $w, 'ms_sigil' => 'B' ) );
}
my $v1 = Text::TEI::Collate::Word->new( 'string' => 'very', 'ms_sigil' => 'D' );
$base[0]->add_variant( $v1 );
my $v2 = Text::TEI::Collate::Word->new( 'string' => 'green', 'ms_sigil' => 'C' );
my $v3 = Text::TEI::Collate::Word->new( 'string' => 'special', 'ms_sigil' => 'D' );
$v2->add_variant( $v3 );
$base[1]->add_variant( $v2 );

# Set up the new: 'not very special'
my @new;
foreach my $w ( qw/ not very special / ) {
    push( @new, Text::TEI::Collate::Word->new( 'string' => $w, 'ms_sigil' => 'E' ) );
}

# Set up the base_idx
my $base_idx = { $v1 => 0, $v2 => 1, $v3 => 1 };

# Get the right matches in the first place
$aligner->make_fuzzy_matches( [ @base, $v1, $v2, $v3 ], \@new );
my @matches = $aligner->_match_variants( [ $v1, $v2, $v3 ], \@new, $base_idx );
is( scalar @matches, 2, "Got two matches from constructed case" );
is_deeply( $matches[0], [ 0, 1, $v1 ], "First match is correct" );
is_deeply( $matches[1], [ 1, 2, $v3 ], "Second match is correct" );

# Now do the real testing
my( $nb, $nn ) = $aligner->_add_variant_matches( \@matches, \@base, \@new, $base_idx );
is( scalar @$nb, 3, "Got three base words" );
is( scalar @$nn, 3, "Got three new words" );
is( $nb->[0], $aligner->empty_word, "Empty word at front of base" );

=end testing

=cut

sub _add_variant_matches {
 	my( $self, $match_sets, $base, $new, $base_idx ) = @_;
 	my( $base_wlist, $new_wlist ) = ( [], [] );

 	my( $last_b, $last_n ) = ( -1, -1 );
	my %seen_base_indices;
	foreach my $p ( @$match_sets ) {
		my( $b_idx, $n_idx, $v ) = @$p;
		# Balance the arrays up to the indices we have.
		my( @tb, @tn );
		if( $b_idx > $last_b+1 
 			&& $b_idx < scalar @$base ) {
 			@tb = @{$base}[ ( $last_b < 0 ? 0 : $last_b ) .. $b_idx-1];
		}
		if( $n_idx > $last_n+1 ) {
			@tn = @{$new}[ ( $last_n < 0 ? 0 : $last_n ) .. $n_idx-1];
		}
		$self->_balance_arrays( \@tb, \@tn );
		push( @$base_wlist, @tb ) if @tb;
		push( @$new_wlist, @tn ) if @tn;

		# If this is the first occurrence of $b_idx, push the pair.
		# If it is not the first occurrence, we have more than one 'new' 
		# match on one 'base' plus variants.  Unlink the subsequent 
		# variant into its own column and then push the pair.
		if( $seen_base_indices{$b_idx} 
 			|| $b_idx == -1
			|| $b_idx == scalar( @$base ) ) {
  			# Unlink variant from base, push as extra.
 			$v->variant_of->unlink_variant( $v );
 			# Push the variant.
			push( @$base_wlist, $v );
		} else {
 			# Just push the base.
 			push( @$base_wlist, $base->[$b_idx] );
		}
		# Either way, push the new.
		push( @$new_wlist, $new->[$n_idx] );
		$seen_base_indices{$b_idx} = 1;

		# Save the index pair we were just working on.
		( $last_b, $last_n ) = ( $b_idx, $n_idx );
    }

	# Now push whatever remains of each array.
	my( @tb, @tn );
	if( scalar @$base > $last_b+1 ) {
		@tb = @{$base}[$last_b+1 .. $#{$base}];
	}
	if( scalar @$new > $last_n+1 ) {
		@tn = @{$new}[$last_n+1 .. $#{$new}];
	}
	$self->_balance_arrays( \@tb, \@tn );
	push( @$base_wlist, @tb ) if @tb;
	push( @$new_wlist, @tn ) if @tn;

	# ...and return the whole.
	return( $base_wlist, $new_wlist );
}

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate;
use Text::TEI::Collate::Word;
use Text::WagnerFischer;

my $base_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'հարիւրից' );
my $variant_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'զ100ից' );
my $match_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'զհարիւրից' );
my $new_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => '100ից' );
my $different_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'անգամ' );

# not really Greek, but we want Text::WagnerFischer::distance here
my $aligner = Text::TEI::Collate->new( 'language' => 'Greek' ); 
$base_word->add_variant( $variant_word );
is( $aligner->word_match( $base_word, $match_word), $base_word, "Matched base word" );
is( $aligner->word_match( $base_word, $new_word), $variant_word, "Matched variant word" );
is( $aligner->word_match( $base_word, $different_word), undef, "Did not match irrelevant words" );

my( $ms1 ) = $aligner->read_source( 'Jn bedwange harde swaer Doe riepen si op gode met sinne' );
my( $ms2 ) = $aligner->read_source( 'Jn bedvanghe harde suaer. Doe riepsi vp gode met sinne.' );
$aligner->make_fuzzy_matches( $ms1->words, $ms2->words );
is( scalar keys %{$aligner->{fuzzy_matches}}, 15, "Got correct number of vocabulary words" );
my %unique;
map { $unique{$_} = 1 } values %{$aligner->{fuzzy_matches}};
is( scalar keys %unique, 11, "Got correct number of fuzzy matching words" );

=end testing

=cut

# TODO This doesn't match against base variants - does that matter?
sub make_fuzzy_matches {
	my( $self, $base, $other ) = @_;
	my %frequency;
	map { $frequency{$_->comparison_form}++ } @$base;
	map { $frequency{$_->comparison_form}++ } @$other;
	my $fm = $self->{fuzzy_matches};
	unless( $fm ) {
		$fm = {};
		$self->{fuzzy_matches} = $fm;
	}
	my @all_words = sort { $frequency{$b} <=> $frequency{$a} } keys %frequency;
	while( @all_words ) {
		my $w = shift @all_words;
		# Skip it if we already have a fuzzy match for $w.
		next if exists $fm->{$w};
		# $w matches itself if nothing else.
		$fm->{$w} = $w;
		# What else does $w match?
		foreach my $x ( @all_words ) {
			if( $self->_is_near_word_match( $w, $x ) ) {
				# If $x already exists, it was probably more popular.  Use
				# it instead.
				if( exists $fm->{$x} ) {
					$fm->{$w} = $x;
					last;
				} else {
					# Otherwise make $x match $w.
					$fm->{$x} = $w;
				}
			}
		}
	}
}

# A key generation function for our Diff module.	Always return the comparison
# string for the base text word; if the non-base word is in $a and it doesn't
# match the base (which is therefore in $b), return its own comparison string.

sub diff_key {
	my( $self, $word ) = @_;
	return $self->{fuzzy_matches}->{$word->comparison_form};
}

sub word_match {
	# A and B are word objects.  We want to match if b matches a, 
	# but also if b matches a variant of a.
	my( $self, $a, $b, $use_diffkey ) = @_;
	my $a_key = $a->comparison_form;
	$a_key = $self->diff_key( $a ) if $self->diff_key( $a ) && $use_diffkey;
	my $b_key = $b->comparison_form;
	$b_key = $self->diff_key( $b ) if $self->diff_key( $b ) && $use_diffkey;
	if( $self->_is_near_word_match( $a_key, $b_key ) ) {
		return $a;
	}
	foreach my $v ( $a->variants ) {
	    my $v_key = $v->comparison_form;
	    $v_key = $self->diff_key( $v ) if $self->diff_key( $v ) && $use_diffkey;
		if( $self->_is_near_word_match( $v_key, $b_key ) ) {
			return $v;
		}
	}
	return undef;
}

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();
ok( $aligner->_is_near_word_match( 'Արդ', 'Արդ' ), "matched exact string" );
ok( $aligner->_is_near_word_match( 'հաւասն', 'զհաւասն' ), "matched near-exact string" );
ok( !$aligner->_is_near_word_match( 'հարիւրից', 'զ100ից' ), "did not match differing string" );
ok( !$aligner->_is_near_word_match( 'ժամանակական', 'զշարագրական' ), "did not match differing string 2" );
ok( $aligner->_is_near_word_match( 'ընթերցողք', 'ընթերցողսն' ), "matched near-exact string 2" );
ok( $aligner->_is_near_word_match( 'պատմագրացն', 'պատգամագրացն' ), "matched pretty close string" );
ok( $aligner->_is_near_word_match( 'αι̣τια̣ν̣', 'αιτιαν' ), "matched string one direction" );
ok( $aligner->_is_near_word_match( 'αιτιαν', 'αι̣τια̣ν̣' ), "matched string other direction" );

=end testing

=cut

sub _is_near_word_match {
 	my $self = shift;
 	my( $word1, $word2 ) = @_;
    
 	# Find our distance routine in case we need it.
	unless( ref $self->distance_sub ) {
		throw( ident => 'bad language module',
		       message => "No word comparison algorithm specified." );
 	}
 	my $dist = $self->distance_sub->( $word1, $word2 );

  	# Now see if the distance is low enough to be a match.
  	my $answer;
	if( $self->has_fuzziness_sub ) {
		$answer = $self->fuzziness_sub->( $word1, $word2, $dist );
	} else {
		my $ref_str = length( $word1 ) < length( $word2 ) ? $word1 : $word2;
		my $fuzz = length( $ref_str ) > $self->fuzziness->{short}
			? $self->fuzziness->{val} : $self->fuzziness->{shortval};
		$answer = $dist <= ( length( $ref_str ) * $fuzz / 100 );
	}
	# $self->debug( "Words $word1 and $word2 " . ( $answer ? 'matched' : 'did not match' ), 3 );
	return $answer;
}

## Diff handling functions.  Used in build_array and in match_and_align_words.  
## Thanks to our array-substitution trickery in match_and_align_words, we may
## not assume that the $diff object has the actual items we want.  Only the
## indices are meaningful.

sub _handle_diff_same {
	my $self = shift;
	my( $diff, $base_text, $new_text, $base_result, $new_result ) = @_;
 	# Get the index range.
	my @rbase = $diff->Range( 1 );
	my @rnew = $diff->Range( 2 );
 	my @base_wlist = @{$base_text}[@rbase];
	my @new_wlist = @{$new_text}[@rnew];
 	my $msg_words = join( ' ', _stripped_words( \@base_wlist ) );
	$msg_words .= ' / ' . join( ' ', _stripped_words( \@new_wlist ) );
 	$self->debug( "Diff: pushing matched words $msg_words", 2 );
	foreach my $i ( 0 .. $#base_wlist ) {
		# Link the word to its match.  This means having to compare
		# the words again, grr argh.  Use the diff key this time because
		# we used it when finding these 'same'.
		my $matched = $self->word_match( $base_wlist[$i], $new_wlist[$i], 1 );
		$DB::single = 1 if !$matched;
		$matched->add_link( $new_wlist[$i] );
	}
	push( @$base_result, @base_wlist );
	push( @$new_result, @new_wlist );
}

sub _handle_diff_interpolation {
    my $self = shift;
    my( $diff, $which, $from_text, $from_result, $to_result ) = @_;
    
    # $which has either 1 or 2, stating which array in $diff has the items.
    # $from_result corresponds to $which.
    my $op = $which == 1 ? 'deletion' : 'addition';
    my @range = $diff->Range( $which );
    my @wlist = @{$from_text}[@range];
    
    $self->debug( "DBrecord: pushing $op " 
		  . join( ' ',  _stripped_words( \@wlist ) ), 2 );
    push( @$to_result, ( $self->empty_word ) x scalar( @wlist ) );
    push( @$from_result, @wlist );
}

# generate_base: Take an array of text arrays and flatten them.  There
# should not be a blank element in the resulting base.  Currently
# used for only two input arrays at a time.  

sub generate_base {
    my $self = shift;
    my @texts = @_;

	my @word_arrays;
	foreach( @texts ) {
		push( @word_arrays, 
			ref( $_ ) eq 'Text::TEI::Collate::Manuscript' ? $_->words : $_ );
	}
	
	# Error checking: are they all the same length?
	my $width = scalar @word_arrays;
	my $length = scalar @{$word_arrays[0]};
	foreach my $t ( @word_arrays ) {
		throw( ident => 'bad result',
		       message => 'Word arrays differ in length: ' . scalar @$t . "vs. $length" )
		    unless @$t == $length;
	}

	# Get busy.	 Take a word from T0 if it's there; otherwise take a word
	# from T1, otherwise T2, etc.  
	my @new_base;
	foreach my $idx ( 0 .. $length-1 ) {
		my $word = $self->empty_word;  # We should never end up using this
									 # word, but just in case there is a
									 # gap, it should be the right object.
		foreach my $col ( 0 .. $width - 1 ) {
			if( $word_arrays[$col]->[$idx]->comparison_form ne '' ) {
				$word = $word_arrays[$col]->[$idx];
				$word->is_base( 1 );
				last;
			}
		}
		# Disabled due to BEGIN shenanigans
		# warn( "No word found in any column at index $idx!" )
			# if( $word eq $self->empty_word );
		push( @new_base, $word );
	}
    
    return \@new_base;
}

# Helper function for begin_end_mark
sub _wordlist_slice {
    my $self = shift;
    my( $list, $entry, $replace ) = @_;
    my( $toss, $size, $idx ) = split( /_/, $entry );
    if( $replace ) {
	my @repl_array;
	if( $replace eq 'empty' ) {
	    @repl_array = ( $self->empty_word ) x $size;
	} elsif( ref $replace eq 'ARRAY' ) {
	    @repl_array = @$replace;
	}
	splice( @$list, $idx-$size+1, $size, @repl_array );
    } else {
	return @{$list}[ ($idx-$size+1) .. $idx ];
    }
}

=begin testing

use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();
my( $base ) = $aligner->read_source( 'The black cat' );
my( $other ) = $aligner->read_source( 'The black and white little cat' );
$aligner->align( $base, $other );
# Check length
is( scalar @{$base->words}, 8, "Got six columns plus top and tail" );
is( scalar @{$other->words}, 8, "Got six columns plus top and tail" );
# Check contents
is( $base->words->[-1]->special, 'END', "Got ending mark at end" );
is( $base->words->[0]->special, 'BEGIN', "Got beginning mark at start" );
is( $other->words->[-1]->special, 'END', "Got ending mark at end" );
is( $other->words->[0]->special, 'BEGIN', "Got beginning mark at start" );
# Check empty spaces
my $base_exp = [ 'BEGIN', 'the', 'black', '', '', '', 'cat', 'END' ];
my $other_exp = [ 'BEGIN', 'the', 'black', 'and', 'white', 'little', 'cat', 'END' ];
my @base_str = map { $_->printable } @{$base->words};
my @other_str = map { $_->printable } @{$other->words};
is_deeply( \@base_str, $base_exp, "Right sequence of words in base" );
is_deeply( \@other_str, $other_exp, "Right sequence of words in other" );

my @test = (
    'The black dog chases a red cat.',
    'A red cat chases the black dog.',
    'A red cat chases the yellow dog<',
);
my @mss = map { $aligner->read_source( $_ ) } @test;
$aligner->align( @mss );

$base = $mss[0];
$other = $mss[2];
is( scalar @{$base->words}, 13, "Got 11 columns plus top and tail" );
is( scalar @{$other->words}, 13, "Got 11 columns plus top and tail" );
$base_exp = [ 'BEGIN', 'the', 'black', 'dog', 'chases', 'a', 'red', 'cat', 'END', '', '', '', '' ];
$other_exp = [ '', '', '', '', 'BEGIN', 'a', 'red', 'cat', 'chases', 'the', 'yellow', 'dog', 'END' ];
@base_str = map { $_->printable } @{$base->words};
@other_str = map { $_->printable } @{$other->words};
is_deeply( \@base_str, $base_exp, "Right sequence of words in base" );
is_deeply( \@other_str, $other_exp, "Right sequence of words in other" );
is( $base->words->[-5]->special, 'END', "Got ending mark at end for base" );
is( $base->words->[0]->special, 'BEGIN', "Got beginning mark at start for base" );
is( $other->words->[-1]->special, 'END', "Got ending mark at end for other" );
is( $other->words->[4]->special, 'BEGIN', "Got beginning mark at start for other" );

=end testing

=cut

# begin_end_mark: Note, with special words spliced in, where each
# text actually begins and ends.
my $GAP_MIN_SIZE = 18;
sub begin_end_mark {
	my $self = shift;
	my @manuscripts = @_;
	foreach my $text( @manuscripts ) {
		my $wordlist = $text->words;
		my $sigil = $text->sigil;
		my $first_word_idx = -1;
		my $last_word_idx = -1;
		my $gap_start = -1;
		my $gap_end = -1;
		foreach my $idx ( 0 .. $#{$wordlist} ) {
			my $word_obj = $wordlist->[$idx];
			if( $first_word_idx > -1 ) {
				# We have found and coped with the first word; 
				# now we are looking for substantive gaps.
				if ( !$word_obj->is_empty ) {
					$last_word_idx = $idx;
					if( $gap_start > 0 &&
						( $gap_end - $gap_start ) > $GAP_MIN_SIZE ) {
						# Put in the gap start & end markers.  Here we are
						# replacing a blank, rather than adding to the array.
						# This should be okay as we are not changing the index
						# of the rest of the word elements.
						foreach( $gap_start, $gap_end ) {
							my $tag =  $_ < $gap_end ? 'BEGINGAP' : 'ENDGAP';
							my $gapdesc = $tag . "_1_$_";
							$self->_wordlist_slice( $wordlist, $gapdesc,
											[ _special( $tag, $sigil ) ] );
						}
					}
					# Either way we are not now in a gap.  Reset the counters.
					$gap_end = $gap_start = -1;
				# else empty space; have we found a gap?
				} elsif( $gap_start < 0 ) { 
					$gap_start = $idx;
				# else we know we are in a gap; push the end forward.
				} else {
					$gap_end = $idx;
				}
			# else we are still looking for the first non-blank word.
			} elsif( !$word_obj->is_empty ) {
				# We have found the first real word.  Note where the begin
				# marker should go.
				$first_word_idx = $idx;
			} # else it's a blank before the first word.
		} ## end foreach
		
		# Splice in the BEGIN element before the $first_word_idx.
		my $slicedesc = join( '_', 'begin', 0, $first_word_idx-1 );
		$self->_wordlist_slice( $wordlist, $slicedesc, [ _special( 'BEGIN', $sigil ) ] );

		
		# Now put in the END element after the last word found.
		# First account for the fact that we just spliced a BEGIN into the array.
		$slicedesc = join( '_', 'end', 0, $last_word_idx + 1 );
		$self->_wordlist_slice( $wordlist, $slicedesc, 
								[ _special( 'END', $sigil ) ] );
	}
}

# Helper function for begin_end_mark, to create a mark
		
sub _special {
    my( $mark, $sigil ) = @_;
    return Text::TEI::Collate::Word->new( special => $mark, 
					  ms_sigil => $sigil );
}

=head1 OUTPUT METHODS

=head2 to_json

Takes a list of aligned manuscripts and returns a data structure suitable for 
JSON encoding; documented at L<http://gregor.middell.net/collatex/api/collate>

=begin testing

my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
$aligner->align( @mss );
my $jsondata = $aligner->to_json( @mss );
ok( exists $jsondata->{alignment}, "to_json: Got alignment data structure back");
my @wits = @{$jsondata->{alignment}};
is( scalar @wits, 28, "to_json: Got correct number of witnesses back");
# Without the beginning and end marks, we have 75 word spots.
my $columns = 73;
foreach ( @wits ) {
	is( scalar @{$_->{tokens}}, $columns, "to_json: Got correct number of words back for witness")
}

=end testing

=cut

sub to_json {
	my( $self, @mss ) = @_;
	my $result = { 'title' => $self->title, 'alignment' => [] };
	my @invisible_row;

    # Leave out the rows with no actual word tokens.
	foreach my $i ( 0 .. $#{$mss[0]->words} ) {
	    my @rowitems = map { $_->words->[$i] } @mss;
	    push( @invisible_row, $i ) 
	        unless grep { $_ && !$_->invisible } @rowitems;
	}
	foreach my $ms ( @mss ) {
		push( @{$result->{'alignment'}},
			  { 'witness' => $ms->sigil,
				'tokens' => $ms->tokenize_as_json( @invisible_row )->{'tokens'}, } );
	}
	return $result;
}

=head2 to_csv

Takes a list of aligned Manuscript objects and returns a CSV file, one 
column per Manuscript.  The first row contains the manuscript sigla; the 
subsequent rows contain the aligned text.

=begin testing

use IO::String;
use Text::CSV_XS;
use Test::More::UTF8;

my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
$aligner->align( @mss );
my $csvstring = $aligner->to_csv( @mss );
ok( $csvstring, "Got a CSV string returned" );
# Parse the CSV data and test that it parsed
my $io = IO::String->new( $csvstring );
my $csv = Text::CSV_XS->new( { binary => 1 } );

# Test the number of columns in the first row
my $sigilrow = $csv->getline( $io );
ok( $sigilrow, "Got a row" );
is( scalar @$sigilrow, 28, "Got the correct number of witnesses" );

# Test the number of rows in the table
my $rowctr = 0;
while( my $row = $csv->getline( $io ) ) {
    is( scalar @$row, 28, "Got a reading for all columns" );
    $rowctr++;
    if( $rowctr == 1 ) {
        # Test that we are getting our encoding right
        is( $row->[0], "λέγει", "Got the right first word" );
    }
}
is( $rowctr, 73, "Got expected number of rows in CSV" );

=end testing

=cut

sub to_csv {
    my( $self, @mss ) = @_;
    my @out;
    my $csv = Text::CSV_XS->new( { binary => 1, quote_null => 0 } );
    
    # First get the witness sigla.
    my @sigla = map { $_->sigil } @mss;  
    $csv->combine( @sigla );
    push( @out, decode_utf8( $csv->string ) );
    
    # Now go through the aligned text, leaving out invisible-only rows.
    my $length = scalar @{$mss[0]->words};
    foreach my $i ( 0 .. $length-1 ) {
        my @words = map { $_->words->[$i] } @mss;
        next unless grep { $_ && !$_->invisible } @words;
        my $status = $csv->combine( map { $_ ? $_->word : undef } @words );
        throw( ident => 'output error',
	           message => "Could not convert " . $csv->error_input . " to CSV" ) 
	        unless $status;
        push( @out, decode_utf8( $csv->string ) );
    }
    return join( "\n", @out );
}

=head2 to_tei

Takes a list of aligned Manuscript objects and returns a fairly simple TEI 
XML document in parallel segmentation format, with the words lexically marked 
as such.  At the moment returns a single paragraph, with the original div and
paragraph breaks for each witness marked as a <witDetail/> in the apparatus.

=begin testing

use Text::TEI::Collate;
use XML::LibXML::XPathContext;
# Get an alignment to test with
my $testdir = "t/data/xml_plain";
opendir( XF, $testdir ) or die "Could not open $testdir";
my @files = readdir XF;
my @mss;
my $aligner = Text::TEI::Collate->new(
	'fuzziness' => '50',
	'language' => 'Armenian',
	'title' => 'Test Armenian collation',
	);
foreach ( sort @files ) {
	next if /^\./;
	push( @mss, $aligner->read_source( "$testdir/$_" ) );
}
$aligner->align( @mss );

my $doc = $aligner->to_tei( @mss );
is( ref( $doc ), 'XML::LibXML::Document', "Made TEI document header" );
my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
$xpc->registerNs( 'tei', $doc->documentElement->namespaceURI );

# Test the creation of a document header from TEI files
my @witdesc = $xpc->findnodes( '//tei:witness/tei:msDesc' );
is( scalar @witdesc, 5, "Found five msdesc nodes");
my $title = $xpc->findvalue( '//tei:titleStmt/tei:title' );
is( $title, $aligner->title, "TEI doc title set correctly" );

# Test the creation of apparatus entries
my @apps = $xpc->findnodes( '//tei:app' );
is( scalar @apps, 107, "Got the correct number of app entries");
my @words_not_in_app = $xpc->findnodes( '//tei:body/tei:div/tei:p/tei:w' );
is( scalar @words_not_in_app, 175, "Got the correct number of matching words");
my @details = $xpc->findnodes( '//tei:witDetail' );
my @detailwits;
foreach ( @details ) {
	my $witstr = $_->getAttribute( 'wit' );
	push( @detailwits, split( /\s+/, $witstr ));
}
is( scalar @detailwits, 13, "Found the right number of witness-detail wits");

# TODO test the reconstruction of witnesses from the parallel-seg.

=end testing

=cut

## Block for to_tei logic
{
	##  Counter variables
	my $app_id_ctr = 0;  # for xml:id of <app/> tags
	my $word_id_ctr = 0; # for xml:id of <w/> tags that have witDetails
	
	## Constants
	my $ns_uri = 'http://www.tei-c.org/ns/1.0';
	# Local globals
	my ( $doc, $body );

	sub to_tei {
		my( $self, @mss ) = @_;
		( $doc, $body ) = _make_tei_doc( $self->title, @mss );
		##  Generate a base by flattening all the results                               
		my $initial_base = $self->generate_base( map { $_->words } @mss );
		foreach my $idx ( 0 .. $#{$initial_base} ) {
			my %seen;
			map { $seen{$_->sigil} = 0 } @mss;
			_make_tei_app( $initial_base->[$idx], %seen );
		}

		return $doc;
	}
	
	sub _make_tei_doc {
	    my $title = shift;
		my @mss = @_;
		my $doc = XML::LibXML->createDocument( '1.0', 'UTF-8' );
		my $root = $doc->createElementNS( $ns_uri, 'TEI' );

		# Make the header
		my $teiheader = $root->addNewChild( $ns_uri, 'teiHeader' );
		my $filedesc = $teiheader->addNewChild( $ns_uri, 'fileDesc' );
		$filedesc->addNewChild( $ns_uri, 'titleStmt' )->
			addNewChild( $ns_uri, 'title' )->
			appendText( $title );
		$filedesc->addNewChild( $ns_uri, 'publicationStmt' )->
			addNewChild( $ns_uri, 'p' )->
			appendText( 'Created by nCritic' );
		my $witnesslist = $filedesc->addNewChild( $ns_uri, 'sourceDesc')->
			addNewChild( $ns_uri, 'listWit' );
		foreach my $m ( @mss ) {
			my $wit = $witnesslist->addNewChild( $ns_uri, 'witness' );
			$wit->setAttribute( 'xml:id', $m->sigil );
			if( $m->has_msdesc ) {
				my $local_msdesc = $m->msdesc->cloneNode( 1 );
				$local_msdesc->removeAttribute( 'xml:id' );
				$wit->appendChild( $local_msdesc );
			} else {
				$wit->appendText( $m->identifier );
			}
		}

		# Make the body element
		my $body_p = $root->addNewChild( $ns_uri, 'text' )->
			addNewChild( $ns_uri, 'body' )->
			addNewChild( $ns_uri, 'div' )->
			addNewChild( $ns_uri, 'p' );  # TODO maybe this should be lg?

		# Set the root...
		$doc->setDocumentElement( $root );
		# ...and return the doc and the body
		return( $doc, $body_p );
	}

	sub _make_tei_app {
		my( $word_obj, %seen ) = @_;
		my @all_words = ( $word_obj, $word_obj->links, $word_obj->variants );
		foreach( $word_obj->variants ) {
			push( @all_words, $_->links );
		}
		# Do we have the exact same word across all manuscripts with no pesky
		# placeholders?  And which manuscripts have words?
		my $variation = 0;
		foreach( @all_words ) {
			$variation = 1 if $_->original_form ne $word_obj->original_form;
			# We need an <app/> tag if there is a placeholder to record too.
			$variation = 1 if $_->placeholders;
			$seen{$_->ms_sigil} = 1 if $_->ms_sigil;
		}
		# If we do have variation, we create an <app/> element to describe 
		# it.  If we don't, we create a <w/> element to hold the common word.
		if( $variation ) {
			my $app_el = $body->addNewChild( $ns_uri, 'app');
			$app_el->setAttribute( 'xml:id', 'app'.$app_id_ctr++ );
			# We want only one reading per unique original_form.
			my %forms;
			foreach my $rdg ( @all_words ) {
				my $rdgkey = $rdg->original_form;
				next unless $rdgkey;
				push( @{$forms{$rdgkey}}, $rdg );
			}
			# Now for each form, go through and get the reading witnesses and
			# placeholders.
			foreach my $form ( keys %forms ) {
				my $rdg_el = $app_el->addNewChild( $ns_uri, 'rdg' );
				# Set the witness string.
				my $wit_str = join( ' ', map { '#'.$_->ms_sigil } @{$forms{$form}});
				$rdg_el->setAttribute( 'wit', $wit_str );
				# Set the word element within the reading.
				my $w_el = $rdg_el->addNewChild( $ns_uri, 'w' );
				$w_el->setAttribute( 'xml:id', 'w'.$word_id_ctr++ );
				# Arbitrarily use the first reading of this form to get the punctuation.
				_wrap_punct( $w_el, $forms{$form}->[0] );
				# Add the placeholder information as <witDetail/> elements.
				my $witDetails;
				foreach my $rdg ( @{$forms{$form}} ) {
					foreach my $pl ( $rdg->placeholders ) {
						push( @{$witDetails->{'#'.$w_el->getAttribute( 'xml:id' )}->{$pl}}, '#'.$rdg->ms_sigil );
					}
				}
				foreach my $wd ( keys %$witDetails ) {
					foreach my $type ( keys %{$witDetails->{$wd}} ) {
						my $wd_el = $app_el->addNewChild( $ns_uri, 'witDetail' );
						$wd_el->setAttribute( 'target', $wd );
						$wd_el->setAttribute( 'wit', join( ' ', @{$witDetails->{$wd}->{$type}}) );
						$wd_el->appendText( $type );
					}
				}
			}
			my @empty = grep { $seen{$_} == 0 } keys( %seen );
			if( @empty ) {
				my $rdg_el = $app_el->addNewChild( $ns_uri, 'rdg' );
				my $wit_str = join( ' ', map { '#'.$_ } @empty );
				$rdg_el->setAttribute( 'wit', $wit_str );
			}
		} else {
			# No variation across manuscripts, just make a <w/> and use the initial
			# $word_obj to represent all mss.
			my $w_el = $body->addNewChild( $ns_uri, 'w');
			$w_el->setAttribute( 'xml:id', 'w'.$word_id_ctr++ );
			_wrap_punct( $w_el, $word_obj );
		}
	}
	
	sub _wrap_punct {
		my( $w_el, $word_obj ) = @_;
		my $str = $word_obj->original_form;
		my @punct = $word_obj->punctuation;
		my $last_pos = -1;
		foreach my $p ( @punct ) {
			my @letters = split( '', $str );
			if( $p->{char} eq $letters[$p->{pos}] ) {
				my @wordpart = @letters[$last_pos+1..$p->{pos}-1];
				$w_el->appendText( join( '', @wordpart ) );
				my $char = $w_el->addNewChild( $ns_uri, 'c');
				$char->setAttribute( "type", "punct" );
				$char->appendText( $p->{char} );
				$last_pos = $p->{pos};
			} else {
			    throw( ident => 'data inconsistency',
			           message => "Punctuation mismatch: " 
			            . join( '/', $p->{char}, $p->{pos} ) . " on " . $str );
			}
		}
		# Now append what is left of the word after the last punctuation.
		if( $last_pos < length( $str ) - 1 ) {
			my @letters = split( '', $str );
			my @wordpart = @letters[$last_pos+1..$#letters];
			$w_el->appendText( join( '', @wordpart ) );
		}
		return $w_el;
	}

}

=head2 to_graphml

Takes a list of aligned manuscript objects and returns a GraphML document that
represents the collation as a variant graph. Words in the same location with
the same canonized form are treated as the same node.

=cut

sub to_graphml {
	my( $self, @manuscripts ) = @_;
	my $graph = $self->to_graph( @manuscripts );
	
	# Make the XML doc
	my $GMLNS = 'http://graphml.graphdrawing.org/xmlns';
	my $graphml = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $root = $graphml->createElementNS( $GMLNS, 'graphml' );
	$root->setNamespace( 'http://www.w3.org/2001/XMLSchema-instance', 'xsi', 0 );
	$root->setAttribute( 'xsi:schemaLocation', 'http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd');
	
	# Make the interminable graph header
	my $graph_el = $root->addNewChild( $GMLNS, 'graph' );
	$graph_el->setAttribute( 'id', 'G' );
	$graph_el->setAttribute( 'edgedefault', 'directed' );
	my $nkey = $graph_el->addNewChild( $GMLNS, 'key' );
	$nkey->setAttribute( 'attr.name', 'number' );
	$nkey->setAttribute( 'attr.type', 'string' );
	$nkey->setAttribute( 'for', 'node' );
	$nkey->setAttribute( 'id', 'd0' );
	my $tkey = $graph_el->addNewChild( $GMLNS, 'key' );
	$tkey->setAttribute( 'attr.name', 'token' );
	$tkey->setAttribute( 'attr.type', 'string' );
	$tkey->setAttribute( 'for', 'node' );
	$tkey->setAttribute( 'id', 'd1' );
	my $ms_ctr = 0;
	my %ms_key;
	foreach my $ms ( @manuscripts ) {
		my $wkey = $graph_el->addNewChild( $GMLNS, 'key' );
		$wkey->setAttribute( 'attr.name', $ms->sigil );
		$wkey->setAttribute( 'attr.type', 'string' );
		$wkey->setAttribute( 'for', 'edge' );
		$wkey->setAttribute( 'id', 'w'.$ms_ctr++ );
		$ms_key{$ms->sigil} = $wkey->getAttribute( 'id' );
	}
	
	# Whew.  Now add all the nodes
	foreach my $n ( $graph->nodes ) {
		my $node_el = $graph_el->addNewChild( $GMLNS, 'node' );
		$node_el->setAttribute( 'id', $n->name );
		my $id_el = $node_el->addNewChild( $GMLNS, 'data' );
		$id_el->setAttribute( 'key', 'd0' );
		$id_el->appendText( $n->name );
		my $token_el = $node_el->addNewChild( $GMLNS, 'data' );
		$token_el->setAttribute( 'key', 'd1' );
		$token_el->appendText( $n->label );
	}
	
	# Finally, add the edges.
	my $edge_ctr = 0;
	foreach my $n ( $graph->nodes ) {
		foreach my $succ ( $n->successors() ) {
			my $edge_el = $graph_el->addNewChild( $GMLNS, 'edge' );
			$edge_el->setAttribute( 'id', 'e'.$edge_ctr++ );
			$edge_el->setAttribute( 'source', $n->name );
			$edge_el->setAttribute( 'target', $succ->name );
			foreach my $edge ( $n->edges_to( $succ ) ) {
				# The edge label is the sigil.  Add a data key for that sigil.
				my $sig = $edge->name;
				my $sig_el = $edge_el->addNewChild( $GMLNS, 'data' );
				$sig_el->setAttribute( 'key', $ms_key{$sig} );
				$sig_el->appendText( $sig );
			}
		}
	}
	$graphml->setDocumentElement( $root );
	return $graphml;
}

=head2 to_svg

Takes a list of aligned manuscript objects and returns an SVG representation
of the variant graph, as described for the to_graphml method.

=cut

sub to_svg {
	my( $self, @mss ) = @_;
        my $graph = $self->to_graph( @mss );
        $graph->set_attribute( 'node', 'shape', 'ellipse' );
        _combine_edges( $graph );
	my $dot = File::Temp->new();
	binmode( $dot, ':utf8' );
        print $dot $graph->as_graphviz();
	close $dot;
        my @cmd = qw/dot -Tsvg/;
	push( @cmd, $dot->filename );
	my( $svg, $err );
	run( \@cmd, ">", binary(), \$svg, '2>', \$err );
	throw( ident => 'output error',
	       message => 'SVG output failed: $err' )
	    if $err;
	return $svg;    
}

sub _combine_edges {
	my $graph = shift;
	foreach my $n ( $graph->nodes ) {
		foreach my $s ( $n->successors ) {
			my @edges = $n->edges_to( $s );
			my $new_edge = join( ', ', sort( map { $_->name } @edges ) );
			map { $graph->del_edge( $_ ) } @edges;
			$graph->add_edge( $n, $s, $new_edge );
		}
	}
}

=head2 to_graph

Base method for graph-based output - create the (Graph::Easy) graph that will
be used to generate graphml or svg.

=begin testing

use lib 't/lib';
use Text::TEI::Collate;
use XML::LibXML::XPathContext;

eval 'require Graph::Easy;';
unless( $@ ) {
# Get an alignment to test with
my $testdir = "t/data/xml_plain";
opendir( XF, $testdir ) or die "Could not open $testdir";
my @files = readdir XF;
my @mss;
my $aligner = Text::TEI::Collate->new(
	'fuzziness' => '50',
	'language' => 'Armenian',
	);
foreach ( sort @files ) {
	next if /^\./;
	push( @mss, $aligner->read_source( "$testdir/$_" ) );
}
$aligner->align( @mss );

my $graph = $aligner->to_graph( @mss );

is( ref( $graph ), 'Graph::Easy', "Got a graph object from to_graph" );
is( scalar( $graph->nodes ), 380, "Got the right number of nodes" );
is( scalar( $graph->edges ), 992, "Got the right number of edges" );
}

=end testing

=cut

sub to_graph {
	my( $self, @manuscripts ) = @_;
	my $graph = Graph::Easy->new();
	# All manuscripts run from START to END.
	my $start_node = $graph->add_node( 'n0' );
	$start_node->set_attribute( 'label', '#START#');
	my $end_node = $graph->add_node( 'n1' );
	$end_node->set_attribute( 'label', '#END#');
	my $textlen = $#{$manuscripts[0]->words};
	my $paths = {};  # A list of nodes per manuscript sigil.
	my $node_counter = 2;  # We've used n0 and n1 already
	foreach my $idx ( 0..$textlen ) {
		my $unique_words;
		my @location_words = map { $_->words->[$idx] } @manuscripts;
		foreach my $w ( @location_words ) {
			if( $w->special && $w->special eq 'BEGIN' ) {
				$paths->{$w->ms_sigil} = [ $start_node ];
			} elsif( $w->special && $w->special eq 'END' ) {
				push( @{$paths->{$w->ms_sigil}}, $end_node );
			} elsif( !$w->is_empty && !$w->special ) {
				push( @{$unique_words->{$w->canonical_form}}, $w->ms_sigil )
			}
		}
		foreach my $w ( keys %$unique_words ) {
			# Make the node.
			my $n = $graph->add_node( 'n'.$node_counter++ );
			$n->set_attribute( 'label', $w );
			foreach my $sig ( @{$unique_words->{$w}} ) {
				push( @{$paths->{$sig}}, $n );
			}
		}
	}
	# Have the nodes, now make the edges.
	foreach my $sig ( keys %$paths ) {
		my $from = shift @{$paths->{$sig}};
		foreach my $to ( @{$paths->{$sig}} ) {
			$graph->add_edge( $from, $to, $sig );
			$from = $to;
		}
	}
	return $graph;
}

## Print a debugging message.
sub debug {
    my $self = shift;
    my( $msg, $lvl, $no_newline ) = @_;
    $lvl = 0 unless $lvl;
    print STDERR 'DEBUG ' . ($lvl+1) . ": $msg"
	. ( $no_newline ? '' : "\n" )
	if $self->debuglevel > $lvl;
}

## Utility function for exception handling
sub throw {
    Text::TEI::Collate::Error->throw( @_ );
}

## Utility function for debugging 
sub show_links {
    my( $self, $base ) = @_;
    foreach my $w ( @$base ) {
        _show_word_with_links( $w, 1 );
    }
}
sub _show_word_with_links {
    my( $w, $tab ) = @_;
    my $prefix = "\t" x $tab;
    print STDERR $w->printable . " " . $w->ms_sigil . "\n";
    foreach my $l ( $w->links ) {
        print STDERR $prefix . "L: " . $l->printable . " " . $l->ms_sigil . "\n";
    }
    foreach my $v ( $w->variants ) {
        print STDERR $prefix . "Variant: ";
        _show_word_with_links( $v, $tab+1 );
    }
}
1;


=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
