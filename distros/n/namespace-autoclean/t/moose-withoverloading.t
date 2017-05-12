use strict;
use warnings;
use Test::More 0.88;
{
  package Temp1;
  use Test::Requires qw(Moose);
}
{
  package Temp2;
  use Test::Requires qw(MooseX::Role::WithOverloading);
}

{
    package MyRole;
    use MooseX::Role::WithOverloading;

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
is "$mc", 'foobar', 'overload from MooseX::Role::WithOverloading maintained';

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
