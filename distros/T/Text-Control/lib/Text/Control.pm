package Text::Control;

use strict;
use warnings;

our $VERSION = '0.3';

my $CTRL_PATTERN = '[\x00-\x19\x7f-\xff]';

=encoding utf-8

=head1 NAME

Text::Control - Transforms of control characters

=head1 SYNOPSIS

    use Text::Control;

    Text::Control::to_dot("\x00\\Hi\x7fthere.\x80\xff");    # .\Hi.there...

    Text::Control::to_hex("\x00\\Hi\x7fthere.\x80\xff");
    # \x00\\Hi\x7fthere.\x80\xff -- note the escaped backslash

=head1 DESCRIPTION

These are transforms that I find useful for debugging. Maybe you will, too?

=head1 NONPRINTABLE BYTES

This module considers byte numbers 32 - 126 to be “printable”; i.e., they
represent actual ASCII characters. Anything outside this range is thus
“nonprintable”.

=head1 FUNCTIONS

=head2 to_dot( OCTET_STRING )

Transforms each nonprintable byte into a dot (C<.>, ASCII 46) and returns
the result.

=cut

sub to_dot {
    my ($input) = @_;

    $input =~ s<$CTRL_PATTERN><.>g;

    return $input;
}

=head2 to_hex( OCTET_STRING )

Transforms each nonprintable byte into the corresponding \x.. sequence,
appropriate for feeding into
C<eval()>. For example, a NUL byte comes out as C<\x00>.

In order to make this encoding reversible, backslash characters (C<\>) are
double-escaped (i.e., C<\> becomes C<\\>).

=cut

sub to_hex {
    my ($input) = @_;

    $input =~ s<\\><\\\\>g;
    $input =~ s<($CTRL_PATTERN)><'\\x' . sprintf('%02x', ord $1)>ge;

    return $input;
}

=head2 from_hex( FROM_TO_HEX )

This transforms the result of C<to_hex()> back into its original form.
I’m not sure this is actually useful :), but hey.

=cut

sub from_hex {
    my ($input) = @_;

    $input =~ s<\\x([0-9a-f]{2})><chr hex $1>ge;
    $input =~ s<\\\\><\\>g;

    return $input;
}

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 REPOSITORY

https://github.com/FGasper/p5-Text-Control

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
