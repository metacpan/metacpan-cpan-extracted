use strict;
use warnings;

{
    package Foo;
    use Want;

    sub new { return (bless({}, shift)); }

    my $foo;

    sub foo :lvalue
    {
        my (@args) = Want::want('ASSIGN');
        $foo = $args[0];
        Want::lnoreturn;
        return;
    }

}

use threads;
my $obj = Foo->new();
$obj->foo() = 'bar';

# EOF
