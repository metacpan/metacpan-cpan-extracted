#!/perl

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use File::Temp;
use strict;
$Tree::Family::Person::keyMethod = 'first_name';
our $tmp = File::Temp->new;
our $tmpfile = $tmp->filename;

#     a --- B
#  
#        carol     ----------    mike
#    |     |   |             |     |    |
#  cindy jan marsha         bobby peter greg 
#
{
    my $tree = Tree::Family->new(filename => $tmpfile);
    my $carol  = Tree::Family::Person->new(first_name => 'carol',  gender => 'f');
    my $cindy  = Tree::Family::Person->new(first_name => 'cindy',  gender => 'f');
    my $jan    = Tree::Family::Person->new(first_name => 'jan',    gender => 'f');
    my $marsha = Tree::Family::Person->new(first_name => 'marsha', gender => 'f');
    my $mike   = Tree::Family::Person->new(first_name => 'mike',   gender => 'm');
    my $bobby  = Tree::Family::Person->new(first_name => 'bobby',  gender => 'm');
    my $peter  = Tree::Family::Person->new(first_name => 'peter',  gender => 'm');
    my $greg   = Tree::Family::Person->new(first_name => 'greg',   gender => 'm');
    $_->mom($carol) for ($cindy,$jan,$marsha);
    $_->dad($mike) for ($bobby,$peter,$greg);
    $carol->spouse($mike);
    $tree->add_person($_) for ($carol,$cindy,$jan,$marsha,$mike,$bobby,$peter,$greg);
    $tree->write;
}

{
    my $tree = Tree::Family->new(filename => $tmpfile);
    is scalar($tree->people),8, "saved, got 8 people";
    my $tmpdot = File::Temp->new;
    my $dotfile = $tmpdot->filename;
    $tree->write_dotfile($dotfile);
    diag "Wrote dotfile $dotfile";
}


