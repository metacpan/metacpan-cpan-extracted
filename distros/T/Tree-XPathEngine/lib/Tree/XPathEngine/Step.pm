# $id$
# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Step.pm 25 2006-02-15T15:34:11.453583Z mrodrigu  $

package Tree::XPathEngine::Step;
use Tree::XPathEngine;
use strict;

# constants used to describe the test part of a step
sub test_name ()       { 0; } # Full name
sub test_any ()        { 1; } # *
sub test_attr_name ()  { 2; } # @attrib
sub test_attr_any ()   { 3; } # @*
sub test_nt_text ()    { 4; } # text()
sub test_nt_node ()    { 5; } # node()

sub new {
    my $class = shift;
    my ($pp, $axis, $test, $literal) = @_;
    my $axis_method = "axis_$axis";
    $axis_method =~ tr/-/_/;
    my $self = {
        pp => $pp, # the Tree::XPathEngine class
        axis => $axis,
        axis_method => $axis_method,
        test => $test,
        literal => $literal,
        predicates => [],
        };
    bless $self, $class;
}

sub as_string {
    my $self = shift;
    my $string = $self->{axis} . "::";

    my $test = $self->{test};
        
    if ($test == test_nt_text) {
        $string .= 'text()';
    }
    elsif ($test == test_nt_node) {
        $string .= 'node()';
    }
    else {
        $string .= $self->{literal};
    }
    
    foreach (@{$self->{predicates}}) {
        next unless defined $_;
        $string .= "[" . $_->as_string . "]";
    }
    return $string;
}

sub evaluate {
    my $self = shift;
    my $from = shift; # context nodeset
    
#    warn "Step::evaluate called with ", $from->size, " length nodeset\n";
    
    $self->{pp}->_set_context_set($from);
    
    my $initial_nodeset = Tree::XPathEngine::NodeSet->new();
    
    # See spec section 2.1, paragraphs 3,4,5:
    # The node-set selected by the location step is the node-set
    # that results from generating an initial node set from the
    # axis and node-test, and then filtering that node-set by
    # each of the predicates in turn.
    
    # Make each node in the nodeset be the context node, one by one
    for(my $i = 1; $i <= $from->size; $i++) {
        $self->{pp}->_set_context_pos($i);
        $initial_nodeset->append($self->evaluate_node($from->get_node($i)));
    }
    
#    warn "Step::evaluate initial nodeset size: ", $initial_nodeset->size, "\n";
    
    $self->{pp}->_set_context_set(undef);

    $initial_nodeset->sort;
        
    return $initial_nodeset;
}

# Evaluate the step against a particular node
sub evaluate_node {
    my $self = shift;
    my $context = shift;
    
#    warn "Evaluate node: $self->{axis}\n";
    
#    warn "Node: ", $context->[node_name], "\n";
    
    my $method = $self->{axis_method};
    
    my $results = Tree::XPathEngine::NodeSet->new();
    no strict 'refs';
    eval {
        #$method->($self, $context, $results);
        $self->$method( $context, $results);
    };
    if ($@) {
        die "axis $method not implemented [$@]\n";
    }
    
#    warn("results: ", join('><', map {$_->xpath_string_value} @$results), "\n");
    # filter initial nodeset by each predicate
    foreach my $predicate (@{$self->{predicates}}) {
        $results = $self->filter_by_predicate($results, $predicate);
    }
    
    return $results;
}

sub axis_ancestor {
    my $self = shift;
    my ($context, $results) = @_;
    
    my $parent = $context->xpath_get_parent_node;
        
    while( $parent)
      { $results->push($parent) if (node_test($self, $parent));
        $parent = $parent->xpath_get_parent_node;
      }
    return $results unless $parent;
}

sub axis_ancestor_or_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    START:
    return $results unless $context;
    if (node_test($self, $context)) {
        $results->push($context);
    }
    $context = $context->xpath_get_parent_node;
    goto START;
}

sub axis_attribute {
    my $self = shift;
    my ($context, $results) = @_;
    
    foreach my $attrib ($context->xpath_get_attributes) {
        if ($self->test_attribute($attrib)) {
            $results->push($attrib);
        }
    }
}

sub axis_child {
    my $self = shift;
    my ($context, $results) = @_;
    
    foreach my $node ($context->xpath_get_child_nodes) {
        if (node_test($self, $node)) {
            $results->push($node);
        }
    }
}

sub axis_descendant {
    my $self = shift;
    my ($context, $results) = @_;

    my @stack = $context->xpath_get_child_nodes;

    while (@stack) {
        my $node = pop @stack;
        if (node_test($self, $node)) {
            $results->unshift($node);
        }
        push @stack, $node->xpath_get_child_nodes;
    }
}

sub axis_descendant_or_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    my @stack = ($context);
    
    while (@stack) {
        my $node = pop @stack;
        if (node_test($self, $node)) {
            $results->unshift($node);
        }
        push @stack, $node->xpath_get_child_nodes;
    }
}

sub axis_following {
    my $self = shift;
    my ($context, $results) = @_;
    
    START:

    my $parent = $context->xpath_get_parent_node;
    return $results unless $parent;
        
    while ($context = $context->xpath_get_next_sibling) {
        axis_descendant_or_self($self, $context, $results);
    }

    $context = $parent;
    goto START;
}

sub axis_following_sibling {
    my $self = shift;
    my ($context, $results) = @_;

    while ($context = $context->xpath_get_next_sibling) {
        if (node_test($self, $context)) {
            $results->push($context);
        }
    }
}

sub axis_parent {
    my $self = shift;
    my ($context, $results) = @_;
    
    my $parent = $context->xpath_get_parent_node;
    return $results unless $parent;
    if (node_test($self, $parent)) {
        $results->push($parent);
    }
}

sub axis_preceding {
    my $self = shift;
    my ($context, $results) = @_;
    
    # all preceding nodes in document order, except ancestors
    
    START:

    my $parent = $context->xpath_get_parent_node;
    return $results unless $parent;

    while ($context = $context->xpath_get_previous_sibling) {
        axis_descendant_or_self($self, $context, $results);
    }
    
    $context = $parent;
    goto START;
}

sub axis_preceding_sibling {
    my $self = shift;
    my ($context, $results) = @_;
    
    while ($context = $context->xpath_get_previous_sibling) {
        if (node_test($self, $context)) {
            $results->push($context);
        }
    }
}

sub axis_self {
    my $self = shift;
    my ($context, $results) = @_;
    
    if (node_test($self, $context)) {
        $results->push($context);
    }
}
    
sub node_test {
    my $self = shift;
    my $node = shift;
    
    # if node passes test, return true
    
    my $test = $self->{test};

    return 1 if $test == test_nt_node;
        
    if ($test == test_any) { 
        return 1 if( $node->xpath_is_element_node && defined $node->xpath_get_name);
    }
        
    local $^W;

    if ($test == test_name) {
        return unless $node->xpath_is_element_node;
        return 1 if $node->xpath_get_name eq $self->{literal};
    }
    elsif ($test == test_nt_text) {
        return 1 if $node->xpath_is_text_node;
    }
    return; # fallthrough returns false
}

sub test_attribute {
    my $self = shift;
    my $node = shift;
    
#    warn "test_attrib: '$self->{test}' against: ", $node->xpath_get_name, "\n";
#    warn "node type: $node->[node_type]\n";
    
    my $test = $self->{test};

    if(    ($test == test_attr_any) || ($test == test_nt_node) 
        || ( ($test == test_attr_name) && ($node->xpath_get_name eq $self->{literal}) )
      )
      { return 1; }
    else
      { return; }
}


sub filter_by_predicate {
    my $self = shift;
    my ($nodeset, $predicate) = @_;
    
    # See spec section 2.4, paragraphs 2 & 3:
    # For each node in the node-set to be filtered, the predicate Expr
    # is evaluated with that node as the context node, with the number
    # of nodes in the node set as the context size, and with the
    # proximity position of the node in the node set with respect to
    # the axis as the context position.
    
    if (!ref($nodeset)) { # use ref because nodeset has a bool context
        die "No nodeset!!!";
    }
    
#    warn "Filter by predicate: $predicate\n";
    
    my $newset = Tree::XPathEngine::NodeSet->new();
    
    for(my $i = 1; $i <= $nodeset->size; $i++) {
        # set context set each time 'cos a loc-path in the expr could change it
        $self->{pp}->_set_context_set($nodeset);
        $self->{pp}->_set_context_pos($i);
        my $result = $predicate->evaluate($nodeset->get_node($i));
        if ($result->isa('Tree::XPathEngine::Boolean')) {
            if ($result->value) {
                $newset->push($nodeset->get_node($i));
            }
        }
        elsif ($result->isa('Tree::XPathEngine::Number')) {
            if ($result->value == $i) {
                $newset->push($nodeset->get_node($i));
            }
        }
        else {
            if ($result->xpath_to_boolean->value) {
                $newset->push($nodeset->get_node($i));
            }
        }
    }
    
    return $newset;
}

1;

__END__
=head1 NAME

Tree::XPathEngine::Step - implements a step in an XPath location path

=head1 METHODS

These methods should probably not be called from outside of Tree::XPathEngine.

=head2 new 

create the step

=head2 evaluate $nodeset

evaluate the step against a nodeset

=head2 evaluate_node $node

evaluate the step against a single node

=head2 axis methods

All these methods return the nodes along the chosen axis

=over 4

=item axis_ancestor 
=item axis_ancestor_or_self 
=item axis_attribute 
=item axis_child 
=item axis_descendant 
=item axis_descendant_or_self 
=item axis_following 
=item axis_following_sibling 
=item axis_parent 
=item axis_preceding 
=item axis_preceding_sibling 
=item axis_self 

=back

=head2 node_test 

apply the node test to the nodes gathered by the axis method

=head2 test_attribute 

test on attribute existence

=head2 filter_by_predicate 

filter the results on a predicate

=head2 as_string 

dump the step as a string

=head2 as_xml 

dump the step as xml

=head1 Test type constants

These constants are used in this package and in Tree::XPathEngine to describe 
the type of test in a step:

=over 4

=item test_name
=item test_any
=item test_attr_name
=item test_attr_any
=item test_nt_text
=item test_nt_node

=back
