#!perl 

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use File::Temp;
use strict;
$File::Temp::KEEP_ALL = $ENV{TREE_FAMILY_KEEP_TESTS} if exists($ENV{TREE_FAMILY_KEEP_TESTS});
our $tmp = File::Temp->new;
our $tmpdotfile = File::Temp->new;
our $tmpfile = $tmp->filename;
our $tmpdot = $tmpdotfile->filename;


$Tree::Family::Person::keyMethod = 'first_name';

#
#         abe --- berma   
#              |     
#    carl -- darlene
#
diag "Making temporary file $tmpfile";
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $c = Tree::Family::Person->new(first_name => 'carl', gender => 'm');
    my $d = Tree::Family::Person->new(first_name => 'darlene', gender => 'f');
    my $a = Tree::Family::Person->new(first_name => 'abe', gender => 'm');
    $d->dad($a);
    my $b = Tree::Family::Person->new(first_name => 'berma', gender => 'f');
    $b->spouse($a);
    $c->spouse($d);
    $d->mom($b);
    $tree->add_person($_) for ($a,$b,$c,$d);
    # $tree->write;
    is $a->spouse->first_name, 'berma', 'added berma';
    is $d->mom->first_name, 'berma', 'berma is a mom';
    $tree->delete_person($b);
    $tree->write
}
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    ok $tree->people==3, '3 people in tree';
    my $a = $tree->find(first_name => 'abe');
    my $d = $tree->find(first_name => 'darlene');
    ok !$a->spouse, 'deleted spouse';
    ok !$d->mom, 'deleted mom';
    $tree->delete_person($a);
    ok !$d->dad, 'deleted dad';
    ok $tree->people==2, '2 people in tree';
    my $c = $tree->find(first_name => 'carl');
    $tree->delete_person($c);
    ok !$d->spouse, 'deleted d';
    ok $tree->people==1, '1 left';
    $tree->write;
}
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    ok $tree->people==1, "wrote and re-read $tmpfile";;
    my ($a) = $tree->people;
    ok !$a->spouse, 'no spouse';
    ok !$a->dad, 'no dad';
    ok !$a->mom, 'no mom';
    ok !$a->kids, 'no kids';
    $tree->delete_person($a);
    ok $tree->people==0, 'and then there were none';
    $tree->write;
}
    



