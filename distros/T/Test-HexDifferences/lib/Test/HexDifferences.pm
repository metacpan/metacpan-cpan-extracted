package Test::HexDifferences; ## no critic (TidyCode)

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [
        qw(eq_or_dump_diff dumped_eq_dump_or_diff),
    ],
    groups  => {
        default => [ qw(eq_or_dump_diff dumped_eq_dump_or_diff) ],
    },
};
use Test::Builder::Module;
use Test::HexDifferences::HexDump qw(hex_dump);
use Text::Diff qw(diff);

our $VERSION = '1.000';

my $builder = Test::Builder->new;

my %diff_arg_of = (
    STYLE       => 'Table',
    INDEX_LABEL => 'Ln',
    FILENAME_A  => 'Got',
    FILENAME_B  => 'Expected',
);

sub eq_or_dump_diff ($$;$$) { ## no critic (SubroutinePrototypes)
    my ($got, $expected, @more) = @_;

    my $attr_ref
        = ( @more && ref $more[0] eq 'HASH' )
        ? shift @more
        : ();
    my $both_undefined
       = ! defined $got
       && ! defined $expected;
    my $any_undefined
       = ! defined $got
       || ! defined $expected;
    if ( $both_undefined || $any_undefined ) {
        my $result
            = $both_undefined
            || ! $any_undefined && $got eq $expected;
        $got      = defined $got      ? $got      : 'undef';
        $expected = defined $expected ? $expected : 'undef';
        my $ok = $builder->ok($result, $more[0])
            or $builder->diag(
                diff(
                    \$got,
                    \$expected,
                    \%diff_arg_of,
                ),
            );
        return $ok;
    }
    my $ok = $builder->ok($got eq $expected, $more[0])
        or $builder->diag(
            diff(
                \hex_dump($got, $attr_ref),
                \hex_dump($expected, $attr_ref),
                \%diff_arg_of,
            ),
        );

    return $ok;
}

sub dumped_eq_dump_or_diff ($$;$$) { ## no critic (SubroutinePrototypes)
    my ($got, $expected_dump, @more) = @_;

    my $attr_ref
        = ( @more && ref $more[0] eq 'HASH' )
        ? shift @more
        : ();
    $got = defined $got
        ? hex_dump($got, $attr_ref)
        : 'undef';
    $expected_dump = defined $expected_dump
        ? $expected_dump
        : 'undef';
    $expected_dump = defined $expected_dump ? $expected_dump : q{};
    my $ok = $builder->ok($got eq $expected_dump, $more[0])
        or $builder->diag(
            diff(
                \$got,
                \$expected_dump,
                \%diff_arg_of,
            ),
        );

    return $ok;
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences - Test binary as hexadecimal string

=head1 VERSION

1.000

=head1 SYNOPSIS

    use Test::HexDifferences;

    eq_or_dump_diff(
        $got,
        $expected,
    );

    eq_or_dump_diff(
        $got,
        $expected,
        $test_name,
    );

    eq_or_dump_diff(
        $got,
        $expected,
        {
            address => $start_address,
            format  => "%a : %4C : %d\n",
        }
        $test_name,
    );

If C<$got> or C<$expected> is C<undef> or a reference,
the hexadecimal formatter is off.
Then C<eq_or_dump_diff> is a text compare.

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
    );

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        $test_name,
    );

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        {
            address => $start_address,
            format  => "%a : %4C : %d\n",
        }
        $test_name,
    );

See L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>
for the format description.

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.t files.

=head1 DESCRIPTION

The are some special cases for testing binary data.

=over

=item * The ascii format is not good for e.g. a length byte 0x41 displayed as A.

=item * Multibyte values are better shown as 1 value.

=item * Structured binary e.g. 2 byte length followed by bytes better are shown as it is.

=item * Compare 2 binary or 1 binary and a dump.

=back

=head1 SUBROUTINES/METHODS

=head2 subroutine eq_or_dump_diff

    eq_or_dump_diff(
        $got_value,
        $expected_value,
        {                                      # optional hash reference
            address => $display_start_address, # optional
            format  => $format_string,         # optional
        }
        $test_name,                            # optional
    );

=head2 subroutine dumped_eq_dump_or_diff

    dumped_eq_dump_or_diff(
        $got_value,
        $expected_dump,
        {                                      # optional hash reference
            address => $display_start_address, # optional
            format  => $format_string,         # optional
        }
        $test_name,                            # optional
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Sub::Exporter|Sub::Exporter>

L<Test::Builder::Module|Test::Builder::Module>

L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>

L<Text::Diff|Text::Diff>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Test::HexDifferences::HexDump|Test::HexDifferences::HexDump>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
