use strict;
use warnings;
use Test::More 0.88;

use Test::Needs { 'Moose' => '2.1300' };

{
    package MyRole;
    use Moose::Role;

    use overload
        q{""}    => 'as_string',
        fallback => 1;

    has message => (
        is       => 'rw',
        isa      => 'Str',
    );

    sub as_string { shift->message }
}

{
    package MyClass;
    use Moose;
    use namespace::autoclean;

    with 'MyRole';
}

my $mc = MyClass->new( message => 'foobar' );
is "$mc", 'foobar', 'overload Moose maintained';

{
    package MyClass2;
    use Moose;
    use namespace::autoclean;

    use overload q{""} => 'as_string';

    sub as_string { '42' }
}

my $mc2 = MyClass2->new( message => 'foobar' );
is "$mc2", '42', 'overload in class is not cleaned';

done_testing;
