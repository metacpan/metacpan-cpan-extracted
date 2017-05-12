use FindBin;
use Test::More;
use utf8;
use strict;
use warnings;

{
    use_ok 'Validation::Class';
}
{

    package TestClass::A;
    use Validation::Class;

    field name  => {mixin => ':str'};
    field color => {mixin => ':str'};
    field year  => {mixin => ':str'};

    method redish_brown => {
        input => ['color'],
        using => sub { 1 }
    };

    package TestClass::B;
    use Validation::Class;

    adopt 'TestClass::A', 'field',  'name';
    adopt 'TestClass::A', 'field',  'color';
    adopt 'TestClass::A', 'method', 'redish_brown';

    package main;

    my $b = TestClass::B->new(color => 'red');

    ok "TestClass::B" eq ref $b, "TestClass::B instantiated";
    ok $b->proto->fields->has($_) => "TestClass::B has $_" for qw(name color);
    can_ok $b, qw(name color redish_brown);
    ok $b->redish_brown() => "TestClass::B redish_brown executed and valid";

}

done_testing();
