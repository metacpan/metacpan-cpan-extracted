# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/LocationPath.pm 22 2006-02-13T14:00:25.731780Z mrodrigu  $

package Tree::XPathEngine::LocationPath;
use strict;

sub new {
	my $class = shift;
	my $self = [];
	bless $self, $class;
}

sub as_string {
	my $self = shift;
	my $string;
	for (my $i = 0; $i < @$self; $i++) {
		$string .= $self->[$i]->as_string;
		$string .= "/" if $self->[$i+1];
	}
	return $string;
}

sub as_xml {
    my $self = shift;
    my $string = "<LocationPath>\n";

    for (my $i = 0; $i < @$self; $i++) {
        $string .= $self->[$i]->as_xml;
    }

    $string .= "</LocationPath>\n";
    return $string;
}


sub evaluate {
	my $self = shift;
	# context _MUST_ be a single node
	my $context = shift;
	die "No context" unless $context;
	
	# I _think_ this is how it should work :)
	
	my $nodeset = Tree::XPathEngine::NodeSet->new();
	$nodeset->push($context);
	
	foreach my $step (@$self) {
		# For each step
		# evaluate the step with the nodeset
		my $pos = 1;
		$nodeset = $step->evaluate($nodeset);
	}
	
	return $nodeset->remove_duplicates;
}

1;

__END__
=head1 NAME Tree::XPathEngine::LocationPath - a complete XPath location path

=head1 METHODS

=head2 new 

creates the location path

=head2 evaluate

evaluates it in C<$context>

=head2 as_string 

dumps the location path as a string

=head2 as_xml

dumps the location path as xml

