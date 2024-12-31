[![Build Status](https://travis-ci.org/akiym/Test2-Tools-JSON.svg?branch=master)](https://travis-ci.org/akiym/Test2-Tools-JSON)
# NAME

Test2::Tools::JSON - Compare JSON string as data structure with Test2

# SYNOPSIS

    use Test2::V0;
    use Test2::Tools::JSON;
    
    is {
        foo     => 'bar',
        payload => '{"a":1}',
    }, {
        foo     => 'bar',
        payload => json({a => E}),
    };

# DESCRIPTION

Test2::Tools::JSON provides comparison tools for JSON string.
This module was inspired by [Test::Deep::JSON](https://metacpan.org/pod/Test%3A%3ADeep%3A%3AJSON).

# FUNCTIONS

- $check = json($expected)

    Verify the value in the `$got` JSON string has the same data structure as `$expected`.

        is '{"a":1}', json({a => 1});

        is '{"a":{"b":1},"c":2}', json hash { field a => {b => 1}; etc; };

- $check = relaxed\_json($expected)

    Verify the value in the `$got` relaxed JSON string has the same data structure as `$expected`.

        is '[1,2,3,]', relaxed_json([1,2,3]);

# SEE ALSO

[Test::Deep::JSON](https://metacpan.org/pod/Test%3A%3ADeep%3A%3AJSON)

[Test2::Suite](https://metacpan.org/pod/Test2%3A%3ASuite), [Test2::Tools::Compare](https://metacpan.org/pod/Test2%3A%3ATools%3A%3ACompare)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
