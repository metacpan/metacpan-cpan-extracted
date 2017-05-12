#!/perl

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use File::Temp;
use strict;
$Tree::Family::Person::keyMethod = 'first_name';
our $tmp = File::Temp->new;
our $tmpfile = $tmp->filename;

#
#     a --- B --- c
#        |     |
#        d     e
#
my ($a_id,$b_id,$c_id,$d_id,$e_id);
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $a = Tree::Family::Person->new(first_name => 'a', gender => 'f');
    my $b = Tree::Family::Person->new(first_name => 'b', gender => 'm');
    my $c = Tree::Family::Person->new(first_name => 'c', gender => 'f');
    my $d = Tree::Family::Person->new(first_name => 'd', gender => 'm');
    my $e = Tree::Family::Person->new(first_name => 'e', gender => 'f');
    $d->mom($a);
    $d->dad($b);
    $e->mom($c);
    $e->dad($b);
    $tree->add_person($_) for ($a,$b,$c,$d,$e);
    $tree->write;
    ($a_id,$b_id,$c_id,$d_id,$e_id) = map $_->id, ($a,$b,$c,$d,$e);
}

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),5, "saved, got 5 people";
    my $b = $tree->find(first_name => 'b');
    my $tmpdot = File::Temp->new;
    my $dotfile = $tmpdot->filename;
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


