#!/usr/bin/perl;

use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use Getopt::Long;
use Storable;
use Text::TEI::Collate;
use XML::LibXML;

eval { no warnings; binmode $DB::OUT, ":utf8"; };

my( $debug, $fuzziness, $language ) = ( undef, 50, 'Default' );
GetOptions( 
	    'debug:i' => \$debug,
	    'fuzziness=i' => \$fuzziness,
	    'l|language=s' => \$language,
    );
## Option checking
if( defined $debug ) {
    # If it's defined but false, no level was passed.  Use default 1.
    $debug = 1 unless $debug;
} else {
    $debug = 0;
}

my( @files ) = @ARGV;

# how fuzzy a match we can tolerate
my $aligner = Text::TEI::Collate->new( 'fuzziness' => $fuzziness,
				       'debuglevel' => $debug, 'language' => $language,
    );
my @mss;
if( scalar ( @files ) == 1 ) {
    no warnings 'once'; 
    $Storable::Eval = 1;
    my $savedref = retrieve( $files[0] );
    @mss = @$savedref;
} else {
    foreach ( @files ) {
	push( @mss, $aligner->read_source( $_ ) );
    }
    $aligner->align( @mss );
}

my $ns_uri = 'http://www.tei-c.org/ns/1.0';
my ( $doc, $body ) = make_tei_doc( @mss );

### Initialization 
##  Generate a base by flattening all the mss
my $initial_base = $aligner->generate_base( map { $_->words } @mss );

##  Counter variables
my $app_id_ctr = 0;  # for xml:id of <app/> tags
my $word_id_ctr = 0; # for xml:id of <w/> tags that have witDetails

## Loop state variables
my %text_active;            # those texts BEGUN but not ENDed
my %text_on_vacation;       # We all need a break sometimes.
my $in_app = 0;             # Whether we have deferred apparatus creation
my @app_waiting = ();       # List of deferred entries

foreach my $idx ( 0 .. $#{$initial_base} ) {
    # Mark which texts are on duty
    foreach my $w ( map { $_->words->[$idx] } @mss ) {
	_mark_start_end( $w, $body, 'end' );
    }

    # Get all the words; if all active texts are accounted for make the
    # single word an app.  If not, open/add to an app until the next row
    # in which all active texts are accounted for.
    my $word_obj = $initial_base->[$idx];
    my %text_unseen;
    map { $text_unseen{$_} = 1 if ( $text_active{$_} 
				    && !$text_on_vacation{$_} ) } 
        keys( %text_active );
    if( keys( %text_unseen ) ) {
	# A hash will go into @line_words for each run of &class_words
	# for a given line.
	my @line_words;
	push( @line_words, class_words( $word_obj, \%text_unseen ) );
	my @variants = $word_obj->variants;
	foreach( @variants ) {
	    push( @line_words, class_words( $_, \%text_unseen ) );
	}
	
	# Either make the apparatus entry, or defer it.
	# TODO Now only deferring glommed entries.  Refactor this code.
	if( grep( /^__GLOM__$/, keys( %text_unseen ) ) ) {
	    # Add a reading for the omitted words
	    delete $text_unseen{'__GLOM__'};
	    push( @line_words, class_words( 'omitted', \%text_unseen ) );
	    push( @app_waiting, \@line_words );
	    $in_app = 1;
	} else {
	    if( $in_app ) {
		make_app( @app_waiting );
		# Reset state vars
		@app_waiting = ();
		$in_app = 0;
	    }
	    make_app( \@line_words );
	}
    }

    # Mark which texts will now turn up
    foreach my $w ( map { $_->words->[$idx] } @mss ) {
	_mark_start_end( $w, $body, 'start' );
    }
}

print $doc->toString(1);
print STDERR "Done.\n";

# Creates a TEI document with an empty body.
sub make_tei_doc {
    my @mss = @_;
    my $doc = XML::LibXML->createDocument( '1.0', 'UTF-8' );
    $doc->createProcessingInstruction( 'oxygen', 
			       'RNGSchema="tei_ms_crit.rng" type="xml"' );
    my $root = $doc->createElementNS( $ns_uri, 'TEI' );

    # Make the header
    my $teiheader = $root->addNewChild( $ns_uri, 'teiHeader' );
    my $filedesc = $teiheader->addNewChild( $ns_uri, 'fileDesc' );
    $filedesc->addNewChild( $ns_uri, 'titleStmt' )->
	addNewChild( $ns_uri, 'title' )->
	appendText( 'this is a title' );
    $filedesc->addNewChild( $ns_uri, 'publicationStmt' )->
	addNewChild( $ns_uri, 'p' )->
	appendText( 'this is a publication statement' );
    my $witnesslist = $filedesc->addNewChild( $ns_uri, 'sourceDesc')->
	addNewChild( $ns_uri, 'listWit' );
    foreach my $m ( @mss ) {
	my $wit = $witnesslist->addNewChild( $ns_uri, 'witness' );
	$wit->setAttribute( 'xml:id', $m->sigil );
	$wit->appendText( $m->identifier );
    }

    # Make the body element
    my $body_p = $root->addNewChild( $ns_uri, 'text' )->
	addNewChild( $ns_uri, 'body' )->
	addNewChild( $ns_uri, 'div' )->
	addNewChild( $ns_uri, 'p' );
    
    # Set the root...
    $doc->setDocumentElement( $root );
    # ...and return the doc and the body
    return( $doc, $body_p );
}

# Returns a hashref that has looked at the punct-free forms of each
# word and grouped the identical witnesses.  Take each ms we see out
# of the 'unseen' array that was passed in.
	# line_words = { word1 => [ s1, s2, ... ],
	#                word2 => [ s3, s4, ... ] },
	#              { other1 => [ s1, s2, ... ]
	#                other2 => [ s3, s4, ... ] },
	#              { meta => 'yes',
	#                sections => { div => [ s2, ... ],
	#                              p   => [ s2, s6, ... ], },
	#                punct => { '\x{554}' => [ s3, ... ] }, },

sub class_words {
    my( $word_obj, $unseen ) = @_;
    my $varhash = {};
    my $meta = {};
    if( ref $word_obj ) {
	_add_word_to_varhash( $varhash, $meta, $word_obj );
	# Nasty hack.  If the word in question was matched by being glommed
	# onto the next word, we want to defer the call to &make_app.  So
	# we add a bogus entry to the unseen hash.
	if ( $word_obj->is_glommed ) {
	    $unseen->{'__GLOM__'} = 1;
	}
	delete $unseen->{ $word_obj->ms_sigil };
	foreach my $w ( $word_obj->links ) {
	    _add_word_to_varhash( $varhash, $meta, $w );
	    delete $unseen->{ $w->ms_sigil };
	}
	if( keys %$meta ) {
	    $varhash->{'meta'} = $meta;
	}
    } elsif ( $word_obj eq 'omitted' ) {
	# Do we really have any unseen entries, or just specials?
	foreach my $sig ( keys %$unseen ) {
	    _add_hash_entry( $varhash, '__OMITTED__', $sig );
	}
    } else {
	warn "Unsupported argument to \&class_words: $word_obj.  Doing nothing.";
    }
    return $varhash;
}

# general utility function
sub _add_hash_entry {
    my( $hash, $key, $entry ) = @_;
    if( exists( $hash->{$key} ) ) {
	push( @{$hash->{$key}}, $entry );
    } else {
	$hash->{$key} = [ $entry ];
    }
}

# utility function for class_words
sub _add_word_to_varhash {
    my( $varhash, $meta, $word_obj ) = @_;
    _add_hash_entry( $varhash, 
		     Words::Armenian::print_word( $word_obj->word ), 
		     $word_obj->ms_sigil );
    if( $word_obj->punctuation ) {
	$meta->{'punctuation'} = {} unless $meta->{'punctuation'};
	foreach my $punct( $word_obj->punctuation ) {
	    _add_hash_entry( $meta->{'punctuation'}, $punct,
			     $word_obj->ms_sigil );
	}
    }
    if( $word_obj->placeholders ) {
	$meta->{'section_div'} = {} unless $meta->{'section_div'};
	foreach my $ph( $word_obj->placeholders ) {
	    _add_hash_entry( $meta->{'section_div'}, $ph, $word_obj->ms_sigil );
	}
    }
}

# Write out the apparatus entry to our root element.
sub make_app {
    my( @app_entries ) = @_;
    my $app = $body->addNewChild( $ns_uri, 'app' );
    $app->setAttribute( 'xml:id', "App$app_id_ctr" );
    $app_id_ctr++;
    if( scalar( @app_entries ) == 1 ) {
	# Only a single row.
	my $line_entry = $app_entries[0];
	my $single_reading = scalar( @$line_entry ) == 1 ;
	foreach my $entry ( @$line_entry ) {
	    # Each reading group in the row
	    my $meta;
	    # Get the meta information for this word.
	    $meta = delete $entry->{'meta'};
	    foreach my $rdg_word ( keys %$entry ) {
		my $wits = $entry->{$rdg_word};
		my $wit_string = _make_wit_string( @$wits );
		my $rdg = $app->addNewChild( $ns_uri, 'rdg' );
		$rdg->setAttribute( 'wit', $wit_string );
		if( $rdg_word eq '__OMITTED__' ) {
		    $rdg->setAttribute( 'type', 'omission' );
		} else {
		    _add_word( $rdg, $rdg_word, $meta, $wits );
		}
	    }
	}
    } else {
	# Combine the entries into distinct phrases, keyed by sigil.
	my %phrases;
	# Keep track of the meta-information we have seen.  This is 
	# a sanity check to make sure we have used it all.
	my @meta_info;
	foreach my $entry ( @app_entries ) {
	    foreach my $reading ( @$entry ) {
		my $meta;
		if ( exists $reading->{'meta'} ) {
		    $meta = delete $reading->{'meta'};
		    push( @meta_info, $meta );
		}
		foreach my $word ( keys %$reading ) {
		    foreach my $sigil ( @{$reading->{$word}} ) {
			_add_hash_entry( \%phrases, $sigil, { 'word' => $word,
							      'meta' => $meta }
			    );
		    }
		}
	    }
	}
	
	# Make a lookup for arrayref phrase to plaintext phrase_key.
	# We need both ways, irritatingly.
	my( %phrase_key, %phrase_array );
	foreach my $k ( keys %phrases ) {
	    my $plaintext = join( ' ', map { $_->{'word'} } @{$phrases{$k}} );
	    $phrase_key{ scalar( $phrases{$k} ) } = $plaintext;
	    $phrase_array{ $plaintext } = $phrases{$k};
	}
	
	# Now invert the hash, keying on unique phrases.
	my %distinct_phrases = invert_hash( \%phrases, \%phrase_key );
	foreach my $phrase ( keys %distinct_phrases ) {
	    my $wits = $distinct_phrases{$phrase}; 
	    my $wit_string = _make_wit_string( @$wits );
	    my $rdg = $app->addNewChild( $ns_uri, 'rdg' );
	    $rdg->setAttribute( 'wit', $wit_string );
	    foreach my $phr_el ( @{$phrase_array{$phrase}} ) {
		my $word = $phr_el->{'word'};
		my $meta = $phr_el->{'meta'};
		if ( $word ne '__OMITTED__' ) {
		    _add_word( $rdg, $word, $meta, $wits );
		} # else there is no point adding an omission in the
	    }     #   middle of a compound phrase.
	}
	
	# Sanity check - at this point, all the entries should have
	# been deleted from every hash in %meta_mark.
	foreach my $m ( @meta_info ) {
	    my $used = delete $m->{'used'};
	    foreach my $k ( keys %$m ) {
		foreach my $i ( keys %{$m->{$k}} ) {
		    warn "witDetail $k/$i got omitted at $app_id_ctr!" 
			unless $used->{"$k/$i"};
		}
	    }
	}
    }
}

sub metamark_subst {
    my( $rdg, $phrase_elements, $wits ) = @_;
}


# Add a word, and any meta info relevant to that word, to the
# given element.
sub _add_word {
    my( $el, $word, $meta, $witnesses ) = @_;

    my( @sect, @punct );
    my $word_id;
    if( $meta ) {
	my %relevant_witnesses;
	@relevant_witnesses{@$witnesses} = ( 1 ) x scalar @$witnesses;
	foreach my $key ( qw( section_div punctuation ) ) {
	    if( $meta->{$key} ) {
		foreach my $item ( keys %{$meta->{$key}} ) {
		    my @wits = @{$meta->{$key}->{$item}};
		    if( keys %relevant_witnesses ) {
			my @rwits = grep { $relevant_witnesses{$_} } @wits;
			next unless scalar( @rwits );
			@wits = @rwits;
		    }
		    my $wit_string = _make_wit_string( @wits );
		    my $witDetail = XML::LibXML::Element->new( 'witDetail' );
		    $word_id = 'Word' . $word_id_ctr;
		    $witDetail->setAttribute( 'target', '#'.$word_id );
		    $witDetail->setAttribute( 'wit', $wit_string );
		    $witDetail->setAttribute( 'type', $key );
		    $witDetail->appendText( $item );

		    if( $key eq 'section_div' ) {
			push( @sect, $witDetail );
		    } else {
			push( @punct, $witDetail );
		    }
		    
		    # Use this to check that all meta tags got used
		    $meta->{'used'} = {} unless $meta->{'used'};
		    $meta->{'used'}->{join( '/', $key, $item )} = 1;
		}
	    }
	}
    }

    foreach( @sect ) {
	$el->appendChild( $_ );
    }
    my $w_el = $el->addNewChild( $el->namespaceURI, 'w' );
    if( $word_id ) {
	$w_el->setAttribute( 'xml:id', $word_id );
	$word_id_ctr++;
    }
    $w_el->appendText( $word );
    foreach( @punct ) {
	$el->appendChild( $_ );
    }
}

## utility functions for various loops

sub _make_wit_string {
    return join( ' ', map { '#'.$_ } @_ );
}

sub _mark_start_end {
    my( $word_obj, $body, $mode ) = @_;
    my $boundary_tag = $word_obj->special || '';
    my $sig = $word_obj->ms_sigil;
    if( $mode eq 'start' ) {
	if( $boundary_tag eq 'BEGIN' ) {
	    $text_active{$sig} = 1;
	    _add_collation_note( $body, "$sig incipit" );
	} elsif( $boundary_tag eq 'ENDGAP' ) {
	    $text_on_vacation{$sig} = 0;
	    _add_collation_note( $body, "$sig resumes" );
	} 
    } else {
	if( $boundary_tag eq 'END' ) {
	    $text_active{$sig} = 0;
	    _add_collation_note( $body, "$sig explicit" );
	} elsif( $boundary_tag eq 'BEGINGAP' ) {
	    $text_on_vacation{$sig} = 1;
	    _add_collation_note( $body, "$sig pauses" );
	} 
    }	    
}

sub _add_collation_note {
    my( $element, $text ) = @_;
    my $note_obj = $element->addNewChild( $ns_uri, 'note' );
    $note_obj->setAttribute( 'type', 'collation' );
    $note_obj->appendText( $text );
    return $note_obj;
}


# general utility function.  Takes a bunch of key/value pairs and
# returns a bunch of value/list-of-keys pairs.
# Second argument holds plaintext reference keys in case the 
# original values are arrayrefs.
sub invert_hash {
    my ( $hash, $plaintext_keys ) = @_;
    my %new_hash;
    foreach my $key ( keys %$hash ) {
	my $val = $hash->{$key};
	my $valkey = $val;
	if( $plaintext_keys 
	    && ref( $val ) ) {
	    $valkey = $plaintext_keys->{ scalar( $val ) };
	    warn( "No plaintext value given for $val" ) unless $valkey;
	}
	if( exists ( $new_hash{$valkey} ) ) {
	    push( @{$new_hash{$valkey}}, $key );
	} else {
	    $new_hash{$valkey} = [ $key ];
	}
    }
    return %new_hash;
}
	
