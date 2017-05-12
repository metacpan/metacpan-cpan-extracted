package Text::Tradition::Parser::CollateX;

use strict;
use warnings;
use Text::Tradition::Parser::GraphML qw/ graphml_parse /;
use TryCatch;

=head1 NAME

Text::Tradition::Parser::CollateX

=head1 SYNOPSIS

  use Text::Tradition;
  
  my $t_from_file = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'CollateX',
    'file' => '/path/to/collation.xml'
    );
    
  my $t_from_string = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'CollateX',
    'string' => $collation_xml,
    );

=head1 DESCRIPTION

Parser module for Text::Tradition, given a GraphML file from the
CollateX program that describes a collation graph.  For further
information on the GraphML format for text collation, see
http://gregor.middell.net/collatex/

=head1 METHODS

=head2 B<parse>

parse( $tradition, $init_options );

Takes an initialized Text::Tradition object and a set of options; creates
the appropriate nodes and edges on the graph.  The options hash should
include either a 'file' argument or a 'string' argument, depending on the
source of the XML to be parsed.

=begin testing

use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

# Test a simple CollateX input
my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );

is( ref( $t ), 'Text::Tradition', "Parsed a CollateX input" );
if( $t ) {
    is( scalar $t->collation->readings, 26, "Collation has all readings" );
    is( scalar $t->collation->paths, 32, "Collation has all paths" );
    is( scalar $t->witnesses, 3, "Collation has all witnesses" );
    
    # Check an 'identical' node
    my $transposed = $t->collation->reading( 'n15' );
    my @related = $transposed->related_readings;
    is( scalar @related, 1, "Reading links to transposed version" );
    is( $related[0]->id, 'n18', "Correct transposition link" );
}

# Now test a CollateX result with a.c. witnesses

my $ct = Text::Tradition->new( 
	name => 'florilegium',
	input => 'CollateX',
	file => 't/data/florilegium_cx.xml' );

is( ref( $ct ), 'Text::Tradition', "Parsed the CollateX input" );
if( $ct ) {
    is( scalar $ct->collation->readings, 309, "Collation has all readings" );
    is( scalar $ct->collation->paths, 361, "Collation has all paths" );
    is( scalar $ct->witnesses, 13, "Collation has correct number of witnesses" );
    
    my %layered = ( E => 1, P => 1, Q => 1, T => 1 );
    foreach my $w ( $ct->witnesses ) {
    	is( $w->is_layered, $layered{$w->sigil}, 
    		"Witness " . $w->sigil . " has correct layered setting" );
    }
    
    my $pseq = $ct->witness('P')->text;
    my $pseqac = $ct->witness('P')->layertext;
    is( scalar @$pseq, 264, "Witness P has correct number of tokens" );
    is( scalar @$pseqac, 261, "Witness P (a.c.) has correct number of tokens" );
}
    

=end testing

=cut

my $IDKEY = 'number';
my $CONTENTKEY = 'tokens';
my $EDGETYPEKEY = 'type';
my $WITKEY = 'witnesses';

sub parse {
    my( $tradition, $opts ) = @_;
    my( $graph_data ) = graphml_parse( $opts );
    my $collation = $tradition->collation;

	# First add the readings to the graph.
	## Assume the start node has no text and id 0, and the end node has
	## no text and ID [number of nodes] - 1.
    my $endnode = scalar @{$graph_data->{'nodes'}} - 1;
    foreach my $n ( @{$graph_data->{'nodes'}} ) {
        unless( defined $n->{$IDKEY} && defined $n->{$CONTENTKEY} ) {
        	if( defined $n->{$IDKEY} && $n->{$IDKEY} == 0 ) {
        		# It's the start node.
        		$n->{$IDKEY} = $collation->start->id;
        	} elsif ( defined $n->{$IDKEY} && $n->{$IDKEY} == $endnode ) {
        		# It's the end node.
        		$n->{$IDKEY} = $collation->end->id;
        	} else {
        		# Something is probably wrong.
				warn "Did not find an ID or token for graph node, can't add it";
        	} 
            next;
        }
        # Node ID should be an XML name, so prepend an 'n' if necessary.
        if( $n->{$IDKEY} =~ /^\d/ ) {
			$n->{$IDKEY} = 'n' . $n->{$IDKEY};
		}
		# Create the reading.
        my $gnode_args = { 
        	'id' => $n->{$IDKEY},
        	'text' => $n->{$CONTENTKEY},
        };
        my $gnode = $collation->add_reading( $gnode_args );
    }
        
    # Now add the path edges.
    my %transpositions;
    foreach my $e ( @{$graph_data->{'edges'}} ) {
        my $from = $e->{'source'};
        my $to = $e->{'target'};
        
        ## Edge data keys are ID (which we don't need), witnesses, and type.
        ## Type can be 'path' or 'relationship'; 
        ## witnesses is a comma-separated list.
		if( $e->{$EDGETYPEKEY} eq 'path' ) {
			## Add the path for each witness listesd.
            # Create the witness objects if they does not yet exist.
            foreach my $wit ( split( /, /, $e->{$WITKEY} ) ) {
            	my $sigil = _base_sigil( $collation, $wit ) || $wit;
            	my $wit_object = $tradition->witness( $sigil );
				unless( $wit_object ) {
					$wit_object = $tradition->add_witness( 
						sigil => $sigil, 
						sourcetype => 'collation' );
				}
				$wit_object->is_collated(1);
				if( $wit ne $sigil ) {
					$wit_object->is_layered(1);
				}
				$collation->add_path( $from->{$IDKEY}, $to->{$IDKEY}, $wit );
			}
        } else { # CollateX-marked transpositions
			# Save the transposition links so that we can apply them 
			# once they are all collected.
			$transpositions{ $from->{$IDKEY} } = $to->{$IDKEY};
        }
    }
    
    # Mark initialization as done so that relationship validation turns on
    $tradition->_init_done( 1 );
    # Now apply transpositions as appropriate.
    if( $collation->linear ) {
    	# Sort the transpositions by reading length, then try first to merge them
    	# and then to transpose them. Warn if the text isn't identical.
    	foreach my $k ( sort { 
				my $t1 = $collation->reading( $a )->text;
				my $t2 = $collation->reading( $b )->text;
				return length( $t2 ) <=> length( $t1 );
    		} keys %transpositions ) {
    		my $v = $transpositions{$k};
    		my $merged;
			try {
				$collation->add_relationship( $k, $v, { type => 'collated' } );
				$merged = 1;
			} catch ( Text::Tradition::Error $e ) {
				1;
			}
    		unless( $merged ) {
    			my $transpopts = { type => 'transposition' };
    			unless( $collation->reading( $k )->text eq $collation->reading( $v )->text ) {
    				$transpopts->{annotation} = 'CollateX fuzzy match';
    			}
				try {
					$collation->add_relationship( $k, $v, $transpopts );
				} catch ( Text::Tradition::Error $e ) {
					warn "Could neither merge nor transpose $k and $v; DROPPING transposition";
				}
	    	}		
    	}
    
    	# Rank the readings and find the commonalities
    	unless( $opts->{'nocalc'} ) {
			$collation->calculate_ranks();
			$collation->flatten_ranks();
			$collation->calculate_common_readings();
		}
    } else {
    	my %merged;
    	foreach my $k ( keys %transpositions ) {
    		my $v = $transpositions{$k};
    		$k = $merged{$k} if exists $merged{$k};
    		$v = $merged{$v} if exists $merged{$v};
    		next if $k eq $v;
    		if( $collation->reading( $k )->text eq $collation->reading( $v )->text ) {
    			$collation->merge_readings( $k, $v );
    			$merged{$v} = $k;
    		} else {
    			warn "DROPPING transposition link for non-identical readings $k and $v";
    		}
    	}
    }

    # Save the text for each witness so that we can ensure consistency
    # later on
	$tradition->collation->text_from_paths();	
}

sub _base_sigil {
	my( $collation, $sigil ) = @_;
	my $acstr = $collation->ac_label;
	if( $sigil =~ /^(.*)\Q$acstr\E$/ ) {
		return $1;
	}
	return undef;
}
	
    
=head1 BUGS / TODO

=over

=item * Make this into a stream parser with GraphML

=item * Use CollateX-calculated ranks instead of recalculating our own

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews, aurum@cpan.org

=cut

1;
