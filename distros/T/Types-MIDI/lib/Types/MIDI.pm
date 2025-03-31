## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
package Types::MIDI;
our $AUTHORITY = 'cpan:MJGARDNER';
## use critic (TestingAndDebugging::RequireUseStrict)
## use critic (TestingAndDebugging::RequireUseWarnings)

use 5.016;
use strict;
use warnings;

# ABSTRACT: Type library for MIDI

#<<<
our $VERSION = 'v0.601.0';
#>>>

use Type::Library 2.000000 -extends => [ qw(
    Types::Common::Numeric
    Types::Common::String
) ],
    -declare => qw(
    Channel
    Velocity
    Note
    PercussionNote
    );
use Type::Utils 2.000000 -all;
use MIDI;
use Readonly;

#pod =head1 SYNOPSIS
#pod
#pod     use Moo;
#pod     use Types::MIDI -all;
#pod
#pod     has volume => (
#pod         is      => 'ro',
#pod         isa     => Velocity,
#pod         default => 100,
#pod     );
#pod     has a440 => (
#pod         is      => 'ro',
#pod         isa     => Note,
#pod         default => 69,
#pod     );
#pod     has electric_snare => (
#pod         is      => 'ro',
#pod         isa     => PercussionNote,
#pod         coerce  => 1,
#pod         default => 'Electric Snare',
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a type constraint library intended to be useful for those
#pod developing music software using the MIDI (Musical Instrument Digital
#pod Interface) specification.
#pod
#pod It is a work in progress driven by real-world usage, and as such
#pod B<does not yet necessarily have a stable interface>. Once it reaches
#pod version 1.0, though, the author does not intend to introduce any
#pod breaking changes without a corresponding increase in the major version
#pod number.
#pod
#pod =head1 OVERVIEW
#pod
#pod Because this leverages L<Type::Library>, it should be usable in a
#pod variety of Perl object systems, including L<Moo> and L<Moose>. By
#pod default, it exports nothing into the consumer's namespace; however, in
#pod addition to specifying individual functions in the L<perlfunc/use>
#pod statement, you can also provide or combine the following tags to export
#pod groups of functions:
#pod
#pod =over
#pod
#pod =item C<use Types::MIDI qw(:types);>
#pod
#pod Exports all types by name into the namespace.
#pod
#pod =item C<use Types::MIDI qw(:is);>
#pod
#pod Exports all C<is_>I<TypeName> functions into the namespace.
#pod
#pod =item C<use Types::MIDI qw(:assert);>
#pod
#pod Exports all C<assert_>I<TypeName> functions into the namespace.
#pod
#pod =item C<use Types::MIDI qw(:to);>
#pod
#pod Exports all C<to_>I<TypeName> functions into the namespace.
#pod
#pod =item C<use Types::MIDI qw(+>I<TypeName>C<);>
#pod
#pod Exports I<TypeName> and all related functions into the namespace.
#pod
#pod =item C<use Types::MIDI qw(:all);>
#pod
#pod Exports everything.
#pod
#pod =back
#pod
#pod This library also inherits from L<Exporter::Tiny>; consult
#pod L<Exporter::Tiny::Manual::Importing> for ways to customize how functions
#pod are imported, such as renaming or omitting certain names.
#pod
#pod Also note that the tags listed above may be preceded with a C<->
#pod (hyphen) instead of a C<:> (colon); Perl's auto-quoting of barewords
#pod thus enables you to import a tag group of functions like so:
#pod
#pod     use Types::MIDI -all;
#pod
#pod =cut

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

#pod =type Channel
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 15 corresponding
#pod to a MIDI Channel.
#pod
#pod =func is_Channel
#pod
#pod Returns true if the passed value can be used as a L</Channel>.
#pod
#pod =func assert_Channel
#pod
#pod Returns the passed value if and only if it can be used as a L</Channel>;
#pod otherwise it throws an exception.
#pod
#pod =cut

declare Channel, as IntRange [ 0, 15 ];

#pod =type Velocity
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
#pod to a MIDI velocity.
#pod
#pod =func is_Velocity
#pod
#pod Returns true if the passed value can be used as a L</Velocity>.
#pod
#pod =func assert_Velocity
#pod
#pod Returns the passed value if and only if it can be used as a
#pod L</Velocity>; otherwise it throws an exception.
#pod
#pod =cut

declare Velocity, as IntRange [ 0, 127 ];

#pod =type Note
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
#pod to a MIDI note number.
#pod
#pod =func is_Note
#pod
#pod Returns true if the passed value can be used as a L</Note>.
#pod
#pod =func assert_Note
#pod
#pod Returns the passed value if and only if it can be used as a L</Note>;
#pod otherwise it throws an exception.
#pod
#pod =cut

declare Note, as IntRange [ 0, 127 ];

#pod =type PercussionNote
#pod
#pod A L</Note> from 27 through 87, corresponding to a L</Note> number in the
#pod General MIDI 2 Percussion Sound Set.
#pod
#pod This type can also coerce case-insensitive
#pod L<Types::Common::String/NonEmptySimpleStr>s of instrument names in the
#pod General MIDI 2 Percussion Sound Set, returning the corresponding
#pod L</Note>.
#pod
#pod =func is_PercussionNote
#pod
#pod Returns true if the passed value can be used as a L</PercussionNote>.
#pod
#pod =func assert_PercussionNote
#pod
#pod Returns the passed value if and only if it can be used as a
#pod L</PercussionNote>; otherwise it throws an exception.
#pod
#pod =func to_PercussionNote
#pod
#pod Coerces the passed value to a L</PercussionNote>.
#pod
#pod =cut

my %notenum2percussion = %MIDI::notenum2percussion;    ## no critic (Variables::ProhibitPackageVars)
@notenum2percussion{ 27 .. 34, 82 .. 87 } = (
    'High Q',
    'Slap',
    'Scratch Push',
    'Scratch Pull',
    'Sticks',
    'Square Click',
    'Metronome Click',
    'Metronome Bell',

    'Shaker',
    'Jingle Bell',
    'Bell Tree',
    'Castanets',
    'Mute Surdo',
    'Open Surdo',
);
Readonly my %NOTENUM2PERCUSSION_FC =>
    map { fc $notenum2percussion{$_} => $_ } keys %notenum2percussion;

declare PercussionNote, as Note,
    where { exists $notenum2percussion{$_} };
coerce PercussionNote, from NonEmptySimpleStr,
    via { $NOTENUM2PERCUSSION_FC{"\F$_"} };

#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item *
#pod
#pod I<MIDI 1.0 Detailed Specification (Document Version 4.2.1)>,
#pod revised February 1996 by the MIDI Manufacturers Association:
#pod L<https://midi.org/midi-1-0-core-specifications>
#pod
#pod =item *
#pod
#pod B<Appendix B: GM 2 Percussion Sound Set> in
#pod I<General MIDI 2 (Version 1.2a)>,
#pod published February 6, 2007 by the MIDI Manufacturers Association:
#pod L<https://midi.org/general-midi-2>
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::MIDI - Type library for MIDI

=head1 VERSION

version v0.601.0

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a type constraint library intended to be useful for those
developing music software using the MIDI (Musical Instrument Digital
Interface) specification.

It is a work in progress driven by real-world usage, and as such
B<does not yet necessarily have a stable interface>. Once it reaches
version 1.0, though, the author does not intend to introduce any
breaking changes without a corresponding increase in the major version
number.

=head1 OVERVIEW

Because this leverages L<Type::Library>, it should be usable in a
variety of Perl object systems, including L<Moo> and L<Moose>. By
default, it exports nothing into the consumer's namespace; however, in
addition to specifying individual functions in the L<perlfunc/use>
statement, you can also provide or combine the following tags to export
groups of functions:

=over

=item C<use Types::MIDI qw(:types);>

Exports all types by name into the namespace.

=item C<use Types::MIDI qw(:is);>

Exports all C<is_>I<TypeName> functions into the namespace.

=item C<use Types::MIDI qw(:assert);>

Exports all C<assert_>I<TypeName> functions into the namespace.

=item C<use Types::MIDI qw(:to);>

Exports all C<to_>I<TypeName> functions into the namespace.

=item C<use Types::MIDI qw(+>I<TypeName>C<);>

Exports I<TypeName> and all related functions into the namespace.

=item C<use Types::MIDI qw(:all);>

Exports everything.

=back

This library also inherits from L<Exporter::Tiny>; consult
L<Exporter::Tiny::Manual::Importing> for ways to customize how functions
are imported, such as renaming or omitting certain names.

Also note that the tags listed above may be preceded with a C<->
(hyphen) instead of a C<:> (colon); Perl's auto-quoting of barewords
thus enables you to import a tag group of functions like so:

    use Types::MIDI -all;

=head1 TYPES

=head2 Channel

An L<integer from|Types::Common::Numeric/Types> 0 to 15 corresponding
to a MIDI Channel.

=head2 Velocity

An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
to a MIDI velocity.

=head2 Note

An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
to a MIDI note number.

=head2 PercussionNote

A L</Note> from 27 through 87, corresponding to a L</Note> number in the
General MIDI 2 Percussion Sound Set.

This type can also coerce case-insensitive
L<Types::Common::String/NonEmptySimpleStr>s of instrument names in the
General MIDI 2 Percussion Sound Set, returning the corresponding
L</Note>.

=head1 FUNCTIONS

=head2 is_Channel

Returns true if the passed value can be used as a L</Channel>.

=head2 assert_Channel

Returns the passed value if and only if it can be used as a L</Channel>;
otherwise it throws an exception.

=head2 is_Velocity

Returns true if the passed value can be used as a L</Velocity>.

=head2 assert_Velocity

Returns the passed value if and only if it can be used as a
L</Velocity>; otherwise it throws an exception.

=head2 is_Note

Returns true if the passed value can be used as a L</Note>.

=head2 assert_Note

Returns the passed value if and only if it can be used as a L</Note>;
otherwise it throws an exception.

=head2 is_PercussionNote

Returns true if the passed value can be used as a L</PercussionNote>.

=head2 assert_PercussionNote

Returns the passed value if and only if it can be used as a
L</PercussionNote>; otherwise it throws an exception.

=head2 to_PercussionNote

Coerces the passed value to a L</PercussionNote>.

=head1 SEE ALSO

=over

=item *

I<MIDI 1.0 Detailed Specification (Document Version 4.2.1)>,
revised February 1996 by the MIDI Manufacturers Association:
L<https://midi.org/midi-1-0-core-specifications>

=item *

B<Appendix B: GM 2 Percussion Sound Set> in
I<General MIDI 2 (Version 1.2a)>,
published February 6, 2007 by the MIDI Manufacturers Association:
L<https://midi.org/general-midi-2>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://codeberg.org/mjgardner/perl-Types-MIDI/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
