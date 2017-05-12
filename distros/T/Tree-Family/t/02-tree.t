#!perl 

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use Data::Dumper;
use strict;
use warnings;

use File::Temp;
$File::Temp::KEEP_ALL = $ENV{TREE_FAMILY_KEEP_TESTS} if exists($ENV{TREE_FAMILY_KEEP_TESTS});
our $tmp = File::Temp->new;
our $tmpfile = $tmp->filename;

# $Tree::Family::Person::keyMethod = 'first_name';

# 
# Make this tree (uppercase = male, lowercase = female) :
#
#           A --- b           C -- d
#              |                |
#        ------------     -----------------
#        |     |    |     |     |     |   |
#        e     f    G-----h     I     j   K ---- l
#                      |                     
#                  -----------
#                  |         |
#                  m         N----o
#                              |
#                              P
#
# all couples are married except N and o
#
diag "Making temporary file $tmpfile";
my $number_of_people;
{
    my %l = map { ($_ => Tree::Family::Person->new(first_name => $_, gender => 'f')) } qw(b d e f h j l m o);
    my %m = map { (lc $_ => Tree::Family::Person->new(first_name => $_, gender => 'm')) } qw(A C G I K N P);
    my %p = (%l, %m);

    # kids
    do { $p{$_}->dad($p{a}); $p{$_}->mom($p{b}) } for qw(e f g);
    #diag "globalhash is ".Dumper(\%Tree::Family::Person::globalHash);
    do { $p{$_}->dad($p{c}); $p{$_}->mom($p{d}) } for qw(h i j k);
    do { $p{$_}->dad($p{g}); $p{$_}->mom($p{h}) } for qw(m n);
    $p{p}->dad($p{n});
    $p{p}->mom($p{o});

    # marriages
    $p{a}->spouse($p{b});
    $p{c}->spouse($p{d});
    $p{g}->spouse($p{h});
    $p{k}->spouse($p{l});

    my $tree = Tree::Family->new(filename => $tmpfile);
    $tree->add_person($_) for values %p;
    $number_of_people = values %p;
    my $result = $tree->write;
    ok $result, "wrote successfully to $tmpfile";
}

#
# Writing updates the fields generations, partners
#

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my @people = $tree->people;
    is (@people+0,$number_of_people,"Saved and retrieved $number_of_people people");
    my $g = $tree->find(first_name => 'G');
    ok (defined($g), 'found person');
    is $g->get('first_name'), 'G', "first_name is G";
    ok defined($g->spouse), "g's spouse is defined";
    #diag "globalhash is ".Dumper(\%Tree::Family::Person::globalHash);
    my $spouse = $g->spouse;
    diag "spouse is $spouse"; # oops, ref to a ref
    cmp_ok $g->spouse->get('first_name'), 'eq', 'h', "spouse's name";
    is scalar($g->kids),2, "has 2 kids";
    is scalar($g->dad->kids), 3, 'has 2 siblings';
    my $n = $tree->find(first_name => 'N');
    my @n_kids = $n->kids;
    is $n_kids[0]->get('first_name'),'P', 'kids name';
    is $n_kids[0]->get('gender'),'m','gender';
    my @o_partners = $tree->find(first_name => 'o')->partners;
    is @o_partners+0, 1, 'o has a partner';
    is $o_partners[0]->get('first_name'), 'N', "o's partner is N";
}
{   # generations
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $generation = $tree->find(first_name => 'A')->get('generation');
    ok defined($generation), 'Got a generation for A';
    for (qw(b C d)) {
        is $tree->find(first_name => $_)->get('generation'), $generation, "first generation is $generation";
    }
    for (qw(e f G h I j K l)) {
        is $tree->find(first_name => $_)->get('generation'), $generation + 1, "second generation: $_ ";
    }
    for (qw(m N o)) {
        is $tree->find(first_name => $_)->get('generation'), $generation + 2, "third generation: $_";
    }
    for (qw(P)) {
        is $tree->find(first_name => $_)->get('generation'), $generation + 3, "fourth generation: $_";
    }
    my @p = $tree->find(generation => $generation + 2);
    is (scalar(@p), 3, 'three people in third generation');
    my $min = $tree->min_generation;
    my $max = $tree->max_generation;
    is ($max, $min + 3, '3 generations');
}
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $xxx = Tree::Family::Person->new;
    $xxx->first_name('xxx');
    my $p = $tree->find(first_name => 'P');
    ok defined($p), "found p";
    $xxx->spouse($p);
    $tree->add_person($xxx);
    $tree->write;
}
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $xxx = $tree->find(first_name => 'xxx');
    ok defined($xxx), 'found xxx';
    ok $xxx->spouse;
    is $xxx->spouse->first_name, 'P', "added a spouse";
    my $p = $tree->find(first_name => 'P');
    is $p->spouse->first_name, 'xxx', 'reciprication';
}



