use strict;
use Test::More tests => 3;
use lib 't/lib';

{

    package MyParent;
    sub exclaim { "I CAN HAS PERL?" }
}

{

    package Child;
    use superclass -norequire, 'MyParent';
}

my $obj = {};
bless $obj, 'Child';
isa_ok $obj, 'MyParent', 'Inheritance';
can_ok $obj, 'exclaim';
is $obj->exclaim, "I CAN HAS PERL?", 'Inheritance is set up correctly';

