package Verilog::VCD;

use warnings;
use strict;
use Carp qw(croak);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
                        parse_vcd list_sigs get_timescale get_endtime
                        get_date get_version get_dumps get_closetime
                        get_decl_comments get_sim_comments
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.08';

my $timescale;
my $endtime;
my $closetime;
my $date;
my $version;
my @decl_comments;
my @sim_comments;
my %dumps;

sub list_sigs {
    # Parse input VCD file into data structure,
    # then return just a list of the signal names.
    my $file = shift;
    unless (defined $file) {
        croak('Error: list_sigs requires a filename. It seems like no ',
              'filename was provided or filename was undefined');
    }
    my $vcd = parse_vcd($file, {only_sigs => 1});

    my @sigs;
    for my $code (keys %{ $vcd }) {
        my @nets = @{ $vcd->{$code}->{nets} };
        push @sigs, map { "$_->{hier}.$_->{name}" } @nets;
    }
    return @sigs;
}

sub parse_vcd {
    # Parse input VCD file into data structure.
    # Also, print t-v pairs to STDOUT, if requested.
    my ($file, $opt) = @_;

    unless (defined $file) {
        croak('Error: parse_vcd requires a filename.  It seems like no ',
              'filename was provided or filename was undefined');
    }

    if ($opt) {
        unless (ref($opt) eq 'HASH') {
            croak('Error: If options are passed to parse_vcd, they must be ',
                  'passed as a hash reference.');
        }
    }

    my $only_sigs = (exists $opt->{only_sigs}) ? 1 : 0;

    my $all_sigs;
    my %usigs;
    if (exists $opt->{siglist}) {
        %usigs = map { $_ => 1 } @{ $opt->{siglist} };
        unless (%usigs) {
            croak('Error: The signal list passed using siglist was empty.');
        }
        $all_sigs = 0;
    }
    else {
        $all_sigs = 1;
    }

    my $use_stdout = (exists $opt->{use_stdout}) ? 1 : 0;

    open my $fh, '<', $file or croak("Error: Can not open VCD file $file: $!");

    # Parse declaration section of VCD file
    my %data;
    my $mult;
    my @hier;
    @decl_comments = ();
    while (<$fh>) {
        if (s/ ^ \s* \$ (\w+) \s+ //x) {
            my $keyword = $1;
            my @lines = read_more_lines($fh, $_);
            if ($keyword eq 'date') {
                $date = join "\n", @lines;
            }
            elsif ($keyword eq 'version') {
                $version = join "\n", @lines;
            }
            elsif ($keyword eq 'comment') {
                push @decl_comments, join "\n", @lines;
            }
            elsif ($keyword eq 'timescale') {
                $mult = calc_mult("@lines", $opt);
            }
            elsif ($keyword eq 'scope') {
                my $scope = "@lines";
                push @hier, (split /\s+/, $scope)[1]; # just keep scope name
            }
            elsif ($keyword eq 'upscope') {
                pop @hier;
            }
            elsif ($keyword eq 'var') {
                my $var = "@lines";
                #   $var reg 1 *@ data $end
                #   $var wire 4 ) addr [3:0] $end
                #   $var port [3:0] <4 addr $end
                my ($type, $size, $code, $name) = split /\s+/, $var, 4;
                $name =~ s/ \s //xg;
                $name .= $size if ($type eq 'port') and ($size ne '1');
                my $path = join '.', @hier;
                my $full_name = "$path.$name";
                push @{ $data{$code}{nets} }, {
                    type => $type,
                    name => $name,
                    size => $size,
                    hier => $path,
                } if exists $usigs{$full_name} or $all_sigs;
            }
            else { # enddefinitions
                last;
            }
        }
    }

    my $num_sigs = scalar keys %data;
    unless ($num_sigs) {
        if ($all_sigs) {
            croak("Error: No signals were found in the VCD file $file.",
                  'Check the VCD file for proper $var syntax.');
        }
        else {
            croak("Error: No matching signals were found in the VCD file $file.",
                  ' Use list_sigs to view all signals in the VCD file.');
        }
    }
    if (($num_sigs>1) and $use_stdout) {
        croak("Error: There are too many signals ($num_sigs) for output ",
              'to STDOUT.  Use list_sigs to select a single signal.');
    }

    unless ($only_sigs) {
        # Parse simulation section of VCD file
        # Continue reading file
        @sim_comments = ();
        %dumps = ();
        undef $closetime;
        my $time = 0;
        while (<$fh>) {
            trim($_);
            if (s/ ^ \$ comment \s* //x) {
                my $comment = join "\n", read_more_lines($fh, $_);
                push @sim_comments, {time => $time, comment => $comment};
            }
            if (s/ ^ \$ vcdclose \s* //x) {
                my $close = join "\n", read_more_lines($fh, $_);
                ($closetime) = $close =~ / ^ [#] (\d+) /x;
                $closetime *= $mult;
            }
            elsif (/ ^ \$ (dump \w+) /x) {
                push @{ $dumps{$1} }, $time;
            }
            elsif (/ ^ [#] (\d+) /x) {
                $time = $mult * $1;
            }
            elsif (/ ^ ([01zx]) (.+) /xi  or / ^ [br] (\S+) \s+ (.+) /xi) {
                my $value = lc $1;
                my $code  = $2;
                if (exists $data{$code}) {
                    if ($use_stdout) {
                        print "$time $value\n";
                    }
                    else {
                        push @{ $data{$code}{tv} }, [$time, $value];
                    }
                }
            }
            elsif (/ ^ p /x) { # Extended VCD format
                my @tokens = split;
                $tokens[0] =~ s/p//;
                my $code  = pop @tokens;
                if (exists $data{$code}) {
                    if ($use_stdout) {
                        print "$time @tokens\n";
                    }
                    else {
                        push @{ $data{$code}{tv} }, [$time, @tokens];
                    }
                }
            }
        }
        $endtime = $time;
    }

    close $fh;

    return \%data;
}

sub read_more_lines {
    # Read more lines of the VCD file for keywords terminated with $end.
    # These keywords may be on one line or multiple lines.
    # Remove the $end token and return an array of lines.
    my $fh   = shift;
    my $line = shift;
    my @lines;
    push @lines, $line if length $line;
    while ($line !~ / \$end \b /x) {
        $line = <$fh>;
        push @lines, $line;
    }
    for my $line (@lines) {
        trim($line);
        $line =~ s/ \s* \$end \b //x;
    }
    pop @lines unless length $lines[-1];
    return @lines;
}

sub calc_mult {
    # Calculate a new multiplier for time values.
    # Return numeric multiplier.
    # Also sets the package $timescale variable.

    my ($tscale, $opt) = @_;

    my $new_units;
    if (exists $opt->{timescale}) {
        $new_units = lc $opt->{timescale};
        $new_units =~ s/\s//g;
        $timescale = "1$new_units";
    }
    else {
        $timescale = $tscale;
        return 1;
    }

    my $mult;
    my $units;
    if ($tscale =~ / (\d+) \s* ([a-z]+) /xi) {
        $mult  = $1;
        $units = lc $2;
    }
    else {
        croak("Error: Unsupported timescale found in VCD file: $tscale.  ",
              'Refer to the Verilog LRM.');
    }

    my %mults = (
        'fs' => 1e-15,
        'ps' => 1e-12,
        'ns' => 1e-09,
        'us' => 1e-06,
        'ms' => 1e-03,
         's' => 1e-00,
    );
    my $usage = join '|', sort { $mults{$a} <=> $mults{$b} } keys %mults;

    my $scale;
    if (exists $mults{$units}) {
        $scale = $mults{$units};
    }
    else {
        croak("Error: Unsupported timescale units found in VCD file: $units.  ",
              "Supported values are: $usage");
    }

    my $new_scale;
    if (exists $mults{$new_units}) {
        $new_scale = $mults{$new_units};
    }
    else {
        croak("Error: Illegal user-supplied timescale: $new_units.  ",
              "Legal values are: $usage");
    }

    return (($mult * $scale) / $new_scale);
}

sub trim {
    # Modify input string in-place
    $_[0] =~ s/ \s+ \z //x;  # Remove trailing whitespace
    $_[0] =~ s/ ^ \s+  //x;  # Remove leading  whitespace
}

sub get_timescale {
    return $timescale;
}

sub get_endtime {
    return $endtime;
}

sub get_closetime {
    return $closetime;
}

sub get_date {
    return $date;
}

sub get_version {
    return $version;
}

sub get_decl_comments {
    return @decl_comments;
}

sub get_sim_comments {
    return @sim_comments;
}

sub get_dumps {
    return %dumps;
}


=head1 NAME

Verilog::VCD - Parse a Verilog VCD text file

=head1 VERSION

This document refers to Verilog::VCD version 0.08.

=head1 SYNOPSIS

    use Verilog::VCD qw(parse_vcd);
    my $vcd = parse_vcd('/path/to/some.vcd');

=head1 DESCRIPTION

Verilog is a Hardware Description Language (HDL) used to model digital logic.
While simulating logic circuits, the values of signals can be written out to
a Value Change Dump (VCD) file.  This module can be used to parse a VCD file
so that further analysis can be performed on the simulation data.  The entire
VCD file can be stored in a Perl data structure and manipulated using
standard hash and array operations.

=head2 Input File Syntax

The syntax of the VCD text file is described in the documentation of the
IEEE standard for Verilog.  Both VCD formats (4-state and Extended) are
supported.  Since the input file is assumed to be legal VCD syntax, only
minimal validation is performed.

=head1 SUBROUTINES


=head2 parse_vcd($file, $opt_ref)

Parse a VCD file and return a reference to a data structure which
includes hierarchical signal definitions and time-value data for all
the specified signals.  A file name is required.  By default, all
signals in the VCD file are included, and times are in units
specified by the C<$timescale> VCD keyword.

    my $vcd = parse_vcd('/path/to/some.vcd');

It returns a reference to a nested data structure.  The top of the
structure is a Hash-of-Hashes.  The keys to the top hash are the VCD
identifier codes for each signal.  The following is an example
representation of a very simple 4-state VCD file.  It shows one signal named
C<chip.cpu.alu.clk>, whose VCD code is C<+>.  The time-value pairs
are stored as an Array-of-Arrays, referenced by the C<tv> key.  The
time is always the first number in the pair, and the times are stored in
increasing order in the array.

    {
      '+' => {
               'tv' => [
                         [
                           '0',
                           '1'
                         ],
                         [
                           '12',
                           '0'
                         ],
                       ],
               'nets' => [
                           {
                             'hier' => 'chip.cpu.alu.',
                             'name' => 'clk',
                             'type' => 'reg',
                             'size' => '1'
                           }
                         ]
             }
    };

Since each code could have multiple hierarchical signal names, the names are
stored as an Array-of-Hashes, referenced by the C<nets> key.  The example above
only shows one signal name for the code.

For the Extended VCD format, the C<tv> key returns an array of 4-element arrays:

    time value strength0 strength1

=head3 OPTIONS

Options to C<parse_vcd> should be passed as a hash reference.

=over 4

=item timescale

It is possible to scale all times in the VCD file to a desired timescale.
To specify a certain timescale, such as nanoseconds:

    my $vcd = parse_vcd($file, {timescale => 'ns'});

Valid timescales are:

    s ms us ns ps fs

=item siglist

If only a subset of the signals included in the VCD file are needed,
they can be specified by a signal list passed as an array reference.
The signals should be full hierarchical paths separated by the dot
character.  For example:

    my @signals = qw(
        top.chip.clk
        top.chip.cpu.alu.status
        top.chip.cpu.alu.sum[15:0]
    );
    my $vcd = parse_vcd($file, {siglist => \@signals});

Limiting the number of signals can substantially reduce memory usage of the
returned data structure because only the time-value data for the selected
signals is loaded into the data structure.

=item use_stdout

It is possible to print time-value pairs directly to STDOUT for a
single signal using the C<use_stdout> option.  If the VCD file has
more than one signal, the C<siglist> option must also be used, and there
must only be one signal specified.  For example:

    my $vcd = parse_vcd($file, {
                    use_stdout => 1,
                    siglist    => [(top.clk)]
                });

The time-value pairs are output as space-separated tokens, one per line.
For example, for a 4-state VCD file:

    0 x
    15 0
    277 1
    500 0

Times are listed in the first column.
Time units can be controlled by the C<timescale> option.

=item only_sigs

Parse a VCD file and return a reference to a data structure which
includes only the hierarchical signal definitions.  Parsing stops once
all signals have been found.  Therefore, no time-value data are
included in the returned data structure.  This is useful for
analyzing signals and hierarchies.

    my $vcd = parse_vcd($file, {only_sigs => 1});

=back


=head2 list_sigs($file)

Parse a VCD file and return a list of all signals in the VCD file.
Parsing stops once all signals have been found.  This is
helpful for deciding how to limit what signals are parsed.

Here is an example:

    my @signals = list_sigs('input.vcd');

The signals are full hierarchical paths separated by the dot character

    top.chip.cpu.alu.status
    top.chip.cpu.alu.sum[15:0]

=head2 get_timescale( )

This returns a string corresponding to the timescale as specified
by the C<$timescale> VCD keyword.  It returns the timescale for
the last VCD file parsed.  If called before a file is parsed, it
returns an undefined value.  If the C<parse_vcd> C<timescale> option
was used to specify a timescale, the specified value will be returned
instead of what is in the VCD file.

    my $vcd = parse_vcd($file); # Parse a file first
    my $ts  = get_timescale();  # Then query the timescale

=head2 get_endtime( )

This returns the last time found in the VCD file, scaled
appropriately.  It returns the last time for the last VCD file parsed.
If called before a file is parsed, it returns an undefined value.
This should not be confused with closetime.

    my $vcd = parse_vcd($file); # Parse a file first
    my $et  = get_endtime();    # Then query the endtime

=head2 get_closetime( )

For the Extended VCD format, this returns the time specified by the
C<$vcdclose> keyword in the VCD file, scaled appropriately.  It returns the
last closetime for the last VCD file parsed.  If called before a file is
parsed, it returns an undefined value.  For the 4-state VCD format, it
returns an undefined value.

    my $vcd = parse_vcd($file); # Parse a file first
    my $ct  = get_closetime();  # Then query the closetime

=head2 get_date( )

This returns a string corresponding to the date as specified
by the C<$date> VCD keyword.  It returns the date for
the last VCD file parsed.  If called before a file is parsed, it
returns an undefined value.

    my $vcd  = parse_vcd($file); # Parse a file first
    my $date = get_date();       # Then query the date

=head2 get_version( )

This returns a string corresponding to the version as specified
by the C<$version> VCD keyword.  It returns the version for
the last VCD file parsed.  If called before a file is parsed, it
returns an undefined value.

    my $vcd     = parse_vcd($file); # Parse a file first
    my $version = get_version();    # Then query the version

=head2 get_decl_comments( )

This returns an array corresponding to the comments as specified by the
C<$comment> VCD keyword in the declaration section of the VCD file.  There
may be any number of C<$comment> keywords in the file.  It returns the
comments for the last VCD file parsed.  If called before a file is parsed,
it returns an empty array.  If there are no C<$comment> keywords in the
declaration section of the file, it returns an empty array.

    my $vcd   = parse_vcd($file);    # Parse a file first
    my @comms = get_decl_comments(); # Then query the comments

=head2 get_sim_comments( )

This returns an array-of-hashes corresponding to the comments as specified
by the C<$comment> VCD keyword in the simulation section of the VCD file.
There may be any number of C<$comment> keywords in the file.  It returns
the comments for the last VCD file parsed.  If called before a file is
parsed, it returns an empty array.  If there are no C<$comment> keywords in
the declaration section of the file, it returns an empty array.

    my $vcd   = parse_vcd($file);    # Parse a file first
    my @comms = get_sim_comments();  # Then query the comments

The time at which the comment occurred is included with each comment.
An example returned structure is:

    ({time => 123, comment => '1st comment'},
     {time => 456, comment => '2nd comment'})

=head2 get_dumps( )

This returns a hash-of-arrays corresponding to the C<$dump*> VCD keywords
(C<$dumpvars>, C<$dumpon>, etc.) in the simulation section of the VCD
file.  The keys of the hash are the keywords, and the values are the
simulation times at which the keywords occurred.  It returns the dump
commands for the last VCD file parsed.  If called before a file is parsed,
it returns an empty hash.

    my $vcd   = parse_vcd($file);   # Parse a file first
    my %dumps = get_dumps();        # Then query the dump commands

=head1 EXPORT

Nothing is exported by default.  Functions may be exported individually, or
all functions may be exported at once, using the special tag C<:all>.

=head1 DIAGNOSTICS

Error conditions cause the program to die using C<croak> from the
L<Carp|Carp> Core module.

=head1 LIMITATIONS

The default mode of C<parse_vcd> is to load the entire VCD file into the
data structure.  This could be a problem for huge VCD files.  The best solution
to any memory problem is to plan ahead and keep VCD files as small as possible.
When simulating, dump fewer signals and scopes, and use shorter dumping
time ranges.  Another technique is to parse only a small list of signals
using the C<siglist> option; this method only loads the desired signals into
the data structure.  Finally, the C<use_stdout> option will parse the input VCD
file line-by-line, instead of loading it into the data structure, and directly
prints time-value data to STDOUT.  The drawback is that this only applies to
one signal.

=head1 BUGS

There are no known bugs in this module.

=head1 SEE ALSO

Refer to the following Verilog documentation:

    IEEE Standard for SystemVerilog
    Unified Hardware Design, Specification and Verification Language
    IEEE Std 1800-2012
    Section 21.7, "Value change dump (VCD) files"

=head1 AUTHOR

Gene Sullivan (gsullivan@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Gene Sullivan.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See L<perlartistic|perlartistic>.

=cut

1;

