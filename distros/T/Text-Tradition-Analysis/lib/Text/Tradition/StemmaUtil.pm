package Text::Tradition::StemmaUtil;

use strict;
use warnings;
use Exporter 'import';
use vars qw/ @EXPORT_OK /;
use Bio::Phylo::IO;
use Encode qw( encode_utf8 decode_utf8 );
use File::chdir;
use File::Temp;
use File::Which;
use Graph;
use Graph::Reader::Dot;
use IPC::Run qw/ run binary /;
use Text::Tradition::Error;
@EXPORT_OK = qw/ read_graph display_graph editable_graph 
	character_input phylip_pars parse_newick newick_to_svg /;

=head1 NAME

Text::Tradition::StemmaUtil - standalone utilities for stemma graph display and
distance tree calculations

=head1 DESCRIPTION

This package contains a set of utilities for displaying arbitrary stemmata and 
running phylogenetic analysis on text collations.

=head1 SUBROUTINES

=head2 read_graph( $dotstr) {

Parses the graph specification on the filehandle in $dotstr and returns a Graph 
object. This subroutine works around some deficiencies in Graph::Reader::Dot.

=cut

sub read_graph {
	my $dotstr = shift;
	# Graph::Reader::Dot does not handle bare non-ASCII Unicode word characters.
	# We get around this by wrapping all words in double quotes, as long as they 
	# aren't already wrapped, and as long as they aren't the initial '(di)?graph'.
	# Also need to deal correctly with the graph title.
	if( $dotstr =~ /^\s*((di)?graph)\s+(.*?)\s*\{(.*)$/s ) {
		my( $decl, $ident, $rest ) = ( $1, $3, $4 );
		unless( substr( $ident, 0, 1 ) eq '"' ) {
			$ident = '"'.$ident.'"';
		}
		$rest =~ s/(?<!")\b(\w+)\b(?!")/"$1"/g;
		$dotstr = "$decl $ident { $rest";
	}
		
	# Now open a filehandle onto the string and pass it to Graph::Reader::Dot.
	$dotstr = encode_utf8( $dotstr );
	my $dotfh;
	open $dotfh, '<', \$dotstr;
	binmode $dotfh, ':utf8';
 	my $reader = Graph::Reader::Dot->new();
 	# Redirect STDOUT in order to trap any error messages - syntax errors
 	# are evidently not fatal.
	my $graph;
	my $reader_out;
	my $reader_err;
	{
		local(*STDOUT);
		open( STDOUT, ">", \$reader_out );
		local(*STDERR);
		open( STDERR, ">", \$reader_err );
		$graph = $reader->read_graph( $dotfh );
		close STDOUT;
		close STDERR;
	}
	if( $reader_out && $reader_out =~ /error/s ) {
		throw( "Error trying to parse dot: $reader_out" );
	} elsif( !$graph ) {
		throw( "Failed to create graph from dot" );
	}
	# Wrench the graph identifier out of the graph
	## HORRIBLE HACK but there is no API access to the graph identifier!
	$graph->set_graph_attribute( 'name', $graph->[4]->{'name'} );

	# Correct for implicit graph -> digraph quirk of reader
	if( $reader_err && $reader_err =~ /graph will be treated as digraph/ ) {
		my $udgraph = $graph->undirected_copy;
		$udgraph->set_graph_attributes( $graph->get_graph_attributes );
		foreach my $v ( $graph->vertices ) {
			$udgraph->set_vertex_attributes( $v, $graph->get_vertex_attributes( $v ) );
		}
		$graph = $udgraph;
	}
	
	return $graph;
}

=head2 display_graph( $graph, $opts )

Returns a dot specification intended for display, according to the logical 
attributes of the witnesses.

=cut

sub display_graph {
    my( $graph, $opts ) = @_;
    
    # Get default and specified options
    my %graphopts = (
    	# 'ratio' => 1,
    	'bgcolor' => 'transparent',
    );
    my %nodeopts = (
		'fontsize' => 11,
		'style' => 'filled',
		'fillcolor' => 'white',
		'color' => 'white',
		'shape' => 'ellipse',	# Shape for the extant nodes
	);
	my %edgeopts = (
		'arrowhead' => 'none',
	);
	@graphopts{ keys %{$opts->{'graph'}} } = values %{$opts->{'graph'}} 
		if $opts->{'graph'};
	@nodeopts{ keys %{$opts->{'node'}} } = values %{$opts->{'node'}} 
		if $opts->{'node'};
	@edgeopts{ keys %{$opts->{'edge'}} } = values %{$opts->{'edge'}} 
		if $opts->{'edge'};
		
	my $gdecl = $graph->is_directed ? 'digraph' : 'graph';
	my $gname = $opts->{'name'} ? '"' . $opts->{'name'} . '"'
		: 'stemma';
	my @dotlines;
	push( @dotlines, "$gdecl $gname {" );
	## Print out the global attributes
	push( @dotlines, _make_dotline( 'graph', %graphopts ) ) if keys %graphopts;
	push( @dotlines, _make_dotline( 'edge', %edgeopts ) ) if keys %edgeopts;
	push( @dotlines, _make_dotline( 'node', %nodeopts ) ) if keys %nodeopts;

	# Add each of the nodes.
    foreach my $n ( $graph->vertices ) {
    	my %vattr = ( 'id' => $n );  # Set the SVG element ID to the sigil itself
        if( $graph->has_vertex_attribute( $n, 'label' ) ) {
        	$vattr{'label'} = $graph->get_vertex_attribute( $n, 'label' );
        }
		push( @dotlines, _make_dotline( $n, %vattr ) );
    }
    # Add each of our edges.
    foreach my $e ( $graph->edges ) {
    	my( $from, $to ) = map { _dotquote( $_ ) } @$e;
    	my $connector = $graph->is_directed ? '->' : '--';
    	push( @dotlines, "  $from $connector $to;" );
    }
    push( @dotlines, '}' );
    
    return join( "\n", @dotlines );
}


=head2 editable_graph( $graph, $opts )

Returns a dot specification of a stemma graph with logical witness features,
intended for editing the stemma definition.

=cut

sub editable_graph {
	my( $graph, $opts ) = @_;

	# Create the graph
	my $join = ( $opts && exists $opts->{'linesep'} ) ? $opts->{'linesep'} : "\n";
	my $gdecl = $graph->is_undirected ? 'graph' : 'digraph';
	my $gname = exists $opts->{'name'} ? '"' . $opts->{'name'} . '"'
		: 'stemma';
	my @dotlines;
	push( @dotlines, "$gdecl $gname {" );
	my @real; # A cheap sort
    foreach my $n ( sort $graph->vertices ) {
    	my $c = $graph->get_vertex_attribute( $n, 'class' );
    	$c = 'extant' unless $c;
    	if( $c eq 'extant' ) {
    		push( @real, $n );
    	} else {
			push( @dotlines, _make_dotline( $n, 'class' => $c ) );
		}
    }
	# Now do the real ones
	foreach my $n ( @real ) {
		push( @dotlines, _make_dotline( $n, 'class' => 'extant' ) );
	}
	foreach my $e ( sort _by_vertex $graph->edges ) {
		my( $from, $to ) = map { _dotquote( $_ ) } @$e;
		my $conn = $graph->is_undirected ? '--' : '->';
		push( @dotlines, "  $from $conn $to;" );
	}
    push( @dotlines, '}' );
    return join( $join, @dotlines );
}

sub _make_dotline {
	my( $obj, %attr ) = @_;
	my @pairs;
	foreach my $k ( keys %attr ) {
		my $v = _dotquote( $attr{$k} );
		push( @pairs, "$k=$v" );
	}
	return sprintf( "  %s [ %s ];", _dotquote( $obj ), join( ', ', @pairs ) );
}
	
sub _dotquote {
	my( $str ) = @_;
	return $str if $str =~ /^[A-Za-z0-9_]+$/;
	$str =~ s/\"/\\\"/g;
	$str = '"' . $str . '"';
	return $str;
}

sub _by_vertex {
	return $a->[0].$a->[1] cmp $b->[0].$b->[1];
}

=head2 character_input( $tradition, $opts )

Returns a character matrix string suitable for Phylip programs, which 
corresponds to the given alignment table.  See Text::Tradition::Collation 
for a description of the alignment table format. Options include:

=over

=item * exclude_layer - Exclude layered witnesses from the character input, 
using only the 'main' text of the witnesses in the tradition.

=item * collapse - A reference to an array of relationship names that should
be treated as equivalent for the purposes of generating the character matrix.

=back

=cut

sub character_input {
    my ( $tradition, $opts ) = @_;
    my $table = $tradition->collation->alignment_table;
    if( $opts->{exclude_layer} ) {
    	# Filter out all alignment table rows that do not correspond
    	# to a named witness - these are the layered witnesses.
    	my $newtable = { alignment => [], length => $table->{length} };
    	foreach my $row ( @{$table->{alignment}} ) {
    		if( $tradition->has_witness( $row->{witness} ) ) {
    			push( @{$newtable->{alignment}}, $row );
    		}
    	}
    	$table = $newtable;
    }
    my $character_matrix = _make_character_matrix( $table, $opts );
    my $input = '';
    my $rows = scalar @{$character_matrix};
    my $columns = scalar @{$character_matrix->[0]} - 1;
    $input .= "\t$rows\t$columns\n";
    foreach my $row ( @{$character_matrix} ) {
        $input .= join( '', @$row ) . "\n";
    }
    return $input;
}

sub _make_character_matrix {
    my( $table, $opts ) = @_;
    # Push the names of the witnesses to initialize the rows of the matrix.
    my @matrix = map { [ _normalize_witname( $_->{'witness'} ) ] } 
    				@{$table->{'alignment'}};
    foreach my $token_index ( 0 .. $table->{'length'} - 1) {
        my @pos_tokens = map { $_->{'tokens'}->[$token_index] }
        						@{$table->{'alignment'}};
        my @pos_readings = map { $_ ? $_->{'t'} : $_ } @pos_tokens;
        my @chars = _convert_characters( \@pos_readings, $opts );
        foreach my $idx ( 0 .. $#matrix ) {
            push( @{$matrix[$idx]}, $chars[$idx] );
        }
    }
    return \@matrix;
} 

# Helper function to make the witness name something legal for pars

sub _normalize_witname {
    my( $witname ) = @_;
    $witname =~ s/\s+/ /g;
    $witname =~ s/[\[\]\(\)\:;,]//g;
    $witname = substr( $witname, 0, 10 );
    return sprintf( "%-10s", $witname );
}

sub _convert_characters {
    my( $row, $opts ) = @_;
    # This is a simple algorithm that treats every reading as different.
    # Eventually we will want to be able to specify how relationships
    # affect the character matrix.
    my %unique = ( '__UNDEF__' => 'X',
                   '#LACUNA#'  => '?',
                 );
    my %equivalent;
    my %count;
    my $ctr = 0;
    foreach my $rdg ( @$row ) {
    	next unless $rdg;
    	next if $rdg->is_lacuna;
		next if exists $unique{$rdg->text};
		if( ref( $opts->{'collapse'} ) eq 'ARRAY' ) {
			my @exclude_types = @{$opts->{'collapse'}};
			my @set = $rdg->related_readings( sub { my $rel = shift;
				$rel->colocated && grep { $rel->type eq $_ } @exclude_types } );
			push( @set, $rdg );
			my $char = chr( 65 + $ctr++ );
			map { $unique{$_->text} = $char } @set;
			$count{$rdg->text} += scalar @set;
		} else {
			$unique{$rdg->text} = chr( 65 + $ctr++ );
			$count{$rdg->text}++;			
		}
    }
    # Try to keep variants under 8 by lacunizing any singletons.
    if( scalar( keys %unique ) > 8 ) {
		foreach my $word ( keys %count ) {
			if( $count{$word} == 1 ) {
				$unique{$word} = '?';
			}
		}
    }
    my %u = reverse %unique;
    if( scalar( keys %u ) > 8 ) {
        warn "Have more than 8 variants on this location; phylip will break";
    }
    my @chars = map { $_ ? $unique{$_->text} : $unique{'__UNDEF__' } } @$row;
    return @chars;
}

=head2 phylip_pars( $character_matrix )

Runs Phylip Pars on the given character matrix.  Returns results in Newick format.

=cut

sub phylip_pars {
	my( $charmatrix, $opts ) = @_;
    # Set up a temporary directory for all the default Phylip files.
    my $phylip_dir = File::Temp->newdir();
    # $phylip_dir->unlink_on_destroy(0);
    # We need an infile, and we need a command input file.
    open( MATRIX, ">$phylip_dir/infile" ) or die "Could not write $phylip_dir/infile";
    print MATRIX $charmatrix;
    close MATRIX;

    open( CMD, ">$phylip_dir/cmdfile" ) or die "Could not write $phylip_dir/cmdfile";
    ## TODO any configuration parameters we want to set here
#   U                 Search for best tree?  Yes
#   S                        Search option?  More thorough search
#   V              Number of trees to save?  100
#   J     Randomize input order of species?  No. Use input order
#   O                        Outgroup root?  No, use as outgroup species 1
#   T              Use Threshold parsimony?  No, use ordinary parsimony
#   W                       Sites weighted?  No
#   M           Analyze multiple data sets?  No
#   I            Input species interleaved?  Yes
#   0   Terminal type (IBM PC, ANSI, none)?  ANSI
#   1    Print out the data at start of run  No
#   2  Print indications of progress of run  Yes
#   3                        Print out tree  Yes
#   4          Print out steps in each site  No
#   5  Print character at all nodes of tree  No
#   6       Write out trees onto tree file?  Yes
    print CMD "Y\n";
    close CMD;

    # And then we run the program.
    my $program = $opts->{parspath} || File::Which::which( 'pars' );
    unless( $program && -x $program ) {
		throw( "Phylip pars $program not executable" );
    }

    {
        # We need to run it in our temporary directory where we have created
        # all the expected files.
        local $CWD = $phylip_dir;
        my @cmd = ( $program );
        run \@cmd, '<', 'cmdfile', '>', '/dev/null';
    }
    # Now our output should be in 'outfile' and our tree in 'outtree',
    # both in the temp directory.

    my @outtree;
    if( -f "$phylip_dir/outtree" ) {
        open( TREE, "$phylip_dir/outtree" ) or die "Could not open outtree for read";
        @outtree = <TREE>;
        close TREE;
    }
    return join( '', @outtree ) if @outtree;

	# If we got this far, we are about to throw an error.
    my @error;
    if( -f "$phylip_dir/outfile" ) {
        open( OUTPUT, "$phylip_dir/outfile" ) or die "Could not open output for read";
        @error = <OUTPUT>;
        close OUTPUT;
    } else {
        push( @error, "Neither outtree nor output file was produced!" );
    }
    throw( join( '', @error ) );
}

=head2 parse_newick( $newick_string )

Parses the given Newick tree(s) into one or more Stemma objects with
undirected graphs.

=cut

sub parse_newick {
    my $newick = shift;
    # Parse the result into a set of trees and return them.
    my $forest = Bio::Phylo::IO->parse( 
        -format => 'newick',
        -string => $newick,
        );
    return map { _graph_from_bio( $_ ) } @{$forest->get_entities};
}

sub _graph_from_bio {
    my $tree = shift;
    my $graph = Graph->new( 'undirected' => 1 );
    # Give all the intermediate anonymous nodes a name.
    my $i = 0;
    my $classes = {};
    foreach my $n ( @{$tree->get_terminals} ) {
    	# The terminal nodes are our named witnesses.
		$classes->{$n->get_name} = 'extant';
	}
	foreach my $n ( @{$tree->get_internals} ) {
    	unless( defined $n->get_name && $n->get_name ne '' ) {
    		# Get an integer, make sure it's a unique name
    		while( exists $classes->{$i} ) {
    			$i++;
    		}
    		$n->set_name( $i++ );
    	}
    	$classes->{$n->get_name} = 'hypothetical';
    }
    _add_tree_children( $graph, $classes, undef, [ $tree->get_root ]);
    return $graph;
}

sub _add_tree_children {
    my( $graph, $classes, $parent, $tree_children ) = @_;
    foreach my $c ( @$tree_children ) {
        my $child = $c->get_name;
        $graph->add_vertex( $child );
        $graph->set_vertex_attribute( $child, 'class', $classes->{$child} );
        $graph->add_path( $parent, $child ) if defined $parent;
        _add_tree_children( $graph, $classes, $child, $c->get_children() );
    }
}

=head2 newick_to_svg( $newick_string )

Uses the FigTree utility (if installed) to transform the given Newick tree(s)
into a graph visualization.

=cut

sub newick_to_svg {
	my $newick = shift;
    my $program = File::Which::which( 'figtree' );
    unless( -x $program ) {
		throw( "FigTree commandline utility not found in path" );
    }
    my $svg;
    my $nfile = File::Temp->new();
    print $nfile $newick;
    close $nfile;
	my @cmd = ( $program, '-graphic', 'SVG', $nfile );
    run( \@cmd, ">", binary(), \$svg );
    return decode_utf8( $svg );
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'StemmaUtil error',
		'message' => $_[0],
		);
}

1;

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
