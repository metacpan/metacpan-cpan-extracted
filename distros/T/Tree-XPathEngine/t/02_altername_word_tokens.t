#!/usr/bin/perl 
# $Id: /tree-xpathengine/trunk/t/02_altername_word_tokens.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $

use strict;
use warnings;

use Test::More qw( no_plan);
use Tree::XPathEngine;

BEGIN { push @INC, './t'; }

foreach my $extra_char ( '#', ':')
  { my $tree = init_tree( $extra_char);
    my $xp   = Tree::XPathEngine->new( xpath_name_re => qr/[a-z][\w$extra_char]*/);
    { my @kid_nodes= $xp->findnodes( "/root/kid${extra_char}0", $tree);
      is( scalar @kid_nodes, 2, qq{findnodes( '/root/kid${extra_char}0', \$tree)});
    }
    { my $kid_nodes= $xp->findvalue( "/root/kid${extra_char}0", $tree);
      is( $kid_nodes, 'vkid2vkid4', qq{findvalue( '/root/kid${extra_char}0', \$tree)});
    }
  }

sub init_tree
  { my( $extra_char)= @_;
    my $tree  = tree->new( 'att', name => 'tree', value => 'tree');
    my $root  = tree->new( 'att', name => 'root', value => 'root_value', att1 => 'v1');
    $root->add_as_last_child_of( $tree);

    foreach (1..5)
      { my $kid= tree->new( 'att', name => 'kid' . $extra_char . $_ % 2, value => "vkid$_", att1 => "v$_");
        $kid->add_as_last_child_of( $root);
        my $gkid1= tree->new( 'att', name => 'gkid' . $extra_char . $_ % 2, value => "gvkid$_", att2 => "vv");
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
sub xpath_get_child_nodes      { return return wantarray ? shift->children : [shift->children]; }
sub xpath_get_next_sibling     { return shift->next_sibling;        }
sub xpath_get_previous_sibling { return shift->previous_sibling;    }
sub xpath_is_element_node      { return 1;                          }
sub get_pos              { return shift->pos;          }
sub xpath_get_attributes       { return wantarray ? @{shift->attributes} : shift->attributes; }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

package att;
use base 'attribute';

sub xpath_get_name          { return shift->name;                }
sub xpath_string_value      { return shift->value;               }
sub to_string         { return shift->value;               }
sub xpath_get_root_node     { return shift->parent->root;        }
sub xpath_get_parent_node   { return shift->parent;              }
sub xpath_is_attribute_node { return 1;                          }
sub xpath_get_child_nodes   { return; }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

