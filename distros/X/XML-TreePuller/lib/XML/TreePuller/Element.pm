#!/usr/bin/env perl

#things got ugly in here when XPath
#support was hammered in - should be cleaned up

package XML::TreePuller::Element;

our $VERSION = '0.1.0';

use strict;
use warnings;
use Carp qw(croak);

use XML::LibXML::Reader;
use Tree::XPathEngine::Number;
use Data::Dumper;
use Scalar::Util qw(weaken);
use Tree::XPathEngine;

use XML::TreePuller::Constants;

sub new {
	my ($class, $tree) = @_;
	
	if ($tree->[XML_TREEPULLER_ELEMENT_TYPE] != XML_READER_TYPE_ELEMENT) {
		croak("must specify an element node");
	}
	
	bless($tree, $class);

	$tree->[XML_TREEPULLER_ELEMENT_XPATH_ENGINE] = Tree::XPathEngine->new;
	$tree->_init($tree, 0);
	
	return $tree;
}

sub get_elements {
	my ($self, $path) = @_;
	my @results;

	if (! defined($path)) {
		@results = _extract_elements(@{$self->[XML_TREEPULLER_ELEMENT_CHILDREN]});
	} else {
		@results = $self->_recursive_get_child_elements(split('/', $path));		
	}

	if (wantarray()) {
		return @results;
	}
	
	return shift(@results);
}

sub xpath {
	my @return = $_[0]->[XML_TREEPULLER_ELEMENT_XPATH_ENGINE]->findnodes($_[1], XML::TreePuller::Element::Document->new($_[0]));
	
	if (wantarray()) {
		return @return;
	}
	
	return shift(@return);
}

sub name {
	my ($tree) = @_;
	
	return $tree->[XML_TREEPULLER_ELEMENT_NAME];
}

sub text {
	my ($self) = @_;
	my @content;
	
	foreach (@{$self->[XML_TREEPULLER_ELEMENT_CHILDREN]}) {
		if ($_->[XML_TREEPULLER_ELEMENT_TYPE] == XML_READER_TYPE_TEXT || $_->[0] == XML_READER_TYPE_CDATA) {
			push(@content, $_->[XML_TREEPULLER_ELEMENT_NAME]);
		} elsif ($_->[XML_TREEPULLER_ELEMENT_TYPE] == XML_READER_TYPE_ELEMENT) {
			push(@content, $_->text);
		}
	}
	
	return join('', @content);
}

sub attribute {
	my ($tree, $name) = @_;
	my $attr = $tree->[XML_TREEPULLER_ELEMENT_ATTRIBUTES];
	
	$attr = {} unless defined $attr;

	if (! defined($name)) {
		return $attr;
	}
	
	return $attr->{$name};
}

#private methods
sub _extract_elements {
	return grep { $_->[XML_TREEPULLER_ELEMENT_TYPE] == XML_READER_TYPE_ELEMENT } @_;	
}

#an easier to understand algorithm would be nice
sub _recursive_get_child_elements {
	my ($tree, @path) = @_;
	my $child_nodes = $tree->[XML_TREEPULLER_ELEMENT_CHILDREN];
	my @results;
	my $target;
	
	if (! scalar(@path)) {
		return $tree;
	}
	
	$target = shift(@path);
	
	return () unless defined $child_nodes;
	
	foreach (_extract_elements(@$child_nodes)) {
		next unless $_->[XML_TREEPULLER_ELEMENT_NAME] eq $target;
		
		push(@results, _recursive_get_child_elements($_, @path));
	}
	
	return @results;
}

sub _init {
	my ($self, $root, $depth) = @_;
	my @elements = $self->get_elements;
	
	$self->[XML_TREEPULLER_ELEMENT_XPATH_ENGINE] = $root->[XML_TREEPULLER_ELEMENT_XPATH_ENGINE];
	
	$self->[XML_TREEPULLER_ELEMENT_PARENT] = undef;
	$self->[XML_TREEPULLER_ELEMENT_ROOT] = $root;
	$self->[XML_TREEPULLER_ELEMENT_DEPTH] = $depth;
	
	weaken($self->[XML_TREEPULLER_ELEMENT_ROOT]);
	
	$depth++;

	for(my $i = 0; $i < @elements; $i++) {
		my $before = $elements[$i - 1];
		my $after = $elements[$i + 1];
		
		if ($i - 1 < 0) {
			$before = undef;
		}
		
		$elements[$i]->[XML_TREEPULLER_ELEMENT_NEXT_SIBLING] = $before;
		$elements[$i]->[XML_TREEPULLER_ELEMENT_PREV_SIBLING] = $after;
		
		weaken($elements[$i]->[XML_TREEPULLER_ELEMENT_NEXT_SIBLING]);
		weaken($elements[$i]->[XML_TREEPULLER_ELEMENT_PREV_SIBLING]);
	}	
	
	foreach (@elements) {
		#set the parent and root of each element
		$_->[XML_TREEPULLER_ELEMENT_PARENT] = $self;
		$_->[XML_TREEPULLER_ELEMENT_ROOT] = $root;
		
		$_[XML_TREEPULLER_ELEMENT_DEPTH] = $depth;
		
		weaken($_->[XML_TREEPULLER_ELEMENT_PARENT]);
		weaken($_->[XML_TREEPULLER_ELEMENT_ROOT]);
		
		bless($_, 'XML::TreePuller::Element');
		
		$_->_init($root, $depth);
	}
}

#methods for Tree::XPathEngine
sub xpath_get_name {
	return name(@_);
}

sub xpath_string_value {
	return (text(@_));
}

sub xpath_get_parent_node {
	return $_[0]->[XML_TREEPULLER_ELEMENT_ROOT] || XML::TreePuller::Element::Document->new($_[0]);
}

sub xpath_get_child_nodes {
	return $_[0]->get_elements;
}	

sub xpath_is_element_node {
	return 1;
}

sub xpath_is_document_node {
	return 0;
}

sub xpath_is_attribute_node {
	return 0;
}

sub xpath_to_string {
	return $_[0];
}

sub xpath_to_number {
	return Tree::XPathEngine::Number->new($_[0]->xpath_to_string);
}

sub xpath_cmp {
	return $_[0]->[XML_TREEPULLER_ELEMENT_DEPTH] cmp $_[1]->[XML_TREEPULLER_ELEMENT_DEPTH];
}

sub xpath_get_attributes {
	
	my $elt= shift;
    my $atts= $elt->attribute;
    my $rank=-1;
    my @atts= map { bless( { name => $_, value => $atts->{$_}, elt => $elt, rank => $rank -- }, 
                           'XML::TreePuller::Element::Attribute') 
                  }
                   sort keys %$atts; 
    return @atts;
}

sub xpath_get_next_sibling  {
	return $_[0]->[XML_TREEPULLER_ELEMENT_NEXT_SIBLING];	
}

sub xpath_get_prev_sibling {
	return $_[0]->[XML_TREEPULLER_ELEMENT_PREV_SIBLING];
}

sub xpath_get_root_node {
	my ($node) = @_;
	
    return $node->[XML_TREEPULLER_ELEMENT_ROOT]->xpath_get_parent_node; 
}

package XML::TreePuller::Element::Document;

use strict;
use warnings;

use XML::TreePuller::Constants;

sub new {
	my ($class, $root) = @_;
	my $self = [ $root ];
	
	$self->[XML_TREEPULLER_ELEMENT_DEPTH] = -1;
	
	return bless($self, $class);
}

sub xpath_get_child_nodes   { return( $_[0]->[0] ); } 
sub xpath_get_attributes    { return (); }
sub xpath_is_document_node  { return 1   }
sub xpath_is_element_node   { return 0   }
sub xpath_is_attribute_node { return 0   }
sub xpath_get_parent_node   { return; }
sub xpath_get_root_node     { return $_[0] }
sub xpath_get_name          { return; }
sub xpath_get_next_sibling  { return; }
sub xpath_get_previous_sibling { return; }

package XML::TreePuller::Element::Attribute;

use strict;
use warnings;

sub xpath_get_value         { return $_[0]->{value}; }
sub xpath_get_name          { return $_[0]->{name} ; }
sub xpath_string_value      { return $_[0]->{value}; }
sub xpath_to_number         { return Tree::XPathEngine::Number->new( $_[0]->{value}); }
sub xpath_is_document_node  { 0 }
sub xpath_is_element_node   { 0 }
sub xpath_is_attribute_node { 1 }
sub to_string         { return qq{$_[0]->{name}="$_[0]->{value}"}; }

1;