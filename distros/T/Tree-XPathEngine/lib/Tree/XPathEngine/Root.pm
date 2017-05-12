# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Root.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::Root;
use strict;
use Tree::XPathEngine::NodeSet;

sub new {
	my $class = shift;
	my $self; # actually don't need anything here - just a placeholder
	bless \$self, $class;
}

sub as_string {
	# do nothing
}

sub as_xml {
    return "<Root/>\n";
}

sub evaluate {
	my $self = shift;
	my $nodeset = shift;
	
#	warn "Eval ROOT\n";
	
	# must only ever occur on 1 node
	die "Can't go to root on > 1 node!" unless $nodeset->size == 1;
	
	my $newset = Tree::XPathEngine::NodeSet->new();
	$newset->push($nodeset->get_node(1)->xpath_get_root_node());
	return $newset;
}

1;
__END__
=head1 NAME 

 Tree::XPathEngine::Root - going back to the root node in an XPath expression

=head1 METHODS

=head2 new

=head2 evaluate ($nodeset)

returns a nodeset containing the root node of the first element of the nodeset

=head2  as_string

=head2 as_xml

dumps the action as XML (as C<< <Root/> >>)
