use strict;
use warnings;
use Test::More 0.88;

{
    package Foo;
    use constant CAT => 'kitten';
    BEGIN { our $DOG = 'puppy' }
    use constant DOG => 'puppy';
    use namespace::autoclean;
}

ok(Foo->can('CAT'), 'constant sub was not cleaned');
ok(Foo->can('DOG'), 'constant with existing glob entries was not cleaned');

done_testing;

