use lib -e 't' ? 't' : 'test';
use TestML1;
use TestML1Bridge;

TestML1->new(
    testml => join('', <DATA>),
    bridge => 'TestML1Bridge',
)->run;

__DATA__

%TestML 0.1.0

Title = "Ingy's Test";
Plan = 4;

*foo == *bar;
*bar == *foo;

=== Foo for thought
--- foo: O HAI
--- bar: O HAI

=== Bar the door
--- bar
O
HAI
--- foo
O
HAI
