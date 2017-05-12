#!perl 

use Test::More qw(no_plan);
use Tree::Family;
use Tree::Family::Person;
use strict;

{   # spouse tests
    my $p = Tree::Family::Person->new(first_name => 'Fred', last_name => 'Flintstone' );
    is ($p->get('first_name'),'Fred', 'get name');
    is ($p->get('last_name'), 'Flintstone', 'get last name');
    my $q = Tree::Family::Person->new(first_name => 'Wilma');
    $p->spouse($q);
    is ($p->spouse->get('first_name'),'Wilma', 'Set spouse');
    is ($p->spouse->spouse->get('first_name'),'Fred', 'Spouse is reflexive');
    $p->spouse(undef);
    ok (!defined($p->spouse), "un-set spouse");
    ok (!defined($q->spouse), "un-set was reflexive");
}

{   # kid tests
    my $p = Tree::Family::Person->new(first_name => 'Mr. Cleaver');
    my $q = Tree::Family::Person->new(first_name => 'Mrs. Cleaver');
    $p->spouse($q);
    my $kid = Tree::Family::Person->new(first_name => 'Beaver');
    my $kid2 = Tree::Family::Person->new(first_name => 'Wally');
    $kid->dad($p);
    $kid->mom($q);
    $kid2->dad($p);
    $kid2->mom($q);
    is (scalar($p->kids),2,"Added two kids");
    my @kids = sort { $a->get('first_name') cmp $b->get('first_name') } $p->kids;
    is $kids[0]->get('first_name'),'Beaver', 'first kid ok';
    is $kids[1]->get('first_name'),'Wally', 'second kid ok';
}

{   # addition and deletion
    my $dad = Tree::Family::Person->new(first_name => 'Mr. Cleaver');
    my $mom = Tree::Family::Person->new(first_name => 'Mrs. Cleaver');
    my $kid = Tree::Family::Person->new(first_name => 'Beaver');
    $kid->dad($dad);
    $kid->mom($mom);
    is ($kid->dad->get('first_name'),'Mr. Cleaver','set dad');
    $kid->dad(undef);
    ok (!defined($kid->dad),'unset dad');
    is ($kid->mom->get('first_name'),'Mrs. Cleaver', 'mom not changed');
    is (scalar($dad->kids),0,'unsetting dad removed kid');
    is (scalar($mom->kids),1,'mom still has the kid');
}



