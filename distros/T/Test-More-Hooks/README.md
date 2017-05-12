# NAME

Test::More::Hooks - It provides before/after hooks of subtest.

# SYNOPSIS

    use Test::More;
    use Test::More::Hooks;

    subtest "some context" => sub {
        my $subject;
        before { $subject = Foo->new; };
        after  { undef $subject; };

        subtest "given some argument" => sub {
            my $actual = $subject->foo(1,2,3);
            is $actual, 10;
        };

        subtest "given other argument" => sub {
            my $actual = $subject->foo(4,5,6);
            is $actual, 20;
        };
    };

# DESCRIPTION

Test::More::Hooks is simply testing module. This provides only before/after hooks
for Test::More::subtest based test cases.

# FUNCTIONS

## before BLOCK

Test::More::Hooks export this function by default.
If you given BLOCK for 'before' function, Test::More::Hooks would register this BLOCK with the 'before stack'.
Then, it is executed before the process continue to each subtest blocks of same level variable scope.

## after BLOCK

Test::More::Hooks export this function by default.
If you given BLOCK for 'after' function, Test::More::Hooks would register this BLOCK with the 'after stack'.
Then, it is executed after the process go out each subtest blocks of same level variable scope.

# LICENSE

Copyright (C) ainame.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ainame <ainame954@facebook.com>
