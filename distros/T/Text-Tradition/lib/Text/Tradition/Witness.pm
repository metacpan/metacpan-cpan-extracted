package Text::Tradition::Witness;

use vars qw( %tags );
use JSON;
use Moose;
use Text::Tradition::Datatypes;
use Text::TEI::Markup qw( word_tag_wrap );
use TryCatch;

=head1 NAME

Text::Tradition::Witness - a manuscript witness to a text tradition

=head1 SYNOPSIS

  use Text::Tradition::Witness;
  my $w = Text::Tradition::Witness->new( 
    'sigil' => 'A',
    'identifier' => 'Oxford MS Ex.1932',
    );  
    
=head1 DESCRIPTION

Text::Tradition::Witness is an object representation of a manuscript
witness to a text tradition.  A manuscript has a sigil (a short code that
represents it in the wider tradition), an identifier (e.g. the library ID),
and probably a text.

=head1 METHODS

=head2 new

Create a new witness.  Options include:

=over

=item * sigil - A short code to represent the manuscript.  Required.

=item * sourcetype - What sort of witness data this is. Options are 
'xmldesc', 'plaintext', 'json', or 'collation' (the last should only be 
used by Collation parsers.)

=item * file
=item * string
=item * object

The data source for the witness.  Use the appropriate option.

=item * use_text - An initialization option.  If the witness is read from a
TEI document and more than one <text/> tag exists therein, the default
behavior is to use the first defined text.  If this is not desired,
use_text should be set to an XPath expression that will select the correct
text.

=item * identifier - The recognized name of the manuscript, e.g. a library
identifier. Taken from the msDesc element for a TEI file.

=item * other_info - A freeform string for any other description of the
manuscript. 

=back

=head2 sigil

The sigil by which to identify this manuscript, which must conform to the
specification for XML attribute strings (broadly speaking, it must begin
with a letter and can have only a few sorts of punctuation characters in
it.)

=head2 identifier

A freeform name by which to identify the manuscript, which may be longer
than the sigil.  Defaults to 'Unidentified ms', but will be taken from the
TEI msName attribute, or constructed from the settlement and idno if
supplied.

=head2 settlement

The city, town, etc. where the manuscript is held. Will be read from the
TEI msDesc element if supplied.

=head2 repository

The institution that holds the manuscript. Will be read from the TEI msDesc
element if supplied.

=head2 idno

The identification or call number of the manuscript.  Will be read from the
TEI msDesc element if supplied.

=head2 text

An array of strings (words) that contains the text of the
manuscript.  This should not change after the witness has been
instantiated, and the path through the collation should always match it.

=head2 layertext

An array of strings (words) that contains the layered
text, if any, of the manuscript.  This should not change after the witness
has been instantiated, and the path through the collation should always
match it.

=head2 identifier

Accessor method for the witness identifier.

=head2 other_info

Accessor method for the general witness description.

=head2 has_source

Boolean method that returns a true value if the witness was created with a
data source (that is, a file, string, or object to be parsed).

=head2 is_layered

Boolean method to note whether the witness has layers (e.g. pre-correction 
readings) in the collation.

=begin testing

use Test::More::UTF8 qw/ -utf8 /;
use Text::Tradition;
my $trad = Text::Tradition->new( 'name' => 'test tradition' );
my $c = $trad->collation;

# Test a plaintext witness via string
my $str = 'This is a line of text';
my $ptwit = $trad->add_witness( 
    'sigil' => 'A',
    'sourcetype' => 'plaintext',
    'string' => $str
     );
is( ref( $ptwit ), 'Text::Tradition::Witness', 'Created a witness' );
if( $ptwit ) {
    is( $ptwit->sigil, 'A', "Witness has correct sigil" );
    $c->make_witness_path( $ptwit );
    is( $c->path_text( $ptwit->sigil ), $str, "Witness has correct text" );
}

# Test some JSON witnesses via object
open( JSIN, 't/data/witnesses/testwit.json' ) or die "Could not open JSON test input";
binmode( JSIN, ':encoding(UTF-8)' );
my @lines = <JSIN>;
close JSIN;
$trad->add_json_witnesses( join( '', @lines ) );
is( ref( $trad->witness( 'MsAJ' ) ), 'Text::Tradition::Witness', 
	"Found first JSON witness" );
is( ref( $trad->witness( 'MsBJ' ) ), 'Text::Tradition::Witness', 
	"Found second JSON witness" );

# Test an XML witness via file
my $xmlwit = $trad->add_witness( 'sourcetype' => 'xmldesc', 
	'file' => 't/data/witnesses/teiwit.xml' );
is( ref( $xmlwit ), 'Text::Tradition::Witness', "Created witness from XML file" );
if( $xmlwit ) {
	is( $xmlwit->sigil, 'V887', "XML witness has correct sigil" );
	ok( $xmlwit->is_layered, "Picked up correction layer" );
	is( @{$xmlwit->text}, 182, "Got correct text length" );
	is( @{$xmlwit->layertext}, 182, "Got correct a.c. text length" );
}
my @allwitwords = grep { $_->id =~ /^V887/ } $c->readings;
is( @allwitwords, 184, "Reused appropriate readings" );

## Test use_text
my $xpwit = $trad->add_witness( 'sourcetype' => 'xmldesc',
	'file' => 't/data/witnesses/group.xml',
	'use_text' => '//tei:group/tei:text[2]' );
is( ref( $xpwit ), 'Text::Tradition::Witness', "Created witness from XML group" );
if( $xpwit ) {
	is( $xpwit->sigil, 'G', "XML part witness has correct sigil" );
	ok( !$xpwit->is_layered, "Picked up no correction layer" );
	is( @{$xpwit->text}, 157, "Got correct text length" );
}

# Test non-ASCII sigla
my $at = Text::Tradition->new(
	name => 'armexample',
	input => 'Tabular',
	excel => 'xlsx',
	file => 't/data/armexample.xlsx' );
foreach my $wit ( $at->witnesses ) {
	my $sig = $wit->sigil;
	if( $sig =~ /^\p{ASCII}+$/ ) {
		is( $wit->ascii_sigil, '_A_' . $sig, 
			"Correct ASCII sigil for ASCII witness $sig" );
	} else {
		# This is our non-ASCII example
		is( $wit->ascii_sigil, '_A_5315622',
			"Correct ASCII sigil for non-ASCII witness $sig" );
	}
}


=end testing 

=cut

# Enable plugin(s) if available
eval { with 'Text::Tradition::WitLanguage'; };
	
has 'tradition' => (
	is => 'ro',
	isa => 'Text::Tradition',
	required => 1,
	weak_ref => 1
	);

# Sigil. Required identifier for a witness, but may be found inside
# the XML file.
has 'sigil' => (
	is => 'ro',
	isa => 'Sigil',
	predicate => 'has_sigil',
	writer => '_set_sigil',
	);
	
# An ASCII version of the sigil, for any applications that cannot
# deal with Unicode. This should not be set directly, but will be
# set automatically when the sigil is set.
has 'ascii_sigil' => (
	is => 'ro',
	isa => 'Sigil',
	writer => '_set_ascii_sigil',
	);
	
# Other identifying information
has 'identifier' => (
	is => 'rw',
	isa => 'Str',
	);

has 'settlement' => (
	is => 'rw',
	isa => 'Str',
	);

has 'repository' => (
	is => 'rw',
	isa => 'Str',
	);

has 'idno' => (
	is => 'rw',
	isa => 'Str',
	);

# Source. Can be XML obj, JSON data struct, or string.
# Not used if the witness is created by parsing a collation.
has 'sourcetype' => (
	is => 'ro',
	isa => 'SourceType',
	required => 1, 
);

has 'file' => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_file',
);

has 'string' => (
	is => 'ro',
	isa => 'Str',
	predicate => 'has_string',
);

has 'object' => ( # could be anything.
	is => 'ro',
	predicate => 'has_object',
	clearer => 'clear_object',
);

# In the case of a TEI document with multiple texts, specify
# which text is the root. Should be an XPath expression.
has 'use_text' => (
	is => 'ro',
	isa => 'Str',
	);

# Text.	 This is an array of strings (i.e. word tokens).
# TODO Think about how to handle this for the case of pre-prepared
# collations, where the tokens are in the graph already.
has 'text' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	predicate => 'has_text',
	);
	
has 'layertext' => (
	is => 'rw',
	isa => 'ArrayRef[Str]',
	predicate => 'has_layertext',
	);
	
has 'is_collated' => (
	is => 'rw',
	isa => 'Bool'
	);
	
# Path.	 This is an array of Reading nodes that can be saved during
# initialization, but should be cleared before saving in a DB.
has 'path' => (
	is => 'rw',
	isa => 'ArrayRef[Text::Tradition::Collation::Reading]',
	predicate => 'has_path',
	clearer => 'clear_path',
	);		   

## TODO change the name of this
has 'uncorrected_path' => (
	is => 'rw',
	isa => 'ArrayRef[Text::Tradition::Collation::Reading]',
	clearer => 'clear_uncorrected_path',
	);

## TODO is_layered should be set automatically when an a.c. reading
## is added to the graph.	
has 'is_layered' => (
	is => 'rw',
	isa => 'Bool',
	);

# If we set an uncorrected path, ever, remember that we did so.
around 'uncorrected_path' => sub {
	my $orig = shift;
	my $self = shift;
	
	$self->is_layered( 1 );
	$self->$orig( @_ );
};

sub BUILD {
	my $self = shift;
	if( $self->has_source ) {
		my $init_sub = '_init_from_' . $self->sourcetype;
		$self->$init_sub();
		# Remove our XML / source objects; we no longer need them.
		$self->clear_object if $self->has_object;
		# $self->tradition->collation->make_witness_path( $self );
	}
	if( $self->sourcetype eq 'collation' ) {
		$self->is_collated( 1 );
	}
	# Make an ASCII sigil. Convert each non-ASCII character to its Unicode 
	# number and just string them together.
	my $asig = '_A_';
	foreach my $char ( split( '', $self->sigil ) ) {
		if( $char =~ /\p{ASCII}/ ) {
			$asig .= $char;
		} else {
			$asig .= sprintf( "%x", ord( $char ) );
		}
	}
	$self->_set_ascii_sigil( $asig ) ;
	return $self;
}

sub has_source {
	my $self = shift;
	return $self->has_file || $self->has_string || $self->has_object;
}

sub _init_from_xmldesc {
	my $self = shift;
	my $xmlobj;
	if( $self->has_object ) {
		unless( ref( $self->object ) eq 'XML::LibXML::Element' ) {
			throw( ident => "bad source",
				   message => "Source object must be an XML::LibXML::Element (this is " 
				   	. ref( $self->object ) . ");" );
		}
		$xmlobj = $self->object;
	} else {
		require XML::LibXML;
		my $parser = XML::LibXML->new();
		my $parsersub = $self->has_file ? 'parse_file' : 'parse_string';
		try {
			$xmlobj = $parser->$parsersub( $self->file )->documentElement;
		} catch( XML::LibXML::Error $e ) {
			throw( ident => "bad source",
				   message => "XML parsing error: " . $e->as_string );
		}
	}
		
	unless( $xmlobj->nodeName eq 'TEI' ) {
		throw( ident => "bad source", 
		       message => "Source XML must be TEI (this is " . $xmlobj->nodeName . ")" );
	}

	# Set up the tags we need, with or without namespaces.
	map { $tags{$_} = "//$_" } 
		qw/ msDesc msName settlement repository idno p lg w seg add del /;
	# Set up our XPath object
	my $xpc = _xpc_for_el( $xmlobj );
	# Use namespace-aware tags if we have to 
	if( $xmlobj->namespaceURI ) {
	    map { $tags{$_} = "//tei:$_" } keys %tags;
	}

	# Get the identifier
	if( my $desc = $xpc->find( $tags{msDesc} ) ) {
		my $descnode = $desc->get_node(1);
		# First try to use settlement/repository/idno.
		my( $setNode, $reposNode, $idNode ) =
			( $xpc->find( $tags{settlement}, $descnode )->get_node(1),
			  $xpc->find( $tags{repository}, $descnode )->get_node(1),
			  $xpc->find( $tags{idno}, $descnode )->get_node(1) );
		$self->settlement( $setNode ? $setNode->textContent : '' );
		$self->repository( $reposNode ? $reposNode->textContent : '' );
		$self->idno( $idNode ? $idNode->textContent : '' );
		if( $self->settlement && $self->idno ) {
	    	$self->identifier( join( ' ', $self->{'settlement'}, $self->{'idno'} ) );
		} else {
		    # Look for an msName.
		    my $msNameNode = $xpc->find( $tags{msName}, $descnode )->get_node(1);
		    if( $msNameNode ) {
                $self->identifier( $msNameNode->textContent );
            } else {
                # We have an msDesc but who knows what is in it?
                my $desc = $descnode->textContent;
                $desc =~ s/\n/ /gs;
                $desc =~ s/\s+/ /g;
                $self->identifier( $desc );
            }
        }
        if( $descnode->hasAttribute('xml:id') ) {
			$self->_set_sigil( $descnode->getAttribute('xml:id') );
		} elsif( !$self->has_sigil ) {
			throw( ident => 'missing sigil',
				   message => 'Could not find xml:id witness sigil' );
		}
	} else {
	    throw( ident => "bad source",
	           message => "Could not find manuscript description element in TEI header" );
	}

	# Now get the words out.
	my @words;
	my @layerwords;  # if the witness has layers
	# First, make sure all the words are wrapped in tags.
	# TODO Make this not necessarily dependent upon whitespace...
	word_tag_wrap( $xmlobj );
	# Now go text hunting.
	my @textnodes;
	if( $self->use_text ) {
		@textnodes = $xpc->findnodes( $self->use_text );
	} else {
		# Use the first 'text' node in the document.
		@textnodes = $xmlobj->getElementsByTagName( 'text' );
	}
	my $teitext = $textnodes[0];
	if( $teitext ) {
		_tokenize_text( $self, $teitext, \@words, \@layerwords );
	} else {
	    throw( ident => "bad source",
	           message => "No text element in document '" . $self->{'identifier'} . "!" );
	}
	
	my @text = map { $_->text } @words;
	my @layertext = map { $_->text } @layerwords;
	$self->path( \@words );
	$self->text( \@text );
	if( join( ' ', @text ) ne join( ' ', @layertext ) ) {
		$self->uncorrected_path( \@layerwords );
		$self->layertext( \@layertext );
	}
}

sub _tokenize_text {
	my( $self, $teitext, $wordlist, $uncorrlist ) = @_;
	# Strip out the words.
	my $xpc = _xpc_for_el( $teitext );
	my @divs = $xpc->findnodes( '//*[starts-with(name(.), "div")]' );
	foreach( @divs ) {
		my $place_str;
		if( my $n = $_->getAttribute( 'n' ) ) {
			$place_str = '#DIV_' . $n . '#';
		} else {
			$place_str = '#DIV#';
		}
		$self->_objectify_words( $teitext, $wordlist, $uncorrlist, $place_str );
	}  # foreach <div/>
    
	# But maybe we don't have any divs.  Just paragraphs.
	unless( @divs ) {
		$self->_objectify_words( $teitext, $wordlist, $uncorrlist );
	}
}

sub _objectify_words {
	my( $self, $element, $wordlist, $uncorrlist, $divmarker ) = @_;

	my $xpc = _xpc_for_el( $element );
	my $xpexpr = '.' . $tags{p} . '|.' . $tags{lg};
 	my @pgraphs = $xpc->findnodes( $xpexpr );
    return () unless @pgraphs;
    # Set up an expression to look for words and segs
    $xpexpr = '.' . $tags{w} . '|.' . $tags{seg};
	foreach my $pg ( @pgraphs ) {
		# If this paragraph is the descendant of a note element,
		# skip it.
		my @noop_container = $xpc->findnodes( 'ancestor::note', $pg );
		next if scalar @noop_container;
		# Get the text of each node
		my $first_word = 1;
		# Hunt down each wrapped word/seg, and make an object (or two objects)
		# of it, if necessary.
		foreach my $c ( $xpc->findnodes( $xpexpr, $pg ) ) {
			my( $text, $uncorr ) = _get_word_strings( $c );
# 			try {
# 				( $text, $uncorr ) = _get_word_object( $c );
# 			} catch( Text::Tradition::Error $e 
# 						where { $_->has_tag( 'lb' ) } ) {
# 				next;
# 			}
			unless( defined $text || defined $uncorr ) {
				print STDERR "WARNING: no text in node " . $c->nodeName 
					. "\n" unless $c->nodeName eq 'lb';
				next;
			}
			print STDERR "DEBUG: space found in element node "
				. $c->nodeName . "\n" if $text =~ /\s/ || $uncorr =~ /\s/;
			
			my $ctr = @$wordlist > @$uncorrlist ? @$wordlist : @$uncorrlist;
			while( $self->tradition->collation->reading( $self->sigil.'r'.$ctr ) ) {
				$ctr++;
			}
			my $id = $self->sigil . 'r' . $ctr;
			my( $word, $acword );
			if( $text ) {
				$word = $self->tradition->collation->add_reading( 
					{ 'id' => $id, 'text' => $text });
			}
			if( $uncorr && $uncorr ne $text ) {
				$id .= '_ac';
				$acword = $self->tradition->collation->add_reading( 
					{ 'id' => $id, 'text' => $uncorr });
			} elsif( $uncorr ) {
				$acword = $word;
			}

# 			if( $first_word ) {
# 				$first_word = 0;
# 				# Set the relevant sectioning markers 
# 				if( $divmarker ) {
# 					$w->add_placeholder( $divmarker );
# 					$divmarker = undef;
# 				}
# 				$w->add_placeholder( '#PG#' );
# 			}
			push( @$wordlist, $word ) if $word;
			push( @$uncorrlist, $acword ) if $acword;
		}
    }
}

# Given a word or segment node, make a Reading object for the word
# therein. Make two Reading objects if there is an 'uncorrected' vs.
# 'corrected' state.

sub _get_word_strings {
	my( $node ) = @_;
	my( $text, $uncorrtext );
	# We can have an lb or pb in the middle of a word; if we do, the
	# whitespace (including \n) after the break becomes insignificant
	# and we want to nuke it.
	my $strip_leading_space = 0;
	my $word_excluded = 0;
	my $xpc = _xpc_for_el( $node );
	# TODO This does not cope with nested add/dels.
	my @addition = $xpc->findnodes( 'ancestor::' . substr( $tags{add}, 2 ) );
	my @deletion = $xpc->findnodes( 'ancestor::' . substr( $tags{del}, 2 ) );
	foreach my $c ($node->childNodes() ) {
		if( $c->nodeName eq 'num' 
			&& defined $c->getAttribute( 'value' ) ) {
			# Push the number.
			$text .= $c->getAttribute( 'value' ) unless @deletion;
			$uncorrtext .= $c->getAttribute( 'value' ) unless @addition;
			# If this is just after a line/page break, return to normal behavior.
			$strip_leading_space = 0;
		} elsif ( $c->nodeName =~ /^[lp]b$/ ) {
			# Set a flag that strips leading whitespace until we
			# get to the next bit of non-whitespace.
			$strip_leading_space = 1;
		} elsif ( $c->nodeName eq 'fw'	 # for catchwords
				  || $c->nodeName eq 'sic'
				  || $c->nodeName eq 'note'	 #TODO: decide how to deal with notes
				  || $c->textContent eq '' 
				  || ref( $c ) eq 'XML::LibXML::Comment' ) {
			$word_excluded = 1 if $c->nodeName =~ /^(fw|sic)$/;
			next;
		} elsif( $c->nodeName eq 'add' ) {
			my( $use, $discard ) = _get_word_strings( $c );
			$text .= $use;
		} elsif( $c->nodeName eq 'del' ) {
			my( $discard, $use ) = _get_word_strings( $c );
			$uncorrtext .= $use;
		} else {
			my ( $tagtxt, $taguncorr );
			if( ref( $c ) eq 'XML::LibXML::Text' ) {
				# A text node.
				$tagtxt = $c->textContent;
				$taguncorr = $c->textContent;
			} else {
				( $tagtxt, $taguncorr ) = _get_word_strings( $c );
			}
			if( $strip_leading_space ) {
				$tagtxt =~ s/^[\s\n]+//s;
				$taguncorr =~ s/^[\s\n]+//s;
				# Unset the flag as soon as we see non-whitespace.
				$strip_leading_space = 0 if $tagtxt;
			}
			$text .= $tagtxt;
			$uncorrtext .= $taguncorr;
		} 
	}
	throw( ident => "text not found",
	       tags => [ $node->nodeName ],
	       message => "No text found in node " . $node->toString(0) )
	    unless $text || $uncorrtext || $word_excluded || $node->toString(0) =~/gap/;
	return( $text, $uncorrtext );
}

sub _split_words {
	my( $self, $string, $c ) = @_;
 	my @raw_words = split( /\s+/, $string );
 	my @words;
	foreach my $w ( @raw_words ) {
		my $id = $self->sigil . 'r'. $c++;
		my %opts = ( 'text' => $w, 'id' => $id );
		my $w_obj = $self->tradition->collation->add_reading( \%opts );
 		# Skip any words that have been canonized out of existence.
		next if( length( $w_obj->text ) == 0 );
		push( @words, $w_obj );
 	}
 	return @words;
}

sub _init_from_json {
	my( $self ) = shift;
	my $wit;
	if( $self->has_object ) {
		$wit = $self->object;
	} elsif( $self->has_string ) {
		$wit = from_json( $self->string );
	} elsif( $self->has_file ) {
    	my $ok = open( INPUT, $self->file );
    	unless( $ok ) {
			throw( ident => "bad source",
				   message => 'Could not open ' . $self->file . ' for reading' );
    	}
    	binmode( INPUT, ':encoding(UTF-8)' );
    	my @lines = <INPUT>;
    	close INPUT;
    	$wit = from_json( join( '', @lines ) );
	}
	
	if( exists $wit->{'id'} ) {
		$self->_set_sigil( $wit->{'id'} );
	} elsif( !$self->has_sigil ) {
		throw( ident => 'missing sigil',
			   message => 'Could not find witness sigil (id) in JSON spec' );
	}
	$self->identifier( $wit->{'name'} );
	my @words;
	my @layerwords;
	my( @text, @layertext );
	if( exists $wit->{'content'} ) {
		# We need to tokenize the text ourselves.
		@words = _split_words( $self, $wit->{'content'} );
	} elsif( exists $wit->{'tokens'} ) {
		# We have a bunch of pretokenized words.
		my $ctr = 0;
		foreach my $token ( @{$wit->{'tokens'}} ) {
			my $w_obj = $self->tradition->collation->add_reading({
				'text' => $token->{'t'}, 'id' => $self->sigil . 'r' . $ctr++ });
			push( @words, $w_obj );
			push( @text, $token->{'t'} ); # TODO unless...?
		}
		## TODO rethink this JSOn mechanism
		if( exists $wit->{'layertokens'} ) {
			foreach my $token ( @{$wit->{'layertokens'}} ) {
				my $w_obj = $self->tradition->collation->add_reading({
					'text' => $token->{'t'}, 'id' => $self->sigil . 'r' . $ctr++ });
				push( @layerwords, $w_obj );
				push( @layertext, $token->{'t'} );
			}
		}
	}
	$self->text( \@text );
	$self->layertext( \@layertext ) if @layertext;
	$self->path( \@words );
	$self->uncorrected_path( \@layerwords ) if @layerwords;
}

sub _init_from_plaintext {
    my( $self ) = @_;
    unless( $self->has_sigil ) {
    	throw( "No sigil defined for the plaintext witness" );
    }
    my $str;
    if( $self->has_file ) {
    	my $ok = open( INPUT, $self->file );
    	unless( $ok ) {
			throw( ident => "bad source",
				   message => 'Could not open ' . $self->file . ' for reading' );
    	}
    	binmode( INPUT, ':encoding(UTF-8)' );
    	my @lines = <INPUT>;
    	close INPUT;
    	$str = join( '', @lines );
    } elsif( $self->has_object ) { # ...seriously?
    	$str = ${$self->object};
    } else {
    	$str = $self->string;
    }
    
    # TODO allow a different word separation expression
    my @text = split( /\s+/, $str );
    $self->text( \@text );
    my @words = _split_words( $self, $str );
	$self->path( \@words );
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Witness parsing error',
		'message' => $_[0],
		);
}

sub _xpc_for_el {
        my $el = shift;
        my $xpc = XML::LibXML::XPathContext->new( $el );
		if( $el->namespaceURI ) {
			$xpc->registerNs( 'tei', $el->namespaceURI );
		}
        return $xpc;
}       

=head2 export_as_json

Exports the witness as a JSON structure, with the following keys:

=over 4

=item * id - The witness sigil

=item * name - The witness identifier

=item * tokens - An array of hashes of the form { "t":"WORD" }

=back

=begin testing

use Text::Tradition;
my $trad = Text::Tradition->new();

my @text = qw/ Thhis is a line of text /;
my $wit = $trad->add_witness( 
    'sigil' => 'A',
    'string' => join( ' ', @text ),
    'sourcetype' => 'plaintext',
    'identifier' => 'test witness',
     );
my $jsonstruct = $wit->export_as_json;
is( $jsonstruct->{'id'}, 'A', "got the right witness sigil" );
is( $jsonstruct->{'name'}, 'test witness', "got the right identifier" );
is( scalar @{$jsonstruct->{'tokens'}}, 6, "got six text tokens" );
foreach my $idx ( 0 .. $#text ) {
	is( $jsonstruct->{'tokens'}->[$idx]->{'t'}, $text[$idx], "tokens look OK" );
}

my @ctext = qw( when april with his showers sweet with fruit the drought of march 
				has pierced unto the root );
$trad = Text::Tradition->new(
	'input' => 'CollateX',
	'file' => 't/data/Collatex-16.xml' );

$jsonstruct = $trad->witness('A')->export_as_json;
is( $jsonstruct->{'id'}, 'A', "got the right witness sigil" );
is( $jsonstruct->{'name'}, undef, "got undef for missing identifier" );
is( scalar @{$jsonstruct->{'tokens'}}, 17, "got all text tokens" );
foreach my $idx ( 0 .. $#ctext ) {
	is( $jsonstruct->{'tokens'}->[$idx]->{'t'}, $ctext[$idx], "tokens look OK" );
}

## TODO test layertext export

=end testing

=cut

sub export_as_json {
	my $self = shift;
	my @wordlist = map { { 't' => $_ || '' } } @{$self->text};
	my $obj =  { 
		'id' => $self->sigil,
		'tokens' => \@wordlist,
		'name' => $self->identifier,
	};
	if( $self->is_layered ) {
		my @lwlist = map { { 't' => $_ || '' } } @{$self->layertext};
		$obj->{'layertokens'} = \@lwlist;
	}
	return $obj;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 BUGS / TODO

=over

=item * Figure out how to serialize a witness

=item * Support encodings other than UTF-8

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
