#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use lib 't';
use MyTest;
use Devel::Peek;
use BSD::Resource;

{
    package MyClass;

    sub new {
        my ($class, $value) = @_;
        my $obj = {_value => $value};
        return bless $obj => $class;
    }
}

while (1) {
    MyTest::test_leaks1("MyClass", "new", 10000);
    say BSD::Resource::getrusage()->{"maxrss"};
}

