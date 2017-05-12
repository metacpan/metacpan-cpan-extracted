#!/usr/bin/env perl

use strict;
use warnings;

use UR;

use Test::More tests => 5;

class Person::Relationship {
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
    id_by => [
        name => {
            is => 'Text',
        },
    ],
    has => [
        relationships => {
            is => 'Person::Relationship',
            reverse_as => 'person',
            is_many => 1,
            is_mutable => 1,
            is_optional => 1,
        },
        best_friend => {
            is => 'Person',
            via => 'relationships',
            to => 'related',
            where => [ name => 'best friend', ],
            is_many => 0,
            is_mutable => 1,
            is_optional => 1,
        }
    ],
};

my $george = Person->create(
    name => 'George Washington',
);
ok($george, 'created George Washington');
my $john = Person->create(
    name => 'John Adams',
);
ok($john, 'created John Adams');
my $james = Person->create(
    name => 'James Madison',
    best_friend => $george,
);
ok($james, 'created James Madison');
is_deeply($james->best_friend, $george, 'James best friend is set to George in create');
$james->best_friend($john);
is_deeply($james->best_friend, $john, 'James best friend is set to John');

