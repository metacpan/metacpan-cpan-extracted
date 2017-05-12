package Test::HexDifferences::HexDump;  ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.008';

use Hash::Util qw(lock_keys);
use Sub::Exporter -setup => {
    exports => [
        qw(hex_dump),
    ],
    groups  => {
        default => [ qw(hex_dump) ],
    },
};

my $default_format = "%a : %4C : %d\n";

sub hex_dump {
    my ($data, $attr_ref) = @_;

    defined $data
        or return $data;
    ref $data
        and return $data;
    $attr_ref
        = ref $attr_ref eq 'HASH'
        ? $attr_ref
        : {};
    my $data_pool = {
        # global
        data               => $data,
        format             => $attr_ref->{format}  || "$default_format%*x",
        address            => $attr_ref->{address} || 0,
        output             => q{},
        # to format a block
        format_block       => undef,
        data_length        => undef,
        is_multibyte_error => undef,
    };
    lock_keys %{$data_pool};
    BLOCK:
    while ( length $data_pool->{data} ) {
        _next_format($data_pool);
        _format_items($data_pool);
    }

    return $data_pool->{output};
}

sub _next_format {
    my $data_pool = shift;

    my $is_match = $data_pool->{format} =~ s{
        \A
          ( .*? [^%] )               # format of the block
          % ( 0* [1-9] \d* | [*] ) x # repetition factor
    } {
        my $new_count = $2 eq q{*} ? q{*} : $2 - 1;
        $data_pool->{format_block} = $1;
        $new_count
        ? "$1\%${new_count}x"
        : q{};
    }xmse;
    if ( $data_pool->{is_multibyte_error} || ! $is_match ) {
        $data_pool->{format}             = "$default_format%*x";
        $data_pool->{format_block}       = $default_format;
        $data_pool->{is_multibyte_error} = 0;
        return;
    }

    return;
}

sub _format_items {
    my $data_pool = shift;

    $data_pool->{data_length} = 0;
    RUN: {
        # % written as %%
        $data_pool->{format_block} =~ s{
            \A % ( % )
        } {
            do {
                $data_pool->{output} .= $1;
                q{};
            }
        }xmse and redo RUN;
        # \n written as %\n will be ignored
        $data_pool->{format_block} =~ s{
            \A % [\n]
        }{}xms and redo RUN;
        # address
        _format_address($data_pool)
            and redo RUN;
        # words
        _format_word($data_pool)
            and redo RUN;
        # display ASCII
        _format_ascii($data_pool)
            and redo RUN;
        # display any other char
        $data_pool->{format_block} =~ s{
            \A (.)
        } {
            do {
                $data_pool->{output} .= $1;
                q{};
            }
        }xmse and redo RUN;
        if ( $data_pool->{data_length} ) {
            # clear already displayed data
            substr $data_pool->{data}, 0, $data_pool->{data_length}, q{};
            $data_pool->{data_length} = 0;
        }
    }

    return;
}

sub _format_address {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A % ( 0* [48]? ) a
    } {
        do {
            my $length = $1 || 4;
            $data_pool->{output}
                .= sprintf "%0${length}X", $data_pool->{address};
            q{};
        }
    }xmse;
}

my $big_endian    = q{>};
my $little_endian = q{<};
my $machine_endian
    = ( pack 'S', 1 ) eq ( pack 'n', 1 )
    ? $big_endian # network order
    : $little_endian;
my %format_of = (
    'C'  => { # unsigned char
        bytes  => 1,
        endian => $big_endian,
    },
    'S'  => { # unsigned 16-bit, endian depends on machine
        bytes  => 2,
        endian => $machine_endian,
    },
    'S<' => { # unsigned 16-bit, little-endian
        bytes  => 2,
        endian => $little_endian,
    },
    'S>' => { # unsigned 16-bit, big-endian
        bytes  => 2,
        endian => $big_endian,
    },
    'v'  => { # unsigned 16-bit, little-endian
        bytes  => 2,
        endian => $little_endian,
    },
    'n'  => { # unsigned 16-bit, big-endian
        bytes  => 2,
        endian => $big_endian,
    },
    'L'  => { # unsigned 32-bit, endian depends on machine
        bytes  => 4,
        endian => $machine_endian,
    },
    'L<' => { # unsigned 32-bit, little-endian
        bytes  => 4,
        endian => $little_endian,
    },
    'L>' => { # unsigned 32-bit, big-endian
        bytes  => 4,
        endian => $big_endian,
    },
    'V'  => { # unsigned 32-bit, little-endian
        bytes  => 4,
        endian => $little_endian,
    },
    'N'  => { # unsigned 32-bit, big-endian
        bytes  => 4,
        endian => $big_endian,
    },
    'Q'  => { # unsigned 64-bit, endian depends on machine
        bytes  => 8,
        endian => $machine_endian,
    },
    'Q<' => { # unsigned 64-bit, little-endian
        bytes  => 8,
        endian => $little_endian,
    },
    'Q>' => { # unsigned 64-bit, big-endian
        bytes  => 8,
        endian => $big_endian,
    },
);

sub _format_word {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A
        % ( 0* [1-9] \d* )?
        ( [LSQ] [<>] | [CVNvnLSQ] )
    } {
        do {
            my ($byte_length, $endian)
                = @{ $format_of{$2} }{ qw(bytes endian) };
            $data_pool->{output} .= join q{ }, map {
                (
                    length $data_pool->{data}
                    >= $data_pool->{data_length} + $byte_length
                )
                ? do {
                    my @unpacked
                        = unpack
                            q{C} x $byte_length,
                            substr
                                $data_pool->{data},
                                $data_pool->{data_length},
                                $byte_length;
                    if ( $endian eq q{<} ) {
                        @unpacked = reverse @unpacked;
                    }
                    my $hex = sprintf
                        '%02X' x $byte_length,
                        @unpacked;
                    $data_pool->{data_length} += $byte_length;
                    $data_pool->{address}     += $byte_length;
                    $hex;
                }
                : do {
                    if ( $byte_length > 1 ) {
                        $data_pool->{is_multibyte_error}++;
                    }
                    q{ } x 2 x $byte_length;
                };
            } 1 .. ( $1 || 1 );
            q{};
        }
    }xmse;
}

sub _format_ascii {
    my $data_pool = shift;

    return $data_pool->{format_block} =~ s{
        \A %d
    } {
        do {
            my $data = substr $data_pool->{data}, 0, $data_pool->{data_length};
            $data =~ s{
                ( ['"\\] )
                | ( [!-~] )
                | .
            } {
                defined $1   ? q{.}
                : defined $2 ? $2
                :              q{.}
            }xmsge;
            $data_pool->{output} .= $data;
            q{};
        }
    }xmse;
}

# $Id$

1;

__END__

=head1 NAME

Test::HexDifferences::HexDump - Format binary to hexadecimal strings

=head1 VERSION

0.008

=head1 SYNOPSIS

    use Test::HexDifferences::HexDump;

    $string = hex_dump(
        $binary,
    );

    $string = hex_dump(
        $binary,
        {
            address => $start_address,
            format  => "%a : %4C : %d\n",
        }
    );

=head2 Format elements

Every format element in the format string is starting with % like sprintf.

If the given format is shorter defined as needed for the data length
the remaining data are displayed in default format.
If the given format is longer defined as the data length
the output will filled with space and it stops before next repetition.

=head3 Data format

It is not very clever to use little-endian formats for tests.
There is a fallback to bytes if multibyte formats can not displayed.

 %C  - unsigned char
 %S  - unsigned 16-bit, endian depends on machine
 %S< - unsigned 16-bit, little-endian
 %S> - unsigned 16-bit, big-endian
 %v  - unsigned 16-bit, little-endian
 %n  - unsigned 16-bit, big-endian
 %L  - unsigned 32-bit, endian depends on machine
 %L< - unsigned 32-bit, little-endian
 %L> - unsigned 32-bit, big-endian
 %V  - unsigned 32-bit, little-endian
 %N  - unsigned 32-bit, big-endian
 %Q  - unsigned 64-bit, endian depends on machine
 %Q< - unsigned 64-bit, little-endian
 %Q> - unsigned 64-bit, big-endian

"pack" and "unpack" before Perl v5.10
do not allow "<" and ">" to mark the byte order.
This is allowed here for all Perl versions.

"pack" and "unpack" on a 32 bit machine
do not allow the "Q" formats.
This is allowed here for all machines.

=head3 Address format

 %a  - 16 bit address
 %4a - 16 bit address
 %8a - 32 bit address

=head3 ASCII format

It can not display all chars.
First it must be a printable ASCII char.
It can not be anything of space, q{.}, q{'}, q{"} or q{\}.
Otherwise q{.} will be printed.

 %d - display ASCII

=head3 Repetition

 %*x - repetition endless
 %1x - repetition 1 time
 %2x - repetition 2 times
 ...

=head3 Special formats

 %\n - ignore \n

=head2 Default format

The default format is:

 "%a : %4C : %d\n"

or fully written as

 "%a : %4C : %d\n%*x"

=head2 Complex formats

The %...x allows to write mixed formats e.g.

 Format:
  %a : %N %4C : %d\n%1x%
  %a : %n %2C : %d\n%*x
 Input:
    \0x01\0x23\0x45\0x67\0x89\0xAB\0xCD\0xEF
    \0x01\0x23\0x45\0x67
    \0x89\0xAB\0xCD\0xEF
 Output:
    0000 : 01234567 89 AB CD EF : .#-Eg...
    0008 : 0123 45 67 : .#-E
    000C : 89AB CD EF : g...

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.t files.

=head1 DESCRIPTION

This is a formatter for binary data.

=head1 SUBROUTINES/METHODS

=head2 subroutine hex_dump

    $string = hex_dump(
        $binary,
        {
            address => $display_start_address,
            format  => $format_string,
        }
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Hash::Util|Hash::Util>

L<Sub::Exporter|Sub::Exporter>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Test::HexDifferences|Test::HexDifferences>

L<Data::Hexdumper|Data::HexDumper> inspired by

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
