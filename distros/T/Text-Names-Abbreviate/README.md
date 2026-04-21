[![CPAN version](https://badge.fury.io/pl/Text-Names-Abbreviate.svg)](https://metacpan.org/pod/Text::Names::Abbreviate)
![Ubuntu CI](https://github.com/nigelhorne/Text-Names-Abbreviate/actions/workflows/ubuntu.yml/badge.svg)

# NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

## VERSION

Version 0.02

# SYNOPSIS

    use Text::Names::Abbreviate qw(abbreviate);

    say abbreviate("John Quincy Adams");           # "J. Q. Adams"
    say abbreviate("Adams, John Quincy");         # "J. Q. Adams"
    say abbreviate("George R R Martin", { format => 'initials' }); # "G.R.R.M."

# DESCRIPTION

This module provides simple abbreviation logic for full personal names,
with multiple formatting options and styles.

The input is expected to be a personal name consisting of one or more
whitespace-separated components. These are typically interpreted as:

    First [Middle ...] Last

Names consisting of a single component are treated as a single name,
and no abbreviation of given names is possible.

# SUBROUTINES/METHODS

## abbreviate

Make the abbreviation.
It takes the following optional arguments:

- format

    One of: default, initials, compact, shortlast

    `Shortlast` produces initials followed by the full last name, ignoring style reordering.
    This is similar to the default format but does not support `last_first` output.

- style

    One of: first\_last, last\_first

- separator

    String used between initials (default: ".").

    Note that spacing between initials is handled separately depending on
    the selected format.

### Name Formats

The function recognizes names in both of the following forms:

- `First Middle Last`
- `Last, First Middle`

In the latter case, the name will be normalized internally before
abbreviation.

If the input begins with a comma (e.g., `", John"`), it is interpreted
as having no last name, and only initials will be produced.

### Errors

The function will throw an exception (via `croak`) if:

- The `name` parameter is missing or undefined
- The `name` parameter is an empty string
- An invalid value is provided for `format` or `style`

# EXAMPLES

    abbreviate("Madonna")
    # "Madonna"

    abbreviate("Adams, John Quincy")
    # "J. Q. Adams"

    abbreviate("John Quincy Adams", { style => 'last_first' })
    # "Adams, J. Q."

    abbreviate("John Quincy Adams", { format => 'compact' })
    # "JQA"

### Notes

Abbreviation formats such as `compact` and `initials` are lossy
transformations. They discard structural information about the original
name.

As a result, passing the output of `abbreviate()` back into the function
may not yield equivalent results:

    abbreviate("George R R Martin", { format => 'compact' })   # "GRRM"
    abbreviate("GRRM", { format => 'initials' })                  # "G."

In such cases, the input is treated as a single name.

Initials are derived by taking the first character of each name component verbatim.
No filtering is applied,
so non-alphabetic characters (such as punctuation or digits) will be included as-is.

### API SPECIFICATION

#### INPUT

    {
      'name' => { 'type' => 'string', 'min' => 1, 'optional' => 0 },
      'format' => {
        'type' => 'string',
        'memberof' => [ 'default', 'initials', 'compact', 'shortlast' ],
        'optional' => 1
      }, 'style' => {
        'type' => 'string',
        'memberof' => [ 'first_last', 'last_first' ],
        'optional' => 1
      }, 'separator' => {
        'type' => 'string',
        'optional' => 1
      }
    }

#### OUTPUT

Argument error: croak

    {
      'type' => 'string',
    }

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# REPOSITORY

[https://github.com/nigelhorne/Text-Names-Abbreviate](https://github.com/nigelhorne/Text-Names-Abbreviate)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-text-names-abbreviate at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::Abbreviate

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Text-Names-Abbreviate](https://metacpan.org/dist/Text-Names-Abbreviate)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate](http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Text::Names::Abbreviate](http://deps.cpantesters.org/?module=Text::Names::Abbreviate)

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.
