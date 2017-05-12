package Text::Tradition::Parser::GraphML;

use strict;
use warnings;
use Exporter 'import';
use vars qw/ @EXPORT_OK $xpc /;
use Text::Tradition::Error;
use XML::LibXML;
use XML::LibXML::XPathContext;

@EXPORT_OK = qw/ graphml_parse /;

=head1 NAME

Text::Tradition::Parser::GraphML

=head1 DESCRIPTION

Parser module for Text::Tradition, given a GraphML file that describes
a collation graph.  Returns the information about the graph that has
been parsed out from the GraphML.  This module is meant to be used
with a module (e.g. CollateX or Self) that interprets the specific
GraphML conventions of the source program.

=head1 METHODS

=head2 B<graphml_parse>( $init_opts )

parse( $init_opts );

Takes a set of Tradition initialization options, among which should be either
'file' or 'string'; parses that file or string and returns a list of nodes, edges,
and their associated data.

=cut

# Return graph -> nodeid -> { key1/val1, key2/val2, key3/val3 ... }
#              -> edgeid -> { source, target, wit1/val1, wit2/val2 ...}

sub graphml_parse {
    my( $opts ) = @_;

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
    
    my( $graphattr, $nodedata, $edgedata ) = ( {}, {}, {} );
    my $graphml = $doc->documentElement();
    $xpc = XML::LibXML::XPathContext->new( $graphml );
    $xpc->registerNs( 'g', 'http://graphml.graphdrawing.org/xmlns' );
    
    # First get the ID keys, for node/edge data and for collation data
    foreach my $k ( $xpc->findnodes( '//g:key' ) ) {
        # Each key has a 'for' attribute to say whether it is for graph,
        # node, or edge.
        my $keyid = $k->getAttribute( 'id' );
        my $keyname = $k->getAttribute( 'attr.name' );

		# Keep track of the XML identifiers for the data carried
		# in each node element.
		my $dtype = $k->getAttribute( 'for' );
		if( $dtype eq 'graph' ) {
			$graphattr->{$keyid} = $keyname;
        } elsif( $dtype eq 'node' ) {
            $nodedata->{$keyid} = $keyname;
        } else {
            $edgedata->{$keyid} = $keyname;
        }
    }
    
    my @graph_elements = $xpc->findnodes( '/g:graphml/g:graph' );
	unless( @graph_elements ) {
		throw( "No graph elements found in graph XML - is this really GraphML?" );
	}

    my @returned_graphs;
    foreach my $graph_el ( @graph_elements ) {
        my $graph_hash = { 'nodes' => [],
						   'edges' => [],
						   'name'  => $graph_el->getAttribute( 'id' ) };
                       	
		my $node_reg = {};
		
		# Read in graph globals (if any).
		# print STDERR "Reading graphml global data\n";
		foreach my $dkey ( keys %$graphattr ) {
			my $keyname = $graphattr->{$dkey};
			my $keyvalue = _lookup_node_data( $graph_el, $dkey );
			$graph_hash->{'global'}->{$keyname} = $keyvalue if defined $keyvalue;
		}
	
		# Add the nodes to the graph hash.
		# print STDERR "Reading graphml nodes\n"; 
		my @nodes = $xpc->findnodes( './/g:node', $graph_el );
		foreach my $n ( @nodes ) {
			# Could use a better way of registering these
			my $node_hash = {};
			foreach my $dkey ( keys %$nodedata ) {
				my $keyname = $nodedata->{$dkey};
				my $keyvalue = _lookup_node_data( $n, $dkey );
				$node_hash->{$keyname} = $keyvalue if defined $keyvalue;
			}
			$node_reg->{$n->getAttribute( 'id' )} = $node_hash;
			push( @{$graph_hash->{'nodes'}}, $node_hash );
		}
			
		# Now add the edges, and cross-ref with the node objects.
		# print STDERR "Reading graphml edges\n";
		my @edges = $xpc->findnodes( './/g:edge', $graph_el );
		foreach my $e ( @edges ) {
			my $from = $e->getAttribute('source');
			my $to = $e->getAttribute('target');
	
			# We don't know whether the edge data is one per witness
			# or one per witness type, or something else.  So we just
			# save it and let our calling parser decide.
			my $edge_hash = {
				'source' => $node_reg->{$from},
				'target' => $node_reg->{$to},
			};
			foreach my $wkey( keys %$edgedata ) {
				my $wname = $edgedata->{$wkey};
				my $wlabel = _lookup_node_data( $e, $wkey );
				$edge_hash->{$wname} = $wlabel if $wlabel;
			}
			push( @{$graph_hash->{'edges'}}, $edge_hash );
		}
    	push( @returned_graphs, $graph_hash );
    }
    return @returned_graphs;
}


sub _lookup_node_data {
    my( $xmlnode, $key ) = @_;
    my $lookup_xpath = './g:data[@key="%s"]/child::text()';
    my $data = $xpc->find( sprintf( $lookup_xpath, $key ), $xmlnode );
    # If we get back an empty nodelist, we return undef.
    if( ref( $data ) ) {
    	return undef unless $data->size;
    	return $data->to_literal->value;
    }
    # Otherwise we got back a value. Return it.
    return $data;
}
    
sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Parser::GraphML error',
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
