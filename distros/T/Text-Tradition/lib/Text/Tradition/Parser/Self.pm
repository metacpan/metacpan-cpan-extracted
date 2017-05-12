package Text::Tradition::Parser::Self;

use strict;
use warnings;
use Text::Tradition::Parser::GraphML qw/ graphml_parse /;
use TryCatch;

=head1 NAME

Text::Tradition::Parser::GraphML

=head1 SYNOPSIS

  use Text::Tradition;
  
  my $t_from_file = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'Self',
    'file' => '/path/to/tradition.xml'
    );
    
  my $t_from_string = Text::Tradition->new( 
    'name' => 'my text',
    'input' => 'Self',
    'string' => $tradition_xml,
    );

=head1 DESCRIPTION

Parser module for Text::Tradition to read in its own GraphML output format.
GraphML is a relatively simple graph description language; a 'graph' element
can have 'node' and 'edge' elements, and each of these can have simple 'data'
elements for attributes to be saved.

The graph itself has attributes as in the Collation object:

=over

=item * linear 

=item * ac_label

=item * baselabel

=item * wit_list_separator

=back

The node objects have the following attributes:

=over

=item * name

=item * reading

=item * identical

=item * rank

=item * class

=back

The edge objects have the following attributes:

=over

=item * class

=item * witness (for 'path' class edges)

=item * extra   (for 'path' class edges)

=item * relationship    (for 'relationship' class edges)

=item * equal_rank      (for 'relationship' class edges)

=item * non_correctable (for 'relationship' class edges)

=item * non_independent (for 'relationship' class edges)

=back

=head1 METHODS

=head2 B<parse>

parse( $graph, $opts );

Takes an initialized Text::Tradition object and a set of options; creates
the appropriate nodes and edges on the graph.  The options hash should
include either a 'file' argument or a 'string' argument, depending on the
source of the XML to be parsed.

=begin testing

use Safe::Isa;
use Test::Warn;
use Text::Tradition;
use TryCatch;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $tradition = 't/data/florilegium_graphml.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Self',
    'file'  => $tradition,
    );

ok( $t->$_isa('Text::Tradition'), "Parsed GraphML version 2" );
if( $t ) {
    is( scalar $t->collation->readings, 319, "Collation has all readings" );
    is( scalar $t->collation->paths, 376, "Collation has all paths" );
    is( scalar $t->witnesses, 13, "Collation has all witnesses" );
}

# TODO add a relationship, add a stemma, write graphml, reparse it, check that 
# the new data is there
my $language_enabled = $t->can('language');
if( $language_enabled ) {
	$t->language('Greek');
}
my $stemma_enabled = $t->can('add_stemma');
if( $stemma_enabled ) {
	$t->add_stemma( 'dotfile' => 't/data/florilegium.dot' );
}
$t->collation->add_relationship( 'w12', 'w13', 
	{ 'type' => 'grammatical', 'scope' => 'global', 
	  'annotation' => 'This is some note' } );
ok( $t->collation->get_relationship( 'w12', 'w13' ), "Relationship set" );
my $graphml_str = $t->collation->as_graphml;

my $newt = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str );
ok( $newt->$_isa('Text::Tradition'), "Parsed current GraphML version" );
if( $newt ) {
    is( scalar $newt->collation->readings, 319, "Collation has all readings" );
    is( scalar $newt->collation->paths, 376, "Collation has all paths" );
    is( scalar $newt->witnesses, 13, "Collation has all witnesses" );
    is( scalar $newt->collation->relationships, 1, "Collation has added relationship" );
    if( $language_enabled ) {
	    is( $newt->language, 'Greek', "Tradition has correct language setting" );
	}
    my $rel = $newt->collation->get_relationship( 'w12', 'w13' );
    ok( $rel, "Found set relationship" );
    is( $rel->annotation, 'This is some note', "Relationship has its properties" );
    if( $stemma_enabled ) {
	    is( scalar $newt->stemmata, 1, "Tradition has its stemma" );
    	is( $newt->stemma(0)->witnesses, $t->stemma(0)->witnesses, "Stemma has correct length witness list" );
    }
}

# Test warning if we can
unless( $stemma_enabled ) {
	my $nst;
	warnings_exist {
		$nst = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/lexformat.xml' );
	} [qr/DROPPING stemmata/],
		"Got expected stemma drop warning on parse";
} else {
	# Test parse of existing Stemweb job id
	$t->set_stemweb_jobid( '1234' );
	$graphml_str = $t->collation->as_graphml;
	try {
		$newt = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str );
		is( $newt->stemweb_jobid, '1234', "Stemweb job ID was reparsed" );
	} catch {
		ok( 0, "Existing stemweb job ID causes parser to explode" );
	}
}


=end testing

=cut
use Data::Dump;
sub parse {
    my( $tradition, $opts ) = @_;
    
    # Collation data is in the first graph; relationship-specific stuff 
    # is in the second.
    my( $graph_data, $rel_data ) = graphml_parse( $opts );

    my $collation = $tradition->collation;
    my $tmeta = $tradition->meta;
    my $cmeta = $collation->meta;

    my %witnesses;
    
    # print STDERR "Setting graph globals\n";
    $tradition->name( $graph_data->{'name'} );
    my $use_version;
    foreach my $gkey ( keys %{$graph_data->{'global'}} ) {
		my $val = $graph_data->{'global'}->{$gkey};
		if( $gkey eq 'version' ) {
			$use_version = $val;
		} elsif( $gkey eq 'stemmata' ) {
			# Make sure we can handle stemmata
			# Parse the stemmata into objects
			if( $tradition->can('add_stemma') ) {
				foreach my $dotstr ( split( /\n/, $val ) ) {
					$tradition->add_stemma( 'dot' => $dotstr );
				}
			} else {
				warn "Analysis module not installed; DROPPING stemmata";
			}
		} elsif( $gkey eq 'user' ) {
			# Assign the tradition to the user if we can
			if( exists $opts->{'userstore'} ) {
				my $userdir = delete $opts->{'userstore'};
				my $user = $userdir->find_user( { username => $val } );
				if( $user ) {
					$user->add_tradition( $tradition );
				} else {
					warn( "Found no user with ID $val; DROPPING user assignment" );
				}
			} else {
				warn( "DROPPING user assignment without a specified userstore" );
			}
		# Is this key an attribute of the tradition or collation?
		} elsif( $tmeta->has_attribute( $gkey ) ) {
			my $attr = $tmeta->get_attribute( $gkey );
			warn( "Nonexistent tradition attribute $gkey" ) unless $attr;
			my $method = $attr->get_write_method();
			$tradition->$method( $val );
		} elsif( $cmeta->has_attribute( $gkey ) ) {
			my $attr = $cmeta->find_attribute_by_name( $gkey );
			warn( "Nonexistent collation attribute $gkey" ) unless $attr;
			my $method = $attr->get_write_method();
			$collation->$method( $val );
		# Or is it an indirect attribute or other method?
		} elsif( $tradition->can( $gkey ) ) {
			$tradition->$gkey( $val );
		} elsif( $collation->can( $gkey ) ) {
			$collation->$gkey( $val );
		# Nope? Oh well.
		} else {
			warn( "DROPPING unsupported attribute $gkey" );
		}
	}
		
    # Add the nodes to the graph.
    # Note any reading IDs that were changed in order to comply with XML 
    # name restrictions; we have to hardcode start & end.
    my %namechange = ( '#START#' => '__START__', '#END#' => '__END__' );

    # print STDERR "Adding collation readings\n";
    foreach my $n ( @{$graph_data->{'nodes'}} ) {    	
    	# If it is the start or end node, we already have one, so
    	# grab the rank and go.
        if( defined $n->{'is_start'} ) {
			$collation->start->rank($n->{'rank'});
			next;
        }
    	if( defined $n->{'is_end'} ) {
    		$collation->end->rank( $n->{'rank'} );
    		next;
    	}
		my $gnode = $collation->add_reading( $n );
		if( $gnode->id ne $n->{'id'} ) {
			$namechange{$n->{'id'}} = $gnode->id;
		}
    }
        
    # Now add the edges.
    # print STDERR "Adding collation path edges\n";
    foreach my $e ( @{$graph_data->{'edges'}} ) {
    	my $sourceid = exists $namechange{$e->{'source'}->{'id'}}
    		? $namechange{$e->{'source'}->{'id'}} : $e->{'source'}->{'id'};
    	my $targetid = exists $namechange{$e->{'target'}->{'id'}}
    		? $namechange{$e->{'target'}->{'id'}} : $e->{'target'}->{'id'};
        my $from = $collation->reading( $sourceid );
        my $to = $collation->reading( $targetid );

		warn "No witness label on path edge!" unless $e->{'witness'};
		my $label = $e->{'witness'} . ( $e->{'extra'} ? $collation->ac_label : '' );
		$collation->add_path( $from, $to, $label );
		
		# Add the witness if we don't have it already.
		unless( $witnesses{$e->{'witness'}} ) {
			$tradition->add_witness( 
				sigil => $e->{'witness'}, 'sourcetype' => 'collation' );
			$witnesses{$e->{'witness'}} = 1;
		}
		$tradition->witness( $e->{'witness'} )->is_layered( 1 ) if $e->{'extra'};
    }
    
    ## Done with the main graph, now look at the relationships.
	# Nodes are added via the call to add_reading above.  We only need
	# add the relationships themselves.
	# TODO check that scoping does trt
	$tradition->_init_done( 1 ); # so that relationships get validated
	$rel_data->{'edges'} ||= []; # so that the next line doesn't break on no rels
	# Backward compatibility...
	if( $use_version eq '2.0' || $use_version eq '3.0' ) {
		foreach my $e ( @{$rel_data->{'edges'}} ) {
			delete $e->{'class'};
			$e->{'type'} = delete $e->{'relationship'} if exists $e->{'relationship'};
		}
	}

	my $rg = $collation->relations;
	foreach my $e ( sort { _apply_relationship_order( $a, $b, $rg ) } 
						 @{$rel_data->{'edges'}} ) {
    	my $sourceid = exists $namechange{$e->{'source'}->{'id'}}
    		? $namechange{$e->{'source'}->{'id'}} : $e->{'source'}->{'id'};
    	my $targetid = exists $namechange{$e->{'target'}->{'id'}}
    		? $namechange{$e->{'target'}->{'id'}} : $e->{'target'}->{'id'};
        my $from = $collation->reading( $sourceid );
        my $to = $collation->reading( $targetid );
		delete $e->{'source'};
		delete $e->{'target'};
		# The remaining keys are relationship attributes.
		# Add the specified relationship unless we already have done.
		my $rel_exists;
		if( $e->{'scope'} ne 'local' ) {
			my $relobj = $collation->get_relationship( $from, $to );
			if( $relobj && $relobj->scope eq $e->{'scope'}
				&& $relobj->type eq $e->{'type'} ) {
				$rel_exists = 1;
			} else {
				# Don't propagate the relationship; all the propagations are
				# already in the XML.
				$e->{'thispaironly'} = 1;
			}
		}
		try {
			$collation->add_relationship( $from, $to, $e ) unless $rel_exists;
		} catch( Text::Tradition::Error $err ) {
			warn "DROPPING " . $e->{type} . " rel on $from -> $to: " . $err->message;
		}
	}
	
    # Save the text for each witness so that we can ensure consistency
    # later on
	$collation->text_from_paths();	
}

# Helper sort function for applying the saved relationships in a
# sensible order.
sub _apply_relationship_order {
	my( $a, $b, $rg ) = @_;
	my $at = $rg->type( $a->{type} ); my $bt = $rg->type( $b->{type} );
	# Apply strong relationships before weak
	return -1 if $bt->is_weak && !$at->is_weak;
	return 1 if $at->is_weak && !$bt->is_weak;
	# Apply more tightly bound relationships first
	my $blcmp = $at->bindlevel <=> $bt->bindlevel;
	return $blcmp if $blcmp;
	# Apply local before global
	return -1 if $a->{scope} eq 'local' && $b->{scope} ne 'local';
	return 1 if $b->{scope} eq 'local' && $a->{scope} ne 'local';
}

1;

=head1 BUGS / TODO

=over

=item * Make this into a stream parser with GraphML

=back

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
