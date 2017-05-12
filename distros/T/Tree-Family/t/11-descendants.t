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
#    a --- B  c --- D
#        \       /
#   E -+- f --- G
#      |     |
#      H     i -+- J
#
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my %p;
    $p{$_} = Tree::Family::Person->new(first_name => $_, gender => 'm')
        for qw(B D E G H J);
    $p{$_} = Tree::Family::Person->new(first_name => $_, gender => 'f')
        for qw(a c f i);
    $p{f}->mom($p{a});
    $p{f}->dad($p{B});
    $p{f}->spouse($p{E});
    $p{G}->mom($p{c});
    $p{G}->dad($p{D});
    $p{H}->mom($p{f});
    $p{H}->dad($p{E});
    $p{i}->mom($p{f});
    $p{i}->dad($p{G});
    $p{i}->spouse($p{J});
    $tree->add_person($_) for values %p;
    $tree->write;
}

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),10, "saved, got 10 people";
    my $tmpdot = File::Temp->new;
    my $dotfile = $tmpdot->filename;
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


