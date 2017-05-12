package Text::FixedWidth::Helper;

=head1 NAME

Text::FixedWidth::Helper - Create or verify samples of fixed-width data

=head1 SYNOPSIS

    use Text::FixedWidth::Helper qw( d2fw f2dw );

    $output = d2fw( $delimited_input_file, $fixed_width_output_file );
    $output = f2dw( $fixed_width_output_file, $delimited_input_file );

=head1 DESCRIPTION

Preparation and verification of fixed-width data are often part of software
development projects.  Because fixed-width data is more difficult for humans
to visually decode than character-delimited data, it is often difficult to
construct and/or verify small sample files.  This library provides assistance
with that task.

This library assumes that the user of a program can type a plain-text file in
a simple format and present it, perhaps via a GUI interface, to a Perl program
using the library.

Two variations are possible: delimited-data-to-fixed-width (d2fw), and
fixed-width-to-delimited-data (fw2d).  In each case, the plain-text file
consists of two parts: metadata and sample data.  The metadata is a mapping of
data field names to the widths of the those fields in the fixed-width record.
In each case, the subroutine handling the case is exported by this module on
demand only.

=head2 Delimited data to fixed width (I<d2fw>)

In I<d2fw>, the sample data consists of at
most 3 rows of data in a pipe-delimited format.  The user presents the file to
the program, which then generates a second file which shows how those records
will look in a fixed-width format. Here is an example:

    fname            15
    mi                1
    lname            15
    customer_id      10
    city             20
    state             2
    zip               5

    Sylvester|J|Gomez|M789294592X|Rochester|NY|14618
    Arthur|X|Fridrikkson|M783891590X|Oakland|CA|94601
    Kasimir|E|Kristemanaczewski|N389182992X|Buffalo|NY|14214

The user enters one data field per line:  a string holding the field's name,
followed by one or more whitespace characters, followed by a number which is
the field's width in characters.

The user then types one blank line to separate the metadata from the sample
data.  The user then enters the metadata, one record per line, separating the
fields with pipe characters.

When this file is run through the program, a second file is generated that
looks like this:

    12345678901234567890123456789012345678901234567890123456789012345678
    |              ||              |         |                   | |    
    Sylvester      JGomez          M789294592Rochester           NY14618
    Arthur         XFridrikkson    M783891590Oakland             CA94601
    Kasimir        EKristemanaczewsN389182992Buffalo             NY14214

The index row at the top has a length equal to the sum of the sizes of the
fixed-width fields.  The second, or I<spacer> row, displays pipe characters at
the start of each fixed-width field.  Finally, the data rows show how the data
will be positioned within a fixed-width record.  In each field, data is
written flush-left and space-padded on the right.  Data which exceeds the
allotted width for a field is truncated.

While this format is very limited (I<e.g.,> it does not permit numerical
fields to be flushed-right or zero-padded on the left, it is sufficient for
visualization of sample data.

=head2 Fixed width data to delimited (I<fw2d>)

In I<f2dw>, the metadata is entered in the same way as in I<d2fw>.  The sample data
consists of at most 3 rows of fixed-width data.  The user presents the file to
the program, which then generates a second file which shows how those records
will look in a pipe-delimited format. Here is an example:

    fname            15
    mi                1
    lname            15
    customer_id      10
    city             20
    state             2
    zip               5

    Sylvester      JGomez          M789294592Rochester           NY14618
    Arthur         XFridrikkson    M783891590Oakland             CA94601
    Kasimir        EKristemanaczewsN389182992Buffalo             NY14214

Output:

    Sylvester|J|Gomez|M789294592X|Rochester|NY|14618
    Arthur|X|Fridrikkson|M783891590X|Oakland|CA|94601
    Kasimir|E|Kristemanaczews|N389182992X|Buffalo|NY|14214

Note that if data internded for a fixed-width field exceeded the field's
allotted width, it is truncated and therefore cannot be fully restored in a
delimited format.

=cut

use strict;
BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT_OK);
    $VERSION     = '0.02';
    @ISA         = qw(Exporter);
    @EXPORT_OK   = qw( d2fw fw2d );
}
use Data::Dumper;$Data::Dumper::Indent=1;
use Carp;
use Cwd;
use IO::File;
use Scalar::Util qw( looks_like_number );

=head1 SUBROUTINES

=head2 C<d2fw()>

=over 4

=item * Purpose

Given an input file with metadata (as described above) about data fields and
sample data in pipe-delimited format, generate an output file which displays
how that data will look in fixed-width format.

=item * Arguments

    $output = d2fw( $delimited_input_file, $fixed_width_output_file );

List of 2 elements, of which second element is optional: Strings holding name
of input file with delimited records and output file with fixed-width records.

If a value is not supplied for the second argument, the name of the output
file will default to that of the input file appended by C<.out>.

=item * Return Value

String holding path to output file.

=back

=cut

sub d2fw {
    my ( $input, $output ) = @_;
    croak "Could not locate input file $input"
        unless (-f $input);
    unless ($output) {
        $output = "$input.out";
    }
    my $metadata_seen = 0;
    my $sample_records_seen = 0;
    my @metadata;
    my $templ = '';
    my $datastr = '';
    my $sum = 0;
    my $DATA = IO::File->new($input, 'r');
    croak unless defined $DATA;
    while (my $l = <$DATA>) {
        chomp $l;
        $l =~ s/\s+$//;
        if ($l =~ m/^\s*$/) {
            croak "Text::FixedWidth::Helper restricts records to 1000 characters"
                if $sum > 1000;
            foreach my $el (@metadata) {
                $templ .= 'A' . $el->[1];
            }
            $metadata_seen++;
        }
        elsif (! $metadata_seen) {
            my @config = split /\s+/, $l, 2;
            croak "In metadata section, value of $config[0] must be numeric"
                unless looks_like_number $config[1];
            push @metadata, [ $config[0] => $config[1] ];
            $sum += $config[1];
        }
        else {
            if ($sample_records_seen >= 3) {
                carp "Text::FixedWidth::Helper restricts you to 3 input records";
                last;
            }
            my @record = split /\|/, $l, -1;
            my $outstr = pack($templ => @record);
            $datastr .= "$outstr\n";
            $sample_records_seen++;
        }
    }
    $DATA->close() or croak "Unable to close $input after reading";

    my $mod = $sum % 10;
    my $dec = int($sum / 10);
    my $OUT = IO::File->new($output, 'w');
    croak "Could not open $output for writing" unless defined $OUT;
    print $OUT "1234567890" for (1 .. $dec);
    print $OUT $_ for (1 .. $mod);
    print $OUT "\n";
    my $spacer = '';
    foreach my $el (@metadata) {
        $spacer .= '|';
        $spacer .= ' ' x ($el->[1] - 1);
    }
    print $OUT "$spacer\n";
    print $OUT $datastr;
    $OUT->close() or croak "Unable to close $output after writing";
    return $output;
}

=head2 C<fw2d()>

=over 4

=item * Purpose

Given an input file with metadata (as described above) about data fields and
sample data in fixed-width format, generate an output file which displays
how that data will look in pipe-delimited format.

=item * Arguments

    $output = f2dw( $fixed_width_output_file, $delimited_input_file );

=item * Return Value

String holding path to output file.

=back

=cut

sub fw2d {
    my ( $input, $output ) = @_;
    croak "Could not locate input file $input"
        unless (-f $input);
    unless ($output) {
        $output = "$input.out";
    }
    my $metadata_seen = 0;
    my $sample_records_seen = 0;
    my @metadata;
    my $templ = '';
    my @delimited_records = ();
    my $sum = 0;
    my $DATA = IO::File->new($input, 'r');
    croak unless defined $DATA;
    while (my $l = <$DATA>) {
        chomp $l;
        $l =~ s/\s+$//;
        if ($l =~ m/^\s*$/) {
            croak "Text::FixedWidth::Helper restricts records to 1000 characters"
                if $sum > 1000;
            foreach my $el (@metadata) {
                $templ .= 'A' . $el->[1];
            }
            $metadata_seen++;
        }
        elsif (! $metadata_seen) {
            my @config = split /\s+/, $l, 2;
            croak "In metadata section, value of $config[0] must be numeric"
                unless looks_like_number $config[1];
            push @metadata, [ $config[0] => $config[1] ];
            $sum += $config[1];
        }
        else {
            if ($sample_records_seen >= 3) {
                carp "Text::FixedWidth::Helper restricts you to 3 input records";
                last;
            }
            my @record = unpack($templ => $l);
            my @parsed_record = ();
            for (my $f = 0; $f <= $#record; $f++) {
                push @parsed_record, [ $metadata[$f]->[0], $record[$f] ];
            }
            push @delimited_records, \@parsed_record;
            $sample_records_seen++;
        }
    }
    $DATA->close() or croak "Unable to close $input after reading";

    my $OUT = IO::File->new($output, 'w');
    croak "Could not open $output for writing"
        unless defined $OUT;
    foreach my $record (@delimited_records) {
        foreach my $field (@{$record}) {
            print $OUT "$field->[0]|$field->[1]\n";
        }
        print $OUT "\n";
    }

    $OUT->close() or croak "Unable to close $output after writing";
    return $output;
}

1;

#################### DOCUMENTATION ###################

=head1 AUTHOR

    James E Keenan
    CPAN ID: jkeenan
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/Text-FixedWidth-Helper

Thanks to Natasha Salam for describing the need for this functionality.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut
