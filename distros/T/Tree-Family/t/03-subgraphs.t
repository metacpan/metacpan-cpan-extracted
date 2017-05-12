#!/perl

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use Data::Dumper;
$Tree::Family::Person::keyMethod = 'first_name';
use strict;

use File::Temp;
$File::Temp::KEEP_ALL = $ENV{TREE_FAMILY_KEEP_TESTS} if exists($ENV{TREE_FAMILY_KEEP_TESTS});
our $tmp = File::Temp->new(TEMPLATE => 'treefile.XXXXXX');
our $tmpfile = $tmp->filename;


#
#  a <--> B ----- c
#             |
#             d
#
my ($a_id,$b_id,$c_id,$d_id);
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    warn "file is $tmpfile";
    my $a = Tree::Family::Person->new(first_name => 'a', gender => 'f');
    my $b = Tree::Family::Person->new(first_name => 'b', gender => 'm');
    my $c = Tree::Family::Person->new(first_name => 'c', gender => 'f');
    my $d = Tree::Family::Person->new(first_name => 'd', gender => 'f');
    ($a_id,$b_id,$c_id,$d_id) = map $_->id, ($a,$b,$c,$d);
    $a->spouse($b);
    $d->dad($b);
    $d->mom($c);
    $tree->add_person($_) for ($a,$b,$c,$d);
    $tree->write;
}

# %Tree::Family::Person::globalHash = ();

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),4, "saved, got 4 people";
    my $b = $tree->find(first_name => 'b');
    my @foo = $tree->_partner_and_marriage_group($b);
    is @foo+0,3,"3 people in group";
    #diag " we have ".Dumper(\%Tree::Family::Person::globalHash);
    my $dot = $tree->as_dot;
    # like $dot, qr/$a_id -- $b_id/, "$a_id<-->$b_id is in the dot file";
    # like $dot,"$b_id -- $b_id\_$c_id -- $c_id { rank=same;$b_id $c_id $b_id\_$c_id }") > 1, "$b_id and $c_id have a kid in the graph";
    ok index($dot, "$b_id\_$c_id -- $d_id") > 1, 'd is the kid of b and c';
    my $tmp_dotfile = File::Temp->new;
    my $dotfile = $tmp_dotfile->filename;
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


