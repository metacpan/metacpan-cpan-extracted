package Text::Table::Lite;

use strict;
use warnings;
use utf8;
use 5.016;

use Exporter 'import';
use Encode qw(encode decode find_encoding FB_CROAK);
use Unicode::GCString ();

our $VERSION   = '1.03';
our @EXPORT_OK = qw(generate_table);

my %BORDERS = (
    ascii => {
        tl => '+', tm => '+', tr => '+',
        ml => '+', mm => '+', mr => '+',
        bl => '+', bm => '+', br => '+',
        h  => '-', v  => '|',
        htl => '+', htm => '+', htr => '+', hh => '=',
    },
    unicode => {
        tl => '┌', tm => '┬', tr => '┐',
        ml => '├', mm => '┼', mr => '┤',
        bl => '└', bm => '┴', br => '┘',
        h  => '─', v  => '│',
        htl => '╞', htm => '╪', htr => '╡', hh => '═',
    },
    none => {
        tl => '', tm => '', tr => '',
        ml => '', mm => '', mr => '',
        bl => '', bm => '', br => '',
        h  => '', v  => '',
        htl => '', htm => '', htr => '', hh => '',
    },
);

sub generate_table {
    my (%opt) = @_;

    my $rows = $opt{rows};
    die "generate_table: rows must be an ARRAY reference\n"
        unless ref($rows) eq 'ARRAY';
    return '' unless @$rows;

    my $header_row    = $opt{header_row} // 0;
    my $row_separator = $opt{row_separator} // 0;
    my $padding       = exists $opt{padding} ? $opt{padding} : 1;
    my $border        = $opt{border} // 'ascii';
    my $align         = exists $opt{align} ? $opt{align} : [];
    my $max_col       = $opt{max_col_width} // 0;
    my $wrap          = exists $opt{wrap} ? $opt{wrap} : 1;
    my $null          = exists $opt{null_value} ? $opt{null_value} : '';
    my $header_border = $opt{header_border} // 'auto';
    my $encoding = exists $opt{encoding} ? $opt{encoding} : 'characters';

    _validate_encoding($encoding, 'encoding');

    die "generate_table: padding must be a non-negative integer\n"
        unless defined($padding) && $padding =~ /\A\d+\z/;
    die "generate_table: row_separator must be 0 or 1\n"
        unless $row_separator eq '0' || $row_separator eq '1';
    die "generate_table: header_row must be 0 or 1\n"
        unless $header_row eq '0' || $header_row eq '1';
    die "generate_table: wrap must be 0 or 1\n"
        unless $wrap eq '0' || $wrap eq '1';
    die "generate_table: align must be an ARRAY reference\n"
        unless ref($align) eq 'ARRAY';
    die "generate_table: unknown border style '$border'\n"
        unless exists $BORDERS{$border};
    die "generate_table: header_border must be 'auto', 'single', or 'double'\n"
        unless $header_border =~ /\A(?:auto|single|double)\z/;

    my $b = $BORDERS{$border};
    my (@data, $ncols);
    $ncols = 0;

    for my $r (@$rows) {
        die "generate_table: each row must be an ARRAY reference\n"
            unless ref($r) eq 'ARRAY';
        $ncols = @$r if @$r > $ncols;
        push @data, [ map {
            my $value = defined($_) ? "$_" : $null;
            $value = _decode_input($value, $encoding);
            _normalize($value);
        } @$r ];
    }
    return '' unless $ncols;

    for my $r (@data) {
        push @$r, ('') x ($ncols - @$r);
    }

    my @logical;
    if ($header_row) {
        my $h = shift @data;
        push @logical, { cells => $h, header => 1 };
    }
    push @logical, map { { cells => $_, header => 0 } } @data;

    my @alignments;
    for my $i (0 .. $ncols - 1) {
        my $a = $align->[$i] // 'left';
        die "generate_table: invalid alignment '$a' at column $i\n"
            unless $a =~ /\A(?:left|right|center)\z/;
        $alignments[$i] = $a;
    }

    my @limits;
    if (ref($max_col) eq 'ARRAY') {
        die "generate_table: max_col_width array must have one entry per column\n"
            unless @$max_col == $ncols;
        @limits = @$max_col;
    }
    elsif (ref($max_col)) {
        die "generate_table: max_col_width must be a number or ARRAY reference\n";
    }
    elsif ($max_col) {
        @limits = ($max_col) x $ncols;
    }
    else {
        @limits = (0) x $ncols;
    }
    for my $i (0 .. $#limits) {
        die "generate_table: max_col_width[$i] must be a non-negative integer\n"
            unless defined($limits[$i]) && $limits[$i] =~ /\A\d+\z/;
    }

    my @widths = (0) x $ncols;
    for my $row (@logical) {
        for my $i (0 .. $ncols - 1) {
            for my $line (split /\n/, $row->{cells}[$i], -1) {
                my $w = _width($line);
                $widths[$i] = $w if $w > $widths[$i];
            }
        }
    }
    for my $i (0 .. $ncols - 1) {
        $widths[$i] = $limits[$i]
            if $limits[$i] && $widths[$i] > $limits[$i];
        $widths[$i] = 1 if $widths[$i] < 1;
    }

    for my $row (@logical) {
        for my $i (0 .. $ncols - 1) {
            my @out_lines;
            for my $line (split /\n/, $row->{cells}[$i], -1) {
                if ($limits[$i] && _width($line) > $widths[$i]) {
                    if ($wrap) {
                        push @out_lines, _wrap_line($line, $widths[$i]);
                    }
                    else {
                        push @out_lines, _truncate($line, $widths[$i]);
                    }
                }
                else {
                    push @out_lines, $line;
                }
            }
            $row->{lines}[$i] = \@out_lines;
        }
    }

    my $pad = ' ' x $padding;
    my $horizontal = sub {
        my ($left, $middle, $right, $glyph) = @_;
        return '' if $border eq 'none';
        $glyph = $b->{h} unless defined $glyph;
        my @parts = map { $glyph x ($widths[$_] + 2 * $padding) } 0 .. $ncols - 1;
        return $left . join($middle, @parts) . $right;
    };
    my @out;
    push @out, $horizontal->($b->{tl}, $b->{tm}, $b->{tr}) if $border ne 'none';

    my @data_indexes = grep { !$logical[$_]{header} } 0 .. $#logical;
    my %last_data_index = @data_indexes ? ($data_indexes[-1] => 1) : ();

    for my $idx (0 .. $#logical) {
        my $row = $logical[$idx];
        my $height = 1;
        for my $i (0 .. $ncols - 1) {
            my $count = scalar @{ $row->{lines}[$i] };
            $height = $count if $count > $height;
        }
        for my $line_no (0 .. $height - 1) {
            my @cells;
            for my $i (0 .. $ncols - 1) {
                my $lines = $row->{lines}[$i];
                my $value = $line_no < @$lines ? $lines->[$line_no] : '';
                my $remaining = $widths[$i] - _width($value);
                die "generate_table: internal width error at column $i\n" if $remaining < 0;
                my ($left, $right) = (0, 0);
                if ($alignments[$i] eq 'right') {
                    $left = $remaining;
                }
                elsif ($alignments[$i] eq 'center') {
                    $left = int($remaining / 2);
                    $right = $remaining - $left;
                }
                else {
                    $right = $remaining;
                }
                push @cells, $pad . (' ' x $left) . $value . (' ' x $right) . $pad;
            }
            my $v = $border eq 'none' ? '' : $b->{v};
            push @out, $v . join($v, @cells) . $v;
        }

        next if $border eq 'none';
        if ($row->{header} && @data) {
            my $double = $header_border eq 'double'
                || ($header_border eq 'auto' && $border eq 'unicode');
            push @out, $double
                ? $horizontal->($b->{htl}, $b->{htm}, $b->{htr}, $b->{hh})
                : $horizontal->($b->{ml}, $b->{mm}, $b->{mr});
        }
        elsif (!$row->{header} && $row_separator && !$last_data_index{$idx}) {
            push @out, $horizontal->($b->{ml}, $b->{mm}, $b->{mr});
        }
    }

    push @out, $horizontal->($b->{bl}, $b->{bm}, $b->{br}) if $border ne 'none';
    my $result = join "\n", @out;
    return lc($encoding) eq 'characters'
        ? $result
        : encode($encoding, $result, FB_CROAK);
}

sub _validate_encoding {
    my ($encoding, $name) = @_;
    die "generate_table: $name must be a non-empty encoding name\n"
        unless defined($encoding) && !ref($encoding) && length($encoding);
    return if lc($encoding) eq 'characters';
    die "generate_table: unsupported $name '$encoding'\n"
        unless find_encoding($encoding);
}

sub _decode_input {
    my ($value, $encoding) = @_;
    return $value if lc($encoding) eq 'characters';
    die "generate_table: encoding '$encoding' expects byte strings, not decoded character strings\n"
        if utf8::is_utf8($value);
    return decode($encoding, $value, FB_CROAK);
}

sub _normalize {
    my ($s) = @_;
    $s =~ s/\r\n?/\n/g;
    my @lines = split /\n/, $s, -1;
    for my $line (@lines) {
        my $out = '';
        my $col = 0;
        while (length $line) {
            if ($line =~ s/\A([^\t]+)//s) {
                my $chunk = $1;
                $out .= $chunk;
                $col += _width($chunk);
            }
            elsif ($line =~ s/\A\t//) {
                my $spaces = 8 - ($col % 8);
                $out .= ' ' x $spaces;
                $col += $spaces;
            }
        }
        $line = $out;
    }
    $s = join "\n", @lines;
    $s =~ s/[\x00-\x08\x0B-\x1F\x7F]/?/g;
    return $s;
}

sub _width {
    my ($s) = @_;
    return Unicode::GCString->new($s)->columns;
}

sub _wrap_line {
    my ($s, $max_width) = @_;
    my (@out, $line, $width);
    $line = '';
    $width = 0;
    for my $g ($s =~ /(\X)/g) {
        my $gw = _width($g);
        if ($width + $gw > $max_width && length $line) {
            push @out, $line;
            $line = '';
            $width = 0;
        }
        if ($gw > $max_width) {
            push @out, $line if length $line;
            push @out, $g;
            $line = '';
            $width = 0;
            next;
        }
        $line .= $g;
        $width += $gw;
    }
    push @out, $line if length $line;
    push @out, '' unless @out;
    return @out;
}

sub _truncate {
    my ($s, $max_width) = @_;
    return $s if _width($s) <= $max_width;
    return '' if $max_width <= 0;
    my $ellipsis = $max_width >= 3 ? '...' : '';
    my $target = $max_width - _width($ellipsis);
    my $out = '';
    for my $g ($s =~ /(\X)/g) {
        last if _width($out . $g) > $target;
        $out .= $g;
    }
    return $out . $ellipsis;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Text::Table::Lite - Generate formatted tables from 2D arrays with multiline cells and multiple character encodings

表格转换文本工具，支持多种编码格式的中文，支持多行单元格。

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

=head2 Basic Usage

    use utf8;
    use Text::Table::Lite qw(generate_table);

    binmode STDOUT, ':encoding(UTF-8)';

    my $rows = [
        ['姓名', '工作地点', '公司职位'],
        ["雷军",   "北京\n昌平", "小米\n集团董事会\n创始人"],
        ["马云",   "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
        ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
    ];

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
    );

    print $table, "\n";

=head2 ASCII Borders

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'ascii',
        row_separator => 1,
    );

    print $table, "\n";

=head2 No Borders

    my $table = generate_table(
        rows   => $rows,
        border => 'none',
        align  => ['left', 'left', 'left'],
    );

    print $table, "\n";

=head2 Column Alignment

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
        align         => ['center', 'left', 'left'],
    );

=head2 Column Width Limits and Wrapping

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
        max_col_width => [6, 8, 10],
        wrap          => 1,
    );

=head2 GBK Input and Output

    use Encode qw(encode);
    use Text::Table::Lite qw(generate_table);

    my $rows = [
        [encode('GBK', '姓名'),
         encode('GBK', '工作地点'),
         encode('GBK', '公司职位')],

        [encode('GBK', '雷军'),
         encode('GBK', "北京\n昌平"),
         encode('GBK', "小米\n集团董事会\n创始人")],

        [encode('GBK', '马云'),
         encode('GBK', "浙江\n杭州"),
         encode('GBK', "阿里巴巴\n董事会\n创始人")],

        [encode('GBK', '刘强东'),
         encode('GBK', "北京\n亦庄"),
         encode('GBK', "京东\n集团董事会\n实控人")],
    ];

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'ascii',
        row_separator => 1,
        encoding      => 'GBK',
    );

    binmode STDOUT, ':raw';
    print $table, "\n";

=head1 DESCRIPTION

C<Text::Table::Lite> generates formatted text tables for terminal output,
command-line applications, database utilities, administrative tools, log
viewers, and other text-based interfaces.

The module is designed to handle Unicode text and multiline cell content
while maintaining consistent table alignment. It calculates the display
width of text rather than relying solely on the number of Perl characters
or the number of encoded bytes.

The module supports the following features:

=over 4

=item *

Unicode-aware display-width calculation for text containing Chinese and
other wide characters.

=item *

Multiline cells containing newline characters.

=item *

Automatic padding of rows containing fewer cells than the table's column
count.

=item *

Left, right, and center alignment for individual columns.

=item *

ASCII borders, Unicode borders, or borderless output.

=item *

Optional separators between data records.

=item *

Configurable header separator styles.

=item *

Optional maximum column widths, text wrapping, and truncation.

=item *

Configurable replacement text for undefined cell values.

=item *

Consistent input and output encoding through a single C<encoding> parameter.

=item *

Strict encoding conversion that reports invalid input bytes and unrepresentable
output characters instead of silently replacing them.

=back

The module exports C<generate_table> on request:

    use Text::Table::Lite qw(generate_table);

The function returns the complete formatted table as a scalar. It does not
print the table automatically.

=head1 FUNCTION

=head2 generate_table

    my $table = generate_table(%options);

Generates a formatted table from an array reference containing rows of cell
values.

The function accepts named options as key-value pairs and returns the
formatted table as a scalar. Depending on the C<encoding> option, the result
is either a Perl character string or an encoded byte string.

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
    );

    print $table, "\n";

Options should be supplied as key-value pairs. Unknown option names and
invalid option values should not be relied upon; consult the module's
validation behavior when integrating it into an application.

=head1 OPTIONS

The following options control the input data, table structure, formatting,
and character encoding.

=head2 rows

Required.

    rows => \@rows

An array reference containing the table rows. Each row must be represented
by an array reference containing its cell values.

Each cell is expected to contain a scalar value. Cell values may be
multiline strings containing newline characters. Undefined values are
replaced with the string specified by C<null_value>.

Example:

    my $rows = [
        ['姓名', '工作地点', '公司职位'],
        ["雷军",   "北京\n昌平", "小米\n集团董事会\n创始人"],
        ["马云",   "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
        ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
    ];

    my $table = generate_table(
        rows       => $rows,
        header_row => 1,
    );

The number of columns is determined by the widest row in the input data.
Rows with fewer cells are padded with empty cells so that all rows have
the same number of columns.

For example:

    my $rows = [
        ['姓名', '工作地点', '公司职位'],
        ['雷军', '北京'],
        ['马云', '浙江', '阿里巴巴', '额外字段'],
    ];

The widest row contains four cells. Consequently, the generated table
contains four columns, and shorter rows are padded with empty cells.

Applications should normally provide a consistent number of columns in
every row when a fixed table structure is required.

=head2 header_row

Optional. Default: C<0>.

    header_row => 1

When true, the first row is treated as the table header. This setting
affects header separator formatting when borders are enabled.

Example:

    my $table = generate_table(
        rows       => $rows,
        header_row => 1,
        border     => 'unicode',
    );

When C<header_row> is false, all rows are treated as ordinary data rows.

When C<header_row> is true, the first row is still part of the supplied
C<rows> array reference. The module does not create a header automatically.

The header is a formatting designation only. It does not change the input
data or the column count.

=head2 border

Optional. Default: C<ascii>.

    border => 'ascii'
    border => 'unicode'
    border => 'none'

Selects the border style used to render the table.

=over 4

=item C<ascii>

Uses ASCII characters for table borders. This style is suitable for
traditional terminals, restricted character sets, log files, and output
that must remain compatible with legacy systems.

    +----------+------------+------------+
    | 姓名     | 工作地点   | 公司职位   |
    +==========+============+============+
    | 雷军     | 北京       | 小米       |
    |          | 昌平       | 集团董事会 |
    |          |            | 创始人     |
    +----------+------------+------------+

The exact widths and separators depend on the input data and selected
options.

=item C<unicode>

Uses Unicode box-drawing characters to produce a visually structured
table.

    ┌────────┬──────────┬────────────┐
    │ 姓名   │ 工作地点 │ 公司职位   │
    ╞════════╪══════════╪════════════╡
    │ 雷军   │ 北京     │ 小米       │
    │        │ 昌平     │ 集团董事会 │
    │        │          │ 创始人     │
    ├────────┼──────────┼────────────┤
    │ 马云   │ 浙江     │ 阿里巴巴   │
    │        │ 杭州     │ 董事会     │
    │        │          │ 创始人     │
    └────────┴──────────┴────────────┘

The actual output depends on the selected width, alignment, padding,
and separator options.

Unicode borders require a terminal or output destination that can represent
the selected Unicode characters. When using UTF-8 output, configure the
output filehandle accordingly.

=item C<none>

Omits table border characters. This is useful for compact command-line
reports, plain-text output, and output that will be embedded in another
format.

    my $table = generate_table(
        rows   => $rows,
        border => 'none',
    );

=back

=head2 row_separator

Optional. Default: C<0>.

    row_separator => 1

When true, inserts a separator between adjacent table records.

This option is particularly useful for database query results, command-line
reports, and tables in which each logical record contains multiple physical
lines.

For example, a cell such as:

    "小米\n集团董事会\n创始人"

occupies three physical display lines, but it remains part of one logical
record. The row separator is drawn after the complete record, not between
the lines within that cell.

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
    );

When C<row_separator> is false, ordinary data records are not separated
by additional horizontal rules.

This option controls separators between records; it does not determine
whether the table has an outer border or whether the header has a distinct
separator.

=head2 header_border

Optional. Default: C<auto>.

    header_border => 'auto'
    header_border => 'single'
    header_border => 'double'

Controls the separator immediately below the header when C<header_row>
is true and the selected border style supports separators.

=over 4

=item C<auto>

Selects the default header separator for the chosen border style. With
Unicode borders, the header separator uses the double-line style. With
ASCII borders, it uses the corresponding ASCII separator style.

=item C<single>

Uses a single-line header separator.

=item C<double>

Uses a double-line header separator where supported by the selected
border style.

=back

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        header_border => 'double',
        row_separator => 1,
    );

The header separator and data-record separators serve different purposes.
C<header_border> controls the line below the header, while
C<row_separator> controls separators between data records.

When C<header_row> is false, there is no designated header row for
C<header_border> to separate.

=head2 padding

Optional. Default: C<1>.

    padding => 1

Specifies the number of spaces placed on each side of a cell's content.

For example, with:

    padding => 1

a cell has one space before its content and one space after it.

With:

    padding => 2

the cell has two spaces on each side of its content.

Example:

    my $table = generate_table(
        rows    => $rows,
        border  => 'unicode',
        padding => 2,
    );

Increasing padding improves readability but also increases the total
width of the table.

Use a small padding value for compact command-line output and a larger
value for reports intended to be read interactively.

The value should be a non-negative integer. Negative values and other
invalid values should not be used.

=head2 align

Optional.

    align => \@alignment

An array reference specifying the horizontal alignment of each column.
Each element should be one of:

=over 4

=item C<left>

Left-aligns the cell content.

=item C<right>

Right-aligns the cell content.

=item C<center>

Centers the cell content.

=back

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        align         => ['center', 'left', 'left'],
        row_separator => 1,
    );

The example centers the first column and left-aligns the second and third
columns.

Columns without an explicitly supplied alignment default to C<left>.

For example:

    align => ['left', 'right']

sets the first column to left alignment and the second column to right
alignment. Any remaining columns use the default alignment.

Alignment is applied to each physical line of a multiline cell. The
calculated display width, rather than the number of bytes in the encoded
string, is used to determine the amount of padding required.

=head2 max_col_width

Optional. Default: no maximum width.

    max_col_width => 20

or:

    max_col_width => [10, 20, 30]

Specifies the maximum content width of each column, measured in terminal
display columns.

Three forms are supported by the option design:

=over 4

=item *

Omit the option or use a value of C<0> to indicate that no explicit
maximum width is requested.

=item *

Supply a positive scalar to apply the same maximum content width to every
column.

=item *

Supply an array reference to specify a separate width for each column.

=back

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        max_col_width => 12,
        wrap          => 1,
    );

Per-column example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        max_col_width => [8, 10, 12],
        wrap          => 1,
    );

In the second example, the first column has a content-width limit of
8 display columns, the second column has a limit of 10, and the third
column has a limit of 12.

The maximum width applies to the cell content, excluding the surrounding
padding and border characters. Therefore, the overall column width can
be greater than the configured content-width limit.

When a column has a non-zero maximum width, C<wrap> determines whether
content is wrapped or truncated.

The maximum width should be a non-negative integer. When an array reference
is supplied, entries should correspond to the columns in the table.
Applications should provide enough entries to describe all columns whose
widths they need to control.

=head2 wrap

Optional. Default: C<1>.

    wrap => 1
    wrap => 0

Controls how content is handled when a column exceeds its configured
maximum width.

=over 4

=item C<wrap =E<gt> 1>

Enables wrapping for columns with a non-zero maximum width. Longer content
is distributed across multiple physical lines so that it fits within the
specified content width.

=item C<wrap =E<gt> 0>

Disables wrapping. Content that exceeds a configured maximum width is
truncated according to the module's rendering behavior.

=back

Example of wrapping:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        max_col_width => [8, 8, 10],
        wrap          => 1,
    );

Example of truncation:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        max_col_width => [8, 8, 10],
        wrap          => 0,
    );

When no maximum column width is configured, C<wrap> does not by itself
impose a width limit. Existing newline characters in cell values still
represent explicit line breaks.

Wrapping and truncation should be tested with the actual text and terminal
environment used by the application, especially when the text contains
wide Unicode characters.

=head2 encoding

Optional. Default: C<characters>.

    encoding => 'characters'
    encoding => 'UTF-8'
    encoding => 'GBK'
    encoding => 'GB2312'
    encoding => 'Big5'

Specifies the encoding used for both input cell values and the returned
table. Input and output encodings are intentionally kept identical.

The module uses Perl's C<Encode> facilities to convert between encoded
byte strings and Perl character strings.

=over 4

=item C<characters>

Indicates that input cell values are already-decoded Perl character
strings and that the returned table should also be a character string.

This is the default and is generally recommended when the application
uses C<use utf8> for source literals and performs I/O through correctly
configured Perl filehandles.

Example:

    use utf8;
    use Text::Table::Lite qw(generate_table);

    binmode STDOUT, ':encoding(UTF-8)';

    my $table = generate_table(
        rows     => $rows,
        encoding => 'characters',
        border   => 'unicode',
    );

    print $table, "\n";

The C<characters> setting does not encode the returned string into UTF-8
or any other byte representation. The output filehandle is responsible
for encoding the character string when it is written.

=item Encoded byte strings

When C<encoding> is set to a name recognized by Perl's C<Encode>, input
cell values are interpreted as byte strings in that encoding, and the
returned table is encoded using the same encoding.

Example using GBK:

    use Encode qw(encode);
    use Text::Table::Lite qw(generate_table);

    my $rows = [
        [encode('GBK', '姓名'),
         encode('GBK', '工作地点'),
         encode('GBK', '公司职位')],

        [encode('GBK', '雷军'),
         encode('GBK', "北京\n昌平"),
         encode('GBK', "小米\n集团董事会\n创始人")],
    ];

    my $table = generate_table(
        rows     => $rows,
        encoding => 'GBK',
        border   => 'ascii',
    );

    binmode STDOUT, ':raw';
    print $table, "\n";

In this example, the input strings are GBK-encoded byte strings, and the
returned table is also a GBK-encoded byte string.

Do not configure the output filehandle to encode the result a second time.
When the function returns encoded bytes, use an appropriate raw filehandle
or write the bytes to a destination expecting that encoding.

=item Supported encoding names

The encoding name must be supported by the installed Perl C<Encode>
implementation. Common examples include C<UTF-8>, C<GBK>, C<GB2312>, and
C<Big5>. The exact set of recognized aliases depends on the installed
Perl distribution and its encoding tables.

Use the encoding name supported by the target Perl installation.

=item Strict conversion

Encoded mode uses strict conversion. Invalid input byte sequences cause
an exception. Output characters that cannot be represented in the selected
encoding also cause an exception.

For example, a Unicode character outside the representable range of GBK
cannot be silently substituted when the conversion is strict.

=item Character strings and byte strings must not be mixed

In encoded mode, input values must be byte strings in the selected encoding.
Do not pass already-decoded, UTF-8-flagged Perl character strings to an
encoded mode that expects raw bytes.

In character mode, pass decoded Perl character strings rather than strings
that still contain bytes in an external encoding.

Mixing these representations can cause decoding errors, incorrect text,
or double encoding.

=item Border compatibility

Some encodings, including GBK and Big5, cannot represent all Unicode
box-drawing characters used by Unicode table borders.

For such output encodings, use:

    border => 'ascii'

when an ASCII border is sufficient and compatible with the target
environment.

If Unicode borders are required, use a compatible Unicode output encoding
such as UTF-8, together with an output destination that supports it.

=back

=head2 null_value

Optional. Default: the empty string.

    null_value => ''

Specifies the replacement value used for undefined cell values.

Example:

    my $rows = [
        ['姓名', '工作地点', '公司职位'],
        ['雷军', undef,      '小米'],
        ['马云', '浙江杭州', undef],
    ];

    my $table = generate_table(
        rows       => $rows,
        header_row => 1,
        border     => 'unicode',
        null_value => '(未提供)',
    );

The replacement value is used instead of an undefined cell value. It does
not replace an explicitly supplied empty string.

For example, C<undef> and C<''> have different meanings:

    ['雷军', undef, '小米']
    ['马云', '',    '阿里巴巴']

With C<null_value =E<gt> '(未提供)'>, the undefined cell is displayed as
C<(未提供)>, while the explicitly empty cell remains empty.

The replacement value should use the same character or byte representation
as the other cell values, according to the selected C<encoding> mode.

=head1 OUTPUT AND DISPLAY WIDTH

The function returns the entire formatted table in one scalar. It does
not automatically print a newline after the table.

Example:

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
    );

    print $table, "\n";

The caller is responsible for adding a final newline if desired.

The module uses Unicode display-width calculation to align cell contents.
This is important because the number of characters in a string is not
always equal to the number of terminal columns it occupies.

For example, many Chinese characters occupy two terminal columns, while
ordinary Latin letters usually occupy one. Counting bytes or Perl
characters alone is therefore insufficient for reliable table alignment.

Actual rendering may also depend on the terminal emulator, font, Unicode
width conventions, and output encoding. Applications that require
consistent presentation across different environments should test their
target terminals and output destinations.

=head1 COMMON USAGE PATTERNS

=head2 Database Query Results

    my $rows = [
        ['ID', '姓名', '工作地点'],
        [1, '雷军',   "北京\n昌平"],
        [2, '马云',   "浙江\n杭州"],
        [3, '刘强东', "北京\n亦庄"],
    ];

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'unicode',
        row_separator => 1,
        align         => ['right', 'left', 'left'],
    );

    print $table, "\n";

This pattern is suitable for rendering database query results or reports
in command-line applications.

=head2 Compact Output

    my $table = generate_table(
        rows    => $rows,
        border  => 'none',
        padding => 0,
    );

Use this style when minimizing output width is more important than
visual separation.

=head2 Fixed-Width Reports

    my $table = generate_table(
        rows          => $rows,
        header_row    => 1,
        border        => 'ascii',
        row_separator => 1,
        max_col_width => [12, 16, 20],
        wrap          => 1,
        padding       => 1,
    );

This pattern is useful when output must fit within a known terminal width
or when producing compact text reports.

=head2 Right-Aligned Numeric Columns

    my $rows = [
        ['姓名', '记录数'],
        ['雷军', 123],
        ['马云', 4567],
    ];

    my $table = generate_table(
        rows       => $rows,
        header_row => 1,
        border     => 'unicode',
        align      => ['left', 'right'],
    );

Right alignment is commonly used for numeric values so that the digits
are easier to compare vertically.

=head1 ERROR HANDLING

The function may throw an exception when it encounters invalid options
or invalid encoding data.

Applications that need to recover from formatting errors should wrap the
call in an C<eval> block and inspect C<$@>.

Example:

    my $table;

    eval {
        $table = generate_table(
            rows     => $rows,
            encoding => 'GBK',
            border   => 'ascii',
        );

        1;
    } or do {
        my $error = $@ || 'Unknown table formatting error';
        warn "Unable to generate table: $error";
    };

Do not assume that invalid input will always be silently corrected.
In particular, encoded mode intentionally reports invalid byte sequences
and output characters that cannot be represented in the requested
encoding.

=head1 DEPENDENCIES

This module requires:

=over 4

=item *

C<Unicode::GCString> for Unicode-aware terminal display-width calculation.

=item *

C<Encode>, included with standard Perl distributions, for character
encoding conversion.

=back

=head1 COMPATIBILITY NOTES

=over 4

=item *

Use C<use utf8> when the Perl source file contains non-ASCII character
literals and is saved in UTF-8.

=item *

C<use utf8> affects how Perl parses source text. It does not automatically
decode arbitrary external byte strings.

=item *

For character-mode output, configure the output filehandle to match the
destination encoding. For UTF-8 terminal output, this is commonly:

    binmode STDOUT, ':encoding(UTF-8)';

=item *

For encoded byte output, avoid applying another encoding layer to the
already-encoded result.

=item *

When using GBK, GB2312, or Big5, ASCII borders are generally safer than
Unicode box-drawing borders.

=item *

Unicode display widths can vary in some terminal environments, particularly
for combining marks, emoji, and characters whose display width is
ambiguous. Validate the final appearance in the target environment.

=back

=head1 AUTHOR

H.Q. Wang

=head1 LICENSE

This module is free software. You may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode>, L<Unicode::GCString>, L<perlunicode>, L<perlfunc>, L<perlop>

=cut