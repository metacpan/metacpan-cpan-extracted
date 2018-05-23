package Text::CSV::Hashify;
use strict;
use 5.8.0;
use Carp;
use IO::File;
use IO::Zlib;
use Scalar::Util qw( reftype looks_like_number );
use Text::CSV;
use open qw( :encoding(UTF-8) :std );

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT);
    $VERSION     = '0.11';
    @ISA         = qw(Exporter);
    @EXPORT      = qw( hashify );
}

=head1 NAME

Text::CSV::Hashify - Turn a CSV file into a Perl hash

=head1 VERSION

This document refers to version 0.11 of Text::CSV::Hashify.  This version was
released May 22 2018.

=head1 SYNOPSIS

    # Simple functional interface
    use Text::CSV::Hashify;
    $hash_ref = hashify('/path/to/file.csv', 'primary_key');

    # Object-oriented interface
    use Text::CSV::Hashify;
    $obj = Text::CSV::Hashify->new( {
        file        => '/path/to/file.csv',
        format      => 'hoh', # hash of hashes, which is default
        key         => 'id',  # needed except when format is 'aoh'
        max_rows    => 20,    # number of records to read; defaults to all
        ... # other key-value pairs as appropriate from Text::CSV
    } );

    # all records requested
    $hash_ref       = $obj->all;

    # arrayref of fields input
    $fields_ref     = $obj->fields;

    # hashref of specified record
    $record_ref     = $obj->record('value_of_key');

    # value of one field in one record
    $datum          = $obj->datum('value_of_key', 'field');

    # arrayref of all unique keys seen
    $keys_ref       = $obj->keys;

=head1 DESCRIPTION

The Comma-Separated-Value ('CSV') format is the most common way to store
spreadsheets or the output of relational database queries in plain-text
format.  However, since commas (or other designated field-separator
characters) may be embedded within data entries, the parsing of delimited
records is non-trivial.  Fortunately, in Perl this parsing is well handled by
CPAN distribution L<Text::CSV|http://search.cpan.org/dist/Text-CSV/>.  This
permits us to address more specific data manipulation problems by building
modules on top of F<Text::CSV>.

B<Note:>  In this document we will use I<CSV> as a catch-all for tab-delimited
files, pipe-delimited files, and so forth.  Please refer to the documentation
for Text::CSV to learn how to handle field separator characters other than the
comma.

F<Text::CSV::Hashify> is designed for the case where you simply want to turn a
CSV file into a Perl hash.  In particular, it is designed for the case where:

=over 4

=item *

the CSV file's first record is a list of fields in the
ancestral database table; and

=item *

one field (column) functions as a primary key, I<i.e.,> each record's entry in
that field is non-null and is distinct from every other record's entry
therein.

=back

F<Text::CSV::Hashify> turns that kind of CSV file into one big hash of hashes.

F<Text::CSV::Hashify> can now take gzip-compressed (F<.gz>) files as input as
well as uncompressed files.

=head2 Primary Case: CSV (with primary key) to Hash of Hashes

Text::CSV::Hashify is designed for the case where you simply want to turn a
CSV file into a Perl hash.  In particular, it is designed for the case where
(a) the CSV file's first record is a list of fields in the ancestral database
table and (b) one field (column) functions as a B<primary key>, I<i.e.,> each
record's entry in that field is non-null and is distinct from every other
record's entry therein.

Text::CSV::Hashify turns that kind of CSV file into one big hash of hashes.
Elements of this hash are keyed on the entries in the designated primary key
field and the value for each element is a hash reference of all the data in a
particular database record (including the primary key field and its value).

=head2 Secondary Case: CSV (lacking primary key) to Array of Hashes

You may, however, encounter cases where a CSV file's header row contains the
list of database fields but no field is capable of serving as a primary key,
I<i.e.,> there is no field in which the entry for that field in any record is
guaranteed to be distinct from the entries in that field for all other
records.

In this case, while an individual record can be turned into a hash,
the CSV file as a whole cannot accurately be turned into a hash of hashes.  As
a fallback, Text::CSV::Hashify can, upon request, turn this into an array of
hashes.  In this case, you will not be able to look up a particular record by
its primary key.  You will instead have to know its index position within the
array (which is equivalent to knowing its record number in the original CSV
file minus C<1>).

=head2 Interfaces

Text::CSV::Hashify provides two interfaces: one functional, one
object-oriented.

Use the functional interface when all you want is to turn a CSV file with a
primary key field into a hash of hashes.

Use the object-oriented interface for any more sophisticated manipulation of
the CSV file.  This includes:

=over 4

=item * Text::CSV options

Access to any of the options available to Text::CSV, such as use of a
separator character other than a comma.  B<Note:>  Much of the time you will
not need any of the Text::CSV options.  Text::CSV::Hashify is focused on
B<reading> CSV files, whereas Text::CSV is focused on both reading and
B<writing> CSV files.  Some Text::CSV options, such as C<eol>, are unlikely to
be needed when using Text::CSV::Hashify.  Hence, you should be very selective
in your use of Text::CSV options.

=item * Limit number of records

Selection of a limited number of records from the CSV file, rather than
slurping the whole file into your in-memory hash.

=item * Array of hash references format

Probably better than the default hash of hash references format when the CSV
file has no field able to serve as a primary key.

=item * Metadata

Access to the list of fields, the list of all primary key values, the values
in an individual record, or the value of an individual field in an individual
record.

=back

B<Note:> On the recommendation of the authors/maintainers of Text::CSV,
Text::CSV::Hashify will internally always set Text::CSV's C<binary =E<gt> 1>
option.

=head1 FUNCTIONAL INTERFACE

Text::CSV::Hashify by default exports one function: C<hashify()>.

    $hash_ref = hashify('/path/to/file.csv', 'primary_key');

or

    $hash_ref = hashify('/path/to/file.csv.gz', 'primary_key');

Function takes two arguments:  path to CSV file; field in that file which
serves as primary key.  If the path to the input file ends in F<.gz>, it is
assumed to be compressed by F<gzip>.  If the file name ends in F<.psv> (or
F<.psv.gz>), the separator character is assumed to be a pipe (C<|>).  If the
file name ends in F<.tsv> (or F<.tsv.gz>), the separator character is assumed
to be a tab (C<	>).  Otherwise, the separator character will be assumed to be
a comma (C<,>).

Returns a reference to a hash of hash references.

=cut

sub hashify {
    croak "'hashify()' must have two arguments"
        unless @_ == 2;
    my @args = @_;
    for (my $i=0;$i<=$#args;$i++) {
        croak "'hashify()' argument at index '$i' not true" unless $args[$i];
    }
    my %obj_args = (
        file    => $args[0],
        key     => $args[1],
    );
    $obj_args{sep_char} =
        ($obj_args{file} =~ m/\.psv(\.gz)?$/)
            ? '|'
            : ($obj_args{file} =~ m/\.tsv(\.gz)?$/)
                ? "\t"
                : ',';
    my $obj = Text::CSV::Hashify->new( \%obj_args );
    return $obj->all();
}

=head1 OBJECT-ORIENTED INTERFACE

=head2 C<new()>

=over 4

=item * Purpose

Text::CSV::Hashify constructor.

=item * Arguments

    $obj = Text::CSV::Hashify->new( {
        file        => '/path/to/file.csv',
        format      => 'hoh', # hash of hashes, which is default
        key         => 'id',  # needed except when format is 'aoh'
        max_rows    => 20,    # number of records to read; defaults to all
        ... # other key-value pairs as appropriate from Text::CSV
    } );

Single hash reference.  Required element is:

=over 4

=item * C<file>

String: path to CSV file serving as input.  If the path to the input file ends
in F<.gz>, it is assumed to be compressed by F<gzip>.

=back

Element usually needed:

=over 4

=item * C<key>

String: name of field in CSV file serving as unique key.  Needed except when
optional element C<format> is C<aoh>.

=back

Optional elements are:

=over 4

=item * C<format>

String: possible values are C<hoh> and C<aoh>.  Defaults to C<hoh> (hash of
hashes).  C<new()> will fail if the same value is encountered in more than one
record's entry in the C<key> column.  So if you know in advance that your data
cannot meet this condition, explicitly select C<format =E<gt> aoh>.

=item * C<max_rows>

Number: provide this if you do not wish to populate the hash with all data
records from the CSV file.  (Will have no effect if the number provided is
greater than or equal to the number of data records in the CSV file.) 

=item * Any option available to Text::CSV

See documentation for either Text::CSV or Text::CSV_XS, but see discussion of
"Text::CSV options" above.

=back

=item * Return Value

Text::CSV::Hashify object.

=item * Comment

=back

=cut

sub new {
    my ($class, $args) = @_;
    my %data;

    croak "Argument to 'new()' must be hashref"
        unless (ref($args) and reftype($args) eq 'HASH');
    croak "Argument to 'new()' must have 'file' element" unless $args->{file};
    croak "Cannot locate file '$args->{file}'"
        unless (-f $args->{file});
    $data{file} = delete $args->{file};

    if ($args->{format} and ($args->{format} !~ m/^(?:h|a)oh$/i) ) {
        croak "Entry '$args->{format}' for format is invalid'";
    }
    $data{format} = delete $args->{format} || 'hoh';

    if (exists $args->{key}) {
        croak "Value for 'key' must be non-empty string"
            unless defined $args->{key} and length($args->{key});
    }

    if (! exists $args->{key} and $data{format} ne 'aoh') {
        croak "Argument to 'new()' must have 'key' element unless 'format' element is 'aoh'";
    }

    $data{key}  = delete $args->{key};

    if (defined($args->{max_rows})) {
        if ($args->{max_rows} !~ m/^[0-9]+$/) {
            croak "'max_rows' option, if defined, must be numeric";
        }
        else {
            $data{max_rows} = delete $args->{max_rows};
        }
    }
    # We've now handled all the Text::CSV::Hashify::new-specific options.
    # Any remaining options are assumed to be intended for Text::CSV::new().

    $args->{binary} = 1;
    my $csv = Text::CSV->new ( $args )
        or croak "Cannot use CSV: ".Text::CSV->error_diag ();
    my $IN;
    if ($data{file} =~ m/\.gz$/) {
        $IN = IO::Zlib->new($data{file}, "rb");
    }
    else {
        $IN = IO::File->new($data{file}, "r");
    }
    croak "Unable to open '$data{file}' for reading"
        unless defined $IN;
    my $header_ref = $csv->getline($IN);
    my %header_fields_seen;
    for (@{$header_ref}) {
        if (exists $header_fields_seen{$_}) {
            croak "Duplicate field '$_' observed in '$data{file}'";
        }
        else {
            $header_fields_seen{$_}++;
        }
    }
    if ($data{format} eq 'hoh') {
        croak "Key '$data{key}' not found in header row"
            unless $header_fields_seen{$data{key}};
    }

    $data{fields} = $header_ref;
    $csv->column_names(@{$header_ref});

    # 'hoh format
    my %keys_seen;
    my @keys_list = ();
    my %parsed_data;
    # 'aoh' format
    my @parsed_data;

    PARSE_FILE: while (my $record = $csv->getline_hr($IN)) {
        if ($data{format} eq 'hoh') {
            my $kk = $record->{$data{key}};
            if ($keys_seen{$kk}) {
                croak "Key '$kk' already seen";
            }
            else {
                $keys_seen{$kk}++;
                push @keys_list, $kk;
                $parsed_data{$kk} = $record;
                last PARSE_FILE if (
                    defined $data{max_rows} and
                    scalar(keys %parsed_data) == $data{max_rows}
                );
            }
        }
        else { # format: 'aoh'
            push @parsed_data, $record;
            last PARSE_FILE if (
                defined $data{max_rows} and
                scalar(@parsed_data) == $data{max_rows}
            );
        }
    }
    $IN->close or croak "Unable to close $data{file} after reading";
    $data{all} = ($data{format} eq 'aoh') ? \@parsed_data : \%parsed_data;
    $data{keys} = \@keys_list if $data{format} eq 'hoh';
    $data{csv} = $csv;
    while (my ($k,$v) = each %{$args}) {
        $data{$k} = $v;
    }
    return bless \%data, $class;
}

=head2 C<all()>

=over 4

=item * Purpose

Get a representation of all data found in a CSV input file.

=item * Arguments

    $hash_ref   = $obj->all; # when format is default or 'hoh'
    $array_ref  = $obj->all; # when format is 'aoh'

=item * Return Value

Reference representing all data records in the CSV input file.  In the default
case, or if you have specifically requested C<format => 'hoh'>, the return
value is a hash reference.  When you have requested C<format => 'aoh'>, the
return value is an array reference.

=item * Comment

In the default (C<hoh>) case, the return value is equivalent to that of
C<hashify()>.

=back

=cut

sub all {
    my ($self) = @_;
    return $self->{all};
}

=head2 C<fields()>

=over 4

=item * Purpose

Get a list of the fields in the CSV source.

=item * Arguments

    $fields_ref = $obj->fields;

=item * Return Value

Array reference.

=item * Comment

If any field names are duplicate, you will not get this far, as C<new()> would
have died.

=back

=cut

sub fields {
    my ($self) = @_;
    return $self->{fields};
}

=head2 C<record()>

=over 4

=item * Purpose

Get a hash representing one record in the CSV input file.

=item * Arguments

    $record_ref = $obj->record('value_of_key');

One argument.  In the default case (C<format =E<gt> 'hoh'>), this argument is the value in the record in the column serving as unique key.

In the C<format =E<gt> 'aoh'> case, this will be index position of the data record
in the array.  (The header row will be at index C<0>.)

=item * Return Value

Hash reference.

=back

=cut

sub record {
    my ($self, $key) = @_;
    croak "Argument to 'record()' either not defined or non-empty"
        unless (defined $key and $key ne '');
    ($self->{format} eq 'aoh')
        ? return $self->{all}->[$key]
        : return $self->{all}->{$key};
}

=head2 C<datum()>

=over 4

=item * Purpose

Get value of one field in one record.

=item * Arguments

    $datum = $obj->datum('value_of_key', 'field');

List of two arguments: the value in the record in the column serving as unique
key; the name of the field.

=item * Return Value

Scalar.

=back

=cut

sub datum {
    my ($self, @args) = @_;
    croak "'datum()' needs two arguments" unless @args == 2;
    for (my $i=0;$i<=$#args;$i++) {
        croak "Argument to 'datum()' at index '$i' either not defined or non-empty"
        unless ((defined($args[$i])) and ($args[$i] ne ''));
    }
    ($self->{format} eq 'aoh')
        ? return $self->{all}->[$args[0]]->{$args[1]}
        : return $self->{all}->{$args[0]}->{$args[1]};
}

=head2 C<keys()>

=over 4

=item * Purpose

Get a list of all unique keys found in the input file.

=item * Arguments

    $keys_ref = $obj->keys;

=item * Return Value

Array reference.

=item * Comment

If you have selected C<format =E<gt> 'aoh'> in the options to C<new()>, the
C<keys> method is inappropriate and will cause your program to die.

=back

=cut

sub keys {
    my ($self) = @_;
    if (exists $self->{keys}) {
        return $self->{keys};
    }
    else {
        croak "'keys()' method not appropriate when 'format' is 'aoh'";
    }
}

=head1 AUTHOR

    James E Keenan
    CPAN ID: jkeenan
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/Text-CSV-Hashify

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Copyright 2012-2018, James E Keenan.  All rights reserved.

=head1 BUGS

There are no bug reports outstanding on Text::CSV::Hashify as of the most recent
CPAN upload date of this distribution.

=head1 SUPPORT

To report any bugs or make any feature requests, please send mail to
C<bug-Text-CSV-Hashify@rt.cpan.org> or use the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Thanks to Christine Shieh for serving as the alpha consumer of this
library's output.

=head1 OTHER CPAN DISTRIBUTIONS

=head2 Text-CSV and Text-CSV_XS

These distributions underlie Text-CSV-Hashify and provide all of its
file-parsing functionality.  Where possible, install both.  That will enable
you to process a file with a single, shared interface but have access to the
faster processing speeds of XS where available.

=head2 Text-CSV-Slurp

Like Text-CSV-Hashify, Text-CSV-Slurp slurps an entire CSV file into memory,
but stores it as an array of hashes instead.

=head2 Text-CSV-Auto

This distribution inspired the C<max_rows> option to C<new()>.

=cut

1;

