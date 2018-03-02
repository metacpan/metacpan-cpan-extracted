package Text::CSV::Pivot;

$Text::CSV::Pivot::VERSION   = '0.01';
$Text::CSV::Pivot::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Text::CSV::Pivot - Transform CSV file into Pivot Table format.

=head1 VERSION

Version 0.01

=cut

use 5.006;
use Data::Dumper;
use Text::CSV;
use File::Basename;

use Moo;
use namespace::autoclean;

has 'output_file'   => (is => 'rw');
has 'input_file'    => (is => 'ro', required => 1);
has 'col_key_idx'   => (is => 'ro', required => 1);
has 'col_name_idx'  => (is => 'ro', required => 1);
has 'col_value_idx' => (is => 'ro', required => 1);
has 'col_skip_idx'  => (is => 'ro', default  => sub { [] });

has '_csv_handler'  => (is => 'rw');
has '_new_columns'  => (is => 'rw');
has '_old_columns'  => (is => 'ro');
has '_raw_data'     => (is => 'rw');

=head1 DESCRIPTION

Recently I was asked to prepare pivot table using csv  file  at work. Having done
that using quick and dirty perl script, I decided to clean up and make it generic
so that others can also benefit.

Below is sample data, I used for prototype as source csv file.

    +----------------+-----------+-----------------+
    | Student        | Subject   | Result | Year   |
    +----------------+-----------+--------+--------+
    | Smith, John    | Music     | 7.0    | Year 1 |
    | Smith, John    | Maths     | 4.0    | Year 1 |
    | Smith, John    | History   | 9.0    | Year 1 |
    | Smith, John    | Language  | 7.0    | Year 1 |
    | Smith, John    | Geography | 9.0    | Year 1 |
    | Gabriel, Peter | Music     | 2.0    | Year 1 |
    | Gabriel, Peter | Maths     | 10.0   | Year 1 |
    | Gabriel, Peter | History   | 7.0    | Year 1 |
    | Gabriel, Peter | Language  | 4.0    | Year 1 |
    | Gabriel, Peter | Geography | 10.0   | Year 1 |
    +----------------+-----------+--------+--------+

I aim to get something like this below.

    +----------------+--------+-----------+---------+----------+-------+-------+
    | Student        | Year   | Geography | History | Language | Maths | Music |
    +----------------+--------+-----------+---------+----------+-------+-------+
    | Gabriel, Peter | Year 1 | 10.0      | 7.0     | 4.0      | 10.0  | 2.0   |
    | Smith, John    | Year 1 | 9.0       | 9.0     | 7.0      | 4.0   | 7.0   |
    +----------------+--------+-----------+---------+----------+-------+-------+

With the help of L<Text::CSV::Pivot>, I came up with the following solution.

    use strict; use warnings;
    use Text::CSV::Pivot;

    Text::CSV::Pivot->new({ input_file    => 'sample.csv',
                            col_key_idx   => 0,
                            col_name_idx  => 1,
                            col_value_idx => 2 })->transform;

After executing the above code, I got the expected result in C<sample.pivot.csv>.

=head1 SYNOPSIS

Let's assume we have the following source csv file (sample.csv):

    +----------------+-----------+-----------------+
    | Student        | Subject   | Result | Year   |
    +----------------+-----------+--------+--------+
    | Smith, John    | Music     | 7.0    | Year 1 |
    | Smith, John    | Maths     | 4.0    | Year 1 |
    | Smith, John    | History   | 9.0    | Year 1 |
    | Smith, John    | Geography | 9.0    | Year 1 |
    | Gabriel, Peter | Music     | 2.0    | Year 1 |
    | Gabriel, Peter | Maths     | 10.0   | Year 1 |
    | Gabriel, Peter | History   | 7.0    | Year 1 |
    | Gabriel, Peter | Language  | 4.0    | Year 1 |
    +----------------+-----------+--------+--------+

If you notice, the student C<"Smith, John"> do not have any score for the subject
C<"Language"> and the student C<"Gabriel, Peter"> missing score for C<"Geography">.

    use strict; use warnings;
    use Text::CSV::Pivot;

    Text::CSV::Pivot->new({ input_file    => 'sample.csv',
                            col_key_idx   => 0,
                            col_name_idx  => 1,
                            col_value_idx => 2 })->transform;

The above code would then create the result in C<sample.pivot.csv> as below:

    +----------------+--------+-----------+---------+----------+-------+-------+
    | Student        | Year   | Geography | History | Language | Maths | Music |
    +----------------+--------+-----------+---------+----------+-------+-------+
    | Gabriel, Peter | Year 1 | 10.0      | 7.0     |          | 10.0  | 2.0   |
    | Smith, John    | Year 1 |           | 9.0     | 7.0      | 4.0   | 7.0   |
    +----------------+--------+-----------+---------+----------+-------+-------+

In case, we would want to skip "Year" column then the following code:

    use strict; use warnings;
    use Text::CSV::Pivot;

    Text::CSV::Pivot->new({ input_file    => 'sample.csv',
                            col_key_idx   => 0,
                            col_name_idx  => 1,
                            col_value_idx => 2,
                            col_skip_idx  => [3] })->transform;

You should get the result as below:

    +----------------+-----------+---------+----------+-------+-------+
    | Student        | Geography | History | Language | Maths | Music |
    +----------------+-----------+---------+----------+-------+-------+
    | Gabriel, Peter | 10.0      | 7.0     |          | 10.0  | 2.0   |
    | Smith, John    |           | 9.0     | 7.0      | 4.0   | 7.0   |
    +----------------+-----------+---------+----------+-------+-------+

=cut

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    die "ERROR: Parameters have to be hashref."
        if (@args == 1 && ((ref $args[0]) ne 'HASH'));

    my $params = {};
    foreach my $key ('output_file',
                     'input_file',
                     'col_key_idx',
                     'col_name_idx',
                     'col_value_idx',
                     'col_skip_idx') {
        my $val = $args[0]->{$key};
        $params->{$key} = $val if (defined $val);
        delete $args[0]->{$key};
    }

    $args[0]->{binary} = 1 unless (exists $args[0]->{binary});

    $params->{'_csv_handler'} = Text::CSV->new($args[0])
        or die "ERROR: Can't use CSV: ".Text::CSV->error_diag;

    my $input_file = $params->{'input_file'};
    open(my $in, '<:encoding(utf8)', $input_file)
        or die "ERROR: Can't open input file $input_file [$!]\n";
    $params->{'input_file'} = $in;

    my $output_file = $params->{'output_file'};
    if (!defined $output_file) {
        $output_file = fileparse($input_file, '\.[^\.]*');
        $output_file = sprintf("%s.pivot.csv", $output_file);
    }

    open(my $out, '>:encoding(utf8)', $output_file)
        or die "ERROR: Can't open output file $output_file [$!]\n";
    $params->{'output_file'} = $out;

    $params->{'_old_columns'} = $params->{'_csv_handler'}->getline($in);

    _process_data($params);

    return $class->$orig($params);
};

=head1 CONSTRUCTOR

The following table explains the parameters for the constructor. However you can
also pass any valid parameters for C<Text::CSV>.

    +---------------+----------+---------------------------------------------------+
    | Name          | Required | Description                                       |
    +---------------+----------+---------------------------------------------------+
    | input_file    | Yes      | Path to the source csv file.                      |
    | output_file   | No       | Path to the output csv file.                      |
    | col_key_idx   | Yes      | Column index that uniquely identify each row.     |
    | col_name_idx  | Yes      | Column index that would provide new column name.  |
    | col_value_idx | Yes      | Column index that would provide new column value. |
    | col_skip_idx  | No       | Column index to ignore in the output csv.         |
    +---------------+----------+---------------------------------------------------+

Column index starts with 0, left to right. So in the example below, the C<col_key_idx>
would be 0. Similarly C<col_name_idx> and C<col_value_idx> would be 1 and 2 resp. In
case, we would want to skip the column "Year" in the output file, then C<col_skip_idx>
would be [3]. All index related parameters except C<col_skip_idx> would expect number
0 or more. The C<col_skip_idx> would expected an C<ArrayRef> of column index.

    +----------------+-----------+-----------------+
    | Student        | Subject   | Result | Year   |
    +----------------+-----------+--------+--------+
    | Smith, John    | Music     | 7.0    | Year 1 |
    | Smith, John    | Maths     | 4.0    | Year 1 |
    | Smith, John    | History   | 9.0    | Year 1 |
    | Smith, John    | Language  | 7.0    | Year 1 |
    | Smith, John    | Geography | 9.0    | Year 1 |
    | Gabriel, Peter | Music     | 2.0    | Year 1 |
    | Gabriel, Peter | Maths     | 10.0   | Year 1 |
    | Gabriel, Peter | History   | 7.0    | Year 1 |
    | Gabriel, Peter | Language  | 4.0    | Year 1 |
    | Gabriel, Peter | Geography | 10.0   | Year 1 |
    +----------------+-----------+--------+--------+

Let's assume, we want column "Student" to be our key column, the "Subject" column
to provide us the new column name and "Result" column for the values. Also "Year"
column to be skipped. Then the call would look like something below:

    use strict; use warnings;
    use Text::CSV::Pivot;

    Text::CSV::Pivot->new({ input_file    => 'sample.csv',
                            col_key_idx   => 0,
                            col_name_idx  => 1,
                            col_value_idx => 2,
                            col_skip_idx  => [3] })->transform;

=head1 METHODS

=head2 transform()

Tranform the source csv into the corresponding pivot csv based on the data passed
to the constructor.

=cut

sub transform {
    my ($self) = @_;

    my $csv           = $self->{'_csv_handler'};
    my $out           = $self->{'output_file'};
    my $raw_data      = $self->{'_raw_data'};
    my $col_key_idx   = $self->{'col_key_idx'};
    my $col_name_idx  = $self->{'col_name_idx'};
    my $col_value_idx = $self->{'col_value_idx'};
    my $col_skip_idx  = $self->{'col_skip_idx'};
    my $old_columns   = $self->{'_old_columns'};
    my $new_columns   = $self->{'_new_columns'};

    my $new_column_headers = [];
    foreach my $index (0 .. $#$old_columns) {
        next if (($index == $col_name_idx)
                 || ($index == $col_value_idx)
                 || (grep($_ == $index, @$col_skip_idx) > 0));
        push @$new_column_headers, $old_columns->[$index];
    }
    foreach my $new_column (@$new_columns) {
        push @$new_column_headers, $new_column;
    }

    $csv->eol("\r\n");
    $csv->print($out, $new_column_headers);
    foreach my $key (sort keys %$raw_data) {
        my $row = [];
        $row->[$col_key_idx] = $key;
        foreach my $index (0 .. $#$old_columns) {
            next if (($index == $col_key_idx)
                     || ($index == $col_name_idx)
                     || ($index == $col_value_idx)
                     || (grep($_ == $index, @$col_skip_idx) > 0));

            if (($index > $col_name_idx) || ($index > $col_value_idx)) {
                if ($col_name_idx > $col_value_idx) {
                    $row->[$index-$col_name_idx] = $raw_data->{$key}->{$old_columns->[$index]};
                }
                else {
                    $row->[$index-$col_value_idx] = $raw_data->{$key}->{$old_columns->[$index]};
                }
            }
            else {
                $row->[$index] = $raw_data->{$key}->{$old_columns->[$index]};
            }
        }

        foreach my $column (@$new_columns) {
            push @$row, $raw_data->{$key}->{$column} || '';
        }

        $csv->print($out, $row);
    }

    $csv->eof;
    close($out);
}

#
#
# PRIVATE METHODS

sub _process_data {
    my ($params) = @_;

    my $csv           = $params->{'_csv_handler'};
    my $in            = $params->{'input_file'};
    my $col_key_idx   = $params->{'col_key_idx'};
    my $col_name_idx  = $params->{'col_name_idx'};
    my $col_value_idx = $params->{'col_value_idx'};
    my $columns       = $params->{'_old_columns'};

    my $raw_data    = {};
    my $new_columns = {};

    while (my $values = $csv->getline($in)) {
        my $key = $values->[$col_key_idx];
        foreach my $index (0 .. $#$columns) {
            next if (($index == $col_key_idx) || ($index == $col_name_idx) || ($index == $col_value_idx));
            $raw_data->{$key}->{$columns->[$index]} = $values->[$index];
        }

        $raw_data->{$key}->{$values->[$col_name_idx]} = $values->[$col_value_idx];
        $new_columns->{$values->[$col_name_idx]} = 1;
    }

    $csv->eof;
    close($in);

    $params->{'_new_columns'} = [ sort keys %$new_columns ];
    $params->{'_raw_data'}    = $raw_data;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Text-CSV-Pivot>

=head1 SEE ALSO

=over 4

=item L<Data::Pivot>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-text-csv-pivot at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-CSV-Pivot>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::CSV::Pivot

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-CSV-Pivot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-CSV-Pivot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-CSV-Pivot>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-CSV-Pivot/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Text::CSV::Pivot
