# NAME

ThaiSchema - Lightweight schema validator

# SYNOPSIS

    use ThaiSchema;

    match_schema({x => 3}, {x => type_int});

# DESCRIPTION

ThaiSchema is a lightweight schema validator.

# FUNCTIONS

- `type_int()`

    Is it a int value?

- `type_str()`

    Is it a str value?

- `type_maybe($child)`

    Is it maybe a $child value?

- `type_hash(\%schema)`

        type_hash(
            {
                x => type_str,
                y => type_int,
            }
        );

    Is it a hash contains valid keys?

- `type_array()`

        type_array(
            type_hash({
                x => type_str,
                y => type_int,
            })
        );

- `type_bool()`

    Is it a boolean value?

    This function allows only JSON::true, JSON::false, `\1`, and `\0`.

# OPTIONS

- $STRICT

    You can check a type more strictly.

    This option is useful for checking JSON types.

- $ALLOW\_EXTRA

    You can allow extra key in hashref.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
