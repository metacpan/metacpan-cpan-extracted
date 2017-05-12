package Text::UnicodeTable::Simple;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.10';

use Carp ();
use Scalar::Util qw(looks_like_number);
use Unicode::EastAsianWidth;
use Term::ANSIColor ();

use constant ALIGN_LEFT  => 1;
use constant ALIGN_RIGHT => 2;

use overload '""' => sub { shift->draw };

# alias for Text::ASCIITable
{
    no warnings 'once';
    *setCols    = \&set_header;
    *addRow     = \&add_row;
    *addRowLine = \&add_row_line;
}

sub new {
    my ($class, %args) = @_;

    my $header = delete $args{header};
    if (defined $header && (ref $header ne 'ARRAY')) {
        Carp::croak("'header' param should be ArrayRef");
    }

    my $alignment = delete $args{alignment};
    if (defined $alignment) {
        unless ($alignment eq 'left' || $alignment eq 'right') {
            Carp::croak("'alignment' param should be 'left' or 'right'");
        }
        if ($alignment eq 'left') {
            $alignment = ALIGN_LEFT;
        } else {
            $alignment = ALIGN_RIGHT;
        }
    }

    my $ansi_color = delete $args{ansi_color} || 0;
    my $self = bless {
        header     => [],
        rows       => [],
        border     => 1,
        ansi_color => $ansi_color,
        alignment  => $alignment,
        %args,
    }, $class;

    if (defined $header) {
        $self->set_header($header);
    }

    $self;
}

sub set_header {
    my $self = shift;
    my @headers = _check_argument(@_);

    if (scalar @headers == 0) {
        Carp::croak("Error: Input array has no element");
    }

    $self->{width} = scalar @headers;
    $self->{header} = [ $self->_divide_multiline(\@headers) ];

    return $self;
}

sub _divide_multiline {
    my ($self, $elements_ref) = @_;

    my @each_lines;
    my $longest = -1;
    for my $element (@{$elements_ref}) {
        my @divided = $element ne '' ? (split "\n", $element) : ('');
        push @each_lines, [ @divided ];

        $longest = scalar(@divided) if $longest < scalar(@divided);
    }

    _adjust_cols(\@each_lines, $longest);

    my @rows;
    my @alignments;
    for my $i (0..($longest-1)) {
        my @cells;
        for my $j (0..($self->{width}-1)) {
            $alignments[$j] ||= $self->_decide_alignment($each_lines[$j]->[$i]);
            push @cells, Text::UnicodeTable::Simple::Cell->new(
                text      => $each_lines[$j]->[$i],
                alignment => $alignments[$j],
            );
        }

        push @rows, [ @cells ];
    }

    return @rows;
}

sub _decide_alignment {
    my ($self, $str) = @_;
    return $self->{alignment} if $self->{alignment};
    return looks_like_number($str) ? ALIGN_RIGHT : ALIGN_LEFT;
}

sub _adjust_cols {
    my ($cols_ref, $longest) = @_;

    for my $cols (@{$cols_ref}) {
        my $spaces = $longest - scalar(@{$cols});
        push @{$cols}, '' for 1..$spaces;
    }
}

sub add_rows {
    my ($self, @rows) = @_;

    $self->add_row($_) for @rows;
    return $self;
}

sub add_row {
    my $self = shift;
    my @rows = _check_argument(@_);

    $self->_check_set_header;

    if ($self->{width} < scalar @rows) {
        Carp::croak("Error: Too many elements")
    }

    push @rows, '' for 1..($self->{width} - scalar @rows);

    push @{$self->{rows}}, $self->_divide_multiline(\@rows);

    return $self;
}

sub _check_set_header {
    my $self = shift;

    unless (exists $self->{width}) {
        Carp::croak("Error: you should call 'set_header' method previously");
    }
}

sub _check_argument {
    my @args = @_;

    my @ret;
    if (ref($args[0]) eq "ARRAY") {
        if (scalar @args == 1) {
            @ret = @{$args[0]}
        } else {
            Carp::croak("Error: Multiple ArrayRef arguments");
        }
    } else {
        @ret = @_;
    }

    # replace 'undef' with 0 length string ''
    return map { defined $_ ? $_ : '' } @ret;
}

sub add_row_line {
    my $self = shift;

    $self->_check_set_header;

    my $line = bless [], 'Text::UnicodeTable::Simple::Line';
    push @{$self->{rows}}, $line;

    return $self;
}

sub draw {
    my $self = shift;
    my @ret;

    $self->_check_set_header;

    $self->_set_column_length();
    $self->_set_separator();

    # header
    push @ret, $self->{top_line} if $self->{border};
    push @ret, $self->_generate_row_string($_) for @{$self->{header}};
    push @ret, $self->{separator} if $self->{border};

    # body
    my $row_length = scalar @{$self->{rows}};
    for my $i (0..($row_length-1)) {
        my $row = $self->{rows}->[$i];

        if (ref($row) eq 'ARRAY') {
            push @ret, $self->_generate_row_string($row);
        } elsif ( ref($row) eq 'Text::UnicodeTable::Simple::Line') {
            # if last line is row_line, it is ignored.
            push @ret, $self->{separator} if $i != $row_length-1;
        }
    }

    push @ret, $self->{bottom_line} if $self->{border};

    my $str = join "\n", @ret;
    return "$str\n";
}

sub _generate_row_string {
    my ($self, $row_ref) = @_;

    my $separator = $self->{border} ? '|' : '';
    my $str = $separator;

    my $index = 0;
    for my $row_elm (@{$row_ref}) {
        $str .= $self->_format($row_elm, $self->_get_column_length($index));
        $str .= $separator;
        $index++;
    }

    $str =~ s{(^\s|\s$)}{}g if $self->{border};

    return $str;
}

sub _format {
    my ($self, $cell, $width) = @_;

    my $str = $cell->text;
    $str = " $str ";
    my $len = $self->_str_width($str);

    my $retval;
    if ($cell->alignment == ALIGN_RIGHT) {
        $retval = (' ' x ($width - $len)) . $str;
    } else {
        $retval = $str . (' ' x ($width - $len));
    }

    return $retval;
}

sub _set_separator {
    my $self = shift;

    my $each_row_width = $self->{column_length};
    my $str = '+';
    for my $width (@{$each_row_width}) {
        $str .= ('-' x $width);
        $str .= '+';
    }

    $self->{separator}    = $self->{border} ? $str : "";
    ($self->{top_line}    = $str) =~ s{^\+(.*?)\+$}{.$1.};
    ($self->{bottom_line} = $str) =~ s{^\+(.*?)\+$}{'$1'};
}

sub _get_column_length {
    my ($self, $index) = @_;
    return $self->{column_length}->[$index];
}

sub _set_column_length {
    my $self = shift;

    my @cols_length = $self->_column_length($self->{header});
    my @rows_length = $self->_column_length($self->{rows});

    # add space before and after string
    my @max = map { $_ + 2 } _select_max(\@cols_length, \@rows_length);

    $self->{column_length} = \@max;
}

sub _column_length {
    my ($self, $matrix_ref) = @_;

    my $width  = $self->{width};
    my $height = scalar @{$matrix_ref};

    my @each_cols_length;
    for (my $i = 0; $i < $width; $i++) {
        my $max = -1;
        for (my $j = 0; $j < $height; $j++) {
            next unless ref $matrix_ref->[$j] eq 'ARRAY';

            my $cell = $matrix_ref->[$j]->[$i];
            my $len = $self->_str_width($cell->text);
            $max = $len if $len > $max;
        }

        $each_cols_length[$i] = $max;
    }

    return @each_cols_length;
}

sub _select_max {
    my ($a, $b) = @_;

    my ($a_length, $b_length) = map { scalar @{$_} } ($a, $b);
    if ( $a_length != $b_length) {
        Carp::croak("Error: compare different length arrays");
    }

    my @max;
    for my $i (0..($a_length - 1)) {
        push @max, $a->[$i] >= $b->[$i] ? $a->[$i] : $b->[$i];
    }

    return @max;
}

sub _str_width {
    my ($self, $str) = @_;

    if ($self->{ansi_color}) {
        $str = Term::ANSIColor::colorstrip($str);
    }

    my $ret = 0;
    while ($str =~ /(?:(\p{InFullwidth}+)|(\p{InHalfwidth}+))/go) {
        $ret += ($1 ? length($1) * 2 : length($2));
    }

    return $ret;
}

# utility class
{
    package # hide from pause
        Text::UnicodeTable::Simple::Cell;

    sub new {
        my ($class, %args) = @_;
        bless {
            text      => $args{text},
            alignment => $args{alignment},
        }, $class;
    }

    sub text {
        $_[0]->{text};
    }

    sub alignment {
        $_[0]->{alignment};
    }
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Text::UnicodeTable::Simple - Create a formatted table using characters.

=head1 SYNOPSIS

  use Text::UnicodeTable::Simple;
  $t = Text::UnicodeTable::Simple->new();

  $t->set_header(qw/Subject Score/);
  $t->add_row('English',     '78');
  $t->add_row('Mathematics', '91');
  $t->add_row('Chemistry',   '64');
  $t->add_row('Physics',     '95');
  $t->add_row_line();
  $t->add_row('Total', '328');

  print "$t";

  # Result:
  .-------------+-------.
  | Subject     | Score |
  +-------------+-------+
  | English     |    78 |
  | Mathematics |    91 |
  | Chemistry   |    64 |
  | Physics     |    95 |
  +-------------+-------+
  | Total       |   328 |
  '-------------+-------'

=head1 DESCRIPTION

Text::UnicodeTable::Simple creates character table.

There are some modules for creating a text table at CPAN, L<Text::ASCIITable>,
L<Text::SimpleTable>, L<Text::Table> etc. But those module deal with only ASCII,
don't deal with full width characters. If you use them with full width
characters, a table created may be bad-looking.

Text::UnicodeTable::Simple resolves problem of full width characters.
So you can use Japansese Hiragana, Katakana, Korean Hangeul, Chinese Kanji
characters. See C<eg/> directory for examples.

=head1 INTERFACE

=head2 Methods

=head3 new(%args)

Creates and returns a new table instance with I<%args>.

I<%args> might be

=over

=item header :ArrayRef

Table header. If you set table header with constructor,
you can omit C<set_header> method.

=item border :Bool = True

Table has no border if C<border> is False.

=item ansi_color :Bool = False

Ignore ANSI color escape sequence

=item alignment :Int = 'left' or 'right'

Alignment for each columns. Every columns are aligned by this if you
specify this parameter.

=back

=head3 set_header() [alias: setCols ]

Set the headers for the table. (compare with E<lt>thE<gt> in HTML).
You must call C<set_header> firstly. If you call other methods
without calling C<set_header>, then you fail.

Input strings should be B<string>, not B<octet stream>.

=head3 add_row(@list_of_columns | \@list_of_columns) [alias: addRow ]

Add one row to the table.

Input strings should be B<string>, not B<octet stream>.

=head3 add_rows(@list_of_columns)

Add rows to the table. You can add row at one time.
Each C<@collists> element should be ArrayRef.

=head3 add_row_line() [alias: addRowLine ]

Add a line after the current row. If 'border' parameter is false,
add a new line.

=head3 draw()

Return the table as string.

Text::UnicodeTable::Simple overload stringify operator,
so you can omit C<-E<gt>draw()> method.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 SEE ALSO

L<Text::ASCIITable>

L<Text::SimpleTable>

L<Text::Table>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
