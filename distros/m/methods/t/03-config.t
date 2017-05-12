# Test derived from Method::Signatures::Simple:
#   Copyright 2008 Rhesa Rozendaal, all rights reserved.
#   This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

use strict;
use warnings;

use Test::More tests => 2;

# testing that we can install several different keywords into the same scope
{
    package Monster;

    use methods;
    use methods name => 'action', invocant => '$monster';
    use methods name => 'constructor', invocant => '$species';

    constructor spawn {
        bless {@_}, $species;
    }

    action speak (@words) {
        return join ' ', $monster->{name}, $monster->{voices}, @words;
    }

    action attack ($me: $you) {
        $you->take_damage($me->{strength});
    }

    method take_damage ($hits) {
        $self->{hitpoints} -= $hits;
        if($self->{hitpoints} <= 0) {
            $self->{is_dead} = 1;
        }
    }
}

package main;
my $hellhound = Monster->spawn( name => "Hellhound", voices => "barks", strength => 22, hitpoints => 100 );
is $hellhound->speak(qw(arf arf)), 'Hellhound barks arf arf';

my $human = Monster->spawn( name => 'human', voices => 'whispers', strength => 4, hitpoints => 16 );
$hellhound->attack($human);
is $human->{is_dead}, 1;

