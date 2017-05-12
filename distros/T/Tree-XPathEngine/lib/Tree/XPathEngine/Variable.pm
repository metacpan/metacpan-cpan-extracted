# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Variable.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::Variable;
use strict;

# This class does NOT contain 1 instance of a variable
# see the Tree::XPathEngine class for the instances
# This class simply holds the name of the var

sub new {
    my $class = shift;
    my ($pp, $name) = @_;
    bless { name => $name, path_parser => $pp }, $class;
}

sub as_string {
    my $self = shift;
    '\$' . $self->{name};
}

sub as_xml {
    my $self = shift;
    return "<Variable>" . $self->{name} . "</Variable>\n";
}

sub xpath_get_value {
    my $self = shift;
    $self->{path_parser}->get_var($self->{name});
}

sub xpath_set_value {
    my $self = shift;
    my ($val) = @_;
    $self->{path_parser}->set_var($self->{name}, $val);
}

sub evaluate {
    my $self = shift;
    my $val = $self->xpath_get_value;
    return $val;
}

1;

__END__
=head1 NAME

Tree::XPathEngine::Variable - a variable in a Tree::XPathEngine object

=head1 METHODS

This class does NOT contain 1 instance of a variable, it's in the 
Tree::XPathEngine class. This class simply holds the name of the var,
for use by the engine when evaluating the query

=head2 new

=head2 xpath_set_value

=head2 xpath_get_value

synonym of get_value

=head2 evaluate

=head2 as_string

dump the variable call in the XPath expression as a string

=head2 as_xml

dump the variable call in the XPath expression as xml
