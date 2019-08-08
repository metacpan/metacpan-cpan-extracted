[![Build Status](https://travis-ci.org/akiym/Test2-Tools-Condition.svg?branch=master)](https://travis-ci.org/akiym/Test2-Tools-Condition)
# NAME

Test2::Tools::Condition - Conditional block with Test2

# SYNOPSIS

    use Test2::V0;
    use Test2::Tools::Condition;

    my $positive_number = condition { $_ > 0 };

    is 123, $positive_number; 
    is {
        a => 0,
        b => 1,
    }, {
        a => !$positive_number,
        b => $positive_number,
    };

# DESCRIPTION

Test2::Tools::Condition checks wether or not the value satisfies the condition.

# FUNCTIONS

- $check = condition { ... };

    Verify the value satisfies the condition and set `$_` for `$got` value in block.

        is 3, condition { 2 < $_ && $_ < 4 };

- $check = !condition { ... };

    Verify the value unsatisfies the condition and set `$_` for `$got` value in block.

        is 7, !condition { 2 < $_ && $_ < 4 };

# SEE ALSO

[Test::Deep::Cond](https://metacpan.org/pod/Test::Deep::Cond)

[Test2::Suite](https://metacpan.org/pod/Test2::Suite), [Test2::Tools::Compare](https://metacpan.org/pod/Test2::Tools::Compare)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
