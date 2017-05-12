package Text::Tradition::Stemma;

use Encode qw( decode_utf8 );
use File::Temp;
use Graph;
use Graph::Reader::Dot;
use IPC::Run qw/ run binary /;
use Text::Tradition::Error;
use Text::Tradition::StemmaUtil qw/ read_graph editable_graph display_graph 
	parse_newick /;
use Moose;

=head1 NAME

Text::Tradition::Stemma - a representation of a I<stemma codicum> for a Text::Tradition

=head1 SYNOPSIS

  use Text::Tradition;
  my $t = Text::Tradition->new( 
    'name' => 'this is a text',
    'input' => 'TEI',
    'file' => '/path/to/tei_parallel_seg_file.xml' );

  my $s = $tradition->add_stemma( dotfile => '/path/to/stemma.dot' );
    
=head1 DESCRIPTION

Text::Tradition is a library for representation and analysis of collated
texts, particularly medieval ones.  The Stemma is a representation of the
copying relationships between the witnesses in a Tradition, modelled with
a connected rooted directed acyclic graph (CRDAG).

=head1 DOT SYNTAX

The easiest way to define a stemma is to use a special form of the 'dot' 
syntax of GraphViz.  

Each stemma opens with the line

 digraph "Name of Stemma" {
 
and continues with a list of all manuscript witnesses in the stemma, whether
extant witnesses or missing archetypes or hyparchetypes.  Each of these is
listed by its sigil on its own line, e.g.:

  alpha [ class=hypothetical ]
  1 [ class=hypothetical,label=* ]
  Ms4 [ class=extant ]
  
Extant witnesses are listed with class=extant; missing or postulated witnesses
are listed with class=hypothetical.  Anonymous hyparchetypes must be given a 
unique name or number, but can be represented as anonymous with the addition 
of 'label=*' to their lines.  Greek letters or other special characters may be
used as names, but they must always be wrapped in double quotes.

Links between manuscripts are then listed with arrow notation, as below. These 
lines show the direction of copying, one step at a time, for the entire stemma.

  alpha -> 1
  1 -> Ms4
  
The final line in the definition should be the closing brace:

 }
  
Thus for a set of extant manuscripts A, B, and C, where A and B were copied 
from the archetype O and C was copied from B, the definition would be:

 digraph "Test stemma 1" {
     O [ class=hypothetical]
     A [ class=extant ]
     B [ class=extant ]
     C [ class=extant ]
     O -> A
     O -> B
     B -> C
 }

=head1 CONSTRUCTOR

=head2 new

The constructor.  This should generally be called from Text::Tradition, but
if called directly it takes the following options:

=over

=item * dot - A filehandle open to a DOT representation of the stemma graph.

=item * graph - If no DOT specification is given, you can pass a Graph object
instead.  The vertices of the graph should have an attribute 'class' set to
either of the values 'extant' or 'hypothetical'.

=item * is_undirected - If the graph specification (or graph object) is for an
undirected graph (e.g. a phylogenetic tree), this should be set.

=back

=begin testing

use TryCatch;

use_ok( 'Text::Tradition::Stemma' );

# Try to create a bad graph
try {
	my $stemma = Text::Tradition::Stemma->new( dotfile => 't/data/besoin_bad.dot' );
	ok( 0, "Created broken stemma from dotfile with syntax error" );
} catch( Text::Tradition::Error $e ) {
	like( $e->message, qr/^Error trying to parse/, "Syntax error in dot threw exception" );
}

# Create a good graph
my $stemma = Text::Tradition::Stemma->new( dotfile => 't/data/florilegium.dot' );
is( ref( $stemma ), 'Text::Tradition::Stemma', "Created stemma from good dotfile" );
is( scalar $stemma->witnesses, 13, "Found correct number of extant witnesses" );
is( scalar $stemma->hypotheticals, 8, "Found correct number of extant hypotheticals" );
ok( $stemma->has_identifier, "Stemma identifier was found in dot" );
is( $stemma->identifier, 'Coislinianum lineage', "Correct stemma identifier was found in dot" );
my $found_unicode_sigil;
foreach my $h ( $stemma->hypotheticals ) {
	$found_unicode_sigil = 1 if $h eq "\x{3b1}";
}
ok( $found_unicode_sigil, "Found a correctly encoded Unicode sigil" );

# Create an undirected graph
my $udstemma = Text::Tradition::Stemma->new( dotfile => 't/data/besoin_undirected.dot' );
is( ref( $udstemma ), 'Text::Tradition::Stemma', "Created stemma from undirected dotfile" );
is( scalar $udstemma->witnesses, 13, "Found correct number of extant witnesses" );
is( scalar $udstemma->hypotheticals, 12, "Found correct number of hypotheticals" );
ok( $udstemma->is_undirected, "Stemma was recorded as undirected" );
is( $udstemma->identifier, "RHM stemma", "Undirected graph retained its name" );

=end testing

=cut

has collation => (
    is => 'ro',
    isa => 'Text::Tradition::Collation',
    clearer => 'clear_collation', # interim measure to remove refs in DB
    weak_ref => 1,
    );  

has graph => (
    is => 'rw',
    isa => 'Graph',
    predicate => 'has_graph',
    );
    
has identifier => (
	is => 'ro',
	isa => 'Str',
	writer => 'set_identifier',
	predicate => 'has_identifier',
	);
	
has from_jobid => (
	is => 'ro',
	isa => 'Str',
	predicate => 'came_from_jobid',
	writer => '_set_from_jobid',
	);
    
sub BUILD {
    my( $self, $args ) = @_;
    # If we have been handed a dotfile, initialize it into a graph.
    my $dotstring;
    if( exists $args->{'dot'} ) {
        $dotstring = $args->{'dot'};
    } elsif( exists $args->{'dotfile'} ) {
    	# Read the file into a string.
    	my @dotlines;
		open( DOTFH, $args->{'dotfile'} ) 
			or throw( "Could not read specified dot file " . $args->{'dotfile'} );
		binmode( DOTFH, ':encoding(UTF-8)' );
		@dotlines = <DOTFH>;
		close DOTFH;
    	$dotstring = join( '', @dotlines );
    }
    $self->_graph_from_dot( $dotstring ) if $dotstring;
}

before 'graph' => sub {
	my $self = shift;
	if( @_ ) {
		# Make sure all unclassed graph nodes are marked extant.
		my $g = $_[0];
		throw( "Cannot set graph to a non-Graph object" ) 
			unless $g->isa( 'Graph' );
		foreach my $v ( $g->vertices ) {
			unless( $g->has_vertex_attribute( $v, 'class' ) ) {
				$g->set_vertex_attribute( $v, 'class', 'extant' );
			}
		}
	}
};

sub _graph_from_dot {
	my( $self, $dotstring ) = @_;
	my $graph = read_graph( $dotstring );
	
	## HORRIBLE HACK but there is no API access to graph attributes!
	my $graph_id = $graph->has_graph_attribute( 'name' ) 
		? $graph->get_graph_attribute( 'name' ) : 'stemma';
	$self->graph( $graph );
	$self->set_identifier( $graph_id );
}

sub is_undirected {
	my( $self ) = @_;
	return undef unless $self->has_graph;
	return $self->graph->is_undirected;
}

=head2 new_from_newick( $newick_string )

A constructor that will read a Newick-format tree specification and return one
or more undirected Stemma objects. TODO test

=cut

sub new_from_newick {
	my( $class, $nstring ) = @_;
	my @stemmata;
	foreach my $tree ( parse_newick( $nstring ) ) {
        my $stemma = new( $class, graph => $tree );
        push( @stemmata, $stemma );
    }
    return \@stemmata;
}

=head2 rename_witnesses( \%namehash, $all_extant ) 

Take a hash of old -> new sigil mappings, and change the names of the witnesses.

=cut

sub rename_witnesses {
	my( $self, $names, $all_extant ) = @_;
	my $old = $self->graph;
	my $newdot = $self->editable;
	foreach my $k ( keys %$names ) {
		my $v = $names->{$k};
		$newdot =~ s/\b$k\b/$v/g;
	}
	$self->alter_graph( $newdot );
	if( $all_extant ) {
		foreach my $v ( values %$names ) {
			$self->graph->set_vertex_attribute( $v, 'class', 'extant' );
		}
		foreach my $v ( $self->graph->vertices ) {
			unless( $self->graph->has_vertex_attribute( $v, 'class' ) ) {
				$self->graph->set_vertex_attribute( $v, 'class', 'hypothetical' );
			}
		}
	} else {
		foreach my $n ( $old->vertices ) {
			my $v = $names->{$n};
			my $class = $old->get_vertex_attribute( $n, 'class' );
			$self->graph->set_vertex_attribute( $v, 'class', $class );
		}
	}
}

=head1 METHODS

=head2 as_dot( \%options )

Returns a normal dot representation of the stemma layout, suitable for rendering
with GraphViz.  Options include:

=over

=item * graph - A hashref of global graph options.

=item * node - A hashref of global node options.

=item * edge - A hashref of global edge options.

=back

See the GraphViz documentation for the list of available options.

=cut

sub as_dot {
    my( $self, $opts ) = @_;
    
	## See if we are including any a.c. witnesses in this graph.
	my $graph = $self->graph;
	if( exists $opts->{'layerwits'} ) {
		my $extant = {};
		map { $extant->{$_} = 1 } $self->witnesses;
		$graph = $self->situation_graph( $extant, $opts->{'layerwits'} );
	}
	if( $self->has_identifier ) {
		$opts->{'name'} = $self->identifier;
	}
	return display_graph( $graph, $opts );
}

=head2 alter_graph( $dotstring )

Alters the graph of this stemma according to the definition specified
in $dotstring.

=cut

sub alter_graph {
	my( $self, $dotstring ) = @_;
	$self->_graph_from_dot( $dotstring );
}

=head2 editable( $opts )

Returns a version of the graph rendered in our definition format.  The
output separates statements with a newline; set $opts->{'linesep'} to the 
empty string or to a space if the result is to be sent via JSON.

If a situational version of the stemma is required, the arguments for 
situation_graph should be passed via $opts->{'extant'} and $opts->{'layerwits'}.

=cut

sub editable {
	my( $self, $opts ) = @_;	
	my $graph = $self->graph;
	if( $self->has_identifier ) {
		$opts->{'name'} = $self->identifier;
	}
	## See if we need an editable version of a situational graph.
	if( exists $opts->{'layerwits'} || exists $opts->{'extant'} ) {
		my $extant = delete $opts->{'extant'} || {};
		my $layerwits = delete $opts->{'layerwits'} || [];
		$graph = $self->situation_graph( $extant, $layerwits );
	}
	return editable_graph( $graph, $opts );
}


=head2 situation_graph( $extant, $layered )

Returns a graph which is the original stemma graph with all witnesses not
in the %$extant hash marked as hypothetical, and witness layers added to
the graph according to the list in @$layered.  A layered (a.c.) witness is
added as a parent of its main version, and additionally shares all other
parents and children with that version.

=cut

sub situation_graph {
	my( $self, $extant, $layerwits, $layerlabel ) = @_;
	
	my $graph = $self->graph->copy;
	foreach my $vertex ( $graph->vertices ) {
		# Set as extant any vertex that is extant in the stemma AND 
		# exists in the $extant hash.
		my $class = 'hypothetical';
		$class = 'extant' if exists $extant->{$vertex} && $extant->{$vertex} &&
			$self->graph->get_vertex_attribute( $vertex, 'class' ) ne 'hypothetical';
		$graph->set_vertex_attribute( $vertex, 'class', $class );
	}
	
	# For each 'layered' witness in the layerwits array, add it to the graph
	# as an ancestor of the 'main' witness, and otherwise with the same parent/
	# child links as its main analogue.
	# TOOD Handle case where B is copied from A but corrected from C
	$layerlabel = ' (a.c.)' unless $layerlabel;
	foreach my $lw ( @$layerwits ) {
		# Add the layered witness and set it with the same attributes as
		# its 'main' analogue
		throw( "Cannot add a layer to a hypothetical witness $lw" )
			unless $graph->get_vertex_attribute( $lw, 'class' ) eq 'extant';
		my $lwac = $lw . $layerlabel;
		$graph->add_vertex( $lwac );
		$graph->set_vertex_attributes( $lwac,
			$graph->get_vertex_attributes( $lw ) );
			
		# Set it as ancestor to the main witness
		$graph->add_edge( $lwac, $lw );
		
		# Give it the same ancestors and descendants as the main witness has,
		# bearing in mind that those ancestors and descendants might also just
		# have had a layered witness defined.
		foreach my $v ( $graph->predecessors( $lw ) ) {
			next if $v eq $lwac; # Don't add a loop
			$graph->add_edge( $v, $lwac );
			$graph->add_edge( $v.$layerlabel, $lwac )
				if $graph->has_vertex( $v.$layerlabel );
		}
		foreach my $v ( $graph->successors( $lw ) ) {
			next if $v eq $lwac; # but this shouldn't occur
			$graph->add_edge( $lwac, $v );
			$graph->add_edge( $lwac, $v.$layerlabel )
				if $graph->has_vertex( $v.$layerlabel );
		}
	}
	return $graph;
}

=head2 as_svg

Returns an SVG representation of the graph, calling as_dot first.

=cut

sub as_svg {
    my( $self, $opts ) = @_;
    my $dot = $self->as_dot( $opts );
    my @cmd = ( '-Tsvg' );
    unshift( @cmd, $self->is_undirected ? 'neato' : 'dot' );
    my $svg;
    my $dotfile = File::Temp->new();
    binmode $dotfile, ':utf8';
    print $dotfile $dot;
    close $dotfile;
    push( @cmd, $dotfile->filename );
    run( \@cmd, ">", binary(), \$svg );
    return decode_utf8( $svg );
}

=head2 witnesses

Returns a list of the extant witnesses represented in the stemma.

=cut

sub witnesses {
    my $self = shift;
    my @wits = grep { $self->graph->get_vertex_attribute( $_, 'class' ) eq 'extant' }
        $self->graph->vertices;
    return @wits;
}

=head2 hypotheticals

Returns a list of the hypothetical witnesses represented in the stemma.

=cut

sub hypotheticals {
    my $self = shift;
    my @wits = grep 
    	{ $self->graph->get_vertex_attribute( $_, 'class' ) eq 'hypothetical' }
        $self->graph->vertices;
    return @wits;
}

=head2 root_graph( $root_vertex )

If the stemma graph is undirected, make it directed with $root_vertex at the root.
If it is directed, re-root it.

=cut

sub root_graph {
	my( $self, $rootvertex ) = @_;
	my $graph;
	my $ident = $self->identifier; # will have to restore this at the end
	if( $self->is_undirected ) {
		$graph = $self->graph;
	} else {
		# Make an undirected version of this graph.
		$graph = $self->graph->undirected_copy();
	}
	# First, ensure that the requested root is actually a vertex in the graph.
	unless( $graph->has_vertex( $rootvertex ) ) {
		throw( "Cannot orient graph $graph on nonexistent vertex $rootvertex" );
	}
	
	# Now make a directed version of the graph.
	my $rooted = Graph->new();
	$rooted->add_vertex( $rootvertex );
	my @next = ( $rootvertex );
	while( @next ) {
		my @children;
		foreach my $v ( @next ) {
			# Place its not-placed neighbors (ergo children) in the tree
			# and connect them
			foreach my $n ( grep { !$rooted->has_vertex( $_ ) } 
				$graph->neighbors( $v ) ) {
				$rooted->add_vertex( $n );
				$rooted->add_edge( $v, $n );
				push( @children, $n );
			}
		}
		@next = @children;
	}
	# Set the vertex classes
	map { $rooted->set_vertex_attribute( $_, 'class', 'hypothetical' ) }
		$self->hypotheticals;
	map { $rooted->set_vertex_attribute( $_, 'class', 'extant' ) }
		$self->witnesses;
	$self->graph( $rooted );
	$self->set_identifier( $ident );
}


sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'Stemma error',
		'message' => $_[0],
		);
}


no Moose;
__PACKAGE__->meta->make_immutable;
    
1;

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
