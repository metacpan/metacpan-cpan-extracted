package Verilog::Readmem;

use warnings;
use strict;
use Carp;

require Exporter;
our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(parse_readmem);
our @EXPORT;

our $VERSION = '0.05';


sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub parse_readmem {
    my ($arg_ref) = @_;
    my $file;
    my $hex_mode;
    my $numeric;

    # Check inputs.
    if (exists $arg_ref->{filename}) {
        $file = $arg_ref->{filename};
    }
    else {
        croak "Error: filename is required.\n";
    }

    if (exists $arg_ref->{binary}) {
        $hex_mode = ($arg_ref->{binary} eq 1) ? 0 : 1;
    }
    else {
        $hex_mode = 1;
    }

    if (exists $arg_ref->{string}) {
        $numeric = ($arg_ref->{string} eq 1) ? 0 : 1;
    }
    else {
        $numeric = 1;
    }

    # Remove comments from input file.
    my $lines = remove_comments($file);
    $lines =~ s/^\s+//m;    # Remove any leading whitespace prior to split
    my @tokens = split /\s+/, $lines;

    # Create array-of-arrays corresponding to all address blocks.
    my @all_blocks;
    my @block;
    push @block, '0';
    for (@tokens) {
        $_ = lc;
        if (/^@/) {
            my $addr = check_addr($_, $numeric);
            if (@block > 1) {push @all_blocks, [@block]}
            @block = ();
            push @block, $addr;
        }
        else {
            push @block, check_data($_, $hex_mode, $numeric);
        }
    }
    if (@block > 1) {push @all_blocks, [@block]}

    return \@all_blocks;
}

sub check_data {
    # Check for proper syntax of a data token.
    # Return transformed data, if there are no errors.
    my ($dat, $hex_mode, $numeric) = @_;
    if ($dat =~ /^_/) {
        croak "Error: illegal leading underscore for data '$dat'.\n";
    }
    if ($numeric) {     # Convert to numeric
        $dat =~ s/_//g;
        if ($hex_mode) {
            croak "Error: unsupported characters in 2-state readmemh input '$dat'.\n" if ($dat =~ /[^\da-f]/);
            croak "Error: Hex value exceeds 32-bits '$dat'.\n" if (length($dat) > 8);
            $dat = hex $dat;
        }
        else {
            croak "Error: unsupported characters in 2-state readmemb input '$dat'.\n" if ($dat =~ /[^01]/);
            croak "Error: Binary value exceeds 32-bits '$dat'.\n" if (length($dat) > 32);
            $dat = bin2dec($dat);
        }
    }
    else {      # String mode
        if ($hex_mode) {
            croak "Error: unsupported characters in 4-state readmemh input '$dat'.\n" if ($dat =~ /[^\da-fxz_]/);
        }
        else {
            croak "Error: unsupported characters in 4-state readmemb input '$dat'.\n" if ($dat =~ /[^01xz_]/);
        }
    }
    return $dat;
}

sub check_addr {
    # Check for proper syntax of an address token.
    # Return transformed address, if there are no errors.
    my ($addr, $numeric) = @_;
    $addr =~ s/^@//;
    return 0 unless length $addr;
    if ($numeric) {     # Convert to numeric
        $addr =~ s/_//g;
        return 0 unless length $addr;
        croak "Error: unsupported characters in 2-state address '$addr'.\n" if ($addr =~ /[^\da-f]/);
        croak "Error: Hex address exceeds 32-bits '$addr'.\n" if (length($addr) > 8);
        $addr = hex $addr;
    }
    else {      # String mode
        croak "Error: unsupported characters in 2-state string address '$addr'.\n" if ($addr =~ /[^\da-f_]/);
    }
    return $addr;
}

sub remove_comments {
    # Remove C++ and Verilog comments from input file and return all
    # lines as a string.
    # Removes block comments (/**/) and single-line comments (//).

    # Slurp file into $lines variable.
    my $file = shift;
    local $/ = undef;
    open my $IN_FH, '<', $file or croak "Error: Can not open file $file: $!";
    my $lines = <$IN_FH>;
    close $IN_FH;

    # 1st, insert space before all /*
    # This handles corner case not handled by perlfaq6 regex below.
    # If the input file contains "123/*456*/789", the perlfaq6 regex
    # will remove the comments, but leave a single value: 123789.
    # But, ncverilog and vcs will replace the comment with a space,
    # leaving 2 values: 123 and 789.  This is the desired behavior.
    # Wait... before we do that, we have to account for the other
    # corner case of "//*": this is really a single-line comment,
    # not a multi-line comment.
    $lines =~ s{//\*}{// \*}g;
    $lines =~ s{/\*}{ /\*}g;

    # Use regex from perlfaq6 (C++ comments).
    $lines =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//[^\n]*|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $2 ? $2 : ""#gse;

    # Returns all lines as a string
    return $lines;
}


=head1 NAME

Verilog::Readmem - Parse Verilog $readmemh or $readmemb text file

=head1 VERSION

This document refers to Verilog::Readmem version 0.05.

=head1 SYNOPSIS

    use Verilog::Readmem qw(parse_readmem);

    # Read memory file into Array-Of-Arrays data structure:
    my $mem_ref = parse_readmem({filename => 'memory.hex'});

    my $num_blocks = scalar @{$mem_ref};
    print "num_blocks = $num_blocks\n";

    # It is typical to have only one data block.
    # Sum up all data values.
    if ($num_blocks == 1) {
        my ($addr, @data) = @{ $mem_ref->[0] };
        my $sum = 0;
        for (@data) { $sum += $_ }
        print "addr = $addr, data sum = $sum\n";
    }

=head1 DESCRIPTION

The Verilog Hardware Description Language (HDL) provides a convenient
way to load a memory during logic simulation.  The C<$readmemh()> and
C<$readmemb()> system tasks are used in the HDL source code to import
the contents of a text file into a memory variable.

In addition to having the simulator software read in these memory files,
it is also useful to analyze the contents of the file outside
of the simulator.  For example, it may be useful to derive some
simulation parameters from the memory file prior to running the
simulation.  Data stored at different addresses may be combined
arithmetically to produce other meaningful values.  In some cases,
it is simpler to perform these calculations outside of the simulator.

C<Verilog::Readmem> emulates the Verilog C<$readmemh()> and C<$readmemb()>
system tasks.  The same memory file which is read in by the
simulator can also be read into a Perl program, potentially easing
the burden of having the HDL code perform numeric calculations
or string manipulations.

=head2 Input File Syntax

The syntax of the text file is described in the documentation of
the IEEE standard for Verilog.  Briefly, the file contains two types
of tokens: data and optional addresses.  The tokens are separated by
whitespace and comments.  Comments may be single-line (//) or
multi-line (/**/), similar to C++.  Addresses are specified by a leading
"at" character (@) and are always hexadecimal strings.  Data values
are either hexadecimal strings (C<$readmemh>) or binary strings (C<$readmemb>).
Data and addresses may contain underscore (_) characters.  The syntax
supports 4-state logic for data values (0, 1, x, z), where x represents
an unknown value and z represents the high impedance value.

If no address is specified, the data is assumed to start at address 0.
Similarly, if data exists before the first specified address, then that data
is assumed to start at address 0.

There are many corner cases which are not explicitly mentioned in the
Verilog document.  In each instance, this module was designed to behave
the same as two widely-known, commercially-available simulators.

=head1 SUBROUTINES


=over 4

=item parse_readmem

Read in a Verilog $readmem format text file and return the addresses
and data as a reference to an array of arrays.  All comments are
stripped out.  All options to the C<parse_readmem> function must
be passed as a single B<hash>.

=back

=head2 OPTIONS

=over 4

=item filename

A filename must be provided.

    my $mem_ref = parse_readmem({filename => 'memory.hex'});

=item binary

By default, the input file format is hexadecimal, consistent with
the Verilog C<$readmemh()> system task.  To read in a binary format,
consistent with the Verilog C<$readmemb()> system task,
use C<< binary=>1 >>.

    my $mem_ref = parse_readmem({filename=>$file, binary=>1});

=item string

By default, all addresses and data values will be converted
to numeric (decimal) values.  If numeric conversion is not
desired, use C<< string=>1 >>.

    my $mem_ref = parse_readmem({filename=>$file, string=>1});

In numeric conversion mode, data must represent 2-state
logic (0 and 1).  If an application requires 4-state logic (0, 1, x, z),
numeric conversion must be disabled using C<< string=>1 >>.

To parse a binary format file using string mode:

    my $mem_ref = parse_readmem(
                    {
                        string      => 1,
                        binary      => 1,
                        filename    => '/path/to/file.bin'
                    }
    );

=back

=head2 EXAMPLE

The returned array-of-arrays has the following structure:

    [a0, d01, d02, d03],
    [a1, d11, d12, d13, d14, d15],
    [a2, d21, d22]

Each array corresponds to a block of memory.  The first item in
each array is the start address of the block.  All subsequent
items are data values.  In the example above, there are 3 memory
blocks.  The 1st block starts at address a0 and has 3 data values.
The 2nd block starts at address a1 and has 5 data values.
The 3rd block starts at address a2 and has 2 data values.

=head1 EXPORT

None by default.

=head1 DIAGNOSTICS

Error conditions cause the program to die using C<croak> from the
standard C<Carp> module.

=head1 LIMITATIONS

In the default numeric conversion mode, address and data values
may not be larger than 32-bit. If an application requires larger values,
numeric conversion must be disabled using C<< string=>1 >>.  This allows
for post-processing of strings in either hexadecimal or binary format.

=head1 SEE ALSO

Refer to the following Verilog documentation:

    IEEE Standard Verilog (c) Hardware Description Language
    IEEE Std 1364-2001
    Version C
    Section 17.2.8, "Loading memory data from a file"

=head1 AUTHOR

Gene Sullivan (gsullivan@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Gene Sullivan.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See L<perlartistic>.

=cut

1;

__END__
