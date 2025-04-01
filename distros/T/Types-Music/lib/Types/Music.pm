package Types::Music;

# ABSTRACT: Type Library for Music Programming

our $AUTHORITY = 'cpan:GENE';

our $VERSION = '0.0104';

use 5.016;
use strict;
use warnings;

use Types::Standard qw(StrMatch);

use Type::Library 2.000000
    -extends => [qw(
        Types::Common::Numeric
        Types::Common::String
    )],
    -declare => qw(
        BPM
        Bars
        Beats
        Divisions
        Signature
        Octave
        Key
        Named_Note
        Named_Note_Octave
        Mode
    );

use Type::Utils 2.000000 -all;

declare BPM,
    as PositiveNum;

declare Bars,
    as PositiveNum;

declare Beats,
    as PositiveNum;

declare Divisions,
    as PositiveNum;

declare Signature,
    as StrMatch[ qr/^[1-9]\d?\/[1-9]\d?$/ ];

declare Octave,
    as PositiveOrZeroNum; # the zero-octave means "use pitch-class" in some module of mine...

declare Key,
    as StrMatch[ qr/^[A-G][#b]?$/ ];

declare Named_Note,
    as StrMatch[ qr/^[A-G][#bsf]?$/ ];

declare Named_Note_Octave,
    as StrMatch[ qr/^[A-G][#bsf]?\d$/ ];

my %modes;
@modes{qw(
    ionian major
    dorian
    phrygian
    lydian
    mixolydian
    aeolian minor
    locrian
)} = undef;
declare Mode,
    as NonEmptyStr, where { exists $modes{$_} };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Music - Type Library for Music Programming

=head1 VERSION

version 0.0104

=head1 SYNOPSIS

    use Moo;
    use Types::Music -all;

    has named_note => (
        is      => 'ro',
        isa     => Named_Note_Octave,
        default => 'C4',
    );

=head1 DESCRIPTION

This is a type constraint library for developing music software.

=head1 USAGE

=over

=item C<use Types::Music qw(:types);>

Exports all types by name.

=item C<use Types::Music qw(:is);>

Exports all C<is_>I<TypeName> functions.

=item C<use Types::Music qw(:assert);>

Exports all C<assert_>I<TypeName> functions.

=item C<use Types::Music qw(:to);>

Exports all C<to_>I<TypeName> functions.

=item C<use Types::Music qw(+>I<TypeName>C<);>

Exports I<TypeName> and all related functions.

=item C<use Types::Music qw(:all);>

Exports everything.

=back

=head1 TYPES

=head2 BPM

A positive integer beats per minute.

=head2 Bars

A positive integer number of bars (or measures).

=head2 Beats

A positive integer number of beats per measure.

=head2 Divisions

A positive integer number of divisions.

=head2 Signature

A string representing a time signature, like C<3/4>. The B<Signature>
is a fraction with B<Beats> as numerator and B<Divisions> as
denominator.

=head2 Octave

A numeric octave. Usually C<1> to C<6>. Higher and it's not really
audible. Zero C<0> is special cased to allow specific module behavior.

=head2 Key

A key note, like C<C>, C<C#>, C<Bb>, etc.

=head2 Named_Note

A named note, in either tradional or MIDI-Perl notation, like C<C>,
C<C#>, C<Cs>, C<Bb>, C<Bf>, etc.

=head2 Named_Note_Octave

A named note with octave, like C<C4>, C<C#5>, C<Cs5>, C<Bb2>, C<Bf2>,
etc.

=head2 Mode

A mode name. The known modes are:

    ionian / major
    dorian
    phrygian
    lydian
    mixolydian
    aeolian / minor
    locrian

=head1 FUNCTIONS

=head2 is_BPM

Returns true if the passed value can be used as a L</BPM>.

=head2 assert_BPM

Returns the passed value if and only if it can be used as a
L</BPM>, otherwise an exception is thrown.

=head2 is_Bars

Returns true if the passed value can be used as the number of
L</Bars>.

=head2 assert_Bars

Returns the passed value if and only if it can be used as the number
of L</Bars>, otherwise an exception is thrown.

=head2 is_Beats

Returns true if the passed value can be used as the number of
L</Beats>.

=head2 assert_Beats

Returns the passed value if and only if it can be used as the number
of L</Beats>, otherwise an exception is thrown.

=head2 is_Divisions

Returns true if the passed value can be used as the number of
L</Divisions>.

=head2 assert_Divisions

Returns the passed value if and only if it can be used as the number
of L</Divisions>, otherwise an exception is thrown.

=head2 is_Signature

Returns true if the passed value can be used as a time signature
L</Signature>.

=head2 assert_Signature

Returns the passed value if and only if it can be used as a time
signature L</Signature>, otherwise an exception is thrown.

=head2 is_Octave

Returns true if the passed value can be used as an L</Octave>.

=head2 assert_Octave

Returns the passed value if and only if it can be used as an
L</Octave>, otherwise an exception is thrown.

=head2 is_Key

Returns true if the passed value can be used as a L</Key>.

=head2 assert_Key

Returns the passed value if and only if it can be used as a
L</Key>, otherwise an exception is thrown.

=head2 is_Named_Note

Returns true if the passed value can be used as a L</Named_Note>.

=head2 assert_Named_Note

Returns the passed value if and only if it can be used as a
L</Named_Note>, otherwise an exception is thrown.

=head2 is_Named_Note_Octave

Returns true if the passed value can be used as a L</Named_Note_Octave>.

=head2 assert_Named_Note_Octave

Returns the passed value if and only if it can be used as a
L</Named_Note_Octave>, otherwise an exception is thrown.

=head2 is_Mode

Returns true if the passed value can be used as a L</Mode>.

=head2 assert_Mode

Returns the passed value if and only if it can be used as a
L</Mode>, otherwise an exception is thrown.

=head1 SEE ALSO

L<Type::Tiny>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
