#!/perl

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use File::Temp;
use strict;
$Tree::Family::Person::keyMethod = 'first_name';
$File::Temp::KEEP_ALL = $ENV{TREE_FAMILY_KEEP_TESTS} if exists($ENV{TREE_FAMILY_KEEP_TESTS});
our $tmp = File::Temp->new;
our $tmpfile = $tmp->filename;


#
#     c --- D -+- e
#        |
#  a -+- B
#
my ($a_id,$b_id,$c_id,$d_id,$e_id);
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $a = Tree::Family::Person->new(first_name => 'a', gender => 'f');
    my $b = Tree::Family::Person->new(first_name => 'b', gender => 'm');
    my $c = Tree::Family::Person->new(first_name => 'c', gender => 'f');
    my $d = Tree::Family::Person->new(first_name => 'd', gender => 'm');
    my $e = Tree::Family::Person->new(first_name => 'e', gender => 'f');
    $a->spouse($b);
    $b->mom($c);
    $b->dad($d);
    $d->spouse($e);
    $tree->add_person($_) for ($a,$b,$c,$d,$e);
    $tree->write;
    ($a_id,$b_id,$c_id,$d_id,$e_id) = map $_->id, ($a,$b,$c,$d,$e);
}

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),5, "saved, got 5 people";
    my $b = $tree->find(first_name => 'b');
    my @foo = $tree->_partner_and_marriage_group($b);
    is @foo+0,2,"2 people in group";
    my $dot = $tree->as_dot;
    #ok index($dot,"subgraph cluster_$a_id\_$b_id { $a_id -- $b_id { rank=same;$a_id $b_id } }") > 1, "$a_id<-->$b_id is in the dot file";
    #ok index($dot,"$b_id -- $b_id\_$c_id -- $c_id { rank=same;$b_id $c_id $b_id\_$c_id }") > 1, "$b_id and $c_id have a kid in the graph";
    #ok index($dot, "$b_id\_$c_id -- $d_id") > 1, 'd is the kid of b and c';

    my $tmpdot = File::Temp->new;
    my $dotfile = $tmpdot->filename;
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


