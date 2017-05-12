package Text::Tradition::Parser::TEI;

use strict;
use warnings;
use Text::Tradition::Error;
use Text::Tradition::Parser::Util qw( collate_variants );
use XML::LibXML;
use XML::LibXML::XPathContext;

=head1 NAME

Text::Tradition::Parser::TEI

=head1 SYNOPSIS

  use Text::Tradition;
  
  my $t_from_file = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'TEI',
    'file' => '/path/to/parallel_seg_file.xml'
    );
    
  my $t_from_string = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'TEI',
    'string' => $parallel_seg_xml,
    );


=head1 DESCRIPTION

Parser module for Text::Tradition, given a TEI parallel-segmentation file
that describes a text and its variants.  Normally called upon
initialization of Text::Tradition.

The witnesses for the tradition are taken from the <listWit/> element
within the TEI header; the readings are taken from any <p/> element that
appears in the text body (including <head/> elements therein.)

=head1 METHODS

=head2 B<parse>( $tradition, $option_hash )

Takes an initialized tradition and a set of options; creates the
appropriate nodes and edges on the graph, as well as the appropriate
witness objects.  The $option_hash must contain either a 'file' or a
'string' argument with the XML to be parsed.

=begin testing

use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $par_seg = 't/data/florilegium_tei_ps.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'TEI',
    'file'  => $par_seg,
    );

is( ref( $t ), 'Text::Tradition', "Parsed parallel-segmentation TEI" );
if( $t ) {
    is( scalar $t->collation->readings, 311, "Collation has all readings" );
    is( scalar $t->collation->paths, 361, "Collation has all paths" );
    my @lemmata = grep { $_->is_lemma } $t->collation->readings;
    is( scalar @lemmata, 7, "Collation has its lemmata" );
}

# Try to re-parse it, ensure we can use the parser twice in the same Perl
# invocation

my $t2 = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'TEI',
    'file'  => $par_seg,
    );

is( ref( $t2 ), 'Text::Tradition', "Parsed parallel-segmentation TEI again" );

=end testing

=cut

my $text = {}; # Hash of arrays, one per eventual witness we find.
my $substitutions = {}; # Keep track of merged readings
my $app_anchors = {};   # Track apparatus references
my $app_ac = {};        # Save a.c. readings
my $app_count;          # Keep track of how many apps we have

# Create the package variables for tag names.

# Would really like to do this with varname variables, but apparently this
# is considered a bad idea.  The long way round then.
my( $LISTWIT, $WITNESS, $TEXT, $W, $SEG, $APP, $RDG, $LEM ); 
sub _make_tagnames {
    my( $ns ) = @_;
    ( $LISTWIT, $WITNESS, $TEXT, $W, $SEG, $APP, $RDG, $LEM ) 
    	= ( 'listWit', 'witness', 'text', 'w', 'seg', 'app', 'rdg', 'lem' );
    if( $ns ) {
        $LISTWIT = "$ns:$LISTWIT";
        $WITNESS = "$ns:$WITNESS";
        $TEXT = "$ns:$TEXT";
        $W = "$ns:$W";
        $SEG = "$ns:$SEG";
        $APP = "$ns:$APP";
        $RDG = "$ns:$RDG";
        $LEM = "$ns:$LEM";
    }
}

# Parse the TEI file.
sub parse {
    my( $tradition, $opts ) = @_;
    
    # First, parse the XML.
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
    my $tei = $doc->documentElement();
	unless( $tei->nodeName =~ /^tei(corpus)?$/i ) {
		throw( "Parsed document has non-TEI root element " . $tei->nodeName );
	}
    my $xpc = XML::LibXML::XPathContext->new( $tei );
    my $ns;
    if( $tei->namespaceURI ) {
        $ns = 'tei';
        $xpc->registerNs( $ns, $tei->namespaceURI );
    }
    _make_tagnames( $ns );

    # Then get the witnesses and create the witness objects.
    foreach my $wit_el ( $xpc->findnodes( "//$LISTWIT/$WITNESS" ) ) {
        my $sig = $wit_el->getAttribute( 'xml:id' );
        my $source = $wit_el->toString();
        $tradition->add_witness( sigil => $sig, sourcetype => 'collation' );
    }
    map { $text->{$_->sigil} = [] } $tradition->witnesses;

    # Look for all word/seg node IDs and note their pre-existence.
    my @attrs = $xpc->findnodes( "//$W/attribute::xml:id" );
    _save_preexisting_nodeids( @attrs );

    # Count up how many apps we have.
    my @apps = $xpc->findnodes( "//$APP" );
    $app_count = scalar( @apps );

    # Now go through the children of the text element and pull out the
    # actual text.
    foreach my $xml_el ( $xpc->findnodes( "//$TEXT" ) ) {
        foreach my $xn ( $xml_el->childNodes ) {
            _get_readings( $tradition, $xn );
        }
    }
    # Our $text global now has lists of readings, one per witness.
    # Join them up.
    my $c = $tradition->collation;
    foreach my $sig ( keys %$text ) {
        # Determine the list of readings for 
        my $sequence = $text->{$sig};
        my @real_sequence = ( $c->start );
        push( @$sequence, $c->end );
        foreach( _clean_sequence( $sig, $sequence, 1 ) ) {
            push( @real_sequence, _return_rdg( $_ ) );
        }
        # See if we need to make an a.c. version of the witness.
        if( exists $app_ac->{$sig} ) {
            my @uncorrected;
            push( @uncorrected, @real_sequence );
            # Get rid of any remaining placeholders.
            @real_sequence = _clean_sequence( $sig, \@uncorrected );
            # Do the uncorrections
            foreach my $app ( keys %{$app_ac->{$sig}} ) {
                my $start = _return_rdg( $app_anchors->{$app}->{$sig}->{'start'} ); 
                my $end = _return_rdg( $app_anchors->{$app}->{$sig}->{'end'} );
                my @new = map { _return_rdg( $_ ) } @{$app_ac->{$sig}->{$app}};
                _replace_sequence( \@uncorrected, $start, $end, @new );
            }
            # and record the results.
            $tradition->witness( $sig )->uncorrected_path( \@uncorrected );
            $tradition->witness( $sig )->is_layered( 1 );
        }
        $tradition->witness( $sig )->path( \@real_sequence );
    }
    # Now make our witness paths.
    $tradition->collation->make_witness_paths();
    
    unless( $opts->{'nocalc'} ) {
		# Calculate the ranks for the nodes.
		$tradition->collation->calculate_ranks();
	
		# Now that we have ranks, see if we have distinct nodes with identical
		# text and identical rank that can be merged.
		$tradition->collation->flatten_ranks();
	
		# And now that we've done that, calculate the common nodes.
		$tradition->collation->calculate_common_readings();
	
		# Save the text for each witness so that we can ensure consistency
		# later on
		$tradition->collation->text_from_paths();	
	}
}

sub _clean_sequence {
    my( $wit, $sequence, $keep_ac ) = @_;
    my @clean_sequence;
    foreach my $rdg ( @$sequence ) {
        if( $rdg =~ /^PH-(.*)$/ ) {
            # It is a placeholder.  Keep it only if we need it for a later
            # a.c. run.
            my $app_id = $1;
            if( $keep_ac && exists $app_ac->{$wit} &&
                exists $app_ac->{$wit}->{$app_id} ) {
				# print STDERR "Retaining empty placeholder for $app_id\n";
				push( @clean_sequence, $rdg );
            }
        } else {
            push( @clean_sequence, $rdg );
        }
    }
    return @clean_sequence;
}

sub _replace_sequence {
    my( $arr, $start, $end, @new ) = @_;
    my( $start_idx, $end_idx );
    foreach my $i ( 0 .. $#{$arr} ) {
    	# If $arr->[$i] is a placeholder, cope.
    	my $iid = ref( $arr->[$i] ) ? $arr->[$i]->id : $arr->[$i];
        $start_idx = $i if( $iid eq $start );
        if( $iid eq $end ) {
            $end_idx = $i;
            last;
        }
    }
    unless( $start_idx && $end_idx ) {
        warn "Could not find start and end";
        return;
    }
    my $length = $end_idx - $start_idx + 1;
    splice( @$arr, $start_idx, $length, @new );
}

sub _return_rdg {
    my( $rdg ) = @_;
    # If we were passed a reading name, return the name.  If we were
    # passed a reading object, return the object.
    my $wantobj = ref( $rdg ) eq 'Text::Tradition::Collation::Reading';
    my $real = $rdg;
    if( exists $substitutions->{ $wantobj ? $rdg->id : $rdg } ) {
        $real = $substitutions->{ $wantobj ? $rdg->id : $rdg };
        $real = $real->id unless $wantobj;
    }
    return $real;
}

## TODO test specific sorts of nodes of the parallel-seg XML.

## Recursive helper function to help us navigate through nested XML,
## picking out the text.  $tradition is the tradition, needed for
## making readings; $xn is the XML node currently being looked at,
## $in_var is a flag to say that we are inside a variant, $ac is a
## flag to say that we are inside an ante-correctionem reading, and
## @cur_wits is the list of witnesses to which this XML node applies.
## Returns the list of readings, if any, created on the run.

{
    my %active_wits;
    my $current_app;
    my $seen_apps;

    sub _get_readings {
        my( $tradition, $xn, $in_var, $ac, @cur_wits ) = @_;
        @cur_wits = grep { $active_wits{$_} } keys %active_wits unless $in_var;

        my @new_readings;
        if( $xn->nodeType == XML_TEXT_NODE ) {
            # Some words, thus make some readings.
            my $str = $xn->data;
            return unless $str =~ /\S/; # skip whitespace-only text nodes
            #print STDERR "Handling text node " . $str . "\n";
            # Check that all the witnesses we have are active.
            foreach my $c ( @cur_wits ) {
                warn "$c is not among active wits" unless $active_wits{$c};
            }
            $str =~ s/^\s+//;
            my $final = $str =~ s/\s+$//;
            foreach my $w ( split( /\s+/, $str ) ) {
                # For now, skip punctuation.
                next if $w !~ /[[:alnum:]]/;
                my $rdg = _make_reading( $tradition->collation, $w );
                push( @new_readings, $rdg );
                foreach ( @cur_wits ) {
                    warn "Empty wit!" unless $_;
                    warn "Empty reading!" unless $rdg;
                    push( @{$text->{$_}}, $rdg ) unless $ac;
                }
            }
        } elsif( $xn->nodeName eq 'w' ) {
            # Everything in this tag is one word.  Also save any original XML ID.
            #print STDERR "Handling word " . $xn->toString . "\n";
            # Check that all the witnesses we have are active.
            foreach my $c ( @cur_wits ) {
                warn "$c is not among active wits" unless $active_wits{$c};
            }
            my $xml_id = $xn->getAttribute( 'xml:id' );
            my $rdg = _make_reading( $tradition->collation, $xn->textContent, $xml_id );
            push( @new_readings, $rdg );
            foreach( @cur_wits ) {
                warn "Empty wit!" unless $_;
                warn "Empty reading!" unless $rdg;
                push( @{$text->{$_}}, $rdg ) unless $ac;
            }
        } elsif ( $xn->nodeName eq 'app' ) {
            $seen_apps++;
            $current_app = $xn->getAttribute( 'xml:id' );
            # print STDERR "Handling app $current_app\n";
            # Keep the reading sets in this app.
            my @sets;
            # Recurse through all children (i.e. rdgs) for sets of words.
            foreach ( $xn->childNodes ) {
                my @rdg_set = _get_readings( $tradition, $_, $in_var, $ac, @cur_wits );
                push( @sets, \@rdg_set ) if @rdg_set;
            }
            # Now collate these sets if we have more than one.
            my $subs = collate_variants( $tradition->collation, @sets ) if @sets > 1;
            map { $substitutions->{$_} = $subs->{$_} } keys %$subs;
            # Return the entire set of unique readings.
            my %unique;
            foreach my $s ( @sets ) {
                map { $unique{$_->id} = $_ } @$s;
            }
            push( @new_readings, values( %unique ) );
            # Exit the current app.
            $current_app = '';
        } elsif ( $xn->nodeName eq 'lem' || $xn->nodeName eq 'rdg' ) {
            # Alter the current witnesses and recurse.
            #print STDERR "Handling reading for " . $xn->getAttribute( 'wit' ) . "\n";
            # TODO handle p.c. and s.l. designations too
            $ac = $xn->getAttribute( 'type' ) && $xn->getAttribute( 'type' ) eq 'a.c.';
            my @rdg_wits = _get_sigla( $xn );
            return unless @rdg_wits;  # Skip readings that appear in no witnesses
            my @words;
            foreach ( $xn->childNodes ) {
                my @rdg_set = _get_readings( $tradition, $_, 1, $ac, @rdg_wits );
                if( $xn->nodeName eq 'lem' ) {
                	map { $_->make_lemma(1) } @rdg_set;
                }
                push( @words, @rdg_set ) if @rdg_set;
            }
            # If we have more than one word in a reading, it should become a segment.
            # $tradition->collation->add_segment( @words ) if @words > 1;
            
            if( $ac ) {
                # Add the reading set to the a.c. readings.
                foreach ( @rdg_wits ) {
                    $app_ac->{$_}->{$current_app} = \@words;
                }
            } else {
                # Add the reading set to the app anchors for each witness
                # or put in placeholders for empty p.c. readings
                foreach ( @rdg_wits ) {
                    my $start = @words ? $words[0]->id : "PH-$current_app";
                    my $end = @words ? $words[-1]->id : "PH-$current_app";
                    $app_anchors->{$current_app}->{$_}->{'start'} = $start;
                    $app_anchors->{$current_app}->{$_}->{'end'} = $end;
                    push( @{$text->{$_}}, $start ) unless @words;
                }
            }
            push( @new_readings, @words );
        } elsif( $xn->nodeName eq 'witStart' ) {
            # Add the relevant wit(s) to the active list.
            #print STDERR "Handling witStart\n";
            map { $active_wits{$_} = 1 } @cur_wits;
            # Record a lacuna in all non-active witnesses if this is
            # the first app. Get the full list from $text.
            if( $seen_apps == 1 ) {
                my $i = 0;
                foreach my $sig ( keys %$text ) {
                    next if $active_wits{$sig};
                    my $l = $tradition->collation->add_reading( {
                    	'id' => $current_app . "_$i",
                    	'is_lacuna' => 1 } );
                    $i++;
                    push( @{$text->{$sig}}, $l );
                }
            }
        } elsif( $xn->nodeName eq 'witEnd' ) {
            # Take the relevant wit(s) out of the list.
            #print STDERR "Handling witEnd\n";
            map { $active_wits{$_} = undef } @cur_wits;
            # Record a lacuna, unless this is the last app.
            unless( $seen_apps == $app_count ) {
                foreach my $i ( 0 .. $#cur_wits ) {
                    my $w = $cur_wits[$i];
                    my $l = $tradition->collation->add_reading( {
                    	'id' => $current_app . "_$i",
                    	'is_lacuna' => 1 } );
                    push( @{$text->{$w}}, $l );
                }
            }
        } elsif( $xn->nodeName eq 'witDetail' 
        		 || $xn->nodeName eq 'note' ) {
            # Ignore these for now.
            return;
        } else {
            # Recurse as if this tag weren't there.
            #print STDERR "Recursing on tag " . $xn->nodeName . "\n";
            foreach( $xn->childNodes ) {
                push( @new_readings, _get_readings( $tradition, $_, $in_var, $ac, @cur_wits ) );
            }
        }
        return @new_readings;
    }

}

=begin testing

use XML::LibXML;
use XML::LibXML::XPathContext;
use Text::Tradition::Parser::TEI;

my $xml_str = '<tei><rdg wit="#A #B #C #D">some text</rdg></tei>';
my $el = XML::LibXML->new()->parse_string( $xml_str )->documentElement;
my $xpc = XML::LibXML::XPathContext->new( $el );
my $obj = $xpc->find( '//rdg' );

my @wits = Text::Tradition::Parser::TEI::_get_sigla( $obj );
is( join( ' ', @wits) , "A B C D", "correctly parsed reading wit string" );

=end testing

=cut

# Helper to extract a list of witness sigla from a reading element.
sub _get_sigla {
    my( $rdg ) = @_;
    # Cope if we have been handed a NodeList.  There is only
    # one reading here.
    if( ref( $rdg ) eq 'XML::LibXML::NodeList' ) {
        $rdg = $rdg->shift;
    }

    my @wits;
    if( ref( $rdg ) eq 'XML::LibXML::Element' ) {
        my $witstr = $rdg->getAttribute( 'wit' );
        return () unless $witstr;
        $witstr =~ s/^\s+//;
        $witstr =~ s/\s+$//;
        @wits = split( /\s+/, $witstr );
        map { $_ =~ s/^\#// } @wits;
    }
    return @wits;
}

# Helper with its counters to actually make the readings.
{
    my $word_ctr = 0;
    my %used_nodeids;

    sub _save_preexisting_nodeids {
        foreach( @_ ) {
            $used_nodeids{$_->getValue()} = 1;
        }
    }

    sub _make_reading {
        my( $graph, $word, $xml_id ) = @_;
        if( $xml_id ) {
            if( exists $used_nodeids{$xml_id} ) {
                if( $used_nodeids{$xml_id} != 1 ) {
                    warn "Already used assigned XML ID somewhere else!";
                    $xml_id = undef;
                }
            } else {
                warn "Undetected pre-existing XML ID";
            }
        }
        if( !$xml_id ) {
            until( $xml_id ) {
                my $try_id = 'w'.$word_ctr++;
                next if exists $used_nodeids{$try_id};
                $xml_id = $try_id;
            }
        }
        my $rdg = $graph->add_reading(
        	{ 'id' => $xml_id,
        	  'text' => $word }
        	);
        $used_nodeids{$xml_id} = $rdg;
        return $rdg;
    }
}

1;

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Parser::TEI error',
		'message' => $_[0],
		);
}

=head1 BUGS / TODO

=over

=item * More unit testing

=item * Handle special designations apart from a.c.

=item * Mark common nodes within collated variants

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
