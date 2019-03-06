# NAME

Text::Control - Transforms of control characters

# SYNOPSIS

    use Text::Control;

    Text::Control::to_dot("\x00\\Hi\x7fthere.\x80\xff");    # .\Hi.there...

    Text::Control::to_hex("\x00\\Hi\x7fthere.\x80\xff");
    # \x00\\Hi\x7fthere.\x80\xff -- note the escaped backslash

# DESCRIPTION

These are transforms that I find useful for debugging. Maybe you will, too?

# NONPRINTABLE BYTES

This module considers byte numbers 32 - 126 to be “printable”; i.e., they
represent actual ASCII characters. Anything outside this range is thus
“nonprintable”.

# FUNCTIONS

## to\_dot( OCTET\_STRING )

Transforms each nonprintable byte into a dot (`.`, ASCII 46) and returns
the result.

## to\_hex( OCTET\_STRING )

Transforms each nonprintable byte into the corresponding \\x.. sequence,
appropriate for feeding into
`eval()`. For example, a NUL byte comes out as `\x00`.

In order to make this encoding reversible, backslash characters (`\`) are
double-escaped (i.e., `\` becomes `\\`).

## from\_hex( FROM\_TO\_HEX )

This transforms the result of `to_hex()` back into its original form.
I’m not sure this is actually useful :), but hey.

# AUTHOR

Felipe Gasper (FELIPE)

# REPOSITORY

[https://github.com/FGasper/p5-Text-Control](https://github.com/FGasper/p5-Text-Control)

# COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
