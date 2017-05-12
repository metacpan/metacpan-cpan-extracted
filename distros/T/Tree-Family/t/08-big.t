#!/perl

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use Data::Faker;
use Text::GenderFromName qw(gender);
use File::Temp;
use strict;
$Tree::Family::Person::keyMethod = 'first_name';
our $Generations = 4;
$File::Temp::KEEP_ALL = $ENV{TREE_FAMILY_KEEP_TESTS} if exists($ENV{TREE_FAMILY_KEEP_TESTS});
our $tmp = File::Temp->new;
our $tmpfile = $tmp->filename;


#
# Two people have kids.  Each of their kids has 1 boy + 1 girl.
# Repeat for several generations.
#
my $tree = Tree::Family->new(filename => $tmpfile);
my $mom = Tree::Family::Person->new(first_name => 'mom',gender => 'f');
my $dad = Tree::Family::Person->new(first_name => 'dad',gender => 'm');
$tree->add_person($_) for ($mom,$dad);

my $faker = Data::Faker->new;
our %used;
sub make_name {
    my $gender = shift;
    my $name;
    do { $name = $faker->first_name; } until 
        !$used{$name} && (gender($name) || 'none') eq $gender;
    $used{$name}++;
    return $name;
}

sub make_descendants {
    my ($n, $mom, $dad, $tree) = @_;
    return unless $n >= 1;
    my $boy = Tree::Family::Person->new(first_name => make_name('m'), gender => "m");
    my $girl = Tree::Family::Person->new(first_name => make_name('f'), gender => "f");
    $boy->mom($mom);
    $boy->dad($dad);
    $girl->mom($mom);
    $girl->dad($dad);
    my $new_wife = Tree::Family::Person->new(first_name => make_name('f'), gender => 'f');
    my $new_husband = Tree::Family::Person->new(first_name => make_name('m'), gender => 'm');
    $boy->spouse($new_wife);
    $girl->spouse($new_husband);
    $tree->add_person($_) for ($boy,$girl,$new_wife,$new_husband);
    make_descendants($n - 1, $girl, $new_husband, $tree);
    make_descendants($n - 1, $new_wife, $boy, $tree);
    make_ascendants($Generations - $n + 1, $new_wife, $tree);
    make_ascendants($Generations - $n + 1, $new_husband, $tree);
}

sub make_ascendants {
    my ($n, $kid, $tree) = @_;
    return unless $n >= 1;
    my $newmom = Tree::Family::Person->new(first_name => make_name('f'), gender => 'f');
    my $newdad = Tree::Family::Person->new(first_name => make_name('m'), gender => 'm');
    $kid->mom($newmom);
    $kid->dad($newdad);
    $newmom->spouse($newdad);
    $tree->add_person($_) for ($newmom,$newdad);
    make_ascendants( $n - 1, $newmom, $tree);
    make_ascendants( $n - 1, $newdad, $tree);
}

make_descendants( $Generations, $mom, $dad, $tree);

my $tmpdot = File::Temp->new;
my $dotfile = $tmpdot->filename;

my $max_generation = $tree->max_generation;

my @last = $tree->find(generation => $max_generation);
diag scalar(@last), ' in last generation';
#is scalar(@last), 64, "64 in last generation";

my @all = $tree->people;
diag scalar(@all), " people in tree";

#my ($orphan) = grep { !$_->mom && !$_->dad } @last;
#diag "adding ascendants for ".$orphan->first_name;
#make_ascendants(5,$orphan,$tree);
#diag "setting generations";
#$tree->_set_generations(force => 1);

$tree->write_dotfile($dotfile);

$tree->write;

diag "Wrote dotfile $dotfile";

ok 1;

