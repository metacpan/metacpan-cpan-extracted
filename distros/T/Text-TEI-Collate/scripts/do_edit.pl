#!/usr/bin/perl -w -CDS

use strict;
use lib 'lib';
use Getopt::Long;
use Words::Armenian;
use XML::LibXML;

eval { no warnings; binmode $DB::OUT, ":utf8"; };

my( $infile, $outfile, $lang_module );

GetOptions( 
    'i|infile=s' => \$infile,
    'o|outfile=s' => \$outfile,
    );

if( scalar( @ARGV ) == 1 && !$infile ) {
    $infile = shift @ARGV;
} elsif( @ARGV ) {
    warn "Extraneous arguments '@ARGV'";
}
unless( defined( $infile ) && defined( $outfile ) ) {
    print STDERR "Need to define input and output files\n";
    exit;
}

my %SPELLINGS = %Words::Armenian::SPELLINGS;
my %ORTHOGRAPHY = %Words::Armenian::ORTHOGRAPHY;
my %start_sp;
map { $start_sp{$_} = 1 } keys( %SPELLINGS );
my %start_orth;
map { $start_orth{$_} = 1 } keys( %ORTHOGRAPHY );
my %PREFIXES = %Words::Armenian::PREFIXES;
my %SUFFIXES = %Words::Armenian::SUFFIXES;

my $ns_uri = 'http://www.tei-c.org/ns/1.0';
my $parser = XML::LibXML->new();
my $doc = $parser->parse_file( $infile );
my $xpc = XML::LibXML::XPathContext->new( $doc );
$xpc->registerNs( 'tei', $ns_uri );

# This is where the action happens.
make_edition( $doc );
print_results( 'end' );
print STDERR "Done.\n";

sub make_edition {
    my ( $doc ) = @_;

    # TODO: separate appLists for each element that can be in <text/>
    my $appList = $xpc->find( '//tei:app', $doc );
    
    my $context = [];
    foreach my $app( $appList->get_nodelist() ) {
	process_app( $app, $context );
	reorder_app( $app );
    }
    return $doc;
}

sub process_app {
    my( $app, $context ) = @_;
    
    # Now, for each thing in the app node list, do the following:
    # - Look for section breaks, ask user if we want one
    # - Un-app any words that have no divergence
    # - For each rdgGrp, check %SPELLINGS and ask if necessary
    #   - hmm, need a %NOTSPELLINGS.
    # - Ask what we can't figure out
    # - Ask about punctuation (maybe as a last pass? )

    # If it already has a lemma, it is processed.
    # TODO: add option for reprocessing
    my $id = $app->getAttribute( 'xml:id' );
    my $curr_lemma;
    my @new_context;
    if( my @lemmas = $app->getChildrenByTagName( 'lem' ) ) {
	# print STDERR "app $id already has a lemma\n";
	$curr_lemma = $lemmas[0];
    } else {
	print STDERR "Looking at app $id\n";
	print "Context: " . join( ' ', @$context ) . " _____\n";
	# Get the chidren of this app entry
	my @contents = $app->childNodes();
	# The children should be either readings or rdgGrps.
	my( @group, @reading );
	foreach my $child( @contents ) {
	    my $node = $child->nodeName;
	    if( $node eq 'rdgGrp' ) {
		push( @group, $child );
	    } elsif( $node eq 'rdg' ) {
		push( @reading, $child );
	    } else {
		warn "Unexpected app child node $node"
		    unless ( $node eq '#text' || $node eq 'note' );
	    }
	}
	if( @reading && @group ) {
	    warn "Found mixed rdg and rdgGrp in app; " . 
		"treating top-level readings as one group";
	}
	my @to_process;
	foreach my $rdgGrp ( @group ) {
	    # Find all the readings within.
	    my @rdg_list = $xpc->findnodes( 'tei:rdg', $rdgGrp );
	    push( @to_process, \@rdg_list );
	} 
	push( @to_process, \@reading ) if @reading;
	# This return value is not necessarily a lemma.  Display
	# it differently if not.
	$curr_lemma = process_reading( $app, @to_process );
    }

    # Now add the words from the new lemma to the context.
    foreach my $word ( $curr_lemma->getChildrenByTagName( 'w' ) ) {
	push( @new_context, $word->textContent() );
    }
    unless( $curr_lemma->nodeName eq 'lem' ) {
	# Surround the thing in some brackets so we know it isn't real.
	unshift( @new_context, '[' );
	push( @new_context, ']' );
    }
    push( @$context, @new_context );
    while( scalar @$context > 15 ) {
	shift @$context;
    }
}

sub process_reading {
    my( $app, @set ) = @_;
    
    # We need to know where we are with our sectioning.
    my $cur_p = $app->parentNode;
    my $cur_sec;
    if( $cur_p->parentNode eq 'div' ) {
	$cur_sec = $cur_p->parentNode;
    }
    my $first_app_id = $xpc->find( 'tei:app[1]/@xml:id', $cur_p )
	->string_value;
    
    my %readings;
    my $rdg_idx = 0;
    my %witDetails;
    my %word_from_id;
    foreach my $rdg_group ( @set ) {
	# Each group has a list of readings.
	foreach my $rdg ( @$rdg_group ) {
	    # Each reading has one or more words and zero or more
	    # witDetails.
	    unless ( $rdg->nodeName eq 'rdg') {
		warn "something that is not a reading is in a reading group!"
		    . $rdg->nodeName;
		next;
	    }
	    # Assign each reading to an index, and get the words out while
	    # we have the xpc object.
	    $readings{ ++$rdg_idx } = { 'obj' => $rdg,
					'words' => $xpc->find( 'tei:w', $rdg ) };
	    foreach my $word_obj ( $readings{$rdg_idx}->{'words'}->get_nodelist ) {
		if( $word_obj->hasAttribute( 'xml:id' ) ) {
		    $word_from_id{ '#' . $word_obj->getAttribute( 'xml:id' ) }
		    = { 'string' => $word_obj->textContent, 
			'obj' => $word_obj };
		}
	    }
	    
	    # Now find the witDetails.
	    my $detailList = $xpc->find( 'tei:witDetail', $rdg );
	    foreach my $det ( $detailList->get_nodelist ) {
		my $val = $det->textContent();
		my $target = $det->getAttribute( 'target' );
		my $detailWitList = $det->getAttribute( 'wit' );
		my $detailType = $det->getAttribute( 'type' );
		# Note the structure of this hash...
		$witDetails{++$rdg_idx} = { 'target' => $target, 
					       'wit' => $detailWitList,
					       'type' => $detailType,
					       'obj' => $det,
					       'val' => $val,
		};
	    }
	}  # foreach reading
    }  # foreach rdgGrp; we're ignoring the separation of groups at the moment.

    # Normalize the readings based on what we know about spellings.
    normalize_readings( \%readings );
    
    my $need_answer = 0;  # For sanity check
    my $return_rdg;
    my @following_apps = $xpc->findnodes( 
	'following-sibling::tei:app[position() <= 5]', $app );
    if( keys( %readings ) > 1 ) {
	# Gather the text of the next few readings, for display purposes.
	# Let's say the next five apps.
	print_following_context( $app, @following_apps );
	print "\nAvailable readings:\n";
    } else {
	if( keys( %witDetails ) ) {
	    # Only one reading, but we still need to see the context.
	    print_following_context( $app, @following_apps );
	    print "\n";
	}
	# There is only one reading.  Lemmatize it.
	my @this_is_only_one_value = values( %readings );
	$return_rdg = $this_is_only_one_value[0]->{'obj'};
	$return_rdg->setNodeName( 'lem' );
    }    
    
    foreach my $disp_idx ( sort keys %readings ) {
	my $rdg = $readings{$disp_idx};
	my $rdg_obj = $rdg->{'obj'};
	my @display_text;
	foreach my $word_obj ( $rdg->{'words'}->get_nodelist ) {
	    # Make the orthography of the word regular.
	    my $word_text = $xpc->find( 'text()', $word_obj )->get_node(1);
	    my $word = Words::Armenian::print_word( $word_text->data );
	    $word_text->setData( $word );
	    push( @display_text, $word );
	}
	my $witnesses = $rdg_obj->getAttribute( 'wit' );
	my $var_str = '';
	if( exists $rdg->{'sp_var'} ) {
	    # Display the spelling and orthographic variations, for 
	    # informational purposes.
	    
	    foreach my $var_desc ( @{$rdg->{'sp_var'}} ) {
		my $var_wit = $var_desc->{'obj'}->getAttribute( 'wit' );
		my $var_words = join( ' ', map { $_->textContent } 
				      $var_desc->{'words'}->get_nodelist );
		$var_str .= "\tVariant: $var_words ( $var_wit )\n";
	    }
	}
	unless( $return_rdg && !(keys (%witDetails) ) ) {
	    printf( "%-2s: %s (%s )\n%s", $disp_idx, 
		    join( ' ', @display_text ), $witnesses, $var_str );
	    $need_answer = 1;
	}
    }
    
    # Do we need to assign punctuation or section divisions?
    my %detailClasses;
    if( keys %witDetails ) {
	print "\nManuscript details:\n";
	foreach my $idx ( sort keys %witDetails ) {
	    my $detailData = $witDetails{$idx};
	    my $detail = $detailData->{'val'};
	    my $type = $detailData->{'type'};
	    
	    # Safeguard...
	    unless( $type =~ /^(section_div|punctuation)$/ ) {
		warn( "Unrecognized witDetail type $type" );
		next;
	    }
	    # Section division is irrelevant if we are already at
	    # the start of a p or div.
	    next if( $type eq 'section_div'
		     && $app->getAttribute( 'xml:id' ) eq $first_app_id );
	    
	    # Record the fact that a decision needs to be made...
	    $detailClasses{$type} = 1;
	    $need_answer = 1;
	    
	    # and print the choice.
	    my $pos = $type eq 'section_div' ? 'before' : 'after';
	    print "$idx: Witness(es) " . $detailData->{'wit'} .
		" contain a $detail $pos " 
		. $word_from_id{ $detailData->{'target'} }->{'string'} . "\n";
	}
    }
    
    if( $need_answer ) {
	my $picked = defined( $return_rdg );
	my $detail_needed = scalar keys( %detailClasses );
	until( $picked && !$detail_needed ) {
	    print " --> ";
	    my $answer = <STDIN>;
	    chomp $answer;
	    if( $answer =~ /^q(uit)?\s*$/ ) {
		print_results( 'end' );
		exit;
	    } elsif( $answer =~ /^save/ ) {
		# Always good to save your work.
		print_results();
	    } elsif( $answer =~ /^(accept|a)\s+(\d+)/ ) {
		my $idx = $2;
		if( exists $readings{$idx} ) {
		    $return_rdg = $readings{$idx}->{'obj'};
		    $return_rdg->setNodeName( 'lem' );
		    $picked = 1;
		} else {
		    print "$idx is not an available reading.  Try again.\n";
		}
	    } elsif( $answer =~ /^((accept|sub)\s+detail|(a|s)\s*d)\s+(\d+|none)(\s+(\S+))?/ ) {
		# Accept the detail with the given ID, or accept the 
		# substitution given in its place.
		## TODO deal with Armenian mid-word punctuation
		my( $op, $id, $new_str ) = ($1, $4, $6 );
		unless( $id eq 'none' ) {
		    unless( exists $witDetails{$id} ) {
			print "$id is not an available witness detail.  Try again.\n";
			next;
		    }
		    my $detail = $witDetails{$id};
		    if( !$new_str && $op =~ /^s/ ) {
			print "Substitution request without any substitution.  Try gain.\n";
			next;
		    }
		    # The punctuation should get added to the main reading if
		    # applicable; otherwise to the reading on which it was
		    # observed.
		    my $word_obj = $word_from_id{ $detail->{'target'} }->{'obj'};
		    # Add the required detail to the relevant word.
		    #  TODO currently assumes append, i.e. assumes punct
		    if( $detail->{'type'} eq 'punctuation' ) {
			my $append_val = $op =~ /^s/ ? $new_str : $detail->{'val'};
			$word_obj->appendText( $append_val );
			$word_obj->parentNode->removeChild( $detail->{'obj'} );
		    } else {
			print "TODO: close out a paragraph and/or div here\n";
		    }
		}  # do nothing if we said 'none'
		$detail_needed--;
	    } elsif( $answer =~ /^n(ext)?\s*$/ ) {
		# Return the first reading for context purposes if we
		# haven't already got one.
		$return_rdg = $readings{1}->{'obj'} unless $return_rdg;
		# De-lemmatize it, since a decision remains to be made.
		$return_rdg->setNodeName( 'rdg' );
		$picked = 1;
		$detail_needed = 0;
	    } elsif( $answer =~ /^note\s+(.*)$/ ) {
		# Add an editorial note to the apparatus.
		my $note_obj = XML::LibXML::Element->new( 'note' );
		$note_obj->setAttribute( 'type', 'editorial' );
		$note_obj->appendText( $1 );
		$app->appendChild( $note_obj );
	    } elsif( $answer =~ /^sp(ell(ing)?)?\s+(\d+)\s+(\d+)/ ) {
		my( $var, $std ) = ( $3, $4 );
		unless( exists( $readings{$var} )
			&& exists( $readings{$std} ) ) {
		    print "Either $var or $std is not an available reading.  Try again.\n";
		    next;
		}
		my $var_str = join( ' ', map { $_->textContent } 
				    $readings{$var}->{'words'}->get_nodelist );
		my $std_str = join( ' ', map { $_->textContent } 
				    $readings{$std}->{'words'}->get_nodelist );
		$readings{$var}->{'obj'}->setAttribute( 'type', 
							'spelling_variant' );
		$SPELLINGS{$var_str} = $std_str;
	    } elsif( $answer =~ /^orth\s+(\d+)\s+(\d+)/ ) {
		my( $var, $std ) = ( $1, $2 );
		unless( exists( $readings{$var} )
			&& exists( $readings{$std} ) ) {
		    print "Either $var or $std is not an available reading.  Try again.\n";
		    next;
		}
		my $var_str = join( ' ', map { $_->textContent } 
				    $readings{$var}->{'words'}->get_nodelist );
		my $std_str = join( ' ', map { $_->textContent } 
				    $readings{$std}->{'words'}->get_nodelist );
		$readings{$var}->{'obj'}->setAttribute( 'type', 
							'orth_variant' );
		$ORTHOGRAPHY{$var_str} = $std_str;
	    } elsif( $answer =~ /^emend\s+([^:]+):\s+(\S+.*)$/ ) {
		# Put a placeholder lemma in this apparatus, and add
		# an editorial note with the text.
		my( $correction, $ed_note ) = ( $1, $2 );
		# Add the unattested lemma...
		$return_rdg = XML::LibXML::Element->new( 'lem' );
		$return_rdg->setAttribute( 'resp', '#tla' );
		$return_rdg->appendTextChild( 'wit', '[unattested]' );
		my @corr_words = split( /\s+/, $correction );
		foreach( @corr_words ) {
		    $return_rdg->appendTextChild( 'w', $_ );
		}
		$app->insertBefore( $return_rdg, $app->firstChild() );
		# ...and add the explanatory note.
		my $note_obj = XML::LibXML::Element->new( 'note' );
		$note_obj->setAttribute( 'type', 'emendation' );
		# TODO Should so not be hardcoded.
		$note_obj->setAttribute( 'resp', '#tla' );
		$note_obj->appendText( $ed_note );
		$app->appendChild( $note_obj );
		$picked = 1;
	    } elsif( $answer =~ /^h(elp)?/ ) {
		print 'Available commands:
accept (#)
accept detail (#)
subst detail (#) (value)
spelling (# alternate) (# canonical)
orth (# alternate) (# canonical)
emend (comment text)
note (note text)
next
help
save
quit
';
	    } else {
		print 'Huh? (h for help)';
	    }
	} # until we have enough answers
    }
    # Leave some space for the next one.
    print "-----------\n\n\n";
    return $return_rdg;
}

# Need to make sure that the lemma is the first child element of the app.
sub reorder_app {
    my( $app ) = @_;
    my @lem = $xpc->findnodes( './/tei:lem', $app );
    if( scalar @lem ) {
	my $lemma = $lem[0];  # there is no more than one lemma
	my @children = $app->childNodes();
	foreach my $c ( @children ) {
	    if( $c->nodeType == 1 && $c->nodeName ne 'lem' ) {
		# print STDERR "Moving lemma for app " 
		#     . $app->getAttribute( 'xml:id' ) . "\n";
		$app->insertBefore( $lemma, $c );
		last;
	    }
	}
    }
}

# Given a set of apparatus entries, string together the various readings
# available in them.
sub print_following_context {
    my( @apps ) = @_;
    my %witnesses;
    my %wit_details;
    foreach my $app ( @apps ) {
	my @readings = $xpc->findnodes( './/tei:rdg | .//tei:lem', $app );
	# TODO code reuse!!
	foreach my $rdg_obj ( @readings ) {
	    my @words = $xpc->findnodes( './/tei:w', $rdg_obj );
	    my @wits = split( /\s+/, $rdg_obj->getAttribute( 'wit' ) );
	    foreach my $w ( @words ) {
		# Add the word content to each of the witness hashes.
		my $w_id = $w->getAttribute( 'xml:id' );
		$w_id = '#' . $w_id if $w_id;
		foreach my $sigil ( @wits ) {
		    $witnesses{$sigil} .= $w->textContent;
		}
		# Look for witDetails applicable to this word.
		if( $w_id ) { # The word has witDetails.
		    my $xpath_expr = './/tei:witDetail[@type=\'punctuation\' and @target=' . "'$w_id']";
		    my @wit_det = $xpc->findnodes( $xpath_expr, $rdg_obj );
		    foreach my $wd ( @wit_det ) {
			foreach my $sigil( split( /\s+/, 
					  $wd->getAttribute( 'wit' ) ) ) {
			    $witnesses{$sigil} .= $wd->textContent;
			}
		    }
		}

		# And put a space on the end.  Clumsy but hey.
		foreach my $seen ( @wits ) {
		    $witnesses{$seen} .= ' ' 
			unless $witnesses{$seen} =~ /\s+$/;
		}
	    } # foreach word
	} # foreach reading
    } # foreach app

    # Now reverse the hash and print them out.
    my %readings = invert_hash( \%witnesses );
    # Find how much margin we need for the "witnesses" column.
    # While we're at it, join the string for easy printing in
    # the next loop.
    my $col_width = 0;
    foreach my $k ( keys %readings ) {
	my $witstr = join( ' ', @{$readings{$k}} );
	$readings{$k} = $witstr;
	$col_width = length( $witstr ) unless $col_width >= length( $witstr );
    }
    print "Following context: \n";
    foreach my $str ( keys %readings ) {
	printf( "%-${col_width}s: %s\n", $readings{$str}, $str );
    }
    print "-----------\n";
}

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

sub normalize_readings {
    my( $rdg_hash ) = @_;
    my %seen_spelling;
    my %seen_orth;
    my $next_rdg_idx = scalar keys( %$rdg_hash );
    foreach my $k ( keys %$rdg_hash ) {
	# Get the nodelist of words.
	my $wordlist = $rdg_hash->{$k}->{'words'};
	# String them together into a text.
	my $word_str = join( ' ', map { $_->textContent } $wordlist->get_nodelist );
	# Check the spelling hash.
	if( exists $SPELLINGS{$word_str} ) {
	    # This is a bad spelling.  Note that we've seen it.
	    my $corr_spell = $SPELLINGS{$word_str};
	    _add_hash_entry( \%seen_spelling, $corr_spell, $k );
	} elsif( exists $ORTHOGRAPHY{$word_str} ) {
	    # This is a bad spelling.  Note that we've seen it.
	    my $corr_spell = $ORTHOGRAPHY{$word_str};
	    _add_hash_entry( \%seen_orth, $corr_spell, $k );
	} 
    }

    # Now that we have got all the misspellings, go through looking
    # for correct versions of those misspellings in the readings.
    my @readings = values %$rdg_hash;
    foreach my $rdg ( @readings ) {
	my $wordlist = $rdg->{'words'};
	# String them together into a text.
	my $word_str = join( ' ', map { $_->textContent } 
			              $wordlist->get_nodelist );
	if( exists $seen_spelling{$word_str} ) {
	    # This is the normal form of a spelling for which we
	    # have seen a variant.  Fold the variant into the normal
	    # reading.
	    foreach my $var_idx ( @{$seen_spelling{$word_str}} ) {
		my $var_rdg = delete $rdg_hash->{$var_idx};
		$var_rdg->{'obj'}->setAttribute( 'type', 'spelling_variant' );
		_add_hash_entry( $rdg, 'sp_var', $var_rdg );
	    }
	    delete $seen_spelling{$word_str};
	}
	if( exists $seen_orth{$word_str} ) {
	    # This is the normal form of an orthography
	    # have seen a variant.  Fold the variant into the normal
	    # reading.
	    foreach my $var_idx ( @{$seen_orth{$word_str}} ) {
		my $var_rdg = delete $rdg_hash->{$var_idx};
		$var_rdg->{'obj'}->setAttribute( 'type', 'orth_variant' );
		# Can still chuck them in the same variant-to-display hash.
		_add_hash_entry( $rdg, 'sp_var', $var_rdg );
	    }
	    delete $seen_orth{$word_str};
	}
    }

    # TODO handle case of misspellings that have no properly-spelled variant
    # available
}

sub print_results {
    # Write it all out.
    my( $quitting ) = @_;
    $doc->toFile( $outfile, 1 );
    if( $quitting ) {
	my( $sp_title, $orth_title );
	foreach ( sort keys %SPELLINGS ) {
	    print " New spellings: \n" unless $sp_title;
	    $sp_title = 1;
	    print "    '$_' => '" . $SPELLINGS{$_} . "',\n"
		unless exists( $start_sp{$_} );
	}
	foreach ( sort keys %ORTHOGRAPHY ) {
	    print " New orthography: \n" unless $orth_title;
	    $orth_title = 1;
	    print "    '$_' => '" . $ORTHOGRAPHY{$_} . "',\n"
		unless exists( $start_orth{$_} );
	}
    }
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
