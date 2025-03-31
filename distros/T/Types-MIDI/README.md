# NAME

Types::MIDI - Type library for MIDI

# VERSION

version v0.601.0

# SYNOPSIS

    use Moo;
    use Types::MIDI -all;

    has volume => (
        is      => 'ro',
        isa     => Velocity,
        default => 100,
    );
    has a440 => (
        is      => 'ro',
        isa     => Note,
        default => 69,
    );
    has electric_snare => (
        is      => 'ro',
        isa     => PercussionNote,
        coerce  => 1,
        default => 'Electric Snare',
    );

# DESCRIPTION

This is a type constraint library intended to be useful for those
developing music software using the MIDI (Musical Instrument Digital
Interface) specification.

It is a work in progress driven by real-world usage, and as such
**does not yet necessarily have a stable interface**. Once it reaches
version 1.0, though, the author does not intend to introduce any
breaking changes without a corresponding increase in the major version
number.

# OVERVIEW

Because this leverages [Type::Library](https://metacpan.org/pod/Type%3A%3ALibrary), it should be usable in a
variety of Perl object systems, including [Moo](https://metacpan.org/pod/Moo) and [Moose](https://metacpan.org/pod/Moose). By
default, it exports nothing into the consumer's namespace; however, in
addition to specifying individual functions in the ["use" in perlfunc](https://metacpan.org/pod/perlfunc#use)
statement, you can also provide or combine the following tags to export
groups of functions:

- `use Types::MIDI qw(:types);`

    Exports all types by name into the namespace.

- `use Types::MIDI qw(:is);`

    Exports all `is_`_TypeName_ functions into the namespace.

- `use Types::MIDI qw(:assert);`

    Exports all `assert_`_TypeName_ functions into the namespace.

- `use Types::MIDI qw(:to);`

    Exports all `to_`_TypeName_ functions into the namespace.

- `use Types::MIDI qw(+`_TypeName_`);`

    Exports _TypeName_ and all related functions into the namespace.

- `use Types::MIDI qw(:all);`

    Exports everything.

This library also inherits from [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny); consult
[Exporter::Tiny::Manual::Importing](https://metacpan.org/pod/Exporter%3A%3ATiny%3A%3AManual%3A%3AImporting) for ways to customize how functions
are imported, such as renaming or omitting certain names.

Also note that the tags listed above may be preceded with a `-`
(hyphen) instead of a `:` (colon); Perl's auto-quoting of barewords
thus enables you to import a tag group of functions like so:

    use Types::MIDI -all;

# TYPES

## Channel

An [integer from](https://metacpan.org/pod/Types%3A%3ACommon%3A%3ANumeric#Types) 0 to 15 corresponding
to a MIDI Channel.

## Velocity

An [integer from](https://metacpan.org/pod/Types%3A%3ACommon%3A%3ANumeric#Types) 0 to 127 corresponding
to a MIDI velocity.

## Note

An [integer from](https://metacpan.org/pod/Types%3A%3ACommon%3A%3ANumeric#Types) 0 to 127 corresponding
to a MIDI note number.

## PercussionNote

A ["Note"](#note) from 27 through 87, corresponding to a ["Note"](#note) number in the
General MIDI 2 Percussion Sound Set.

This type can also coerce case-insensitive
["NonEmptySimpleStr" in Types::Common::String](https://metacpan.org/pod/Types%3A%3ACommon%3A%3AString#NonEmptySimpleStr)s of instrument names in the
General MIDI 2 Percussion Sound Set, returning the corresponding
["Note"](#note).

# FUNCTIONS

## is\_Channel

Returns true if the passed value can be used as a ["Channel"](#channel).

## assert\_Channel

Returns the passed value if and only if it can be used as a ["Channel"](#channel);
otherwise it throws an exception.

## is\_Velocity

Returns true if the passed value can be used as a ["Velocity"](#velocity).

## assert\_Velocity

Returns the passed value if and only if it can be used as a
["Velocity"](#velocity); otherwise it throws an exception.

## is\_Note

Returns true if the passed value can be used as a ["Note"](#note).

## assert\_Note

Returns the passed value if and only if it can be used as a ["Note"](#note);
otherwise it throws an exception.

## is\_PercussionNote

Returns true if the passed value can be used as a ["PercussionNote"](#percussionnote).

## assert\_PercussionNote

Returns the passed value if and only if it can be used as a
["PercussionNote"](#percussionnote); otherwise it throws an exception.

## to\_PercussionNote

Coerces the passed value to a ["PercussionNote"](#percussionnote).

# SEE ALSO

- _MIDI 1.0 Detailed Specification (Document Version 4.2.1)_,
revised February 1996 by the MIDI Manufacturers Association:
[https://midi.org/midi-1-0-core-specifications](https://midi.org/midi-1-0-core-specifications)
- **Appendix B: GM 2 Percussion Sound Set** in
_General MIDI 2 (Version 1.2a)_,
published February 6, 2007 by the MIDI Manufacturers Association:
[https://midi.org/general-midi-2](https://midi.org/general-midi-2)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://codeberg.org/mjgardner/perl-Types-MIDI/issues](https://codeberg.org/mjgardner/perl-Types-MIDI/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Mark Gardner <mjgardner@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
