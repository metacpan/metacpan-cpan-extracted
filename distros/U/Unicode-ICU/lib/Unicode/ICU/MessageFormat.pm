# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::MessageFormat;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::MessageFormat - ICU’s L<MessageFormat|https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classicu_1_1MessageFormat.html> class

=head1 SYNOPSIS

    use utf8;

    my $formatter = Unicode::ICU::MessageFormat->new('en');

    my $chars = $formatter->format('The time is {0, time} on {0, date}.', [time]);

    # Named arguments are also acceptable:
    my $chars = $formatter->format('The time is {now, time} on {now, date}.', { now => time() });

=head1 DESCRIPTION

This module facilitates formatting of ICU message pattern strings.

For a description of the message pattern format, see
L<ICU’s documentation|https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/classicu_1_1MessageFormat.html#patterns>.

=head1 COMPATIBILITY

Named arguments require ICU 4.8 or later.

=cut

#----------------------------------------------------------------------

use Unicode::ICU;
use Unicode::ICU::MessagePattern;
use Unicode::ICU::MessagePatternPart;

#----------------------------------------------------------------------

=head1 CONSTANTS

=head2 CAN_TAKE_NAMED_ARGUMENTS

A boolean that indicates whether C<format()> can accept named arguments
as well as positional.

=head1 METHODS

=head2 $obj = I<CLASS>->new( [$LOCALE] )

Returns an instance of this class. If $LOCALE is not given then
we’ll use ICU’s default.

=cut

=head2 $str = I<OBJ>->format( $PATTERN [, \@ARGUMENTS | \%ARGUMENTS ] );

Formats the given $PATTERN with the given @ARGUMENTS and returns
the resulting string.

Note the following I<important> caveats:

=head2 Dates & Times

Unlike in ICU, dates & times are expressed in B<seconds> rather than
milliseconds.

=head2 Arguments

Arguments may be positional or (assuming a recent enough ICU) named.

=head3 Positional Arguments

If you give arguments as an array reference, then $PATTERN’s arguments
B<MUST> be a continuous sequence starting at 0. A “missing” argument
will trigger an exception.

Note that ICU positional arguments are B<zero>-B<indexed>. This differs
from L<Locale::Maketext> and other systems that use 1-indexing. So if
you do this:

    # bad:
    $formatter->format('My name is {1}.', ['Jonas'])

… you’ll get an exception. (C<{0}> is what you want, not C<{1}>.) If you
I<really> want, though, you could use named arguments; see below.

=head3 Named Arguments

B<NOTE:> This library cannot handle named arguments for all ICU versions.

The above is probably easier to read and maintain as:

    $formatter->format('My name is {name}.', { name => 'Jonas' })

You can also give named arguments for a positional-argument $PATTERN;
in fact, if you do that, you can have “missing” arguments, e.g.:

    # ok:
    $formatter->format('My name is {1}.', { 1 => 'Jonas' })

=head1 $locale = I<OBJ>->get_locale()

Returns I<OBJ>’s configured locale.

=cut

my %_part_is_arg_id;

if ($Unicode::ICU::MessagePatternPart::PART_TYPE{'ARG_NAME'}) {
    %_part_is_arg_id = (
        $Unicode::ICU::MessagePatternPart::PART_TYPE{'ARG_NAME'} => 1,
        $Unicode::ICU::MessagePatternPart::PART_TYPE{'ARG_NUMBER'} => 1,
    );
}

our ($a, $b);

# ICU’s C++ API doesn’t expose controls that allow us to query for the
# type of a named argument. Because of this we can’t send named arguments
# to ICU directly; instead we convert them to positional, then format()
# that positional string with the arguments in the proper order.
#
# It would be possible to query for the argument type via the converted
# positional arguments, then go back and send named arguments to ICU.
# That might get us better error messages, but for now this works (and
# is likely faster besides).
#
sub _parse_named_args_as_positional {
    my ($self, $pattern, $args_hr) = @_;

    my $parse = Unicode::ICU::MessagePattern->new($pattern);

    my %arg_indices;

    my %index_arg;

    for my $i ( 0 .. ($parse->count_parts() - 1) ) {
        my $part = $parse->get_part($i);

        next if !$_part_is_arg_id{ $part->type() };

        my $arg_name = substr($pattern, $part->index(), $part->length());

        push @{$arg_indices{$arg_name}}, $part->index();

        $index_arg{$part->index()} = $arg_name;
    }

    my @given_args = sort keys %$args_hr;
    my @need_args = sort keys %arg_indices;

    if (@need_args != @given_args) {
        die sprintf("Need %d named arguments but got %d", 0 + @need_args, 0 + @given_args);
    }

    for my $i ( 0 .. $#need_args ) {
        if ($given_args[$i] ne $need_args[$i]) {
            die "Needed arguments (@need_args) mismatch given arguments (@given_args)";
        }
    }

    my @reverse_indices = sort { $b <=> $a } keys %index_arg;

    my %named_to_positional;

    my @positional_args;

    for my $index (@reverse_indices) {
        my $named_arg = $index_arg{$index};

        if (!defined $named_to_positional{$named_arg}) {
            $named_to_positional{$named_arg} = keys %named_to_positional;
            $positional_args[ $named_to_positional{$named_arg} ] = $args_hr->{$named_arg};
        }

        my $positional = $named_to_positional{$named_arg};

        substr( $pattern, $index, length($named_arg), $positional );
    }

    return $self->format($pattern, \@positional_args);
}

1;
