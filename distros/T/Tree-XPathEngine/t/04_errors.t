#!/usr/bin/perl 
# $Id: /tree-xpathengine/trunk/t/04_errors.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $

use strict;
use warnings;

use Test::More qw( no_plan);
use Tree::XPathEngine;

BEGIN { push @INC, './t'; }

my $tree = init_tree();
my $xp   = Tree::XPathEngine->new;

{
eval { $xp->findnodes( '/foo#a/toto', $tree); };
like( $@, qr/Invalid query somewhere around here/, "invalid query");
}

{
eval { $xp->findnodes( '/foo[@position()=1]', $tree); };
like( $@, qr/Invalid token/, "invalid token");
}

{
eval { $xp->findnodes( '//@att1[. / 2 > 2]', $tree); };
like( $@, qr/doesn't match format of a 'Step'/, "invalid token");
}

{
eval { $xp->findnodes( '[. / 2 > 2]', $tree); };
like( $@, qr/Not a _primary_expr/, "not a _primary_expr");
}

{
my $path='/foo[@att]a';
eval { $xp->findnodes( $path, $tree); };
like( $@, qr/^Parse of expression \Q$path\E failed - junk after end of expression:/, "junk after end of expression");
}

{
my $path='/root[last(2)]';
eval { $xp->findnodes( $path, $tree); };
like( $@, qr/^last: function doesn't take parameters/, "param in last()");
}

{
my $path='count(1)';
eval { $xp->findnodes( $path, $tree); };
like( $@, qr/^count: Parameter must be a NodeSet/, "wrong param in count()");
}


{
my $path='/root[position("foo")=1]';
eval { $xp->findnodes( $path, $tree); };
like( $@, qr/^position: function doesn't take parameters/, "param in position()");
}


sub init_tree
  { my $tree  = tree->new( 'att', name => 'tree', value => 'tree_value', id =>'t-1');
    my $root  = tree->new( 'att', name => 'root', value => 'vroot', att1 => '1', id => 'r-1');
    $root->add_as_last_child_of( $tree);

    return $tree;
  }


package tree;
use base 'minitree';

sub xpath_get_name             { return shift->name;  }
sub xpath_string_value         { return shift->value; }
sub xpath_get_root_node        { return shift->root;                }
sub xpath_get_parent_node      { return shift->parent;              }
sub xpath_get_child_nodes      { return return wantarray ? shift->children : [shift->children]; }
sub xpath_get_next_sibling     { return shift->next_sibling;        }
sub xpath_get_previous_sibling { return shift->previous_sibling;    }
sub xpath_is_element_node      { return 1;                          }
sub get_pos              { return shift->pos;          }
sub xpath_get_attributes       { return wantarray ? @{shift->attributes} : shift->attributes; }
sub to_string            
  { my $node= shift; 
    my $name= $node->name;
    my $value= $node->value;
    my $atts= join( ' ', map { $_->to_string } $_->xpath_get_attributes);
    return "[$name {$atts} $value]";
  }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

package att;
use base 'attribute';

sub xpath_get_name          { return shift->name;                }
sub to_string         { my $att= shift; return sprintf( '%s="%s"', $att->xpath_get_name, $att->xpath_get_value) ; }
sub xpath_string_value      { return shift->value;               }
sub xpath_get_root_node     { return shift->parent->root;        }
sub xpath_get_parent_node   { return shift->parent;              }
sub xpath_is_attribute_node { return 1;                          }
sub xpath_get_child_nodes   { return; }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

