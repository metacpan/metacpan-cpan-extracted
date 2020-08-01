use 5.006;
use strict;
use warnings;
package Vote::Count::TextTableTiny;
$Vote::Count::TextTableTiny::VERSION = '1.06';
use parent 'Exporter';
use List::Util qw();
use Carp qw/ croak /;

our @EXPORT_OK = qw/ generate_table generate_markdown_table /;

# ABSTRACT: This is forked from Text::Table::Tiny for a pull request that was never accepted. This will go away when it is addressed.

our $COLUMN_SEPARATOR = '|';
our $ROW_SEPARATOR = '-';
our $CORNER_MARKER = '+';
our $HEADER_ROW_SEPARATOR = '=';
our $HEADER_CORNER_MARKER = 'O';

sub generate_table {

    my %params = @_;
    my $rows = $params{rows} or croak "generate_table(): you must pass the 'rows' argument!";

    # foreach col, get the biggest width
    my $widths = _maxwidths($rows);
    my $max_index = _max_array_index($rows);

    # use that to get the field format and separators
    my $format = _get_format($widths);
    my $row_sep = _get_row_separator($widths);
    my $head_row_sep = _get_header_row_separator($widths);

    # here we go...
    my @table;
    push(@table, $row_sep) unless $params{top_and_tail};

    # if the first row's a header:
    my $data_begins = 0;
    if ( $params{header_row} ) {
        my $header_row = $rows->[0];
        $data_begins++;
        push @table, sprintf(
                         $format,
                         map { defined($header_row->[$_]) ? $header_row->[$_] : '' } (0..$max_index)
                     );
        push @table, $params{separate_rows} ? $head_row_sep : $row_sep;
    }

    # then the data
    my $row_number = 0;
    my $last_line_number = int(@$rows);
    $last_line_number-- if $params{header_row};
    foreach my $row ( @{ $rows }[$data_begins..$#$rows] ) {
        $row_number++;
        push(@table, sprintf(
                             $format,
                             map { defined($row->[$_]) ? $row->[$_] : '' } (0..$max_index)
                            ));

 ###       push(@table, $row_sep) if $params{separate_rows} && (!$params{top_and_tail} || $row_number < $last_line_number);

    }

    # this will have already done the bottom if called explicitly
 ###   push(@table, $row_sep) unless $params{separate_rows} || $params{top_and_tail};
# push(@table, $row_sep) unless $params{separate_rows} || $params{top_and_tail};
# if ($params{separate_rows} || $params{top_and_tail} ) {

# } else {
#   push(@table, $row_sep)
# }

    return join("\n",grep {$_} @table);
}

sub generate_markdown_table {
  $CORNER_MARKER = '|';
  $HEADER_ROW_SEPARATOR = '-';
  $HEADER_CORNER_MARKER = '|';
  my @ARGS = (@_);
  unshift @ARGS, ( header_row => 1, top_and_tail => 1 );
  return Vote::Count::TextTableTiny::generate_table(@ARGS);
}

sub _maxwidths {
    my $rows = shift;
    # what's the longest array in this list of arrays?
    my $max_index = _max_array_index($rows);
    my $widths = [];
    for my $i (0..$max_index) {
        # go through the $i-th element of each array, find the longest
        my $max = List::Util::max(map {defined $$_[$i] ? length($$_[$i]) : 0} @$rows);
        push @$widths, $max;
    }
    return $widths;
}

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return List::Util::max( map { $#$_ } @$rows );
}

sub _get_format {
    my $widths = shift;
    return "$COLUMN_SEPARATOR ".join(" $COLUMN_SEPARATOR ",map { "%-${_}s" } @$widths)." $COLUMN_SEPARATOR";
}

sub _get_row_separator {
    my $widths = shift;
    return "$CORNER_MARKER$ROW_SEPARATOR".join("$ROW_SEPARATOR$CORNER_MARKER$ROW_SEPARATOR",map { $ROW_SEPARATOR x $_ } @$widths)."$ROW_SEPARATOR$CORNER_MARKER";
}

sub _get_header_row_separator {
    my $widths = shift;
    return "$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR".join("$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER$HEADER_ROW_SEPARATOR",map { $HEADER_ROW_SEPARATOR x $_ } @$widths)."$HEADER_ROW_SEPARATOR$HEADER_CORNER_MARKER";
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
*table = \&generate_table;

1;

__END__

=pod

=head1 Vote::Count::TextTableTiny

This is a temporary fork of Text::Table::Tiny to support a method I added to set all of the flags for markdown compatible tables. At whatever point the pull request is accepted, or a comparable feature added to the original this module will be withdrawn.

=head1 NAME

Text::Table::Tiny - simple text tables from 2D arrays, with limited templating options

=head1 SYNOPSIS

    use Text::Table::Tiny 0.04 qw/ generate_table /;

    my $rows = [
        # header row
        ['Name', 'Rank', 'Serial'],
        # rows
        ['alice', 'pvt', '123456'],
        ['bob',   'cpl', '98765321'],
        ['carol', 'brig gen', '8745'],
    ];
    print generate_table(rows => $rows, header_row => 1);


=head1 DESCRIPTION

This module provides, C<generate_table>, which formats
a two-dimensional array of data as a text table.

A second function C<generate_markdown_table>, formats the table
as markdown and should not be passed any other formatting directives.

The example shown in the SYNOPSIS generates the following table:

    +-------+----------+----------+
    | Name  | Rank     | Serial   |
    +-------+----------+----------+
    | alice | pvt      | 123456   |
    | bob   | cpl      | 98765321 |
    | carol | brig gen | 8745     |
    +-------+----------+----------+

B<NOTE>: the interface changed with version 0.04, so if you
use the C<generate_table()> function illustrated above,
then you need to require at least version 0.04 of this module,
as shown in the SYNOPSIS.


=head2 generate_table()

The C<generate_table> function understands three arguments,
which are passed as a hash.

=over 4


=item *

rows

Takes an array reference which should contain one or more rows
of data, where each row is an array reference.


=item *

header_row

If given a true value, the first row in the data will be interpreted
as a header row, and separated from the rest of the table with a ruled line.


=item *

separate_rows

If given a true value, a separator line will be drawn between every row in
the table,
and a thicker line will be used for the header separator.

=item *

top_and_tail

If given a true value, then the top and bottom border lines will be skipped.
This reduces the vertical height of the generated table.

=back

=head2 generate_markdown_table()

Calls C<generate_table()> with all of the settings and parameters
necessary to return a table that is valid for most markdown
interpreters.

You should not pass or set any other formatting options when using
C<generate_markdown_table>.

The first row in the data from rows => will be used as the header row.

=head2 EXAMPLES

If you just pass the data and no other options:

 generate_table(rows => $rows);

You get minimal ruling:

    +-------+----------+----------+
    | Name  | Rank     | Serial   |
    | alice | pvt      | 123456   |
    | bob   | cpl      | 98765321 |
    | carol | brig gen | 8745     |
    +-------+----------+----------+

If you want lines between every row, and also want a separate header:

 generate_table(rows => $rows, header_row => 1, separate_rows => 1);

You get the maximally ornate:

    +-------+----------+----------+
    | Name  | Rank     | Serial   |
    O=======O==========O==========O
    | alice | pvt      | 123456   |
    +-------+----------+----------+
    | bob   | cpl      | 98765321 |
    +-------+----------+----------+
    | carol | brig gen | 8745     |
    +-------+----------+----------+

If you want your table in MarkDown compatible format:

 generate_markdown_table( rows => $rows );

    | Name  | Rank     | Serial   |                 |
    |-------|----------|----------|
    | alice | pvt      | 123456   |
    | bob   | cpl      | 98765321 |
    | carol | brig gen | 8745     |

=head1 FORMAT VARIABLES

You can set a number of package variables inside the C<Text::Table::Tiny> package
to configure the appearance of the table.
This interface is likely to be deprecated in the future,
and some other mechanism provided.

=over 4

=item *

$Text::Table::Tiny::COLUMN_SEPARATOR = '|';

=item *

$Text::Table::Tiny::ROW_SEPARATOR = '-';

=item *

$Text::Table::Tiny::CORNER_MARKER = '+';

=item *

$Text::Table::Tiny::HEADER_ROW_SEPARATOR = '=';

=item *

$Text::Table::Tiny::HEADER_CORNER_MARKER = 'O';

=back


=head1 PREVIOUS INTERFACE

Prior to version 0.04 this module provided a function called C<table()>,
which wasn't available for export. It took exactly the same arguments:

 use Text::Table::Tiny;
 my $rows = [ ... ];
 print Text::Table::Tiny::table(rows => $rows, separate_rows => 1, header_row => 1);

For backwards compatibility this interface is still supported.
The C<table()> function isn't available for export though.


=head1 SEE ALSO

There are many modules for formatting text tables on CPAN.
A good number of them are listed in the
L<See Also|https://metacpan.org/pod/Text::Table::Manifold#See-Also>
section of the documentation for L<Text::Table::Manifold>.


=head1 REPOSITORY

L<https://github.com/neilb/Text-Table-Tiny>


=head1 AUTHOR

Creighton Higgins <chiggins@chiggins.com>

Now maintained by Neil Bowers <neilb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Creighton Higgins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

=cut

