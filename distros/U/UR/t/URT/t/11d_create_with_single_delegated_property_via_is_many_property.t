#!/usr/bin/env perl

use strict;
use warnings;
use UR;
use Test::More tests => 7;

# classes
class Person::Relationship {
    is  => 'UR::Object',
    id_by => [
        person_id => { is => 'Number', implied_by => 'person', },
        related_id => { is => 'Number', implied_by => 'related' },
        name => { is => 'Text', },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id', },
        related => { is => 'Person', id_by => 'related_id' },
    ],
};

class Person {
    is => 'UR::Object',
    has => [
        name => { is => 'Text', doc => 'Name of the person', },
        relationships => { 
            is => 'Person::Relationship',
            is_many => 1,
            is_optional => 1,
            reverse_as => 'person',
            doc => 'This person\'s relationships', 
        },
        friends => { 
            is => 'Person',
            is_many => 1,
            is_optional => 1,
            is_mutable => 1,
            via => 'relationships', 
            to => 'related',
            where => [ name => 'friend' ],
            doc => 'Friends of this person', 
        },
        best_friend => {
           is => 'Person',
           is_optional => 1,
           is_mutable => 1,
           via => 'relationships', 
           to => 'related',
           where => [ name => 'best friend' ],
           doc => 'Best friend of this person', 
       },
    ],
};

my $ronnie = Person->create(
    name => 'Ronald Reagan',
);
ok($ronnie, 'created Ronnie');
is_deeply([$ronnie->friends], [], 'Ronnie does not have friends');
ok(!$ronnie->best_friend, 'Ronnie  does not have a best friend');

# Create George 
my $bill = Person->create(
    name => 'Bill Clinton',
    friends => [$ronnie], #works
);
is_deeply([$bill->friends], [$ronnie], 'Bill has friend(s)');

my $george = Person->create(
    name =>  'George HW Bush',
    friends =>  [$ronnie],
    best_friend => $bill, #does not work
);
ok($george, 'created George');
is_deeply([$george->friends], [$ronnie], 'George has friend(s)');
is_deeply($george->best_friend, $bill, 'George is best friends w/ bill');


