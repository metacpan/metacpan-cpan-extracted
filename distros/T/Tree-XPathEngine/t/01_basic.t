#!/usr/bin/perl 
#$Id: /tree-xpathengine/trunk/t/01_basic.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $

use strict;
use warnings;

use Test::More qw( no_plan);
use Tree::XPathEngine;

BEGIN { push @INC, './t'; }

my $tree = init_tree();
my $xp   = Tree::XPathEngine->new;

{
my @root_nodes= $xp->findnodes( '/root', $tree);
is( join( ':', map { $_->value } @root_nodes), 'root_value', q{findnodes( '/root', $tree)});
}
{
my @kid_nodes= $xp->findnodes( '/root/kid0', $tree);
is( scalar @kid_nodes, 2, q{findnodes( '/root/kid0', $tree)});
}
{
my $kid_nodes= $xp->findvalue( '/root/kid0', $tree);
is( $kid_nodes, 'vkid2vkid4', q{findvalue( '/root/kid0', $tree)});
}
{
is( $xp->findvalue( '//*[@att2="vv"]', $tree), 'gvkid1gvkid2gvkid3gvkid4gvkid5', 
    q{findvalue( '//*[@att2="vv"]', $tree)}
  );
is( $xp->findvalue( '//*[@att2]', $tree), 'gvkid1gkid2 1gvkid2gkid2 2gvkid3gkid2 3gvkid4gkid2 4gvkid5gkid2 5', 
    q{findvalue( '//*[@att2]', $tree)}
  );
}

{
is( $xp->findvalue( '//kid1/@att1[.="v1"]', $tree), 'v1', "return attribute values (1)");
is( $xp->findvalue( '//@att1[.="v1"]', $tree), 'v1'x2, "return attribute values (2)");
is( $xp->findvalue( '//@att2[.="vx"]', $tree), 'vx'x5, "return attribute values (5)");

is( $xp->findvalue( '//kid1/@att1[.=~m/v1/]', $tree), 'v1', "regxp match, return attribute values (1)");
is( $xp->findvalue( '//@att1[.=~m/v1/]', $tree), 'v1'x2, "regxp match, return attribute values (2)");
is( $xp->findvalue( '//@att2[.=~/vx/]', $tree), 'vx'x5, "regxp match, return attribute values (5)");
}

{ my $elt= ($xp->findnodes( '/root/kid1[1]/gkid2', $tree))[0];
  ok( $xp->matches( $elt, '/root/kid1/gkid2', $tree), 'matches (true)');
  ok( !$xp->matches( $elt, '/root/kid0/gkid2', $tree), 'matches (false)');
}

{ my @empty= $xp->findnodes( '0', $tree);
  is( scalar( @empty), 0, 'findnodes, empty return in list context');
}

{ is( $xp->findnodes_as_string( '/root/kid1[1]/gkid2', $tree), '[gkid2 {att2="vx"} gkid2 1]' , 'findnode_as_string (nodeset result)');
  is( $xp->findnodes_as_string( '"foo"', $tree), 'foo' , 'findnode_as_string (literal result)');
  is( $xp->findnodes_as_string( '1', $tree), 1 , 'findnode_as_string (number result)');
}
{ is( $xp->findvalue( '/root/kid1[1]/gkid2', $tree), 'gkid2 1' , 'findvalue (nodeset result)');
  is( $xp->findvalue( '"foo"', $tree), 'foo' , 'findvalue (literal result)');
  is( $xp->findvalue( '1', $tree), 1 , 'findvalue (number result)');
  is( $xp->findvalue( '//nothing', $tree), '' , 'findvalue (number result)');
}

{ is( $xp->exists( '/root/kid1[1]/gkid2', $tree), 1, 'exists (true)');
  is( $xp->exists( '/nothing/kid1[1]/gkid2', $tree), 0, 'exists (false)');
}

{ $xp->set_var( var => "gkid2 1");
  is( $xp->get_var( 'var'), 'gkid2 1', 'get_var');
  is( $xp->findvalue( '//gkid2[string()="gkid2 1"]', $tree), 'gkid2 1', "string()");
  #is( $xp->findvalue( '//gkid2[string()=$var]', $tree), 'gkid2 1', "string()"); # TODO
}

{ # to test _get_context_size
  is( $xp->findvalue( '//kid0[last()]/gkid2', $tree), 'gkid2 4', "string()");
  # to test _get_context_pos
  is( $xp->findvalue( '//kid0[position()=2]/gkid2', $tree), 'gkid2 4', "string()");
}


sub init_tree
  {  my $tree  = tree->new( 'att', name => 'tree', value => 'tree');
    my $root  = tree->new( 'att', name => 'root', value => 'root_value', att1 => 'v1');
    $root->add_as_last_child_of( $tree);

    foreach (1..5)
      { my $kid= tree->new( 'att', name => 'kid' . $_ % 2, value => "vkid$_", att1 => "v$_");
        $kid->add_as_last_child_of( $root);
        my $gkid1= tree->new( 'att', name => 'gkid' . $_ % 2, value => "gvkid$_", att2 => "vv");
        $gkid1->add_as_last_child_of( $kid);
        my $gkid2= tree->new( 'att', name => 'gkid2', value => "gkid2 $_", att2 => "vx");
        $gkid2->add_as_last_child_of( $kid);
      }

    $tree->set_pos;
    #tree->dump_all;

    return $tree;
  }


package tree;
use base 'minitree';

sub xpath_get_name             { return shift->name;  }
sub xpath_string_value         { return shift->value; }
sub xpath_get_root_node        { return shift->root;                }
sub xpath_get_parent_node      { return shift->parent;              }
sub xpath_get_child_nodes      { return shift->children; }
sub xpath_get_next_sibling     { return shift->next_sibling;        }
sub xpath_get_previous_sibling { return shift->previous_sibling;    }
sub xpath_is_element_node      { return 1;                          }
sub xpath_get_attributes       { return @{shift->attributes}; }
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
sub to_string         { my $att= shift; return sprintf( '%s="%s"', $att->name, $att->value) ; }
sub xpath_string_value      { return shift->value;               }
sub xpath_get_root_node     { return shift->parent->root;        }
sub xpath_get_parent_node   { return shift->parent;              }
sub xpath_is_attribute_node { return 1;                          }
sub xpath_get_child_nodes   { return; }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

