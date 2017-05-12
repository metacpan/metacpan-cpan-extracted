#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;
use XML::XPathEngine;

BEGIN { push @INC, './t'; }

my $tree = init_tree();
my $xp   = XML::XPathEngine->new;

#warn $tree->as_xml, "\n\n";

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

is( $xp->findvalue( '//kid1[@att1=~/v[345]/]', $tree), 'vkid3vkid5', "match on attributes");

is( $xp->findvalue( '//@*', $tree), 'i1v1i2v1i3vvi4vx1i5v2i6vvi7vx0i8v3i9vvi10vx1i11v4i12vvi13vx0i14v5i15vvi16vx1i17', 'match all attributes');
is( $xp->findvalue( '//@*[parent::*/@att1=~/v[345]/]', $tree), 'v3i9v4i12v5i15', 'match all attributes with a test');

is( $xp->findvalue( '//kid1[@att1="v3"]/following::gkid2[1]', $tree), 'gkid2 4', "following axis[1]");
is( $xp->findvalue( '//kid1[@att1="v3"]/following::gkid2[2]', $tree), 'gkid2 5', "following axis[2]");
is( $xp->findvalue( '//kid1[@att1="v3"]/following::kid1/*', $tree), 'gvkid5gkid2 5', "following axis");
is( $xp->findvalue( '//kid1[@att1="v3"]/preceding::gkid2[1]', $tree), 'gkid2 2', "preceding axis[1]");
is( $xp->findvalue( '//kid1[@att1="v3"]/preceding::gkid2[2]', $tree), 'gkid2 1', "preceding axis[1]");
is( $xp->findvalue( '//kid1[@att1="v3"]/preceding::gkid2', $tree), 'gkid2 1gkid2 2', "preceding axis");

is( $xp->findvalue( 'count(//kid1)', $tree), '3', 'count( //gkid1)');
is( $xp->findvalue( 'count(//gkid2)', $tree), '5', 'count( //gkid2)');

is( $xp->findvalue( 'count(/root[count(.//kid1)=count(.//gkid1)])', $tree), 1, 'count() in expression (count(//kid1)=count(//gkid1))');
is( $xp->findvalue( 'count(/root[count(.//kid1)>count(.//gkid1)])', $tree), 0, 'count() in expression (returns 0)');
is( $xp->findvalue( 'count(/root[count(.//kid1)=count(.//gkid2)])', $tree), 0, 'count() in expression (returns 1)');
is( $xp->findvalue( 'count( root/*[count( ./gkid0) = 1])', $tree), 2, 'count() in expression (root/*[count( ./gkid0) = 1])');

is( $xp->findvalue( 'count(//gkid2[@att2="vx" and @att3=1])', $tree), 3, 'count with and');
is( $xp->findvalue( 'count(//gkid2[@att2="vx" and @att3])', $tree), 5, 'count with and');
is( $xp->findvalue( 'count(//gkid2[@att2="vx" or @att3])', $tree), 5, 'count with or');

#warn $xp->findvalue( './/*/@id', $tree);
is( $xp->findvalue( '(.//*)[2]/@id', $tree), 'i3', '(descendant::*)[2]');

is( $xp->findvalue( '//kid1[@att1="v3"]/following::gkid2[1]', $tree), 'gkid2 4', "following axis[1]");
is( $xp->findvalue( '//kid1[@att1="v3"]/following::gkid2[2]', $tree), 'gkid2 5', "following axis[2]");

is( $xp->findvalue( 'id("i2")/@att1', $tree), 'v1', 'id()');
is( $xp->findvalue( 'substring-after(//kid1[1]/@att1, "v")', $tree), '1', 'substring-after');
is( $xp->findvalue( 'id("i3")//*[1]/@att2', $tree), 'vv', 'id descendants attribute');
is( $xp->findvalue( '(id("i3")//*)[1]/@att2', $tree), 'vv', 'grouped id descendants attribute');
is( $xp->findvalue( 'substring-after((id("i2")//*[1])/@att2, "v")', $tree), 'v', 'substring-after(id())');

is( join( '|', $xp->findvalues( '//kid1[@att1=~/v[345]/]', $tree)), 'vkid3|vkid5', "findvalues match on attributes");
is( join( '|', $xp->findvalues( '//kid1[@att1=~/v[345]/]/@id', $tree)), 'i9|i15', "findvalues on attributes");

is( $xp->findvalue( '2', $tree), 2, 'findvalues on a litteral'); 
is( $xp->findvalue( '//gkid1="gvkid1"', $tree), 1, 'findvalues on a litteral'); 
eval {  $xp->findvalues( '//gkid1="gvkid1"/ggkid', $tree); };
like( $@, qr/cannot get child nodes of a literal/, 'children axis from a litteral');
eval {  $xp->findvalues( '//gkid1="gvkid1"/../gkid1', $tree); };
like( $@, qr/cannot get parent node of a literal/, 'parent axis from a litteral');
eval {  $xp->findvalues( '//gkid1="gvkid1"/@att', $tree); };
like( $@, qr/cannot get attributes of a literal/, 'attribute axis from a litteral');

done_testing();

sub init_tree
  { my $id=0;

    my $tree  = tree->new( 'att', name => 'tree', value => 'tree', id => "i" . ++$id);
    my $root  = tree->new( 'att', name => 'root', value => 'root_value', att1 => 'v1', id => "i" . ++$id);
    $root->add_as_last_child_of( $tree);


    foreach (1..5)
      { my $kid= tree->new( 'att', name => 'kid' . $_ % 2, value => "vkid$_", att1 => "v$_", id => "i" . ++$id);
        $kid->add_as_last_child_of( $root);
        my $gkid1= tree->new( 'att', name => 'gkid' . $_ % 2, value => "gvkid$_", att2 => "vv", id => "i" . ++$id);
        $gkid1->add_as_last_child_of( $kid);
        my $gkid2= tree->new( 'att', name => 'gkid2', value => "gkid2 $_", att2 => "vx", att3 => $_ % 2, id => "i" . ++$id);
        $gkid2->add_as_last_child_of( $kid);
      }

    $tree->set_pos;

    return $tree;
  }

package tree;
use base 'minitree';

sub getName            { return shift->name;  }
sub getValue           { return shift->value; }
sub string_value       { return shift->value; }
sub getRootNode        { return shift->root;                }
sub getParentNode      { return shift->parent;              }
sub getChildNodes      { return wantarray ? shift->children : [shift->children]; }
sub getFirstChild      { return shift->first_child;         }
sub getLastChild       { return shift->last_child;         }
sub getNextSibling     { return shift->next_sibling;        }
sub getPreviousSibling { return shift->previous_sibling;    }
sub isElementNode      { return 1;                          }
sub isAttributeNode    { return 0;                          }
sub get_pos            { return shift->pos;          }
sub getAttributes      { return wantarray ? @{shift->attributes} : shift->attributes; }
sub as_xml 
  { my $elt= shift;
    return "<" . $elt->getName . join( "", map { " " . $_->getName . '="' . $_->getValue . '"' } $elt->getAttributes) . '>'
           . (join( "\n", map { $_->as_xml } $elt->getChildNodes) || $elt->getValue)
           . "</" . $elt->getName . ">"
           ;
  }

sub cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

sub getElementById
  { my $elt = shift;
    my $id = shift;
    foreach ( @{$elt->attributes} ) {
    	$_->getName eq 'id' and $_->getValue eq $id and return $elt;
    }
    foreach ( $elt->getChildNodes ) {
    	return $_->getElementById($id);
    }
}


1;

package att;
use base 'attribute';

sub getName            { return shift->name;                }
sub getValue           { return shift->value;               }
sub string_value       { return shift->value; }
sub getRootNode        { return shift->parent->root;        }
sub getParentNode      { return shift->parent;              }
sub isAttributeNode    { return 1;                          }
sub getChildNodes      { return ; }

sub cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

sub getElementById
  { return shift->getParentNode->getElementById( @_); }


1;

