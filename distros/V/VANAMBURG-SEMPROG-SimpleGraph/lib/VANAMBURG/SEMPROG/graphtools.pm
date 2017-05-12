package VANAMBURG::SEMPROG::graphtools;

use Set::Scalar;


# Inherit from the "Exporter" module which handles exporting functions.
# Most procedural modules make use of this.

use base 'Exporter';

# When the module is invoked, export, by default, the function "hello" into 
# the namespace of the using code.

our @EXPORT = qw(triples_to_dot);

=head2 triples_to_dot

Supply an array reference of triples (each themselves an array reference with a subject predicate and object as elements 0,1, and 2), as well as a filename into which to store the triples in DOT format.

=cut


sub triples_to_dot{
    my ($triples, $filename) = @_;

    open my $out,">", $filename
	or die "Cannot open file: $filename\n$!\n";

    print $out "graph \"SimpleGraph\" {\n";
    print $out "overlap = \"scale\";\n";

    for my $t (@$triples){
	my $line = sprintf ("\"%s\" -- \"%s\" [label=\"%s\"];\n", 
			    $t->[0], $t->[2], $t->[1]);
	print $out $line;
    }

    print $out '}';
}



=head2 query_to_dot

Given a graph, a query, and two bindings representing the left and right site of a DOT file line, as well as a filename, this method will produce a DOT file from a query which has two bindings.

=cut

sub query_to_dot{
    my ($graph, $query, $b1, $b2, $filename) = @_;


    open my $out,">", $filename
	or die "Cannot open file: $filename\n$!\n";

    print $out "graph \"SimpleGraph\" {\n";
    print $out "overlap = \"scale\";\n";


    my @results = $graph->query($query);
    my $donelinks = Set::Scalar->new();
    for my $binding (@results){
	
	if ($binding{$b1} != $binding{$b2}){
	}
	
    }
}


1;
