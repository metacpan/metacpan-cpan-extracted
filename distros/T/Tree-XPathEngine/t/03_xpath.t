#!/usr/bin/perl 
# $Id: /tree-xpathengine/trunk/t/03_xpath.t 22 2006-02-13T14:00:25.731780Z mrodrigu  $

use strict;
use warnings;

use Test::More qw( no_plan);
use Tree::XPathEngine;

BEGIN { push @INC, './t'; }

my $tree = init_tree();
my $xp   = Tree::XPathEngine->new;

is( $xp->findvalue( '/root/kid[@id="k-2" or @id="k-4"]', $tree), 'vkid-2vkid-4', "or expression");

is( $xp->findvalue( '/root/kid[@id="k-2" and @id="k-4"]', $tree), '', "and expression (no return)");
is( $xp->findvalue( '/root/kid[@id="k-2" and position()=1]', $tree), 'vkid-2', "and expression");

is( $xp->findvalue( '//@att1[.>2]', $tree), '345', ">");
is( $xp->findvalue( '//@att1[.>=2]', $tree), '2345', ">=");
is( $xp->findvalue( '//@att1[.<2]', $tree), '11', "<");
is( $xp->findvalue( '//@att1[.<=2]', $tree), '112', "<=");
is( $xp->findvalue( '//@att1[.=2]', $tree), '2', "=");
is( $xp->findvalue( '//@att1[.!=2]', $tree), '11345', "!=");
is( $xp->findvalue( '//@att2[.="vv"]', $tree), "vv"x10, "= (string)");

is( $xp->findvalue( '//@att1[.+1>2]', $tree), '2345', "> and +");
is( $xp->findvalue( '//@att1[.-1>2]', $tree), '45', "> and -");
is( $xp->findvalue( '//@att1[.*2>2]', $tree), '2345', "> and *");
is( $xp->findvalue( '//@att1[. div 2 > 2]', $tree), '5', "> and div");
is( $xp->findvalue( '//@att1[. mod 2 = 1]', $tree), '1135', "> and mod");
is( $xp->findvalue( '//@att1[ -. < -3]', $tree), '45', "> and unary -");


is( $xp->findvalue( '//root | //@att1[ . > 4] | /root/kid[@*="k-3"]' , $tree), 'vrootvkid-35', "|");

is( $xp->findvalue( '/root//gkid1[..//gkid2[@id="gk2-3"]]/@id', $tree), 'gk1-3', '// in the path');
is( $xp->findvalue( '/root//gkid1[..//gkid2[@id="gk2-3"]]/@id', $tree), 'gk1-3', '// in the path');
is( $xp->findvalue( '/root//gkid1[//gkid2[@id="gk2-3"]]/@id', $tree), 'gk1-1gk1-2gk1-3gk1-4gk1-5', '// in the predicate');

is( $xp->findvalue( '2', $tree), '2', 'constant');
is( $xp->findvalue( '2 = (1 + 1)', $tree), 'true', 'boolean constant (true)');
is( $xp->findvalue( '2 = (1 + 2)', $tree), '', 'boolean constant (false)');
is( $xp->findvalue( '"foo"', $tree), 'foo', 'literal constant');

is( $xp->findvalue( '(2 = (1 + 1)) > ( 2 = 3) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) >= ( 2 = 3) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) = ( 2 = 2) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) < ( 2 = 3) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) <= ( 2 = 3) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) != ( 2 = 2) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) < ( 2 = 3) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) <= ( 2 = 3) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) != ( 2 = 2) ', $tree), '', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) > ( 2 = 3) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) >= ( 2 = 3) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '(2 = (1 + 1)) = ( 2 = 2) ', $tree), 'true', 'boolean comparison');
is( $xp->findvalue( '"true" = ( 2 = 2) ', $tree), 'true', 'boolean thingies');
is( $xp->findvalue( '"" = ( 2 = 3) ', $tree), 'true', 'boolean thingies');


# string functions
is( $xp->findvalue( 'concat( "foo", "bar")', $tree), 'foobar', 'concat');
is( $xp->findvalue( 'starts_with( "foobar", "foo")', $tree), 'true', 'starts_with (true)');
is( $xp->findvalue( 'starts_with( "foobar", "bar")', $tree), '', 'starts_with (false)');
is( $xp->findvalue( 'contains( "foobar", "foo")', $tree), 'true', 'contains (true)');
is( $xp->findvalue( 'contains( "foobar", "baz")', $tree), '', 'contains (false)');
is( $xp->findvalue( 'substring-before("1999/04/01","/")', $tree), '1999', 'substring-before (success)');
is( $xp->findvalue( 'substring-before("1999/04/01",":")', $tree), '', 'substring-before (failure)');
is( $xp->findvalue( 'substring-after("1999/04/01","/")', $tree), '04/01', 'substring-after (success)');
is( $xp->findvalue( 'substring-before("1999/04/01",":")', $tree), '', 'substring-after (failure)');
is( $xp->findvalue( 'substring("1999/04/01", 1, 4)', $tree), '1999', 'substring (leading substring)');
is( $xp->findvalue( 'substring("1999/04/01", 6, 2)', $tree), '04', 'substring');
is( $xp->findvalue( 'substring("1999/04/01", 6)', $tree), '04/01', 'substring (no 3rd argument)');
is( $xp->findvalue( 'string-length("1999/04/01")', $tree), '10', 'string-length');
is( $xp->findvalue( 'string-length("")', $tree), '', 'string-length (empty string)');
is( $xp->findvalue( 'normalize-space("foo  bar")', $tree), 'foo bar', 'normalize-space');
is( $xp->findvalue( 'normalize-space("foo  bar ")', $tree), 'foo bar', 'normalize-space');
is( $xp->findvalue( 'normalize-space("  foo  bar ")', $tree), 'foo bar', 'normalize-space');
is( $xp->findvalue( 'normalize-space("  foo  bar   baz")', $tree), 'foo bar baz', 'normalize-space');
is( $xp->findvalue( 'translate("bar","abc","ABC")', $tree), 'BAr', 'translate');
is( $xp->findvalue( 'translate("--aaa--","abc-","ABC")', $tree), 'AAA', 'translate (with deletion)');
is( $xp->findvalue( 'translate("--aada--","abc-","ABC")', $tree), 'AAdA', 'translate (with deletion and untouched char)');

is( $xp->findvalue( 'true()', $tree), 'true', 'true');
is( $xp->findvalue( 'false()', $tree), '', 'false');
is( $xp->findvalue( 'not(false())', $tree), 'true', 'not');
is( $xp->findvalue( 'boolean(1)', $tree), 'true', 'boolean (true)');
is( $xp->findvalue( 'boolean(0)', $tree), '', 'boolean (false)');

is( $xp->findvalue( 'number(1)', $tree), '1', 'number');
is( $xp->findvalue( '"1" = "1.0"', $tree), '', 'number equals (false)');
is( $xp->findvalue( '1 = "1.0"', $tree), 'true', 'number equals (conversion, true)');
is( $xp->findvalue( '1 = number("1.0")', $tree), 'true', 'number equals (true)');
is( $xp->findvalue( 'number( //kid[1]/@att1)', $tree), '1', 'number (node)');
is( $xp->findvalue( 'number( //kid[1]/@att1)="1.0"', $tree), 'true', 'number equals (node, true)');
is( $xp->findvalue( '//kid[1]/@att1[number(.)="1.0"]', $tree), '1', 'number equals (on (current) node)');
is( $xp->findvalue( '//kid[1]/@att1[number()="1.0"]', $tree), '1', 'number equals (on default (current) node)');
is( $xp->findvalue( ' (//kid[1]/@att1)="1.0"', $tree), '', 'number equals (node, false)');
is( $xp->findvalue( ' sum(//kid/@att1)', $tree), 15, "sum (nodes)");


is( $xp->findvalue( 'count( //gkid1)', $tree), 5, "count");


{ my $gk= ($xp->findnodes( '//gkid1', $tree))[0];
  ok( $xp->matches( $gk, '//*[@att2="vv"]', $tree), 'matches');
}

is( $xp->findvalue( '//kid[@att1>2][2]', $tree), "vkid-4", "2 predicates");
is( $xp->findvalue( '//kid[@*=2]', $tree), "vkid-2", "= on a nodeset");
is( $xp->findvalue( '//kid[@*=@id][2]', $tree), "vkid-2", "= on 2 nodesets");
is( $xp->findvalue( '//kid[@*>=@id][2]', $tree), "vkid-2", ">= on 2 nodesets");
is( $xp->findvalue( '//kid[@*<(@id+1)][2]', $tree), "vkid-2", "< on 2 nodesets");
is( $xp->findvalue( '//kid[@*>(@id - 1)][2]', $tree), "vkid-2", "> on 2 nodesets");
is( $xp->findvalue( '//kid[@* != @id][2]', $tree), "", "!= on 2 nodesets (no hit)");
is( $xp->findvalue( '//kid[@* != @id * 2][2]', $tree), "", "!= on 2 nodesets (no hit)");
is( $xp->findvalue( '//kid[@*=~ m/^\d$/][2]', $tree), "vkid-2", "=~ on 2 nodesets");
is( $xp->findvalue( '//kid[@*!~ m/^\d$/][2]', $tree), "vkid-2", "!~ on 2 nodesets");


{ my $gk= ($xp->findnodes( '//gkid1', $tree))[0];
  is( $xp->findvalue( '@att2="vv"', $gk), 'true','predicate only');
}

is( $xp->findvalue( '//@id[.="gk1-4"]/../ancestor::*[@att2="vv"]', $tree), 'vkid-4', 'ancestor (with wc)');
is( $xp->findvalue( '//@id[.="gk1-4"]/ancestor::*[@att2="vv"]', $tree), 'vkid-4vgkid1-4', 'ancestor (with wc, 1)');
is( $xp->findvalue( '//@id[.="gk1-4"]/../ancestor-or-self::*[@att2="vv"]', $tree), 'vkid-4vgkid1-4', 'ancestor-or-self (with wc)');
is( $xp->findvalue( '//@att2/ancestor::kid[@id="k-4"]', $tree), 'vkid-4', 'ancestor');
is( $xp->findvalue( '//@att2/ancestor-or-self::kid[@id="k-4"]', $tree), 'vkid-4', 'ancestor-or-self');

is( $xp->findvalue( '//*[string()="vgkid2-3"]', $tree), 'vgkid2-3', 'string()');


is(  $xp->findvalue( '//*[string()=~ /^vgkid2-3/]', $tree), 'vgkid2-3', 'match (/ delimited) on string()');
is(  $xp->findvalue( '//*[string()=~ /^vg(\/|kid)2-3/]', $tree), 'vgkid2-3', 'match (/ delimited, \/) on string()');
is(  $xp->findvalue( '//*[string()=~ /^vg(\/|kid)2-3/]', $tree), 'vgkid2-3', 'match (/ delimited, \/) on string()');
is(  $xp->findvalue( '//*[string()=~ /^vg(!|\/|kid)2-3/]', $tree), 'vgkid2-3', 'match (/ delimited, !,\/) on string()');
is(  $xp->findvalue( '//*[string()=~ /^vgkid2-[24]/]', $tree), 'vgkid2-2vgkid2-4', 'match (/ delimited) on string() (x)');

is( $xp->findvalue( '//*[@id="k-4"]/preceding-sibling::*[1]', $tree), 'vkid-3', 'preceding-sibling (1)');
is( $xp->findvalue( '//*[@id="k-4"]/preceding-sibling::*', $tree), 'vkid-1vkid-2vkid-3', 'preceding-sibling (x)');
is( $xp->findvalue( '//*[@id="k-4"]/following-sibling::*[1]', $tree), 'vkid-5', 'preceding-sibling (1)');
is( $xp->findvalue( '//*[@id="k-3"]/following-sibling::*', $tree), 'vkid-4vkid-5', 'preceding-sibling (x)');
is( $xp->findvalue( '//*[@id="k-5"]/following-sibling::*', $tree), '', 'preceding-sibling (x)');
is( $xp->findvalue( '//*[@id="k-4"]/preceding::*[1]', $tree), 'vgkid1-1', 'preceding(1)');
is( $xp->findvalue( '//*[@id="k-4"]/following::*[1]', $tree), 'vgkid1-5', 'following(1)');

is( $xp->findvalue( '//kid[//@id="k-4"][2]', $tree), 'vkid-2', '//in predicate');
is( $xp->findvalue( '//kid[//@id="k-8"][2]', $tree), '', '//in predicate (empty result)');

{  sub init_tree
  { my $tree  = tree->new( 'att', name => 'tree', value => 'vtree', id =>'t-1');
    my $root  = tree->new( 'att', name => 'root', value => 'vroot', att1 => '1', id => 'r-1');
    $root->add_as_last_child_of( $tree);

    foreach (1..5)
      { my $kid= tree->new( 'att', name => 'kid', value => "vkid-$_", att1 => "$_", att2 => "vv", id=> "k-$_");
        $kid->add_as_last_child_of( $root);
        my $gkid1= tree->new( 'att', name => 'gkid1', value => "vgkid1-$_", att2 => "vv", id=> "gk1-$_");
        $gkid1->add_as_last_child_of( $kid);
        my $gkid2= tree->new( 'att', name => 'gkid2', value => "vgkid2-$_", att2 => "vx", id=> "gk2-$_");
        $gkid2->add_as_last_child_of( $kid);
      }

    $tree->set_pos;
    #tree->dump_all;

    return $tree;
  }
}

package tree;
use base 'minitree';

sub xpath_get_name             { return shift->name;   }
sub xpath_string_value         { return shift->value;  }
sub xpath_get_root_node        { return shift->root;   }
sub xpath_get_parent_node      { return shift->parent; }
sub xpath_get_child_nodes      { return wantarray ? shift->children : [shift->children]; }
sub xpath_get_next_sibling     { return shift->next_sibling;        }
sub xpath_get_previous_sibling { return shift->previous_sibling;    }
sub xpath_is_element_node      { return 1;                          }
sub xpath_is_attribute_node    { return 0;                          }
sub get_pos              { return shift->pos;          }
sub xpath_get_attributes       { return wantarray ? @{shift->attributes} : shift->attributes; }
sub to_string            
  { my $node= shift; 
    my $name= $node->name;
    my $value= $node->value;
    my $atts= join( ' ', map { $_->to_string } $node->xpath_get_attributes);
    return "[$name {$atts} $value]";
  }
sub xpath_to_number         { return Tree::XPathEngine::Number->new( shift->value);        }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

package att;
use base 'attribute';

sub xpath_get_name          { return shift->name;         }
sub to_string         { my $att= shift; return sprintf( '%s="%s"', $att->xpath_get_name, $att->xpath_get_value) ; }
sub xpath_to_number         { return Tree::XPathEngine::Number->new( shift->value);        }
sub xpath_to_boolean        { return Tree::XPathEngine::Boolean->new( shift->value);       }
sub xpath_string_value      { return shift->value;        }
sub xpath_get_root_node     { return shift->parent->root; }
sub xpath_get_parent_node   { return shift->parent;       }
sub xpath_is_attribute_node { return 1;                   }
sub xpath_is_element_node   { return 0;                   }
sub xpath_get_child_nodes   { return wantarray ? () : []; }

sub xpath_cmp { my( $a, $b)= @_; return $a->pos <=> $b->pos; }

1;

