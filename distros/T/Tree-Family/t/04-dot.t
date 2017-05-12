#!perl 

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use strict;
use File::Temp;
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
    $d->mom($b);
    $d->mom($b);
    $d->mom($b);
    $d->mom($b);
    $tree->add_person($_) for ($a,$b,$c,$d);
    $tree->write;
}
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $a = $tree->find(first_name => 'abe');
    my $b = $tree->find(first_name => 'berma');
    ok $a->kids==1, "abe has one kid";
    ok $b->kids==1, "berma has one kid";
    my @k = $a->kids;
    is $k[0]->first_name, 'darlene', 'kid is darlene';
    $tree->write;
    $tree->write_dotfile($tmpdot);
    diag "wrote dotfile $tmpdot";
}



