#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Trek through a tree one character at a time.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Trek;
our $VERSION = "20210424";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

my $debug = -e q(/home/phil/);                                                  # Developing

#D1 Tree::Trek                                                                  # Methods to create a  trekkable tree.

sub node(;$)                                                                    # Create a new node
 {my ($parent) = @_;                                                            # Optional parent
  genHash(__PACKAGE__,
    jumps  => {},                                                               # {character => node}
    data   => undef,                                                            # The data attached to this node
    parent => $parent,                                                          # The node from whence we came
   );
 }

sub put($$)                                                                     # Add a key to the tree
 {my ($tree, $key) = @_;                                                        # Tree, key

  return $tree unless $key;                                                     # Key is empty so we have found the desired node

  my $c = substr $key, 0, 1;                                                    # Next character of the key

  if (exists $tree->jumps->{$c})                                                # Jump through existing node
   {return $tree->jumps->{$c}->put(substr $key, 1);
   }
  else                                                                          # Create a new node and jump through it
   {my $n = $tree->jumps->{$c} = node $tree;
    return $n->put(substr $key, 1);
   }
 }

sub key($)                                                                      # Return the key of a node
 {my ($node) = @_;                                                              # Node
  if (my $p = $node->parent)
   {for my $c(sort keys $p->jumps->%*)
     {if ($p->jumps->{$c} == $node)
       {return $p->key . $c;
       }
     }
    confess "Child missing in parent";                                          # This should not happen
   }
  ''                                                                            # The key of the root node
 }

sub find($$)                                                                    # Find a key in a tree - return its node if such a node exists else undef
 {my ($tree, $key) = @_;                                                        # Tree, key

  return $tree unless $key;                                                     # We have exhausted the key so this must be the node in question as long as it has no jumps

  my $c = substr $key, 0, 1;

  if (exists $tree->jumps->{$c})                                                # Continue search
   {return $tree->jumps->{$c}->find(substr $key, 1);
   }
  undef                                                                         # Not found
 }

sub delete($)                                                                   # Remove a node from a tree
 {my ($node) = @_;                                                              # Node to be removed

  my $clear = sub                                                               # Clear the parent's jumps if possible
   {my ($child) = @_;                                                           # Child of parent
    if (my $p = $child->parent)
     {for my $c(keys $p->jumps->%*)
       {if ($p->jumps->{$c} == $child)
         {delete $p->jumps->{$c};
         }
       }
      __SUB__->($p) unless keys $p->jumps->%*;
     }
   };

  $node->data = undef;                                                          # Clear data
  $clear->($node) unless (keys $node->jumps->%*);                               # No jumps from this node and no data so we can clear it from the parent
  $node
 }

sub count($)                                                                    # Count the nodes addressed in the specified tree
 {my ($node) = @_;                                                              # Node to be counted from
  my $n = $node->data ? 1 : 0;                                                  # Count the nodes addressed in the specified tree
  for my $c(keys $node->jumps->%*)                                              # Each possible child
   {$n += $node->jumps->{$c}->count;                                            # Each child of the parent
   }
  $n                                                                            # Count
 }

sub traverse($)                                                                 # Traverse a tree returning an array of nodes
 {my ($node) = @_;                                                              # Node to be counted from
  my @n;
  push @n, $node if $node->data;
  for my $c(sort keys $node->jumps->%*)                                         # Each possible child in key order
   {push @n, $node->jumps->{$c}->traverse;
   }
  @n
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Trek - Trek through a tree one character at a time.

=head1 Synopsis

Create a trekkable tree and trek through it:

  my $n = node;

  $n->put("aa") ->data = "AA";
  $n->put("ab") ->data = "AB";
  $n->put("ba") ->data = "BA";
  $n->put("bb") ->data = "BB";
  $n->put("aaa")->data = "AAA";

  is_deeply [map {[$_->key, $_->data]} $n->traverse],
   [["aa",  "AA"],
    ["aaa", "AAA"],
    ["ab",  "AB"],
    ["ba",  "BA"],
    ["bb",  "BB"]];

=head1 Description

Trek through a tree one character at a time.


Version "20210424".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Tree::Trek

Methods to create a  trekkable tree.

=head2 node($parent)

Create a new node

     Parameter  Description
  1  $parent    Optional parent

B<Example:>


  if (1)                                                                                
  
   {my $n = node;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;
  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;
  
    ok  $n->find("a");
    ok !$n->find("b");
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }
  

=head2 put($tree, $key)

Add a key to the tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)                                                                                
   {my $n = node;
  
    $n->put("aa")->data = "AA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $n->put("ab")->data = "AB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $n->put("ba")->data = "BA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $n->put("bb")->data = "BB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $n->put("aaa")->data = "AAA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $n->count, 5;
  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;
  
    ok  $n->find("a");
    ok !$n->find("b");
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }
  

=head2 key($node)

Return the key of a node

     Parameter  Description
  1  $node      Node

B<Example:>


  if (1)                                                                                
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;
  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;
  
    ok  $n->find("a");
    ok !$n->find("b");
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }
  

=head2 find($tree, $key)

Find a key in a tree - return its node if such a node exists else undef

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)                                                                                
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;
  
  
    is_deeply $n->find("aa") ->data, "AA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $n->find("ab") ->data, "AB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $n->find("ba") ->data, "BA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $n->find("bb") ->data, "BB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $n->find("aaa")->data, "AAA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
  
    ok  $n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$n->find("a")->data;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $n->find("b");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$n->find("b")->data;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$n->find("c");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok  $n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$n->find("b");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  !$n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }
  

=head2 delete($node)

Remove a node from a tree

     Parameter  Description
  1  $node      Node to be removed

B<Example:>


  if (1)                                                                                
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;
  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $n->find("a");
    ok !$n->find("b");
  
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  !$n->find("a");
   }
  

=head2 count($node)

Count the nodes addressed in the specified tree

     Parameter  Description
  1  $node      Node to be counted from

B<Example:>


  if (1)                                                                                
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
  
    is_deeply $n->count, 5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $n->find("a");
    ok !$n->find("b");
  
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  !$n->find("a");
   }
  

=head2 traverse($node)

Traverse a tree returning an array of nodes

     Parameter  Description
  1  $node      Node to be counted from

B<Example:>


  if (1)                                                                                
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;
  
    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";
  
  
    is_deeply [map {[$_->key, $_->data]} $n->traverse],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];
  
    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");
  
    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;
  
    ok  $n->find("a");
    ok !$n->find("b");
  
    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }
  


=head1 Index


1 L<count|/count> - Count the nodes addressed in the specified tree

2 L<delete|/delete> - Remove a node from a tree

3 L<find|/find> - Find a key in a tree - return its node if such a node exists else undef

4 L<key|/key> - Return the key of a node

5 L<node|/node> - Create a new node

6 L<put|/put> - Add a key to the tree

7 L<traverse|/traverse> - Traverse a tree returning an array of nodes

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Trek

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::More;

my $localTest = ((caller(1))[0]//'Tree::Trek') eq "Tree::Trek";                 # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 30;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

#goto latest;

if (1)                                                                          #Tnode #Tput #Tfind #Tcount #Ttraverse #Tdelete #Tkey
 {my $n = node;
  $n->put("aa")->data = "AA";
  $n->put("ab")->data = "AB";
  $n->put("ba")->data = "BA";
  $n->put("bb")->data = "BB";
  $n->put("aaa")->data = "AAA";
  is_deeply $n->count, 5;

  is_deeply $n->find("aa") ->data, "AA";
  is_deeply $n->find("ab") ->data, "AB";
  is_deeply $n->find("ba") ->data, "BA";
  is_deeply $n->find("bb") ->data, "BB";
  is_deeply $n->find("aaa")->data, "AAA";

  is_deeply [map {[$_->key, $_->data]} $n->traverse],
   [["aa",  "AA"],
    ["aaa", "AAA"],
    ["ab",  "AB"],
    ["ba",  "BA"],
    ["bb",  "BB"]];

  ok  $n->find("a");
  ok !$n->find("a")->data;
  ok  $n->find("b");
  ok !$n->find("b")->data;
  ok !$n->find("c");

  ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
  ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
  ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
  ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

  ok  $n->find("a");
  ok !$n->find("b");

  ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
  ok  !$n->find("a");
 }

lll "Finished:", time - $start;
