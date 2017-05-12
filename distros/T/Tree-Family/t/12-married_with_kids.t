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
# a -+- b --- c -+- d
#          |
#          e
#
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $a = Tree::Family::Person->new(first_name => 'a',   gender => 'm');
    my $b = Tree::Family::Person->new(first_name => 'b',   gender => 'f');
    my $c = Tree::Family::Person->new(first_name => 'c',   gender => 'm');
    my $d = Tree::Family::Person->new(first_name => 'd',   gender => 'f');
    my $e = Tree::Family::Person->new(first_name => 'e',   gender => 'm');
    $a->spouse($b);
    $c->spouse($d);
    $e->mom($b);
    $e->dad($c);
    $tree->add_person($_) for ($a,$b,$c,$d,$e);
    $tree->write;
}

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),5, "saved, got 5 people";
    my $dotfile = "/tmp/dotfile.$$";
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


