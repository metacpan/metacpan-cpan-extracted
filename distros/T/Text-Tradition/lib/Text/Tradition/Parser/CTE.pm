package Text::Tradition::Parser::CTE;

use strict;
use warnings;
use feature 'say';
use Encode qw/ decode /;
use Text::Tradition::Error;
use Text::Tradition::Parser::Util qw/ collate_variants /;
use XML::LibXML;
use XML::LibXML::XPathContext;
use TryCatch;

binmode( STDERR, ':utf8' );

=head1 NAME

Text::Tradition::Parser::CTE

=head1 DESCRIPTION

Parser module for Text::Tradition, given a TEI file exported from
Classical Text Editor.

=head1 METHODS

=head2 parse

my @apparatus = read( $xml_file );

Takes a Tradition object and a TEI file exported from Classical Text
Editor using double-endpoint-attachment critical apparatus encoding; 
initializes the Tradition from the file.

=cut

my %sigil_for;  # Save the XML IDs for witnesses.
my %apps;       # Save the apparatus XML for a given ID.    
my %has_ac;     # Keep track of witnesses that have corrections.

sub parse {
	my( $tradition, $opts ) = @_;
	my $c = $tradition->collation;	# Some shorthand
	
	## DEBUG/TEST
	$opts->{interpret_transposition} = 1;
	
	# First, parse the XML.
    my( $tei, $xpc ) = _remove_formatting( $opts );
    return unless $tei; # we have already warned.

	# CTE uses a DTD rather than any xmlns-based parsing.  Thus we
	# need no namespace handling.
	# Get the witnesses and create the witness objects.
	%sigil_for = ();
	%apps = ();
	%has_ac = ();
	foreach my $wit_el ( $xpc->findnodes( '//sourceDesc/listWit/witness' ) ) {
		# The witness xml:id is used internally, and is *not* the sigil name.
		my $id= $wit_el->getAttribute( 'xml:id' );
		# If the witness element has an abbr element, that is the sigil. Otherwise
		# the whole thing is the sigil.
		my $sig = $xpc->findvalue( 'abbr', $wit_el );
		my $identifier = 'CTE witness';
		if( $sig ) {
			# The sigil is what is in the <abbr/> tag; the identifier is anything
			# that follows. 
			$identifier = _tidy_identifier( 
				$xpc->findvalue( 'child::text()', $wit_el ) );
		} else {
			my @sig_parts = $xpc->findnodes( 'descendant::text()', $wit_el );
			$sig = _stringify_sigil( @sig_parts );
		}
		_do_warn( $opts, "Adding witness $sig ($identifier)" );
		$tradition->add_witness( sigil => $sig, identifier => $identifier, 
			sourcetype => 'collation' );
		$sigil_for{'#'.$id} = $sig;  # Make life easy by keying on the ID ref syntax
	}
	
	# Now go through the text and find the base tokens, apparatus tags, and
	# anchors.  Make a giant array of all of these things in sequence.
	# TODO consider combining this with creation of graph below
	my @base_text;
	foreach my $pg_el ( $xpc->findnodes( '/TEI/text/body/p' ) ) {
		foreach my $xn ( $pg_el->childNodes ) {
			push( @base_text, _get_base( $xn ) );
		}
	}
	# We now have to work through this array applying the alternate 
	# apparatus readings to the base text.  Essentially we will put 
	# everything on the graph, from which we will delete the apps and
	# anchors when we are done.
	
	# First, put the base tokens, apps, and anchors in the graph. Save the
	# app siglorum separately as it has to be processed in order.
	my @app_sig;
	my @app_crit;
	my $counter = 0;
	my $last = $c->start;
	foreach my $item ( @base_text ) {
	    my $r;
        if( $item->{'type'} eq 'token' ) {
            $r = $c->add_reading( { id => 'n'.$counter++, 
            						text => $item->{'content'} } );
        } elsif ( $item->{'type'} eq 'anchor' ) {
            $r = $c->add_reading( { id => '__ANCHOR_' . $item->{'content'} . '__', 
            						is_ph => 1 } );
        } elsif ( $item->{'type'} eq 'app' ) {
            my $tag = '__APP_' . $counter++ . '__';
            $r = $c->add_reading( { id => $tag, is_ph => 1 } );
            my $app = $item->{'content'};
            $apps{$tag} = $app;
            # Apparatus should be differentiable by type attribute; apparently
            # it is not. Peek at the content to categorize it.
            # Apparatus criticus is type a1; app siglorum is type a2
            my @sigtags = $xpc->findnodes( 'descendant::*[name(witStart) or name(witEnd)]', $app );
            if( @sigtags ) {
	        	push( @app_sig, $tag );
	        } else {
	            push( @app_crit, $tag );
	        }
        }
        $c->add_path( $last, $r, $c->baselabel );
        $last = $r;
    }
    $c->add_path( $last, $c->end, $c->baselabel );
    
    # Now we can parse the apparatus entries, and add the variant readings 
    # to the graph.
    foreach my $app_id ( @app_crit ) {
        _add_readings( $c, $app_id, $opts );
    }
    _add_lacunae( $c, @app_sig );
    
    # Finally, add explicit witness paths, remove the base paths, and remove
    # the app/anchor tags.
    try {
	    _expand_all_paths( $c, $opts );
	} catch( Text::Tradition::Error $e ) {
		throw( $e->message );
	} catch {
		throw( $@ );
	}

    # Save the text for each witness so that we can ensure consistency
    # later on
    unless( $opts->{'nocalc'} ) {
    	try {
			$tradition->collation->text_from_paths();	
			$tradition->collation->calculate_ranks();
			$tradition->collation->flatten_ranks();
		} catch( Text::Tradition::Error $e ) {
			throw( $e->message );
		} catch {
			throw( $@ );
		}
	}
}

sub _stringify_sigil {
    my( @nodes ) = @_;
    my @parts = grep { /\w/ } map { $_->data } @nodes;
    my $whole = join( '', @parts );
    $whole =~ s/\W//g;
    return $whole;
}

sub _tidy_identifier {
	my( $str ) = @_;
	$str =~ s/^\W+//;
	return $str;
}

# Get rid of all the formatting elements that get in the way of tokenization.
sub _remove_formatting {
	my( $opts ) = @_;
	
	# First, parse the original XML
	my $parser = XML::LibXML->new();
    my $doc;
    if( exists $opts->{'string'} ) {
        $doc = $parser->parse_string( $opts->{'string'} );
    } elsif ( exists $opts->{'file'} ) {
        $doc = $parser->parse_file( $opts->{'file'} );
    } elsif ( exists $opts->{'xmlobj'} ) {
    	$doc = $opts->{'xmlobj'};
    } else {
        warn "Could not find string or file option to parse";
        return;
    }

    # Second, remove the formatting
	my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
	my @useless = $xpc->findnodes( '//hi' );
	foreach my $n ( @useless ) {
		my $parent = $n->parentNode();
		my @children = $n->childNodes();
		my $first = shift @children;
		if( $first ) {
			$parent->replaceChild( $first, $n );
			foreach my $c ( @children ) {
				$parent->insertAfter( $c, $first );
				$first = $c;
			}
		} else {
			$parent->removeChild( $n );
		}
	}
	
	# Third, write out and reparse to merge the text nodes.
	my $enc = $doc->encoding || 'UTF-8';
	my $result = decode( $enc, $doc->toString() );
	my $tei = $parser->parse_string( $result )->documentElement;
	unless( $tei->nodeName =~ /^tei(corpus)?$/i ) {
		throw( "Parsed document has non-TEI root element " . $tei->nodeName );
	}
	$xpc = XML::LibXML::XPathContext->new( $tei );
	return( $tei, $xpc );
}

## Helper function to help us navigate through nested XML, picking out 
## the words, the apparatus, and the anchors.

sub _get_base {
	my( $xn ) = @_;
	my @readings;
	if( $xn->nodeType == XML_TEXT_NODE ) {
	    # Base text, just split the words on whitespace and add them 
	    # to our sequence.
		my $str = $xn->data;
		$str =~ s/^\s+//;
		my @tokens = split( /\s+/, $str );
		push( @readings, map { { type => 'token', content => $_ } } @tokens );
	} elsif( $xn->nodeName eq 'app' ) {
		# Apparatus, just save the entire XML node.
		push( @readings, { type => 'app', content => $xn } );
	} elsif( $xn->nodeName eq 'anchor' ) {
		# Anchor to mark the end of some apparatus; save its ID.
		if( $xn->hasAttribute('xml:id') ) {
			push( @readings, { type => 'anchor', 
			    content => $xn->getAttribute( 'xml:id' ) } );
		} # if the anchor has no XML ID, it is not relevant to us.
	} elsif( $xn->nodeName !~ /^(note|seg|milestone|emph)$/ ) {  # Any tag we don't know to disregard
	    say STDERR "Unrecognized tag " . $xn->nodeName;
	}
	return @readings;
}

sub _append_tokens {
	my( $list, @tokens ) = @_;
	if( @$list && $list->[-1]->{'content'} =~ /\#JOIN\#$/ ) {
		# The list evidently ended mid-word; join the next token onto it.
		my $t = shift @tokens;
		if( ref $t && $t->{'type'} eq 'token' ) {
			# Join the word
			$t = $t->{'content'};
		} elsif( ref $t ) {
			# An app or anchor intervened; end the word.
			unshift( @tokens, $t );
			$t = '';
		}
		$list->[-1]->{'content'} =~ s/\#JOIN\#$/$t/;
	}
	foreach my $t ( @tokens ) {
		unless( ref( $t ) ) {
			$t = { 'type' => 'token', 'content' => $t };
		}
		push( @$list, $t );
	}
}

sub _add_readings {
    my( $c, $app_id, $opts ) = @_;
    my $xn = $apps{$app_id};
    my $anchor = _anchor_name( $xn->getAttribute( 'to' ) );
    
    # Get the lemma, which is all the readings between app and anchor,
    # excluding other apps or anchors.
	my @lemma = _return_lemma( $c, $app_id, $anchor );
	my $lemma_str = join( ' ',  map { $_->text } grep { !$_->is_ph } @lemma );
        
    # For each reading, send its text to 'interpret' along with the lemma,
    # and then save the list of witnesses that these tokens belong to.
    my %wit_rdgs;  # Maps from witnesses to the variant text
    my $ctr = 0;
    my $tag = $app_id;
    $tag =~ s/^\__APP_(.*)\__$/$1/;

    foreach my $rdg ( $xn->getChildrenByTagName( 'rdg' ) ) {
    	my @witlist = split( /\s+/, $rdg->getAttribute( 'wit' ) );
        my @text;
        foreach ( $rdg->childNodes ) {
            push( @text, _get_base( $_ ) );
        }
        my( $interpreted, $flag ) = ( '', undef );
        if( @text ) {
        	( $interpreted, $flag ) = interpret( 
        		join( ' ', map { $_->{'content'} } @text ), $lemma_str, $anchor, $opts );
        }
        next if( $interpreted eq $lemma_str ) && !keys %$flag;  # Reading is lemma.
        
        my @rdg_nodes;
        if( $interpreted eq '#LACUNA#' ) {
        	push( @rdg_nodes, $c->add_reading( { id => 'r'.$tag.".".$ctr++,
        										 is_lacuna => 1 } ) );
        } elsif( $flag->{'TR'} ) {
        	# Our reading is transposed to after the given string. Look
        	# down the collation base text and try to find it.
        	# The @rdg_nodes should remain blank here, so that the correct
        	# omission goes into the graph.
	        my @transp_nodes;
        	foreach my $w ( split(  /\s+/, $interpreted ) ) {
        		my $r = $c->add_reading( { id => 'r'.$tag.".".$ctr++,
										   text => $w } );
				push( @transp_nodes, $r );
			}
			if( $anchor && @lemma ) {
				my $success = _attach_transposition( $c, \@lemma, $anchor, 
					\@transp_nodes, \@witlist, $flag->{'TR'}, $opts );
				unless( $success ) {
					# If we didn't manage to insert the displaced reading,
					# then restore it here rather than silently deleting it.
					push( @rdg_nodes, @transp_nodes );
				}
			}
        } else {
			foreach my $w ( split( /\s+/, $interpreted ) ) {
				my $r = $c->add_reading( { id => 'r'.$tag.".".$ctr++,
										   text => $w } );
				push( @rdg_nodes, $r );
			}
        }
        
        # For each listed wit, save the reading.
        # If an A.C. or P.C. reading is implied rather than explicitly noted,
        # this is where it will be dealt with.
        foreach my $wit ( @witlist ) {
			$wit .= '_ac' if $flag->{'AC'};
            $wit_rdgs{$wit} = \@rdg_nodes;
            # If the PC flag is set, there is a corresponding AC that
            # follows the lemma and has to be explicitly declared.
            if( $flag->{'PC'} ) {
            	$wit_rdgs{$wit.'_ac'} = \@lemma;
            }
        }
        		
        # Does the reading have an ID? If so it probably has a witDetail
        # attached, and we need to read it. If an A.C. or P.C. reading is
        # declared explicity, this is where it will be dealt with.
        if( $rdg->hasAttribute( 'xml:id' ) ) {
        	warn "Witdetail on meta reading" if $flag; # this could get complicated.
            my $rid = $rdg->getAttribute( 'xml:id' );
            my $xpc = XML::LibXML::XPathContext->new( $xn );
            my @details = $xpc->findnodes( './witDetail[@target="'.$rid.'"]' );
            foreach my $d ( @details ) {
                _parse_wit_detail( $d, \%wit_rdgs, \@lemma );
            }
        }
    }       
        
    # Now collate the variant readings, since it is not done for us.
    collate_variants( $c, \@lemma, values %wit_rdgs );
        
    # Now add the witness paths for each reading. If we don't have an anchor
    # (e.g. with an initial witStart) there was no witness path to speak of.
	foreach my $wit_id ( keys %wit_rdgs ) {
		my $witstr = _get_sigil( $wit_id, $c->ac_label );
		my $rdg_list = $wit_rdgs{$wit_id};
		_add_wit_path( $c, $rdg_list, $app_id, $anchor, $witstr );
	}
}

sub _anchor_name {
    my $xmlid = shift;
    $xmlid =~ s/^\#//;
    return sprintf( "__ANCHOR_%s__", $xmlid );
}

sub _return_lemma {
    my( $c, $app, $anchor ) = @_;
    my @nodes = grep { $_->id !~ /^__A(PP|NCHOR)/ } 
        $c->reading_sequence( $c->reading( $app ), $c->reading( $anchor ),
        	$c->baselabel );
    return @nodes;
}

# Make a best-effort attempt to attach a transposition farther down the line.
# $lemmaseq contains the Reading objects of the lemma
# $anchor contains the point at which we should start scanning for a match
# $rdgseq contains the Reading objects of the transposed reading 
# 	(should be identical to the lemma)
# $witlist contains the list of applicable witnesses
# $reftxt contains the text to match, after which the $rdgseq should go.
sub _attach_transposition {
	my( $c, $lemmaseq, $anchor, $rdgseq, $witlist, $reftxt, $opts ) = @_;
	my @refwords = split( /\s+/, $reftxt );
	my $checked = $c->reading( $anchor );
	my $found;
	my $success;
	while( $checked ne $c->end && !$found ) {
		my $next = $c->next_reading( $checked, $c->baselabel );
		if( $next->text eq $refwords[0] ) {
			# See if the entire sequence of words matches.
			$found = $next;
			foreach my $w ( 1..$#refwords ) {
				$found = $c->next_reading( $next, $c->baselabel );
				unless( $found->text eq $refwords[$w] ) {
					$found = undef;
					last;
				}
			}
		}
		$checked = $next;
	}
	if( $found ) {
		# The $found variable should now contain the reading after which we
		# should stick the transposition.
		my $fnext = $c->next_reading( $found, $c->baselabel );
		my $aclabel = $c->ac_label;
		foreach my $wit_id ( @$witlist ) {
			my $witstr = _get_sigil( $wit_id, $aclabel );
			_add_wit_path( $c, $rdgseq, $found->id, $fnext->id, $witstr );
		}
		# ...and add the transposition relationship between lemma and rdgseq.
		if( @$lemmaseq == @$rdgseq ) {
			foreach my $i ( 0..$#{$lemmaseq} ) {
				$c->add_relationship( $lemmaseq->[$i], $rdgseq->[$i],
					{ type => 'transposition', annotation => 'Detected by CTE' } );
			}
		$success = 1;
		} else {
			throw( "Lemma at $found and transposed sequence different lengths?!" );
		}
	} else {
		_do_warn( $opts, "WARNING: Unable to find $reftxt in base text for transposition" );
	}
	return $success;
}

=head2 interpret( $reading, $lemma )

Given a string in $reading and a corresponding lemma in $lemma, interpret what
the actual reading should be. Used to deal with apparatus-ese shorthands for
marking transpositions, prefixed or suffixed words, and the like.

=cut

sub interpret {
	# A utility function to change apparatus-ese into a full variant.
	my( $reading, $lemma, $anchor, $opts ) = @_;
	return $reading if $reading eq $lemma;
	my $oldreading = $reading;
	# $lemma =~ s/\s+[[:punct:]]+$//;
	my $flag = {};  # To pass back extra info about the interpretation
	my @words = split( /\s+/, $lemma );
	# Discard any 'sic' notation - that rather goes without saying.
	$reading =~ s/([[:punct:]]+)?sic([[:punct:]]+)?//g;
	
	# Now look for common jargon.
	if( $reading =~ /^(.*) praem.$/ || $reading =~ /^praem\. (.*)$/ ) {
		$reading = "$1 $lemma";
	} elsif( $reading =~ /^(.*) add.$/ || $reading =~ /^add\. (.*)$/ ) {
		$reading = "$lemma $1";
	} elsif( $reading =~ /locus [uv]acuus/
	    || $reading eq 'def.'
	    || $reading eq 'illeg.'
	    || $reading eq 'desunt'
	    ) {
		$reading = '#LACUNA#';
	} elsif( $reading eq 'om.' ) {
		$reading = '';
	} elsif( $reading =~ /^in[uv]\.$/ 
			 || $reading =~ /^tr(ans(p)?)?\.$/ ) {
		# Hope it is two words.
		_do_warn( $opts, "WARNING: want to invert a lemma that is not two words" )
			unless scalar( @words ) == 2;
		$reading = join( ' ', reverse( @words ) );
	} elsif( $reading =~ /^iter(\.|at)$/ ) {
		# Repeat the lemma
		$reading = "$lemma $lemma";
	} elsif( $reading =~ /^(.*?)\s*\(?in marg\.\)?$/ ) {
		$reading = $1;
		if( $reading ) {
			# The given text is a correction.
			$flag->{'PC'} = 1;
		} else {
			# The lemma itself was the correction; the witness carried
			# no reading pre-correction.
			$flag->{'AC'} = 1;
		}
	} elsif( $reading =~ /^(.*) \.\.\. (.*)$/ ) {
		# The first and last N words captured should replace the first and
		# last N words of the lemma.
		my @begin = split( /\s+/, $1 );
		my @end = split( /\s+/, $2 );
		if( scalar( @begin ) + scalar ( @end ) > scalar( @words ) ) {
			# Something is wrong and we can't do the splice.
			throw( "$lemma is too short to accommodate $oldreading" );
		} else {
			splice( @words, 0, scalar @begin, @begin );
			splice( @words, -(scalar @end), scalar @end, @end );
			$reading = join( ' ', @words );
		}
	} elsif( $opts->{interpret_transposition} &&
			 ( $reading =~ /^post\s*(?<lem>.*?)\s+tr(ans(p)?)?\.$/ || 
			   $reading =~ /^tr(ans(p)?)?\. post\s*(?<lem>.*)$/) ) {
		# Try to deal with transposed readings
		## DEBUG
		say STDERR "Will attempt transposition: $reading at $anchor";
		$reading = $lemma;
		$flag->{'TR'} = $+{lem};
	}
	return( $reading, $flag );
}

sub _parse_wit_detail {
    my( $detail, $readings, $lemma ) = @_;
    my $wit = $detail->getAttribute( 'wit' );
    my $content = $detail->textContent;
    if( $content =~ /^a\.?\s*c(orr)?\.$/ ) {
        # Replace the key in the $readings hash
        my $rdg = delete $readings->{$wit};
        $readings->{$wit.'_ac'} = $rdg;
        $has_ac{$sigil_for{$wit}} = 1;
    } elsif( $content =~ /^p\.?\s*c(orr)?\.$/ || $content =~ /^s\.?\s*l\.$/ ) {
        # If no key for the wit a.c. exists, add one pointing to the lemma
        unless( exists $readings->{$wit.'_ac'} ) {
            $readings->{$wit.'_ac'} = $lemma;
        }
        $has_ac{$sigil_for{$wit}} = 1;
    } else {  #...not sure what it is?
    	say STDERR "WARNING: Unrecognized sigil annotation $content";
    }
}

sub _add_lacunae {
	my( $c, @app_id ) = @_;
	# Go through the apparatus entries in order, noting where to start and stop our
	# various witnesses.
	my %lacunose;
	my $ctr = 0;
	foreach my $tag ( @app_id ) {
		my $app = $apps{$tag};
		# Find the anchor, if any. This marks the point where the text starts
		# or ends.
		my $anchor = $app->getAttribute( 'to' );
		my $aname;
		if( $anchor ) {
			$anchor =~ s/^\#//;
			$aname = _anchor_name( $anchor );
		}

		foreach my $rdg ( $app->getChildrenByTagName( 'rdg' ) ) {
    		my @witlist = map { _get_sigil( $_, $c->ac_label ) }
    			split( /\s+/, $rdg->getAttribute( 'wit' ) );
			my @start = $rdg->getChildrenByTagName( 'witStart' );
			my @end = $rdg->getChildrenByTagName( 'witEnd' );
			if( @start && @end ) {
				throw( "App sig entry at $anchor has both witStart and witEnd!" );
			}
			if( @start && $anchor &&
				$c->prior_reading( $aname, $c->baselabel ) ne $c->start ) {
				# We are picking back up after a hiatus. Find the last end and
				# add a lacuna link between there and here.
				foreach my $wit ( @witlist ) {
					my $stoppoint = delete $lacunose{$wit};
					my $stopname = $stoppoint ? _anchor_name( $stoppoint ) : $c->start->id;
					say STDERR "Adding lacuna for $wit between $stopname and $anchor";
					my $lacuna = $c->add_reading( { id => "as_$anchor.".$ctr++,
        				is_lacuna => 1 } );
        			_add_wit_path( $c, [ $lacuna ], $stopname, $aname, $wit );
				}
			} elsif( @end && $anchor && 
				$c->next_reading( $aname, $c->baselabel ) ne $c->end ) {
				# We are stopping. If we've already stopped for the given witness,
				# flag an error; otherwise record the stopping point.
				foreach my $wit ( @witlist ) {
					if( $lacunose{$wit} ) {
						throw( "Trying to end $wit at $anchor when already ended at "
							. $lacunose{$wit} );
					}
					$lacunose{$wit} = $anchor;
				}
			}
		}
	}
	
	# For whatever remains in the %lacunose hash, add a lacuna between that spot and
	# $c->end for each of the witnesses.
	foreach my $wit ( keys %lacunose ) {
		next unless $lacunose{$wit};
		my $aname = _anchor_name( $lacunose{$wit} );
		say STDERR "Adding lacuna for $wit from $aname to end";
		my $lacuna = $c->add_reading( { id => 'as_'.$lacunose{$wit}.'.'.$ctr++,
			is_lacuna => 1 } );
		_add_wit_path( $c, [ $lacuna ], $aname, $c->end, $wit );
	}
}

sub _get_sigil {
    my( $xml_id, $layerlabel ) = @_;
    if( $xml_id =~ /^(.*)_ac$/ ) {
        my $real_id = $1;
        return $sigil_for{$real_id} . $layerlabel;
    } else {
        return $sigil_for{$xml_id};
    }
}

sub _expand_all_paths { 
    my( $c, $opts ) = @_;
    
    # Walk the collation and fish out the paths for each witness
    foreach my $wit ( $c->tradition->witnesses ) {
        my $sig = $wit->sigil;
        my @path = grep { !$_->is_ph } 
            $c->reading_sequence( $c->start, $c->end, $sig );
        $wit->path( \@path );
        if( $has_ac{$sig} ) {
            my @ac_path = grep { !$_->is_ph } 
                $c->reading_sequence( $c->start, $c->end, $sig.$c->ac_label );
            $wit->uncorrected_path( \@ac_path );
        }
    }   
    
    # Delete the anchors
    foreach my $anchor ( grep { $_->is_ph } $c->readings ) {
        $c->del_reading( $anchor );
    }
    # Delete the base edges
    map { $c->del_path( $_, $c->baselabel ) } $c->paths;
    
    # Make the path edges
    $c->make_witness_paths();
    
    # Now remove any orphan nodes, and warn that we are doing so.
    my %suspect_apps;
    while( $c->sequence->predecessorless_vertices > 1 ) {
    	foreach my $v ( $c->sequence->predecessorless_vertices ) {
	    	my $r = $c->reading( $v );
	    	next if $r->is_start;
	    	my $tag = $r->id;
	    	$tag =~ s/^r(\d+)\.\d+/$1/;
    		_do_warn( $opts, "Deleting orphan reading $r / " . $r->text );
    		push( @{$suspect_apps{$tag}}, $r->id ) if $tag =~ /^\d+$/;
    		$c->del_reading( $r );
    	}
    }
    if( $c->sequence->successorless_vertices > 1 ) {
    	my @bad = grep { $_ ne $c->end->id } $c->sequence->successorless_vertices;
    	foreach( @bad ) {
    		my $tag = $_;
    		next unless $tag =~ /^r/;
    		$tag =~ s/^r(\d+)\.\d+/$1/;
    		push( @{$suspect_apps{$tag}}, $_ );
    	}
		_dump_suspects( $opts, %suspect_apps );
    	throw( "Remaining hanging readings: @bad" );
	}
	_dump_suspects( $opts, %suspect_apps ) if keys %suspect_apps;
}

sub _add_wit_path {
    my( $c, $rdg, $app, $anchor, $wit ) = @_;
    my @nodes = @$rdg;
    push( @nodes, $c->reading( $anchor ) );
    
    my $cur = $c->reading( $app );
    foreach my $n ( @nodes ) {
        $c->add_path( $cur, $n, $wit );
        $cur = $n;
    }
}

sub _dump_suspects {
	my $opts = shift;
	my %list = @_;
	my @warning = "Suspect apparatus entries:";
	foreach my $suspect ( sort { $a <=> $b } keys %list ) {
		my @badrdgs = @{$list{$suspect}};
		push( @warning, _print_apparatus( $suspect ) );
		push( @warning, "\t(Linked to readings @badrdgs)" );
	}
	_do_warn( $opts, join( "\n", @warning ) );
}

sub _print_apparatus {
	my( $appid ) = @_;
	my $tag = '__APP_' . $appid . '__';
	my $app = $apps{$tag};
	my $appstring = '';
	# Interpret the XML - get the lemma and readings and print them out.
	my $xpc = XML::LibXML::XPathContext->new( $app );
	my $anchor = $app->getAttribute('to');
	if( $anchor ) {
		# We have a lemma, so we construct it.
		$anchor =~ s/^#//;
		$appstring .= "(Anchor $anchor) ";
		my $curr = $app;
		while( $curr ) {
			last if $curr->nodeType eq XML_ELEMENT_NODE 
				&& $curr->hasAttribute( 'xml:id' ) 
				&& $curr->getAttribute( 'xml:id' ) eq $anchor;
			$appstring .= $curr->data if $curr->nodeType eq XML_TEXT_NODE;
			$curr = $curr->nextSibling;
		}
	}
	$appstring .= '] ';
	my @readings;
	foreach my $rdg_el ( $xpc->findnodes( 'child::rdg' ) ) {
		my $rdgtext = '';
		my $startend = '';
		my %detail;
		foreach my $child_el ( $rdg_el->childNodes ) {
			if( $child_el->nodeType eq XML_TEXT_NODE ) {
				$rdgtext .= $child_el->data;
			} elsif( $child_el->nodeName =~ /^wit(Start|End)$/ ) {
				my $startend = lc( $1 );
			} elsif( $child_el->nodeName eq 'witDetail' ) {
				foreach my $wit ( map { _get_sigil( $_ ) } 
					split( /\s+/, $child_el->getAttribute('wit') ) ) {
					$detail{$wit} = $child_el->textContent;
				}
			}
		}
		
		my @witlist;
		foreach my $witrep (  map { _get_sigil( $_ ) } 
			split( /\s+/, $rdg_el->getAttribute('wit') ) ) {
			if( exists $detail{$witrep} ) {
				$witrep .= '(' . $detail{$witrep} . ')'
			}
			if( $startend eq 'start' ) {
				$witrep = '*' . $witrep;
			} elsif( $startend eq 'end' ) {
				$witrep .= '*';
			}
			push( @witlist, $witrep );
		}
		$rdgtext .= " @witlist";
		push( @readings, $rdgtext );
	}
	$appstring .= join( '  ', @readings );
	return $appstring;
}

# Helper to send warning messages either to STDERR or to an array for alternate display.
sub _do_warn {
	my( $opts, $message ) = @_;
	if( $opts->{'warnings_to'} ) {
		push( @{$opts->{'warnings_to'}}, $message );
	} else {
		say STDERR $message;
	}
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Parser::CTE error',
		'message' => $_[0],
		);
}

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews, aurum@cpan.org

=cut

1;

