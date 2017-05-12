package Text::CSV::Auto;
BEGIN {
  $Text::CSV::Auto::VERSION = '0.06';
}
use Moose;

=head1 NAME

Text::CSV::Auto - Comprehensive and automatic loading, processing, and
analysis of CSV files.

=head1 SYNOPSIS

    use Text::CSV::Auto;
    
    my $auto = Text::CSV::Auto->new( 'path/to/file.csv' );
    
    $auto->process(sub{
        my ($row) = @_;
        ...
    });
    
    $rows = $auto->slurp();
    
    my $info = $auto->analyze();

If you need to set some attributes:

    my $auto = Text::CSV::Auto->new(
        file     => 'path/to/file.csv',
        max_rows => 100,
    );

There is also a non-OO interface:

    use Text::CSV::Auto qw( slurp_csv process_csv );
    
    process_csv('path/to/file.csv', sub{
        my ($row) = @_;
        ...
    });
    
    my $rows = slurp_csv('path/to/file.csv');

=head1 DESCRIPTION

This module provides utilities to quickly process and analyze CSV files
with as little hassle as possible.

The reliable and robust L<Text::CSV> module is used for the actual
CSV parsing.  This module provides a simpler and smarter interface.  In
most situations all you need to do is specify the filename of the file
and this module will automatically figure out what kind of separator is
used and set some good default options for processing the file.

The name CSV is misleading as any variable-width delimited file should
be fine including TSV files and pipe "|" delimited files to name a few.

Install L<Text::CSV_XS> to get the best possible performance.

=cut

use feature ':5.10';

use Text::CSV;
use Text::CSV::Separator qw( get_separator );
use List::MoreUtils qw( zip any );
use autodie;
use Carp qw( croak );
use Clone qw( clone );
use IO::File;

use Moose::Util::TypeConstraints;

use Module::Pluggable::Object;
{
    my $finder = Module::Pluggable::Object->new(
        search_path => 'Text::CSV::Auto::Plugin',
    );
    foreach my $class ($finder->plugins()) {
        with $class;
    }
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if (@_==1 and !ref($_[0])) {
        return $class->$orig( file => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }
};

=head1 ATTRIBUTES

=head2 file

This is the only required attribute and specifies the file name
of the CSV file.

=cut

subtype 'TextCSVAutoFile'
    => as 'Str'
    => where { -f $_ }
    => message { 'The specified file is not a file' };

has 'file' => (
    is       => 'ro',
    isa      => 'TextCSVAutoFile',
    required => 1,
);

sub _fh {
    my ($self) = @_;
    return IO::File->new( $self->file(), 'r' );
}

=head2 separator

If you do not set this the separator will be automatically detected
using L<Text::CSV::Separator>.

=cut

has 'separator' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);
sub _build_separator {
    my ($self) = @_;

    my @chars = get_separator( path => $self->file() );
    croak 'Unable to automatically detect the separator' if @chars != 1;

    return $chars[0];
}

=head2 csv_options

Set this to a hashref of extra options that you'd like to have
passed down to the underlying L<Text::CSV> parser.

Read the L<Text::CSV> docs to see the many options that it supports.

=cut

has 'csv_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 csv

This contains an instance of the L<Text::CSV> object that is used
to parse the CSV file.  You may pass in your own parser object.
If you don't then one will be instantiated for you with the
csv_options().

If not set already in csv_options, the following defaults
will be used:

    binary    => 1 # Assume there is binary data.
    auto_diag => 1 # die() if there are any errors.
    sep_char  => $self->separator()

=cut

has 'csv' => (
    is         => 'ro',
    isa        => 'Text::CSV',
    lazy_build => 1,
);
sub _build_csv {
    my ($self) = @_;

    my $options = clone( $self->csv_options() );

    $options->{binary}    //= 1;
    $options->{auto_diag} //= 1;
    $options->{sep_char}  //= $self->separator();

    return Text::CSV->new($options);
}

=head2 headers

The headers as pulled from the first line of the CSV file,
taking in to account skip_rows().  The format_headers() option
may modifying the format of the headers.

In some cases a CSV file does not have headers.  In these cases
you should specify an arrayref of header names that you would
like to use.

    headers => ['foo', 'bar']

=cut

has 'headers' => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);
has '_headers_from_csv' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
sub _build_headers {
    my ($self) = @_;

    my $headers;

    $self->_raw_process(sub{
        ($headers) = @_;
        return;
    });

    if ($self->format_headers()) {
        my $header_lookup = {};
        my $new_headers = [];
        foreach my $header (@$headers) {
            $header = $self->_format_string( $header );

            if ($header_lookup->{$header}) {
                my $new_header;
                foreach my $num (2..100) {
                    $new_header = $header . '_' . $num;
                    last if !$header_lookup->{$new_header};
                }
                $header = $new_header;
            }
            $header_lookup->{$header} = 1;

            push @$new_headers, $header;
        }
        $headers = $new_headers;
    }

    $self->_headers_from_csv( 1 );

    return $headers;
}

sub _format_string {
    my ($self, $str) = @_;
    $str = lc( $str );
    $str =~ s{-}{_}g;
    $str =~ s{[^a-z_0-9-]+}{_}gs;
    $str =~ s{^_*(.+?)_*$}{$1};
    $str =~ s{_{2,}}{_}g;
    return $str;
}

=head2 format_headers

When the first row is pulled from the CSV to determine the headers
this option will cause them to be formatted to be more consistent
and remove duplications.  For example, if this were the headers:

    Parents Name,Parent Age,Child Name,Child Age,Child Name,Child Age

The headers would be transformed too:

    parent_name,parent_age,child_name,child_age,child_name_2,child_age_2

This defaults to on and does not affect custom headers set via the
headers attribute.

=cut

has 'format_headers' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

=head2 skip_rows

An arrayref of row numbers to skip can be specified.  This is useful for
CSV files that contain ancillary rows that you don't want to be processed.
For example, you could ignore the 2nd row and the 5th through the 10th rows:

    skip_rows => [2, 5..10]

Do not that the headers are pulled *after* taking in to account skip_rows.
So, for example, doing skip_row=>[1] will cause the headers to be pulled
from the second row.

=cut

has 'skip_rows' => (
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    default => sub{ [] },
);

=head2 max_rows

By default all rows will be processed.  In some cases you only want to
run a sample set of rows.  This option will limit the number of rows
processed.  This is most useful for when you are using analyze() on
a very large file where you don't need every row to be analyzed.

=cut

has 'max_rows' => (
    is  => 'ro',
    isa => 'Int',
);

=head1 METHODS

=head2 process

    $auto->process(sub{
        my ($row) = @_;
        ...
    });

Given a code reference, this will iterate over each row in the CSV
and call the code with the $row hashref as the only argument.

=cut

sub _raw_process {
    my ($self, $sub, $skip_headers) = @_;

    my $fh = $self->_fh();
    my $csv = $self->csv();
    my $line = 0;
    my $skip_rows = $self->skip_rows();
    my $max_rows = $self->max_rows();
    my $first_row = 1;

    while (my $row = $csv->getline( $fh )) {
        $line ++;
        next if any { $line == $_ } @$skip_rows;
        last if $max_rows and $line > $max_rows;

        if ($first_row) {
            $first_row = 0;
            next if $self->_headers_from_csv() and $skip_headers;
        }

        last if !$sub->($row, $line);
    }

    return;
}

sub process {
    my ($self, $sub) = @_;

    my $headers = $self->headers();
    $self->_raw_process(sub{
        my ($row, $line) = @_;

        croak 'number of value on line ' . $line . ' does not match the number of headers'
            if @$headers != @$row;

        $row = { zip @$headers, @$row };
        $sub->( $row );

        return 1;
    }, 1);

    return;
}

=head2 slurp

    my $rows = $auto->slurp();

Slurps up all of the rows in to an arrayref of row hashrefs and
returns it.

=cut

sub slurp {
    my ($self) = @_;

    my @rows;
    $self->process(sub{
        my ($row) = @_;
        push @rows, $row;
    });

    return \@rows;
}

=head2 analyze

    my $info = $auto->analyze();

Returns an array of hashes where each hash represents a header in
the CSV file.  The hash will contain a lot of different meta data
about the data that was found in the rows for that header.

It is possible that within the same header that multiple data types are found,
such as finding a integer value on one row then a string value on another row
within the same header.  In a case like this both the integer=>1 and string=>1
flags would be set.

The possible data types are:

    empty    - The field was blank.
    integer  - Looked like a non-fractional number.
    decimal  - Looked like a fractional number.
    mdy_date - A date in the format of MM/DD/YYYY.
    ymd_date - A date in the format of YYYY-MM-DD.
    string   - Anything else.

There will also be a "data_type" key which will contain the most generalized
data type from above.  For example, if string was found on one row and decimal
was found on another data_type will contain string.

Additionally the following attributes may be set:

    string_length     - The length of the largest string value.
    integer_length    - The number of integer digits in the largest number.
    fractional_length - The number of decimal digits in the value with the most decimal places.
    max               - The maximum number value found.
    min               - The minimum number value found.
    signed            - A negative number was found.

Each hash will also contain a 'header' key wich will contain the name of
the header that is represents.

This method is implemented as an attribute so that calls beyond the first
will not re-scan the CSV file.

=cut

has 'analyze' => (
    is         => 'ro',
    isa        => 'ArrayRef[HashRef]',
    lazy_build => 1,
);
sub _build_analyze {
    my ($self) = @_;

    my $types;
    $self->process(sub{
        my ($row) = @_;

        foreach my $header (@{ $self->headers() }) {
            my $type = $types->{$header} //= {};
            my $value = $row->{$header};

            my $is_number;
            if ($value ~~ '') {
                $type->{empty} = 1;
            }
            elsif ($value =~ m{^(-?)(\d+)$}s) {
                my ($dash, $left) = ($1, $2);
                $type->{signed} = 1 if $dash;
                $type->{integer_length} = length($left+0);
                $type->{integer} = 1;
                $is_number = 1;
            }
            elsif ($value =~ m{^(-?)(\d+)\.(\d+)$}s) {
                my ($dash, $left, $right) = ($1, $2, $3);
                $type->{signed} = 1 if $dash;

                $left  = length($left+0);
                $right = length($right);

                $type->{integer_length}  //= 0;
                $type->{fractional_length} //= 0;

                $type->{integer_length}  = $left if $left > $type->{integer_length};
                $type->{fractional_length} = $right if $right > $type->{fractional_length};

                $type->{decimal} = 1;
                $is_number = 1;
            }
            elsif ($value =~ m{^\d\d/\d\d/\d\d\d\d}) {
                $type->{mdy_date} = 1;
            }
            elsif ($value =~ m{^\d\d\d\d-\d\d-\d\d}) {
                $type->{ymd_date} = 1;
            }
            else {
                my $length = length( $value );

                $type->{string_length} //= 0;
                $type->{string_length} = $length if $length > $type->{string_length};

                $type->{string} = 1;
            }

            if ($is_number) {
                $value += 0;

                $type->{min} //= $value;
                $type->{max} //= $value;

                $type->{min} = $value if $value < $type->{min};
                $type->{max} = $value if $value > $type->{max};
            }
        }
    });

    $types = [
        map { $types->{$_}->{header} = $_; $types->{$_} }
        @{ $self->headers() }
    ];

    foreach my $type (@$types) {
        foreach my $data_type (qw( ymd_date mdy_date decimal integer )) {
            $type->{data_type} = $data_type if $type->{$data_type};
        }
        $type->{data_type} ||= 'string';
    }

    return $types;
}

=head1 FUNCTIONS

A non-OO interface is provided for simple cases.

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( process_csv slurp_csv );

=head2 process_csv

    use Text::CSV::Auto qw( process_csv );
    
    process_csv(
        'file.csv',
        { max_rows => 20 },
        sub{
            my ($row) = @_;
            ...
        },
    );

The first argument is the filename of the CSV file, the second argument is a hashref
of options that can be any of the ATTRIBUTES in the OO interface.  The third argument
is a code reference which will be executed for each row.

The second argument is optional.  You can just leave it out, like this:

    process_csv( 'file.csv', sub{
        my ($row) = @_;
        ...
    });

=cut

sub process_csv {
    my ($file, $options, $sub) = @_;

    if (!$sub) {
        $sub = $options;
        $options = {};
    }

    my $auto = __PACKAGE__->new(
        file => $file,
        %$options,
    );

    $auto->process( $sub );

    return;
}

=head2 slurp_csv

    use Text::CSV::Auto qw( slurp_csv );
    
    my $rows = slurp_csv(
        'file.csv',
        { csv_options => {binary => 0} },
    );
    foreach my $row (@$rows) {
        ...
    }

Just like process_csv, the first option is required and the second is optional.

=cut

sub slurp_csv {
    my ($file, $options) = @_;

    $options ||= {};

    my $auto = __PACKAGE__->new(
        file => $file,
        %$options,
    );

    return $auto->slurp();
}

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 TODO

=over

=item *

The date (not to mention time) handling in analyze is primitive
and needs to be improved.  Possibly by providing a CLDR pattern that
then can be used with L<DateTime::Format::CLDR>.

=item *

The original reason for creating analyze was to then take that
meta data and produce table DDLs for relational databases.  This would
then allow for an extremely simple way to take a csv file and pump
it in to a DB to then run queries on.

=item *

Not sure the best way to do this, but it would be really nice if the
quote character could be automatically detected, or detect that no
quote character is used.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

