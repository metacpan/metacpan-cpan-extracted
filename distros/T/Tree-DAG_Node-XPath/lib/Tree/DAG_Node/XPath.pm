package Tree::DAG_Node::XPath;

require 5.006;
use strict;
use warnings;


use vars qw(@ISA $VERSION);
$VERSION="0.11";

use base 'Tree::DAG_Node';
use Tree::XPathEngine;

sub _init {
    my($self, $options) = @_[0,1];
    $self->SUPER::_init($options);
    
    $self->_init_xpath_engine($options);
  }
  
  sub _init_xpath_engine {
    my($self, $options) = @_;
    # copy options, so the delete doesn't modify the original options
    my %options= %$options;
    my %xpath_engine_options;
    my @xpath_engine_options= qw{xpath_name_re};
    foreach my $option_name ( @xpath_engine_options)
      { $xpath_engine_options{$option_name}= $options{$option_name};
        delete $options{$option_name};
      }
    $xpath_engine_options{xpath_name_re}= $options->{xpath_name_re};
    $self->{_xpath_engine} = Tree::XPathEngine->new( %xpath_engine_options);
  }

sub _xpath_engine
  { return shift()->{_xpath_engine}; }

# these are straight from Tree::XPathEngine::Node     
sub find {
    my $node = shift;
    my ($path) = @_;
    my $xp = $node->root->_xpath_engine;
    return $xp->find($path, $node);
}



sub findvalue {
    my $node = shift;
    my ($path) = @_;
    my $xp = $node->root->_xpath_engine;
    return $xp->findvalue($path, $node);
}

sub findnodes {
    my $node = shift;
    my ($path) = @_;
    my $xp = $node->root->_xpath_engine;
    return $xp->findnodes($path, $node);
}

sub matches {
    my $node = shift;
    my ($path, $context) = @_; 
    $context ||= $node;
    my $xp = $node->root->_xpath_engine;
    return $xp->matches($node, $path, $context);
}

# Tree::XPathEngine method   aliased to   Tree::DAG_Node method
*xpath_get_name                 =         *Tree::DAG_Node::name;
*xpath_get_next_sibling         =         *Tree::DAG_Node::right_sister;
*xpath_get_previous_sibling     =         *Tree::DAG_Node::left_sister;

sub xpath_get_root_node
  { my $node= shift;
    # The parent of root is a Tree::DAG_Node::XPath::Root
    # that helps getting the tree to mimic a DOM tree
    return $node->root->xpath_get_parent_node; # I like this one!
  }

sub xpath_get_parent_node
  { my $node= shift;
    return $node->mother || bless { root => $node }, 'Tree::DAG_Node::XPath::Root';
  }


sub xpath_get_child_nodes { my @daughters= shift()->daughters; return @daughters; }
sub xpath_is_document_node  { return 0; }
sub xpath_is_element_node   { return 1; }
sub xpath_is_attribute_node { return 0; }
#sub getValue      { return '' };

sub xpath_get_attributes
  { my $elt= shift;
    my $atts= $elt->attributes;
    my $rank=-1;
    my @atts= map { bless( { name => $_, value => $atts->{$_}, elt => $elt, rank => $rank -- }, 
                           'Tree::DAG_Node::XPath::Attribute') 
                  }
                   sort keys %$atts; 
    return @atts;
  }



sub xpath_cmp { $_[0]->address cmp $_[1]->address }

  
1;

# class for the fake root for a tree
package Tree::DAG_Node::XPath::Root;

    
sub xpath_get_child_nodes   { my @daughters= ( $_[0]->{root}); return @daughters; }
sub address           { return -1; } # the root is before all other nodes
sub xpath_get_attributes    { return (); }
sub xpath_is_document_node  { return 1   }
sub xpath_is_element_node   { return 0   }
sub xpath_is_attribute_node { return 0   }
sub xpath_get_parent_node   { return;    }
sub xpath_get_root_node     { return $_[0] }
sub xpath_get_name          { return;    }
sub xpath_get_next_sibling  { return;    }
sub xpath_get_previous_sibling { return; }


1;

package Tree::DAG_Node::XPath::Attribute;
use Tree::XPathEngine::Number;

# not used, instead xpath_get_attributes in Tree::DAG_Node::XPath directly returns an
# object blessed in this class
#sub new
#  { my( $class, $elt, $att)= @_;
#    return bless { name => $att, value => $elt->att( $att), elt => $elt }, $class;
#  }

sub xpath_get_value         { return $_[0]->{value}; }
sub xpath_get_name          { return $_[0]->{name} ; }
sub xpath_string_value      { return $_[0]->{value}; }
sub xpath_to_number         { return Tree::XPathEngine::Number->new( $_[0]->{value}); }
sub xpath_is_document_node  { 0 }
sub xpath_is_element_node   { 0 }
sub xpath_is_attribute_node { 1 }
sub to_string         { return qq{$_[0]->{name}="$_[0]->{value}"}; }
sub address  
  { my $att= shift;
    my $elt= $att->{elt};
    return $elt->address . ':' . $att->{rank};
  }
      
sub xpath_cmp { $_[0]->address cmp $_[1]->address }

1;



__END__

=head1 NAME

Tree::DAG_Node::XPath - Add XPath support to Tree::DAG_Node

=head1 SYNOPSIS

  use Tree::DAG_Node::XPath;

  # create a tree
  my $root = Tree::DAG_Node::XPath->new()->name( "root_node");
  $root->new_daughter->name("daugther$_") foreach (1..5);

  # now use XPath to find nodes
  my $roots= $root->find( '/root_node');
  foreach (@$roots) { print "found root: ", $_->name, "\n"; }

  my $daughters= $root->find( '/root_node/daugther2 | /root_node/daugther4');
  foreach (@$daughters) { print "found daughter: ", $_->name, "\n"; }

=head1 DESCRIPTION

This package extends Tree::DAG_Node to add XPath queries to it

It adds the L<findnodes>, L<matches> and L<find> methods to the
base C<Tree::DAG_Node> class.

With a little customization it can also add the L<findnodes_as_string>
and L<findvalue> methods.

=head1 METHODS

=head2 Methods you are likely to use

=over 4

=item findnodes($path, [$context])

Returns a list of nodes found by $path, optionally in context $context. 
In scalar context returns an Tree::XPathEngine::NodeSet object.

=item findvalue($path, [$context])

Returns either a C<Tree::XPathEngine::Literal>, a C<Tree::XPathEngine::Boolean> or a
C<Tree::XPathEngine::Number> object. If the path returns a NodeSet,
$nodeset->xpath_to_literal is called automatically for you (and thus a
C<Tree::XPathEngine::Literal> is returned). Note that
for each of the objects stringification is overloaded, so you can just
print the value found, or manipulate it in the ways you would a normal
perl value (e.g. using regular expressions).

=item find($path, [$context])

The find function takes an XPath expression (a string) and returns either an
Tree::XPathEngine::NodeSet object containing the nodes it found (or empty if
no nodes matched the path), or one of Tree::XPathEngine::Literal (a string),
Tree::XPathEngine::Number, or Tree::XPathEngine::Boolean. It should always return 
something - and you can use isa() to find out what it returned. If you
need to check how many nodes it found you should check $nodeset->size.
See L<Tree::XPathEngine::NodeSet>.

=item matches($node, $path, [$context])

Returns true if the node matches the path (optionally in context $context).

=back

=head2 Methods provided by the module for Tree::XPathEngine

You probably don't need to use those.

=over 4

=item xpath_get_attributes

returns an array of attributes of the node (an arrayref in scalar context)

returns 

=item xpath_get_child_nodes

returns an array of children of the node (an arrayref in scalar context)

=item xpath_get_parent_node

returns the parent node

=item xpath_get_root_node

returns the root node of the tree

=item xpath_is_element_node

returns 1

=item xpath_is_document_node

returns 0

=item xpath_is_attribute_node

returns 0

=item xpath_cmp 

compares 2 nodes and returns their order in the tree

=item xpath_get_name

alias for name

=item xpath_get_next_sibling

alias for right_sister

=item xpath_get_previous_sibling

alias for left_sister

=back


=head1 CUSTOMIZATION

XPath is an XML standard, which is designed to work on a DOM 
(L<http://www.w3.org/DOM/DOMTR>) tree. So the closer the tree
you are working on mimics a DOM tree, the more of XPath you will be
able to use. 

In order for a generic tree to work better with XPath here are the main 
features that can be addressed:

=head2 Changing the XPath engine 

In XPath, tokens in the query (node names and attribute names) must follow
the rules for XML tokens (see the definition at 
L<http://xml.com/axml/target.html#NT-Nmtoken>).

The definition of the tokens can be changed, within reasons: in order not
to confuse the interpreter XPath delimiters cannot be used in tokens.
'/', '[', '|', '!'. 

Test carefully your expressions, so they don't confuse the XPath engine. For 
example C<qr/\w+/> is _not_ recommended, as numbers are then matched by the
expression, making the XPath engine consider them as names.

=head1 BUGS

None known at this time

=head1 TODO

better docs, especially on customizing derived classes to use more of 
XPath power

more tests (current coverage according to Devel::Cover: 96.2%)

if needed performance improvements (using C<address> to sort the node sets
is convenient but probably real slow, grabing the code to sort nodesfrom 
XML::Twig::XPath would likely be faster in most cases) 

=head1 SEE ALSO

L<Tree::DAG_Node> the base package that Tree::DAG_Node::XPath extends

L<Tree::XPathEngine> the XPath engine for Tree::DAG_Node::XPath

L<http://www.w3.org/TR/xpath.html> the XPath recommendations

examples are in the C<examples> directory

=head1 AUTHOR

Michel Rodriguez, E<lt>mirod@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Michel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

